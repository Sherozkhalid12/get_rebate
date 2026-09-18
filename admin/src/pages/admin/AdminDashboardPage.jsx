import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import * as adminApi from '../../api/admin';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { PLATFORM_ZIP_TARGET } from '../../lib/zipPotentialByState';

function StatCard({ label, value, hint, to }) {
  const inner = (
    <>
      <span className="admin-stat-label">{label}</span>
      <strong className="admin-stat-value">{value}</strong>
      {hint ? <span className="admin-stat-hint">{hint}</span> : null}
    </>
  );
  if (to) {
    return (
      <Link to={to} className="admin-stat-card admin-stat-card--link">
        {inner}
      </Link>
    );
  }
  return <div className="admin-stat-card">{inner}</div>;
}

function formatNum(n) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  return Number(n).toLocaleString();
}

export function AdminDashboardPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [stats, setStats] = useState(null);
  const [coverage, setCoverage] = useState(() => adminApi.getZipCoverageFromCache());
  const [payments, setPayments] = useState(null);
  const [zipWarming, setZipWarming] = useState(true);

  useEffect(() => {
    let live = true;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const s = await adminApi.getStats();
        if (!live) return;
        setStats(s);
      } catch (err) {
        if (!live) return;
        setError(err?.message || 'Failed to load dashboard');
      } finally {
        if (live) setLoading(false);
      }
    })();

    // Background: warm ZIP + payments caches without blocking first paint
    adminApi.prefetchZipCoverage({ concurrency: 4 }).then((cov) => {
      if (!live) return;
      setCoverage(cov || adminApi.getZipCoverageFromCache());
      setZipWarming(false);
    }).catch(() => { if (live) setZipWarming(false); });

    adminApi.prefetchPayments().then(() => {
      if (!live) return;
      return adminApi.getPayments({ page: 1, limit: 1 });
    }).then((p) => {
      if (!live || !p) return;
      setPayments(p.summary);
    }).catch(() => {});

    const tick = setInterval(() => {
      if (!live) return;
      setCoverage(adminApi.getZipCoverageFromCache());
    }, 1500);

    return () => {
      live = false;
      clearInterval(tick);
    };
  }, []);

  if (loading) return <AnimatedLoader variant="full" label="Loading admin dashboard…" />;
  if (error && !stats) {
    return (
      <div className="admin-alert admin-alert--error">
        <strong>Could not load dashboard</strong>
        <p>{error}</p>
      </div>
    );
  }

  const overall = stats?.stats?.overall || {};
  const agents = stats?.stats?.agents || {};
  const los = stats?.stats?.loanOfficers || {};
  const zip = coverage?.summary || {};
  const unverified = stats?.recentActivity?.latestUnverified || [];

  return (
    <div className="admin-page">
      <div className="admin-page-head">
        <div>
          <h2>Operations overview</h2>
          <p>Platform health at a glance — users load instantly; ZIP inventory warms in the background.</p>
        </div>
      </div>

      <section className="admin-stat-grid">
        <StatCard label="Total users" value={formatNum(overall.totalUsers)} to="/users" />
        <StatCard label="Agents" value={formatNum(agents.total)} hint={`${formatNum(agents.verified)} verified`} to="/users" />
        <StatCard label="Loan officers" value={formatNum(los.total)} hint={`${formatNum(los.verified)} verified`} to="/users" />
        <StatCard
          label="ZIPs loaded"
          value={zipWarming && !(zip.statesLoaded > 0) ? '…' : formatNum(zip.loadedToday)}
          hint={
            zipWarming
              ? `Warming ${formatNum(zip.statesLoaded || 0)}/${formatNum(zip.statesTotal || 41)} states…`
              : `of ${formatNum(zip.platformTarget || PLATFORM_ZIP_TARGET)} target`
          }
          to="/zip-codes"
        />
        <StatCard
          label="Payable ZIPs"
          value={zipWarming && !(zip.statesLoaded > 0) ? '…' : formatNum(zip.payableToday)}
          hint="Have Census population"
          to="/zip-codes"
        />
        <StatCard
          label="Active subscriptions"
          value={payments ? formatNum(payments.active) : '…'}
          hint={payments ? `$${formatNum(payments.revenueRecorded)} recorded` : 'Loading…'}
          to="/payments"
        />
      </section>

      <section className="admin-panel">
        <div className="admin-panel-head">
          <h3>ZIP coverage snapshot</h3>
          <Link to="/zip-codes" className="btn link">View by state</Link>
        </div>
        <p className="admin-lead">
          Today: <strong>{formatNum(zip.loadedToday)}</strong> loaded
          {' · '}
          <strong>{formatNum(zip.payableToday)}</strong> payable
          {' · '}
          <strong>{formatNum(zip.remainingToLoad)}</strong> remaining vs ~27k target
        </p>
        {zipWarming ? (
          <p className="admin-muted">Prefetching state ZIP lists in the background ({formatNum(zip.statesLoaded || 0)} of {formatNum(zip.statesTotal || 41)})…</p>
        ) : (
          <p className="admin-muted">{coverage?.explanation?.whatBlocksRemaining}</p>
        )}
      </section>

      <section className="admin-panel">
        <div className="admin-panel-head">
          <h3>Pending professional verification</h3>
          <Link to="/users" className="btn link">Manage users</Link>
        </div>
        {unverified.length === 0 ? (
          <p className="admin-muted">No unverified agents or loan officers in the latest queue.</p>
        ) : (
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Joined</th>
                </tr>
              </thead>
              <tbody>
                {unverified.map((u) => (
                  <tr key={u._id}>
                    <td>{u.fullname || '—'}</td>
                    <td>{u.email || '—'}</td>
                    <td><span className="admin-pill">{u.role}</span></td>
                    <td>{u.createdAt ? new Date(u.createdAt).toLocaleDateString() : '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
