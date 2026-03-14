import { useEffect, useMemo, useRef, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList } from '../../lib/api';
import * as chatApi from '../../api/chat';
import { getSocket } from '../../lib/socket';

export function ChatThread({ thread, onClose }) {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const scrollRef = useRef(null);

  const title = thread?.name || thread?.title || 'Conversation';

  const otherUserId = thread?.otherUserId || null;

  const extractId = (value) => {
    if (!value) return '';
    if (typeof value === 'string' || typeof value === 'number') return String(value);
    if (typeof value === 'object') return String(value._id || value.id || value.userId || '');
    return '';
  };

  const normalizedMessages = useMemo(
    () =>
      messages.map((m, index) => {
        const fromId =
          m.fromUserId ||
          m.senderId ||
          m.sender ||
          m.userId ||
          m.from ||
          m.authorId ||
          (typeof m.user === 'object' ? m.user._id || m.user.id : null) ||
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
      }),
    [messages],
  );

  const loadMessages = async () => {
    if (!thread?.id || !userId) return;
    setError('');
    try {
      const res = await chatApi.getThreadMessages(thread.id, userId);
      const list = unwrapList(res, ['messages', 'data']);
      setMessages(list);
      try {
        await chatApi.markThreadAsRead(thread.id, userId);
      } catch {
        // Best-effort; ignore failures.
      }
    } catch (err) {
      setError(err.message || 'Unable to load messages.');
      setMessages([]);
    }
  };

  useEffect(() => {
    let live = true;
    if (!thread?.id || !userId) return undefined;

    const run = async () => {
      if (!live) return;
      await loadMessages();
    };

    run();

    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [thread?.id, userId]);

  useEffect(() => {
    if (!scrollRef.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [normalizedMessages.length]);

  useEffect(() => {
    const socket = getSocket();
    if (!socket || !thread?.id || !userId) return undefined;

    // Join the backend Socket.IO room for this thread.
    socket.emit('join_thread', thread.id);

    const handleIncoming = (payload) => {
      if (!payload) return;
      const incomingThreadId = payload.threadId || payload.thread_id || payload.thread?.id;
      if (!incomingThreadId || String(incomingThreadId) !== String(thread.id)) return;
      setMessages((prev) => [...prev, payload]);
    };

    socket.on('new_message', handleIncoming);

    return () => {
      socket.emit('leave_thread', thread.id);
      socket.off('new_message', handleIncoming);
    };
  }, [thread?.id, userId]);

  const handleSend = async () => {
    const text = input.trim();
    if (!text || sending || !thread?.id || !userId) return;

    setSending(true);
    setError('');
    try {
      const socket = getSocket();
      const payload = {
        threadId: thread.id,
        senderId: userId,
        text,
      };

      if (socket && socket.connected) {
        socket.emit('send_message', otherUserId ? { ...payload, participantIds: [userId, otherUserId] } : payload);
      } else {
        await chatApi.sendMessage(payload);
      }

      if (!socket || !socket.connected) {
        const optimistic = {
          id: `local-${Date.now()}`,
          fromUserId: userId,
          text,
          createdAt: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, optimistic]);
      }
      setInput('');
    } catch (err) {
      setError(err.message || 'Unable to send message.');
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

  if (!thread?.id) return null;

  return (
    <section className="glass-card panel chat-thread">
      <header className="chat-thread-header">
        <div>
          <h3>{title}</h3>
          <small>Chat history and live replies</small>
        </div>
        {onClose ? (
          <button type="button" className="btn tiny ghost" onClick={onClose}>
            Close
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
                {new Date(m.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
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
        onSubmit={(event) => {
          event.preventDefault();
          handleSend();
        }}
      >
        <textarea
          rows={2}
          value={input}
          onChange={(event) => setInput(event.target.value)}
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

