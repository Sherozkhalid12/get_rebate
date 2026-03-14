import { io } from 'socket.io-client';
import { API_BASE_URL } from './constants';
import { storage } from './storage';

let socketInstance = null;

function getOrigin() {
  try {
    return new URL(API_BASE_URL).origin;
  } catch {
    return '';
  }
}

export function getSocket() {
  if (socketInstance) return socketInstance;

  const origin = getOrigin();
  if (!origin) return null;

  const token = storage.get('auth_token', '');

  socketInstance = io(origin, {
    transports: ['websocket'],
    auth: token ? { token } : undefined,
  });

  return socketInstance;
}

