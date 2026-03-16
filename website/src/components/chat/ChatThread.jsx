import { useEffect, useMemo, useRef, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList } from '../../lib/api';
import * as chatApi from '../../api/chat';
import { getSocket } from '../../lib/socket';
import { threadPayloadToRow } from '../../lib/chatUtils';

function extractId(value) {
  if (!value) return '';
  if (typeof value === 'string' || typeof value === 'number') return String(value);
  if (typeof value === 'object') return String(value._id || value.id || value.userId || '');
  return '';
}

/** Normalize backend message payload to { id, fromUserId, text, timestamp } */
function normalizeMessage(m, index) {
  const fromId =
    m.sender ||
    m.fromUserId ||
    m.senderId ||
    m.userId ||
    m.from ||
    m.authorId ||
    (typeof m.user === 'object' ? m.user?._id || m.user?.id : null) ||
    null;
  const text = m.text || m.message || m.body || m.content || '';
  const timestamp =
    m.createdAt || m.sentAt || m.timestamp || m.updatedAt || new Date().toISOString();
  return {
    id: m._id || m.id || `m-${index}`,
    fromUserId: extractId(fromId),
    text,
    timestamp,
  };
}

export function ChatThread({ thread, onClose, onThreadCreated }) {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const scrollRef = useRef(null);
  const lastOptimisticIdRef = useRef(null);

  const title = thread?.name || thread?.title || 'Conversation';
  const otherUserId = thread?.otherUserId || null;
  const threadId = thread?.id ? String(thread.id) : null;
  const isTempThread = threadId && (threadId.startsWith('temp_') || threadId === 'temp');

  const normalizedMessages = useMemo(
    () => messages.map((m, i) => normalizeMessage(m, i)),
    [messages],
  );

  const loadMessages = async () => {
    if (!threadId || !userId || isTempThread) return;
    setError('');
    try {
      const res = await chatApi.getThreadMessages(threadId, userId);
      const list = unwrapList(res, ['messages', 'data']);
      setMessages(list);
    } catch (err) {
      setError(err.message || 'Unable to load messages.');
      setMessages([]);
    }
  };

  useEffect(() => {
    let live = true;
    if (!threadId || !userId || isTempThread) return undefined;

    const run = async () => {
      if (!live) return;
      await loadMessages();
    };

    run();

    return () => { live = false; };
  }, [threadId, userId, isTempThread]);

  useEffect(() => {
    if (!scrollRef.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [normalizedMessages.length]);

  // Join thread room, mark as read via socket, listen for messages
  useEffect(() => {
    const socket = getSocket();
    if (!socket || !userId) return undefined;

    if (threadId && !isTempThread) {
      socket.emit('join_thread', threadId);
      socket.emit('mark_messages_read', { threadId, userId });
    }

    const handleNewMessage = (payload) => {
      if (!payload) return;
      const incomingThreadId = payload.threadId || payload.thread_id || payload.chatId;
      if (threadId && incomingThreadId && String(incomingThreadId) !== String(threadId)) return;
      if (isTempThread && incomingThreadId) {
        // Thread created from first message - parent should update
        if (onThreadCreated) onThreadCreated({ ...thread, id: incomingThreadId });
      }

      const fromUs = extractId(payload.sender || payload.senderId) === String(userId);

      setMessages((prev) => {
        const hasId = payload._id && prev.some((m) => String(m._id || m.id) === String(payload._id));
        if (hasId) return prev;

        if (fromUs && lastOptimisticIdRef.current) {
          return prev.map((m) =>
            String(m.id) === lastOptimisticIdRef.current
              ? { ...payload, _id: payload._id, id: payload._id }
              : m,
          );
        }
        return [...prev, payload];
      });
    };

    const handleSentSuccess = (payload) => {
      if (!payload) return;
      const incomingThreadId = payload.threadId || payload.thread_id;
      if (threadId && incomingThreadId && String(incomingThreadId) !== String(threadId)) return;

      setMessages((prev) => {
        const optId = lastOptimisticIdRef.current;
        if (!optId) return prev;
        return prev.map((m) =>
          String(m.id) === optId ? { ...payload, _id: payload._id, id: payload._id } : m,
        );
      });
      lastOptimisticIdRef.current = null;
    };

    const handleThreadCreated = (payload) => {
      if (!payload?.thread || !onThreadCreated) return;
      const t = payload.thread;
      const participants = t.participants || [];
      const isForUs =
        Array.isArray(participants) &&
        participants.some((p) => String(p) === String(userId));
      if (!isForUs) return;
      const otherId = participants.find((p) => String(p) !== String(userId));
      if (isTempThread && otherId === String(otherUserId)) {
        onThreadCreated(threadPayloadToRow(t, userId, title));
      }
    };

    socket.on('new_message', handleNewMessage);
    socket.on('message_sent_success', handleSentSuccess);
    socket.on('thread_created', handleThreadCreated);

    return () => {
      if (threadId && !isTempThread) {
        socket.emit('leave_thread', threadId);
      }
      socket.off('new_message', handleNewMessage);
      socket.off('message_sent_success', handleSentSuccess);
      socket.off('thread_created', handleThreadCreated);
    };
  }, [threadId, userId, isTempThread, otherUserId, title, onThreadCreated]);

  const handleSend = async () => {
    const text = input.trim();
    if (!text || sending || !userId) return;

    const hasValidThread = threadId && !isTempThread;
    const hasParticipants = otherUserId && (isTempThread || !threadId);

    if (!hasValidThread && !hasParticipants) {
      setError('Cannot send: no thread or recipient.');
      return;
    }

    setSending(true);
    setError('');
    const optimisticId = `local-${Date.now()}`;
    lastOptimisticIdRef.current = optimisticId;
    const optimistic = {
      id: optimisticId,
      _id: optimisticId,
      sender: userId,
      senderId: userId,
      text,
      createdAt: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, optimistic]);
    setInput('');

    try {
      const socket = getSocket();
      const payload = {
        senderId: userId,
        text,
        threadId: hasValidThread ? threadId : '',
      };
      if (hasParticipants) {
        payload.participantIds = [userId, otherUserId];
      }

      if (socket?.connected) {
        socket.emit('send_message', payload);
      } else {
        if (!hasValidThread) {
          setError('Connect to start a new conversation.');
          setMessages((prev) => prev.filter((m) => m.id !== optimisticId));
          lastOptimisticIdRef.current = null;
          return;
        }
        const apiRes = await chatApi.sendMessage({
          threadId,
          senderId: userId,
          text,
        });
        const msg = apiRes?.message || apiRes?.data;
        if (msg) {
          setMessages((prev) =>
            prev.map((m) => (m.id === optimisticId ? { ...msg, _id: msg._id, id: msg._id } : m)),
          );
        }
        lastOptimisticIdRef.current = null;
      }
    } catch (err) {
      setError(err.message || 'Unable to send message.');
      setMessages((prev) => prev.filter((m) => m.id !== optimisticId));
      lastOptimisticIdRef.current = null;
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (event) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      handleSend();
    }
  };

  if (!thread) return null;

  return (
    <section className="glass-card panel chat-thread">
      <header className="chat-thread-header">
        <div>
          <h3>{title}</h3>
          <small>Chat history and live replies</small>
        </div>
        {onClose ? (
          <button type="button" className="btn tiny ghost" onClick={onClose}>
            Back
          </button>
        ) : null}
      </header>

      {error ? <p className="error-text">{error}</p> : null}

      <div className="chat-thread-messages" ref={scrollRef}>
        {normalizedMessages.map((m) => {
          const isMine = userId && m.fromUserId && String(m.fromUserId) === String(userId);
          return (
            <div
              key={m.id}
              className={`chat-message ${isMine ? 'chat-message-me' : 'chat-message-them'}`}
            >
              <div className="chat-message-bubble">
                <p>{m.text}</p>
              </div>
              <small className="chat-message-meta">
                {new Date(m.timestamp).toLocaleTimeString([], {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </small>
            </div>
          );
        })}
        {!normalizedMessages.length ? (
          <p className="chat-thread-empty">No messages yet. Say hello to start the chat.</p>
        ) : null}
      </div>

      <form
        className="chat-thread-composer"
        onSubmit={(e) => {
          e.preventDefault();
          handleSend();
        }}
      >
        <textarea
          rows={2}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Type your message..."
        />
        <button className="btn primary" type="submit" disabled={sending || !input.trim()}>
          {sending ? 'Sending...' : 'Send'}
        </button>
      </form>
    </section>
  );
}

