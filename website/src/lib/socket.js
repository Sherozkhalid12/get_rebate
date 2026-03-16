import { io } from 'socket.io-client';
import { API_BASE_URL } from './constants';
import { storage } from './storage';

let socketInstance = null;
let pendingUserId = null;

function getOrigin() {
  try {
    return new URL(API_BASE_URL).origin;
  } catch {
    return '';
  }
}

/**
 * Initialize socket and emit user_online when connected.
 * Call this when user logs in. Re-emits user_online on connect/reconnect.
 */
export function initSocket(userId) {
  const userIdStr = userId ? String(userId).trim() : null;
  pendingUserId = userIdStr;

  const origin = getOrigin();
  if (!origin) return null;

  if (socketInstance) {
    if (userIdStr) {
      socketInstance.emit('user_online', userIdStr);
    }
    return socketInstance;
  }

  const token = storage.get('auth_token', '');

  socketInstance = io(origin, {
    transports: ['websocket', 'polling'],
    auth: token ? { token } : undefined,
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 5,
    timeout: 20000,
    extraHeaders: {
      'ngrok-skip-browser-warning': 'true',
    },
  });

  const emitUserOnline = () => {
    const uid = pendingUserId || socketInstance?.userId;
    if (uid) {
      socketInstance.emit('user_online', uid);
      if (import.meta.env?.DEV) {
        console.log('[socket] emitted user_online', uid);
      }
    }
  };

  socketInstance.on('connect', () => {
    socketInstance.userId = pendingUserId;
    emitUserOnline();
    if (import.meta.env?.DEV) {
      console.log('[socket] connected', socketInstance.id);
    }
  });

  socketInstance.on('disconnect', (reason) => {
    if (import.meta.env?.DEV) {
      console.log('[socket] disconnected', reason);
    }
  });

  socketInstance.on('connect_error', (err) => {
    if (import.meta.env?.DEV) {
      console.error('[socket] connect_error', err?.message);
    }
  });

  socketInstance.on('reconnect', () => {
    emitUserOnline();
    if (import.meta.env?.DEV) {
      console.log('[socket] reconnected');
    }
  });

  socketInstance.on('error', (payload) => {
    if (import.meta.env?.DEV) {
      console.error('[socket] error', payload);
    }
  });

  return socketInstance;
}

/**
 * Get the socket instance. Call initSocket(userId) first when user is logged in.
 */
export function getSocket() {
  if (socketInstance) return socketInstance;

  const origin = getOrigin();
  if (!origin) return null;

  const token = storage.get('auth_token', '');

  socketInstance = io(origin, {
    transports: ['websocket', 'polling'],
    auth: token ? { token } : undefined,
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 5,
    timeout: 20000,
    extraHeaders: {
      'ngrok-skip-browser-warning': 'true',
    },
  });

  socketInstance.on('connect', () => {
    if (pendingUserId) {
      socketInstance.emit('user_online', pendingUserId);
      socketInstance.userId = pendingUserId;
    }
  });

  socketInstance.on('reconnect', () => {
    if (pendingUserId) {
      socketInstance.emit('user_online', pendingUserId);
    }
  });

  return socketInstance;
}

/**
 * Disconnect and clear the socket. Call on logout.
 */
export function disconnectSocket() {
  if (socketInstance) {
    socketInstance.disconnect();
    socketInstance = null;
  }
  pendingUserId = null;
}
