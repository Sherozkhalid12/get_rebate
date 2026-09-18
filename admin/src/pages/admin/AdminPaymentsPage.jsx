import { useCallback, useEffect, useState } from 'react';
import * as adminApi from '../../api/admin';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

function formatNum(n) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  return Number(n).toLocaleString();
}

function formatMoney(n) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  return `$${Number(n).toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
}

function formatDate(value) {
  if (!value) return '—';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleDateString();
}

export function AdminPaymentsPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [summary, setSummary] = useState(null);
  const [payments, setPayments] = useState([]);
  const [meta, setMeta] = useState({ total: 0, totalPages: 1, currentPage: 1 });
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await adminApi.getPayments({
        page,
        limit: 25,
        status,
        search: search.trim(),
      });
      setSummary(res?.summary || null);
      setPayments(res?.payments || []);
      setMeta({
        total: res?.total || 0,
        totalPages: res?.totalPages || 1,
        currentPage: res?.currentPage || page,
        hasNextPage: res?.hasNextPage,
        hasPrevPage: res?.hasPrevPage,
      });
    } catch (err) {
      setError(err?.message || 'Failed to load payments');
      setPayments([]);
    } finally {
      setLoading(false);
    }
  }, [page, status, search]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div className="admin-page">
      <div className="admin-page-head">
        <div>
          <h2>Revenue & subscriptions</h2>
          <p>Stripe ZIP territory subscriptions — status, amount recorded, and billing windows.</p>
        </div>
      </div>

      {summary ? (
        <section className="admin-stat-grid">
          <div className="admin-stat-card">
            <span className="admin-stat-label">All subscriptions</span>
            <strong className="admin-stat-value">{formatNum(summary.totalSubscriptions)}</strong>
          </div>
          <div className="admin-stat-card">
            <span className="admin-stat-label">Active</span>
            <strong className="admin-stat-value">{formatNum(summary.active)}</strong>
          </div>
          <div className="admin-stat-card">
            <span className="admin-stat-label">Past due</span>
            <strong className="admin-stat-value">{formatNum(summary.pastDue)}</strong>
          </div>
          <div className="admin-stat-card">
            <span className="admin-stat-label">Cancelled / expired</span>
            <strong className="admin-stat-value">{formatNum(summary.cancelled)}</strong>
          </div>
          <div className="admin-stat-card">
            <span className="admin-stat-label">Revenue recorded</span>
            <strong className="admin-stat-value">{formatMoney(summary.revenueRecorded)}</strong>
          </div>
          <div className="admin-stat-card">
            <span className="admin-stat-label">Agent / LO split</span>
            <strong className="admin-stat-value">{formatNum(summary.agentSubs)} / {formatNum(summary.loanOfficerSubs)}</strong>
          </div>
        </section>
      ) : null}

      <form
        className="admin-filters"
        onSubmit={(e) => {
          e.preventDefault();
          setPage(1);
          load();
        }}
      >
        <label>
          Status
          <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
            <option value="">All</option>
            <option value="active">active</option>
            <option value="trialing">trialing</option>
            <option value="paid">paid</option>
            <option value="past_due">past_due</option>
            <option value="cancelled">cancelled</option>
            <option value="expired">expired</option>
            <option value="incomplete">incomplete</option>
          </select>
        </label>
        <label className="admin-filters-grow">
          Search user
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Name or email" />
        </label>
        <button type="submit" className="btn primary">Apply</button>
      </form>

      {error ? <div className="admin-alert admin-alert--error">{error}</div> : null}

      {loading ? (
        <AnimatedLoader label="Loading payments…" />
      ) : (
        <>
          <p className="admin-muted">{formatNum(meta.total)} subscription rows</p>
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>User</th>
                  <th>ZIP</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Amount</th>
                  <th>Start</th>
                  <th>End</th>
                  <th>Stripe sub</th>
                </tr>
              </thead>
              <tbody>
                {payments.length === 0 ? (
                  <tr><td colSpan={8} className="admin-muted">No subscriptions found.</td></tr>
                ) : payments.map((p, idx) => (
                  <tr key={p.rowKey || `${p.userId}-${p.stripeSubscriptionId || 'x'}-${p.zipcode || ''}-${idx}`}>
                    <td>
                      <strong>{p.name || '—'}</strong>
                      <div className="admin-muted">{p.email}</div>
                    </td>
                    <td>{p.zipcode || '—'}</td>
                    <td><span className="admin-pill">{p.subscriptionRole || p.role || '—'}</span></td>
                    <td><span className="admin-pill">{p.status || '—'}</span></td>
                    <td>{formatMoney(p.amountPaid)}</td>
                    <td>{formatDate(p.subscriptionStart || p.createdAt)}</td>
                    <td>{formatDate(p.subscriptionEnd)}</td>
                    <td className="admin-mono">{p.stripeSubscriptionId || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="admin-pagination">
            <button type="button" className="btn ghost" disabled={!meta.hasPrevPage} onClick={() => setPage((p) => Math.max(1, p - 1))}>Previous</button>
            <span>Page {meta.currentPage} of {meta.totalPages}</span>
            <button type="button" className="btn ghost" disabled={!meta.hasNextPage} onClick={() => setPage((p) => p + 1)}>Next</button>
          </div>
        </>
      )}
    </div>
  );
}
