import { http } from './http';
import { unwrapList } from '../lib/api';

/**
 * Extract Stripe session_id from the current URL.
 * Checks: search params, hash query string, and regex fallback for cs_xxx pattern.
 */
/** Remove Stripe return query params so revisiting the page does not re-trigger verify. */
export function clearStripeReturnParams() {
  try {
    const url = new URL(window.location.href);
    let changed = false;
    for (const key of ['session_id', 'sessionId', 'checkout_session_id']) {
      if (url.searchParams.has(key)) {
        url.searchParams.delete(key);
        changed = true;
      }
    }
    if (changed) {
      window.history.replaceState({}, document.title, `${url.pathname}${url.search}${url.hash}`);
    }
    return changed;
  } catch {
    return false;
  }
}

export function isIncompleteCheckoutError(err) {
  const msg = String(err?.message || err?.error || '').toLowerCase();
  return /payment not completed|not completed|checkout.*cancel|session.*expired/i.test(msg);
}

export function readPendingZipCheckout(pendingKey, userId) {
  const raw = localStorage.getItem(pendingKey);
  if (!raw) return null;
  try {
    const pending = JSON.parse(raw);
    if (!pending || pending.userId !== userId) return null;
    return pending;
  } catch {
    localStorage.removeItem(pendingKey);
    return null;
  }
}

export function clearPendingZipCheckout(pendingKey) {
  localStorage.removeItem(pendingKey);
}

export function getSessionIdFromUrl() {
  const search = new URLSearchParams(window.location.search);
  let id = search.get('session_id') || search.get('sessionId') || search.get('checkout_session_id');
  if (id) return id;
  const hash = window.location.hash || '';
  const hashQueryStart = hash.indexOf('?');
  if (hashQueryStart >= 0) {
    const hashParams = new URLSearchParams(hash.slice(hashQueryStart));
    id = hashParams.get('session_id') || hashParams.get('sessionId') || hashParams.get('checkout_session_id');
    if (id) return id;
  }
  const match = (window.location.href || '').match(/cs_(test_|live_)?[a-zA-Z0-9]+/);
  return match ? match[0] : '';
}

/** Get user-friendly message when zip is claimed. claimedBy: "agent" | "loanOfficer" | null */
export function getZipClaimedMessage(zipcode, claimedBy) {
  if (!claimedBy) return null;
  if (claimedBy === 'agent') return `This zipcode is already claimed by an Agent.`;
  if (claimedBy === 'loanOfficer') return `This zipcode is already claimed by a Loan Officer.`;
  return `ZIP ${zipcode} is already claimed.`;
}

export async function getStateZipCodes(country, state) {
  const st = String(state ?? '').trim();
  if (!st) {
    throw new Error('Please select a state first.');
  }
  return http.get(`/zip-codes/getstateZip/${encodeURIComponent(country)}/${encodeURIComponent(st)}`);
}

/**
 * Search ZIP code via GET /api/v1/zip-codes/:country/:state/:zipcode
 * Returns the matching ZIP and nearby results.
 */
export async function searchZipCode(country, state, zipcode) {
  const zip = String(zipcode ?? '').trim();
  if (!zip || !/^\d{5}$/.test(zip)) {
    throw new Error('Enter a valid 5-digit ZIP code');
  }
  const path = `/zip-codes/${encodeURIComponent(country)}/${encodeURIComponent(state)}/${encodeURIComponent(zip)}`;
  if (import.meta.env?.DEV) {
    console.log('[zipcodes] searchZipCode GET', path, '→ full URL in Network tab');
  }
  try {
    const res = await http.get(path);
    if (import.meta.env?.DEV) {
      console.log('[zipcodes] searchZipCode OK', Array.isArray(res) ? res.length : typeof res, res);
    }
    return res;
  } catch (err) {
    if (import.meta.env?.DEV) {
      console.error('[zipcodes] searchZipCode FAILED', err.message, path);
    }
    throw err;
  }
}

/**
 * Get ZIP codes within X miles of a given ZIP.
 * GET /api/v1/zip-codes/within10miles/:zipcode/:miles
 * Returns map of postalCode -> distanceMiles (for filtering agents/LOs by proximity)
 */
export async function getZipCodesWithinMiles(zipcode, miles = 10) {
  const trimmed = String(zipcode ?? '').trim();
  if (!/^\d{5}$/.test(trimmed)) {
    throw new Error('ZIP code must be exactly 5 digits');
  }
  const res = await http.get(`/zip-codes/within10miles/${encodeURIComponent(trimmed)}/${miles}`);
  const raw = res?.zipCodes;
  if (!Array.isArray(raw)) return {};
  const map = {};
  for (const e of raw) {
    if (!e || typeof e !== 'object') continue;
    const pc = (e.postalCode ?? e.zipCode ?? e.zipcode ?? '').toString().trim();
    if (!pc) continue;
    const d = e.distanceMiles;
    map[pc] = typeof d === 'number' ? d : (typeof d === 'string' ? parseFloat(d) || 0 : 0);
  }
  return map;
}

/**
 * Flattens API response (zipCodes or results) to a list of zip objects.
 * Handles city-grouped items with postalCodes array.
 * API may return: { zipCodes: [...] } or { results: [...] } or { data: { zipCodes/results } }
 */
export function flattenZipCodeResponse(response) {
  if (!response || typeof response !== 'object') {
    if (import.meta.env?.DEV) console.warn('[zipcodes] flattenZipCodeResponse: empty or invalid response', response);
    return [];
  }
  const raw = unwrapList(response, ['zipCodes', 'data', 'results']);
  if (import.meta.env?.DEV && raw.length === 0) {
    console.warn('[zipcodes] flattenZipCodeResponse: no array found in', Object.keys(response), response);
  }
  const out = [];
  for (const item of raw) {
    if (item && typeof item === 'object') {
      if (item.zipcode || item.zipCode) {
        out.push({ ...item, zipcode: item.zipCode || item.zipcode });
      } else if (item.postalCode) {
        /* API returns { postalCode, state, city, population, distance, _id, ... } */
        out.push({ ...item, zipcode: item.postalCode, zipCode: item.postalCode });
      } else if (Array.isArray(item.postalCodes) && item.postalCodes.length) {
        for (const pc of item.postalCodes) {
          out.push({ ...item, zipcode: pc, zipCode: pc, postalCode: pc });
        }
      }
    }
  }
  return out;
}

function parseZipDistance(value) {
  if (value == null || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

/** Parse population from API zip object (avoids coercing non-numeric fields). */
export function parseZipPopulation(z) {
  const raw = z?.population ?? z?.populationCount;
  if (typeof raw === 'number' && Number.isFinite(raw)) return Math.max(0, Math.round(raw));
  if (typeof raw === 'string' && raw.trim() !== '') {
    const n = parseInt(raw, 10);
    return Number.isFinite(n) ? Math.max(0, n) : 0;
  }
  return 0;
}

/**
 * Order ZIP search results: exact searched ZIP first, then by distance.
 * Clears distance on the searched ZIP (API may return stale distance values).
 */
export function prepareZipSearchRows(rows, searchedZip) {
  const query = String(searchedZip ?? '').trim();
  if (!query || !/^\d{5}$/.test(query) || !Array.isArray(rows) || rows.length === 0) {
    return rows;
  }

  const byZip = new Map();
  for (const row of rows) {
    const zipcode = String(row.zipcode ?? '').trim();
    if (!/^\d{5}$/.test(zipcode)) continue;
    const dist = parseZipDistance(row.distance);
    const existing = byZip.get(zipcode);
    if (!existing) {
      byZip.set(zipcode, { ...row, zipcode });
      continue;
    }
    const existingDist = parseZipDistance(existing.distance);
    if (dist != null && (existingDist == null || dist < existingDist)) {
      byZip.set(zipcode, { ...row, zipcode });
    }
  }

  let rest = Array.from(byZip.values()).filter((r) => r.zipcode !== query);
  rest.sort((a, b) => {
    const da = parseZipDistance(a.distance);
    const db = parseZipDistance(b.distance);
    if (da == null && db == null) return a.zipcode.localeCompare(b.zipcode);
    if (da == null) return 1;
    if (db == null) return -1;
    if (da !== db) return da - db;
    return a.zipcode.localeCompare(b.zipcode);
  });

  const exact = byZip.get(query);
  if (exact) {
    return [{ ...exact, distance: null }, ...rest];
  }
  return rest;
}

/**
 * Available-tab rows: during an active ZIP search, keep all results (including the
 * searched ZIP and zips you already claimed). When browsing by state, hide your claims.
 */
export function filterAvailableZipRows(displayRows, { searchZipRows, zipSearch, claimedSet }) {
  const rows = (displayRows || []).map((row) => ({
    ...row,
    name: row.zipcode || row.name,
  }));
  const searched = String(zipSearch ?? '').trim();
  const isZipSearch = searchZipRows != null && /^\d{5}$/.test(searched);
  if (isZipSearch) return rows;
  return rows.filter((row) => !claimedSet.has(String(row.zipcode)));
}

export async function validateZipCode(zipCode, state) {
  return http.get(`/zip-codes/validate/${encodeURIComponent(zipCode)}/${encodeURIComponent(state)}`);
}

export async function claimZipCode(payload) {
  console.log('[ZIP API] claimZipCode request:', JSON.stringify(payload));
  const res = await http.post('/zip-codes/claim', payload);
  console.log('[ZIP API] claimZipCode response:', JSON.stringify(res));
  return res;
}

export async function releaseZipCode(payload) {
  return http.patch('/zip-codes/release', payload);
}

export async function claimLoanOfficerZipCode(payload) {
  console.log('[ZIP API] claimLoanOfficerZipCode request:', JSON.stringify(payload));
  const res = await http.post('/loan-officer-zip-codes/claim', payload);
  console.log('[ZIP API] claimLoanOfficerZipCode response:', JSON.stringify(res));
  return res;
}

export async function releaseLoanOfficerZipCode(payload) {
  return http.patch('/loan-officer-zip-codes/release', payload);
}

/** Check if ZIP is claimed. Pass userId so backend can return null when current user is the claimer. */
export async function getZipClaimStatus(zipcode, userId = null) {
  const payload = { zipcode };
  if (userId) payload.userId = userId;
  const res = await http.post('/zip-codes/zipclaimstatus', payload);
  console.log('[ZIP API] getZipClaimStatus response:', JSON.stringify(res));
  return res;
}

export async function createCheckoutSession(payload) {
  console.log('[ZIP API] createCheckoutSession request:', JSON.stringify(payload));
  const res = await http.post('/subscription/create-checkout-session', payload);
  console.log('[ZIP API] createCheckoutSession response:', JSON.stringify(res));
  return res;
}

export async function verifyPaymentSuccess(sessionId, zipcode) {
  const id = String(sessionId ?? '').trim();
  if (!id) throw new Error('Payment session ID is missing.');
  const zip = String(zipcode ?? '').trim();
  // Match mobile app (ApiConstants.getPaymentSuccessPath)
  const path = zip
    ? `/subscription/paymentSuccess/${encodeURIComponent(id)}/${encodeURIComponent(zip)}`
    : `/subscription/paymentSuccess/sessionid/${encodeURIComponent(id)}`;
  console.log('[ZIP API] verifyPaymentSuccess GET', path);
  const res = await http.get(path);
  console.log('[ZIP API] verifyPaymentSuccess response:', JSON.stringify(res));
  return res;
}

export async function cancelSubscription(payload) {
  return http.post('/subscription/cancelSubscription', payload);
}

/** POST /waiting-list - Join waiting list for a claimed ZIP. Body: { name, email, zipCode, userId } */
export async function joinWaitingList(payload) {
  const res = await http.post('/waiting-list', payload);
  return res;
}

/** GET /waiting-list/:zipCode - Fetch waiting list entries for a ZIP */
export async function getWaitingListEntries(zipCode) {
  return http.get(`/waiting-list/${encodeURIComponent(zipCode)}`);
}

/** DELETE /waiting-list - Remove from waiting list. Body: { zipCode, userId } */
export async function removeFromWaitingList(payload) {
  return http.delete('/waiting-list', payload);
}

/** GET /zip-codes/getZipListings/:userId/:zipCode - Listing count for a ZIP */
export async function getZipListingsCount(userId, zipCode) {
  const res = await http.get(`/zip-codes/getZipListings/${encodeURIComponent(userId)}/${encodeURIComponent(zipCode)}`);
  if (typeof res === 'number') return res;
  const count = res?.listingsCount ?? res?.count ?? res?.listingCount ?? (Array.isArray(res?.listings) ? res.listings.length : 0);
  return typeof count === 'number' ? count : parseInt(count, 10) || 0;
}
