import { http } from './http';
import { getStateZipCodes, flattenZipCodeResponse, parseZipPopulation } from './zipcodes';
import {
  PLATFORM_ZIP_TARGET,
  ZIP_POTENTIAL_BY_STATE,
  REBATE_ALLOWED_STATES,
} from '../lib/zipPotentialByState';

/** Existing production admin APIs (same host as the app). */
export function getStats() {
  return http.get('/admin/stats');
}

export function getUsersByType({ userType = 'both', verified, search = '', page = 1, limit = 20 } = {}) {
  const params = new URLSearchParams({
    userType,
    page: String(page),
    limit: String(limit),
  });
  if (verified !== undefined && verified !== '' && verified !== 'all') {
    params.set('verified', String(verified));
  }
  if (search) params.set('search', search);
  return http.get(`/admin/users?${params}`);
}

export function getAccountHolders({ role = '', search = '', page = 1, limit = 20 } = {}) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (role) params.set('role', role);
  if (search) params.set('search', search);
  return http.get(`/admin/account-holders?${params}`);
}

export function getRecentUsers() {
  return http.get('/admin/recent-users');
}

export function toggleVerification(userId) {
  return http.patch(`/admin/toggle-verification/${encodeURIComponent(userId)}`);
}

export function verifyUsers({ userId, userIds, verified, userType }) {
  return http.post('/admin/verify', { userId, userIds, verified, userType });
}

const ZIP_CACHE_KEY = 'gr_admin_zip_rows_v1';
const ZIP_CACHE_TTL_MS = 30 * 60 * 1000;
const zipMemory = new Map(); // state -> { row, at }
const zipInflight = new Map();

function emptyStateRow(code) {
  const potential = ZIP_POTENTIAL_BY_STATE[code] || 0;
  return {
    state: code,
    potential,
    loaded: 0,
    withPopulation: 0,
    withoutPopulation: 0,
    remainingToLoad: potential,
    remainingPayable: potential,
    claimedByAgent: 0,
    claimedByOfficer: 0,
    availableForAgent: 0,
    availableForOfficer: 0,
    totalPopulation: 0,
    coveragePct: 0,
  };
}

function summarizeZipRows(rows) {
  const totals = rows.reduce(
    (acc, s) => {
      acc.potential += s.potential || 0;
      acc.loaded += s.loaded || 0;
      acc.withPopulation += s.withPopulation || 0;
      acc.withoutPopulation += s.withoutPopulation || 0;
      acc.remainingToLoad += s.remainingToLoad || 0;
      acc.claimedByAgent += s.claimedByAgent || 0;
      acc.claimedByOfficer += s.claimedByOfficer || 0;
      return acc;
    },
    {
      potential: 0,
      loaded: 0,
      withPopulation: 0,
      withoutPopulation: 0,
      remainingToLoad: 0,
      claimedByAgent: 0,
      claimedByOfficer: 0,
    },
  );
  return {
    platformTarget: PLATFORM_ZIP_TARGET,
    potentialInRebateStates: totals.potential,
    loadedToday: totals.loaded,
    payableToday: totals.withPopulation,
    loadedWithoutPopulation: totals.withoutPopulation,
    remainingToLoad: totals.remainingToLoad,
    claimedByAgent: totals.claimedByAgent,
    claimedByOfficer: totals.claimedByOfficer,
    coveragePct:
      totals.potential > 0
        ? Number(((totals.loaded / totals.potential) * 100).toFixed(1))
        : 0,
    statesLoaded: rows.filter((r) => r.loaded > 0 || r._fetched).length,
    statesTotal: REBATE_ALLOWED_STATES.length,
  };
}

const ZIP_EXPLANATION = {
  availableToday:
    'ZIPs currently returned by getstateZip (same API agents/LOs use). Payable ZIPs have Census population > 0.',
  potentialTarget:
    'Estimated residential ZIP territories across rebate-allowed states (~27,000+). Planning targets until the full catalog is imported.',
  whatBlocksRemaining:
    'Remaining ZIPs are not yet loaded (or lack population). State lists are seeded from GeoNames (max ~500 per first fetch) and only when a state has zero cached rows; Census ACS enrichment is required before a ZIP is offered as payable.',
  etaNote:
    'No hard ship date in the API. Full coverage needs a bulk ZIP + population import for each rebate-allowed state.',
};

function readZipSession() {
  try {
    const raw = sessionStorage.getItem(ZIP_CACHE_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (!parsed?.at || Date.now() - parsed.at > ZIP_CACHE_TTL_MS) return;
    for (const [code, row] of Object.entries(parsed.rows || {})) {
      zipMemory.set(code, { row, at: parsed.at });
    }
  } catch {
    /* ignore */
  }
}

function writeZipSession() {
  try {
    const rows = {};
    for (const [code, entry] of zipMemory.entries()) {
      rows[code] = entry.row;
    }
    sessionStorage.setItem(
      ZIP_CACHE_KEY,
      JSON.stringify({ at: Date.now(), rows }),
    );
  } catch {
    /* ignore */
  }
}

readZipSession();

function aggregateStateZips(code, zips) {
  let withPopulation = 0;
  let withoutPopulation = 0;
  let claimedByAgent = 0;
  let claimedByOfficer = 0;
  let totalPopulation = 0;
  for (const z of zips) {
    const pop = parseZipPopulation(z);
    if (pop > 0) {
      withPopulation += 1;
      totalPopulation += pop;
    } else {
      withoutPopulation += 1;
    }
    if (z.claimedByAgent) claimedByAgent += 1;
    if (z.claimedByOfficer) claimedByOfficer += 1;
  }
  const potential = ZIP_POTENTIAL_BY_STATE[code] || 0;
  const loaded = zips.length;
  return {
    state: code,
    potential,
    loaded,
    withPopulation,
    withoutPopulation,
    remainingToLoad: Math.max(0, potential - loaded),
    remainingPayable: Math.max(0, potential - withPopulation),
    claimedByAgent,
    claimedByOfficer,
    availableForAgent: Math.max(0, withPopulation - claimedByAgent),
    availableForOfficer: Math.max(0, withPopulation - claimedByOfficer),
    totalPopulation,
    coveragePct: potential > 0 ? Number(((loaded / potential) * 100).toFixed(1)) : 0,
    _fetched: true,
  };
}

/** One state — cached + deduped in-flight requests. */
export async function fetchZipStateRow(code, { force = false } = {}) {
  const existing = zipMemory.get(code);
  if (!force && existing && Date.now() - existing.at < ZIP_CACHE_TTL_MS) {
    return existing.row;
  }
  if (!force && zipInflight.has(code)) return zipInflight.get(code);

  const promise = (async () => {
    try {
      const res = await getStateZipCodes('US', code);
      const zips = flattenZipCodeResponse(res);
      const row = aggregateStateZips(code, zips);
      zipMemory.set(code, { row, at: Date.now() });
      writeZipSession();
      return row;
    } catch {
      const row = { ...emptyStateRow(code), _fetched: true, _error: true };
      zipMemory.set(code, { row, at: Date.now() });
      return row;
    } finally {
      zipInflight.delete(code);
    }
  })();

  zipInflight.set(code, promise);
  return promise;
}

function listFilteredStates(filter = '') {
  const q = String(filter || '').trim().toUpperCase();
  return q
    ? REBATE_ALLOWED_STATES.filter((s) => s.includes(q))
    : [...REBATE_ALLOWED_STATES];
}

/** Paginated ZIP coverage — only fetches the current page of states. */
export async function getZipCoveragePage({
  page = 1,
  pageSize = 10,
  filter = '',
  sortKey = 'state',
} = {}) {
  const allCodes = listFilteredStates(filter);
  const total = allCodes.length;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const currentPage = Math.min(Math.max(1, page), totalPages);
  const start = (currentPage - 1) * pageSize;
  const pageCodes = allCodes.slice(start, start + pageSize);

  const pageRows = await Promise.all(pageCodes.map((code) => fetchZipStateRow(code)));

  // Summary: use cached rows for known states + empty placeholders for the rest
  const allRows = REBATE_ALLOWED_STATES.map((code) => {
    const mem = zipMemory.get(code);
    return mem?.row || emptyStateRow(code);
  });

  let sortedPage = [...pageRows];
  sortedPage.sort((a, b) => {
    const av = a[sortKey] ?? 0;
    const bv = b[sortKey] ?? 0;
    if (sortKey === 'state' || typeof av === 'string') {
      return String(a.state).localeCompare(String(b.state));
    }
    return Number(bv) - Number(av);
  });

  return {
    success: true,
    summary: summarizeZipRows(allRows),
    explanation: ZIP_EXPLANATION,
    states: sortedPage,
    meta: {
      total,
      totalPages,
      currentPage,
      pageSize,
      hasNextPage: currentPage < totalPages,
      hasPrevPage: currentPage > 1,
      cachedStates: [...zipMemory.keys()].length,
    },
  };
}

/** Prefetch all states in the background (deduped). */
let prefetchPromise = null;
export function prefetchZipCoverage({ concurrency = 4 } = {}) {
  if (prefetchPromise) return prefetchPromise;
  prefetchPromise = (async () => {
    const queue = [...REBATE_ALLOWED_STATES];
    const workers = Array.from({ length: concurrency }, async () => {
      while (queue.length) {
        const code = queue.shift();
        if (!code) break;
        await fetchZipStateRow(code);
      }
    });
    await Promise.all(workers);
    return getZipCoverageFromCache();
  })().finally(() => {
    /* keep promise so later callers reuse completed result via cache */
  });
  return prefetchPromise;
}

export function getZipCoverageFromCache() {
  const rows = REBATE_ALLOWED_STATES.map((code) => {
    const mem = zipMemory.get(code);
    return mem?.row || emptyStateRow(code);
  });
  return {
    success: true,
    summary: summarizeZipRows(rows),
    explanation: ZIP_EXPLANATION,
    states: rows.filter((r) => r._fetched),
    partial: [...zipMemory.keys()].length < REBATE_ALLOWED_STATES.length,
  };
}

/** @deprecated Prefer getZipCoveragePage + prefetchZipCoverage */
export async function getZipCoverage() {
  await prefetchZipCoverage({ concurrency: 6 });
  return getZipCoverageFromCache();
}

/* ---------------- Payments (paginated via /admin/users) ---------------- */

const paymentsCache = {
  at: 0,
  rows: null,
  promise: null,
};

function flattenSubscriptions(users) {
  const rows = [];
  users.forEach((u, uIdx) => {
    const subs = Array.isArray(u.subscriptions) ? u.subscriptions : [];
    subs.forEach((s, sIdx) => {
      rows.push({
        rowKey: `${u._id}-${s.stripeSubscriptionId || 'none'}-${s.zipcode || 'zip'}-${uIdx}-${sIdx}`,
        userId: u._id,
        name: u.fullname,
        email: u.email,
        role: u.role,
        zipcode: s.zipcode || '',
        population: s.population,
        status: s.subscriptionStatus,
        subscriptionRole: s.subscriptionRole,
        amountPaid: s.amountPaid || 0,
        stripeSubscriptionId: s.stripeSubscriptionId,
        subscriptionStart: s.subscriptionStart,
        subscriptionEnd: s.subscriptionEnd,
        createdAt: s.createdAt,
      });
    });
  });
  return rows;
}

async function loadAllPaymentRows({ search = '', force = false } = {}) {
  const ttl = 5 * 60 * 1000;
  if (
    !force &&
    !search &&
    paymentsCache.rows &&
    Date.now() - paymentsCache.at < ttl
  ) {
    return paymentsCache.rows;
  }
  if (!force && !search && paymentsCache.promise) return paymentsCache.promise;

  const run = (async () => {
    const users = [];
    let page = 1;
    let hasNext = true;
    while (hasNext && page <= 30) {
      const res = await getUsersByType({
        userType: 'both',
        search,
        page,
        limit: 100,
      });
      users.push(...(res?.users || []));
      hasNext = Boolean(res?.hasNextPage);
      page += 1;
    }
    const rows = flattenSubscriptions(users);
    rows.sort((a, b) => {
      const da = new Date(a.createdAt || a.subscriptionStart || 0).getTime();
      const db = new Date(b.createdAt || b.subscriptionStart || 0).getTime();
      return db - da;
    });
    if (!search) {
      paymentsCache.rows = rows;
      paymentsCache.at = Date.now();
    }
    return rows;
  })();

  if (!search) paymentsCache.promise = run.finally(() => { paymentsCache.promise = null; });
  return run;
}

export async function getPayments({ page = 1, limit = 25, status = '', search = '' } = {}) {
  let payments = await loadAllPaymentRows({ search: search.trim() });
  if (status) payments = payments.filter((p) => p.status === status);

  const summary = {
    totalSubscriptions: payments.length,
    active: payments.filter((p) => ['active', 'trialing', 'paid'].includes(p.status)).length,
    cancelled: payments.filter((p) => ['cancelled', 'expired'].includes(p.status)).length,
    pastDue: payments.filter((p) => p.status === 'past_due').length,
    revenueRecorded: payments.reduce((s, p) => s + (Number(p.amountPaid) || 0), 0),
    agentSubs: payments.filter((p) => p.subscriptionRole === 'agent').length,
    loanOfficerSubs: payments.filter((p) => p.subscriptionRole === 'loanofficer').length,
  };

  const total = payments.length;
  const totalPages = Math.max(1, Math.ceil(total / limit) || 1);
  const currentPage = Math.min(Math.max(1, page), totalPages);
  const start = (currentPage - 1) * limit;
  const slice = payments.slice(start, start + limit);

  return {
    success: true,
    summary,
    count: slice.length,
    total,
    totalPages,
    currentPage,
    hasNextPage: currentPage < totalPages,
    hasPrevPage: currentPage > 1,
    payments: slice,
  };
}

export function prefetchPayments() {
  return loadAllPaymentRows({}).catch(() => null);
}

/** Fast analytics — stats + cached ZIP + cached payments (no blocking full scan). */
export async function getAnalytics() {
  const [statsRes, recent] = await Promise.all([
    getStats(),
    getRecentUsers().catch(() => null),
  ]);

  // Kick background warmers; use whatever is cached now
  prefetchZipCoverage({ concurrency: 4 });
  prefetchPayments();

  const coverage = getZipCoverageFromCache();
  const payRows = paymentsCache.rows || [];
  const paySummary = {
    active: payRows.filter((p) => ['active', 'trialing', 'paid'].includes(p.status)).length,
    revenueRecorded: payRows.reduce((s, p) => s + (Number(p.amountPaid) || 0), 0),
  };

  const overall = statsRes?.stats?.overall || {};
  const agents = statsRes?.stats?.agents || {};
  const los = statsRes?.stats?.loanOfficers || {};
  const zip = coverage?.summary || {};

  const byDay = {};
  for (const u of recent?.users || []) {
    const key = u.createdAt || 'unknown';
    byDay[key] = (byDay[key] || 0) + 1;
  }
  const signupsLast30Days = Object.entries(byDay)
    .map(([day, count]) => ({ _id: day, count }))
    .sort((a, b) => String(a._id).localeCompare(String(b._id)));

  return {
    success: true,
    analytics: {
      users: {
        total: overall.totalUsers || 0,
        buyers: Math.max(0, (overall.totalUsers || 0) - (overall.totalProfessionals || 0)),
        agents: agents.total || 0,
        loanOfficers: los.total || 0,
        admins: 0,
        verifiedAgents: agents.verified || 0,
        verifiedLoanOfficers: los.verified || 0,
      },
      zips: {
        platformTarget: zip.platformTarget || PLATFORM_ZIP_TARGET,
        loaded: zip.loadedToday || 0,
        payable: zip.payableToday || 0,
        claimedByAgent: zip.claimedByAgent || 0,
        claimedByOfficer: zip.claimedByOfficer || 0,
        remainingVsTarget: zip.remainingToLoad || 0,
        partial: coverage.partial,
      },
      listings: { total: null },
      waitlist: { total: null },
      payments: {
        activeSubscriptions: paySummary.active,
        revenueRecorded: paySummary.revenueRecorded,
      },
      signupsLast30Days,
    },
  };
}
