import { API_BASE_URL } from '../lib/constants';
import { storage } from '../lib/storage';

async function request(path, options = {}) {
  const token = storage.get('auth_token');
  const isFormData = typeof FormData !== 'undefined' && options.body instanceof FormData;
  const headers = {
    ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
    ...(options.headers || {}),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };

  const url = `${API_BASE_URL}${path}`;
  if (import.meta.env?.DEV && path.includes('/auth/users/')) console.log('[http] GET getUserById', url);
  const res = await fetch(url, {
    ...options,
    headers,
  });

  const text = await res.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }

  if (!res.ok) {
    const message = body?.message || body?.error || body?.msg || (typeof body === 'string' ? body : null) || `Request failed (${res.status})`;
    throw new Error(message);
  }

  return body;
}

export const http = {
  get: (path, opts = {}) => request(path, { ...opts, method: 'GET' }),
  post: (path, data, opts = {}) =>
    request(path, {
      ...opts,
      method: 'POST',
      body: (typeof FormData !== 'undefined' && data instanceof FormData) ? data : JSON.stringify(data),
    }),
  put: (path, data, opts = {}) =>
    request(path, {
      ...opts,
      method: 'PUT',
      body: (typeof FormData !== 'undefined' && data instanceof FormData) ? data : JSON.stringify(data),
    }),
  patch: (path, data, opts = {}) =>
    request(path, {
      ...opts,
      method: 'PATCH',
      body: (typeof FormData !== 'undefined' && data instanceof FormData) ? data : JSON.stringify(data),
    }),
  del: (path, opts = {}) => request(path, { ...opts, method: 'DELETE' }),
};
