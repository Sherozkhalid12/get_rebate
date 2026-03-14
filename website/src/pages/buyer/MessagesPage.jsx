import { useEffect, useState } from 'react';
import { PageHeader } from '../../components/layout/PageHeader';
import { ListPanel } from '../shared/FeatureCards';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList } from '../../lib/api';
import * as chatApi from '../../api/chat';
import { ChatThread } from '../../components/chat/ChatThread';

export function MessagesPage() {
  const { user } = useAuth();
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const [activeThread, setActiveThread] = useState(null);

  useEffect(() => {
    let live = true;
    const run = async () => {
      const userId = resolveUserId(user);
      if (!userId) return;
      try {
        const data = await chatApi.getThreads(userId);
        if (!live) return;
        const parsed = unwrapList(data, ['threads', 'data']).map((item) => {
          const other = item.otherUser || item.other_user || null;
          const otherUserId = other?._id || other?.id || other?.userId || null;
          return {
            id: item._id || item.id,
            name: other?.fullname || other?.name || item.title || 'Conversation',
            preview: item.lastMessage?.text || item.lastMessage?.message || 'No messages yet',
            unread: item.unreadCount || 0,
            otherUserId,
          };
        });
        setRows(parsed);
      } catch (err) {
        if (!live) return;
        setError(err.message || 'Unable to load messages.');
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [user]);

  const openThread = (row) => {
    setActiveThread(row);
  };

  return (
    <div className="page-body">
      <PageHeader title="Messages" subtitle="Instant chat with agents and loan officers." icon="messages" />
      {error ? <p className="error-text">{error}</p> : null}
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
      {activeThread ? (
        <ChatThread thread={activeThread} onClose={() => setActiveThread(null)} />
      ) : null}
    </div>
  );
}
