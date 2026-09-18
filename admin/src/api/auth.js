import { http } from './http';

export async function login(payload) {
  return http.post('/auth/login', payload);
}
