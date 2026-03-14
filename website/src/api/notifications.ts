import { http } from './http';

export async function getNotifications(userId: string) {
  return http.get(`/notifications/${encodeURIComponent(userId)}`);
}

export async function markNotificationRead(notificationId: string) {
  return http.put(`/notifications/mark-read/${encodeURIComponent(notificationId)}`, {});
}

export async function markAllNotificationsRead(userId: string) {
  return http.put(`/notifications/mark-all-read/${encodeURIComponent(userId)}`, {});
}
