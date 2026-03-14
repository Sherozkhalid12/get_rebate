import { http } from './http';

export async function getUserById(userId) {
  const path = `/auth/users/${encodeURIComponent(userId)}`;
  if (import.meta.env?.DEV) console.log('[getUserById] GET', path);
  return http.get(path);
}

export async function updateUser(userId, payload) {
  return http.patch(`/auth/updateUser/${encodeURIComponent(userId)}`, payload);
}
