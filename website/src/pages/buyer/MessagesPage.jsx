import { useEffect, useRef, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { ListPanel } from '../shared/FeatureCards';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId } from '../../lib/api';
import { parseThreadsToRows, threadPayloadToRow } from '../../lib/chatUtils';
import * as chatApi from '../../api/chat';
import { ChatThread } from '../../components/chat/ChatThread';
import { getSocket, initSocket } from '../../lib/socket';

export function MessagesPage() {
  const { user } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [activeThread, setActiveThread] = useState(null);
  const createThreadTimeoutRef = useRef(null);
  const rowsRef = useRef([]);
  rowsRef.current = rows;

  const loadThreads = async () => {
    if (!userId) return;
    setLoading(true);
    setError('');
    try {
      const data = await chatApi.getThreads(userId);
      const parsed = parseThreadsToRows(data, userId);
      setRows(parsed);
      return parsed;
    } catch (err) {
      setError(err?.message || 'Unable to load messages.');
      setRows([]);
      return [];
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!userId) {
      setLoading(false);
      return;
    }
    initSocket(userId);
    loadThreads();
  }, [userId]);

  // Socket: thread_created, thread_updated, unread_count
  useEffect(() => {
    const socket = getSocket();
    if (!socket || !userId) return undefined;

    const handleThreadCreated = (payload) => {
      if (import.meta.env?.DEV) console.log('[MessagesPage] thread_created', payload);
      const t = payload?.thread || payload;
      if (!t?._id) return;
      const row = threadPayloadToRow(t, userId);
      if (!row) return;
      setRows((prev) => {
        const exists = prev.some((r) => String(r.id) === String(row.id));
        if (exists) {
          return prev.map((r) => (String(r.id) === String(row.id) ? { ...r, ...row } : r));
        }
        return [row, ...prev];
      });
    };

    const handleThreadUpdated = (payload) => {
      if (import.meta.env?.DEV) console.log('[MessagesPage] thread_updated', payload);
      const t = payload?.thread || payload;
      if (!t?._id) return;
      const row = threadPayloadToRow(t, userId);
      if (!row) return;
      setRows((prev) => {
        const exists = prev.some((r) => String(r.id) === String(row.id));
        if (exists) {
          return prev.map((r) => (String(r.id) === String(row.id) ? { ...r, ...row } : r));
        }
        return [row, ...prev];
      });
    };

    const handleUnreadCount = (payload) => {
      const threads = payload?.threads || [];
      if (!Array.isArray(threads) || threads.length === 0) return;
      setRows((prev) =>
        prev.map((r) => {
          const match = threads.find((t) => String(t.chatId) === String(r.id));
          return match ? { ...r, unread: Number(match.count) || 0 } : r;
        }),
      );
    };

    /** Backend emits to receiver's room when new message arrives - use for instant thread list updates */
    const handleMessageNotification = (payload) => {
      if (import.meta.env?.DEV) console.log('[MessagesPage] message_notification', payload);
      const threadId = payload?.threadId || payload?.thread_id;
      const preview = payload?.message || payload?.text || 'New message';
      if (!threadId) return;
      const found = rowsRef.current.find((r) => String(r.id) === String(threadId));
      if (found) {
        setRows((prev) =>
          prev.map((r) =>
            String(r.id) === String(threadId)
              ? { ...r, preview, unread: (Number(r.unread) || 0) + 1 }
              : r,
          ),
        );
      } else {
        loadThreads();
      }
    };

    socket.on('thread_created', handleThreadCreated);
    socket.on('thread_updated', handleThreadUpdated);
    socket.on('unread_count', handleUnreadCount);
    socket.on('message_notification', handleMessageNotification);

    return () => {
      socket.off('thread_created', handleThreadCreated);
      socket.off('thread_updated', handleThreadUpdated);
      socket.off('unread_count', handleUnreadCount);
      socket.off('message_notification', handleMessageNotification);
    };
  }, [userId]);

  // openChatWith from navigation state
  useEffect(() => {
    const openChatWith = location.state?.openChatWith;
    if (!openChatWith || !userId) return;

    const otherUserId = openChatWith?._id || openChatWith?.id || openChatWith?.userId;
    const otherName = openChatWith?.fullname || openChatWith?.name || 'Conversation';

    if (!otherUserId || String(otherUserId) === String(userId)) return;

    let cancelled = false;
    const openOrCreate = async () => {
      try {
        const data = await chatApi.getThreads(userId);
        const parsed = parseThreadsToRows(data, userId);
        if (cancelled) return;
        setRows(parsed);

        const existing = parsed?.find(
          (r) => r.otherUserId && String(r.otherUserId) === String(otherUserId),
        );
        if (existing) {
          setActiveThread(existing);
          navigate('.', { replace: true, state: {} });
          return;
        }

        const socket = getSocket();
        if (socket?.connected) {
          socket.emit('create_thread', {
            participantIds: [userId, otherUserId],
            initiatorId: userId,
          });

          const onSuccess = (payload) => {
            const t = payload?.thread || payload;
            const threadId = t?._id || t?.id;
            if (!threadId) return;
            if (cancelled) return;
            setActiveThread({
              id: threadId,
              name: otherName,
              otherUserId,
              preview: t?.lastMessage?.text,
              unread: 0,
            });
            navigate('.', { replace: true, state: {} });
            socket.off('create_thread_success', onSuccess);
          };

          socket.once('create_thread_success', onSuccess);

          createThreadTimeoutRef.current = setTimeout(async () => {
            socket.off('create_thread_success', onSuccess);
            if (cancelled) return;
            try {
              const res = await chatApi.createThread(userId, otherUserId);
              if (cancelled) return;
              const thread = res?.thread || res?.data || res;
              const tid = thread?._id || thread?.id;
              if (tid) {
                setActiveThread({ id: tid, name: otherName, otherUserId });
                navigate('.', { replace: true, state: {} });
              }
            } catch (err) {
              if (!cancelled) setError(err?.message || 'Could not start conversation.');
            }
          }, 5000);

          return;
        }

        const res = await chatApi.createThread(userId, otherUserId);
        if (cancelled) return;
        const thread = res?.thread || res?.data || res;
        const threadId = thread?._id || thread?.id;
        if (threadId) {
          setActiveThread({ id: threadId, name: otherName, otherUserId });
          navigate('.', { replace: true, state: {} });
        }
      } catch (err) {
        if (!cancelled) setError(err?.message || 'Could not start conversation.');
      }
    };

    openOrCreate();
    return () => {
      cancelled = true;
      if (createThreadTimeoutRef.current) {
        clearTimeout(createThreadTimeoutRef.current);
        createThreadTimeoutRef.current = null;
      }
    };
  }, [location.state?.openChatWith, userId, navigate]);

  const openThread = (row) => {
    setActiveThread(row);
  };

  const handleCloseThread = () => {
    setActiveThread(null);
  };

  const handleThreadCreated = (newThread) => {
    if (newThread?.id) {
      setActiveThread(newThread);
      setRows((prev) => {
        const exists = prev.some((r) => String(r.id) === String(newThread.id));
        if (exists) return prev.map((r) => (String(r.id) === String(newThread.id) ? newThread : r));
        return [newThread, ...prev];
      });
    }
  };

  if (activeThread) {
    return (
      <div className="page-body messages-full-chat">
        <ChatThread
          thread={activeThread}
          onClose={handleCloseThread}
          onThreadCreated={handleThreadCreated}
        />
      </div>
    );
  }

  return (
    <div className="page-body">
      <PageHeader
        title="Messages"
        subtitle="Instant chat with agents and loan officers."
        icon="messages"
      />
      {error ? (
        <div className="glass-card panel" style={{ padding: '1rem' }}>
          <p className="error-text">{error}</p>
          <button className="btn tiny" type="button" onClick={loadThreads}>
            Retry
          </button>
        </div>
      ) : loading ? (
        <div className="glass-card panel" style={{ padding: '2rem', textAlign: 'center' }}>
          <p>Loading conversations...</p>
        </div>
      ) : (
        <ListPanel
          title="Conversations"
          rows={rows}
          renderRight={(row) => (
            <div className="row">
              {row.unread ? <span className="pill">{row.unread}</span> : null}
              <button className="btn tiny" type="button" onClick={() => openThread(row)}>
                Open
              </button>
            </div>
          )}
        />
      )}
      {!loading && !error && (
        <button
          className="btn ghost tiny"
          type="button"
          onClick={loadThreads}
          style={{ marginTop: '0.5rem' }}
        >
          Refresh
        </button>
      )}
    </div>
  );
}
