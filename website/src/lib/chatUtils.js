import { unwrapList } from './api';

/**
 * Parses API thread response into a normalized list of conversation rows.
 * Handles: { threads }, { data }, { success, threads }, participants array, otherUser, other_user, otherParticipants.
 */
export function parseThreadsToRows(res, currentUserId) {
  const threads = unwrapList(res, ['threads', 'data']);
  return threads
    .map((item) => {
      const other = getOtherUserFromThread(item, currentUserId);
      const otherUserId = other?._id || other?.id || other?.userId || null;
      const name = other?.fullname || other?.name || other?.username || item?.title || 'Conversation';
      const preview = item.lastMessage?.text || item.lastMessage?.message || 'No messages yet';
      const unread = item.unreadCount ?? item.unreadCounts?.[currentUserId] ?? item.unreadCounts?.['_current_user'] ?? 0;
      return {
        id: item._id || item.id,
        name,
        preview,
        unread: Number(unread) || 0,
        otherUserId,
      };
    })
    .filter((r) => r.id);
}

function getOtherUserFromThread(thread, currentUserId) {
  const cur = String(currentUserId || '');

  // Prefer explicit otherUser / other_user (backend format)
  const other = thread.otherUser || thread.other_user || null;
  if (other && typeof other === 'object') return other;

  // otherParticipants array
  const otherParts = thread.otherParticipants;
  if (Array.isArray(otherParts) && otherParts.length > 0) {
    const first = otherParts[0];
    if (first && typeof first === 'object') return first;
  }

  // participants: array of user objects OR string IDs (backend socket format)
  const participants = thread.participants;
  if (Array.isArray(participants)) {
    for (const p of participants) {
      const pid = typeof p === 'object' && p != null
        ? (p._id || p.id || p.userId || '')
        : String(p || '');
      if (pid && String(pid) !== cur) {
        return typeof p === 'object' && p != null ? p : { _id: pid, id: pid };
      }
    }
  }

  return null;
}

/**
 * Build a row from socket thread_created/thread_updated payload.
 * thread: { _id, participants, lastMessage, unreadCounts, unreadCount }
 */
export function threadPayloadToRow(thread, currentUserId, otherName = 'Conversation') {
  if (!thread || !thread._id) return null;
  const other = getOtherUserFromThread(thread, currentUserId);
  const otherUserId = other?._id || other?.id || null;
  return {
    id: thread._id,
    name: other?.fullname || other?.name || otherName,
    preview: thread.lastMessage?.text || 'No messages yet',
    unread: Number(thread.unreadCount ?? thread.unreadCounts?.[currentUserId] ?? 0) || 0,
    otherUserId,
  };
}
