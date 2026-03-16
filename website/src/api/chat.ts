import { http } from './http';

export async function getThreads(userId: string) {
  return http.get(`/chat/threads?userId=${encodeURIComponent(userId)}`);
}

export async function getThreadMessages(threadId: string, userId: string) {
  return http.get(
    `/chat/thread/${encodeURIComponent(threadId)}/messages?userId=${encodeURIComponent(userId)}`,
  );
}

export async function createThread(userId1: string, userId2: string) {
  return http.post('/chat/thread/create', { userId1, userId2 });
}

/** Sends a message. Uses /chat/message/send to match backend (same as Flutter app). */
export async function sendMessage(payload: {
  threadId: string;
  senderId: string;
  text: string;
}) {
  return http.post('/chat/message/send', payload);
}

export async function markThreadAsRead(threadId: string, userId: string) {
  return http.post('/chat/thread/mark-read', { threadId, userId });
}
