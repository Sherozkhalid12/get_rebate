export function unwrapList(payload, keys = []) {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== 'object') return [];

  for (const key of keys) {
    const value = payload[key];
    if (Array.isArray(value)) return value;
  }

  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;

  return [];
}

export function unwrapObject(payload, keys = []) {
  if (!payload || typeof payload !== 'object') return null;
  for (const key of keys) {
    const value = payload[key];
    if (value && typeof value === 'object' && !Array.isArray(value)) return value;
  }
  if (payload.data && typeof payload.data === 'object' && !Array.isArray(payload.data)) {
    return payload.data;
  }
  return payload;
}

/**
 * Extracts user/profile from getUserById API response.
 * Matches app's UserService.getUserRawById logic: user, data, agent, officer, loanOfficer.
 */
export function extractUserFromGetUserById(res) {
  if (!res || typeof res !== 'object') return res;
  const raw =
    res.user ?? res.data ?? res.agent ?? res.officer ?? res.loanOfficer ?? res;
  return raw && typeof raw === 'object' && !Array.isArray(raw) ? raw : res;
}

export function resolveUserId(user) {
  return user?.id || user?._id || user?.userId || null;
}

export function normalizeRole(rawRole) {
  const value = String(rawRole || '').toLowerCase();
  if (value === 'agent') return 'agent';
  if (value === 'loanofficer' || value === 'loan_officer' || value === 'loan-officer') {
    return 'loanOfficer';
  }
  return 'buyerSeller';
}
