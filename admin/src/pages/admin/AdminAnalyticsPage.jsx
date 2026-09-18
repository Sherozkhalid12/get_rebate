import { useEffect, useState } from 'react';
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

export function AdminAnalyticsPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [analytics, setAnalytics] = useState(null);

  useEffect(() => {
    let live = true;
    let timer;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const res = await adminApi.getAnalytics();
        if (!live) return;
        setAnalytics(res?.analytics || res);
        timer = setTimeout(async () => {
          try {
            const again = await adminApi.getAnalytics();
            if (live) setAnalytics(again?.analytics || again);
          } catch { /* ignore */ }
        }, 4000);
      } catch (err) {
        if (!live) return;
        setError(err?.message || 'Failed to load analytics');
      } finally {
        if (live) setLoading(false);
      }
    })();
    return () => {
      live = false;
      if (timer) clearTimeout(timer);
    };
  }, []);

  if (loading) return <AnimatedLoader variant="full" label="Loading analytics…" />;
  if (error) return <div className="admin-alert admin-alert--error">{error}</div>;

  const users = analytics?.users || {};
  const zips = analytics?.zips || {};
  const payments = analytics?.payments || {};
  const listings = analytics?.listings || {};
  const waitlist = analytics?.waitlist || {};
  const signups = analytics?.signupsLast30Days || [];
  const maxSignup = Math.max(1, ...signups.map((d) => d.count || 0));

  return (
    <div className="admin-page">
      <div className="admin-page-head">
        <div>
          <h2>Performance</h2>
          <p>Signups, inventory, claims, and revenue signals — powered by live stats and warm caches.</p>
        </div>
      </div>

      <section className="admin-stat-grid">
        <div className="admin-stat-card">
          <span className="admin-stat-label">Users</span>
          <strong className="admin-stat-value">{formatNum(users.total)}</strong>
          <span className="admin-stat-hint">
            {formatNum(users.buyers)} buyers · {formatNum(users.agents)} agents · {formatNum(users.loanOfficers)} LOs
          </span>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Verified pros</span>
          <strong className="admin-stat-value">
            {formatNum((users.verifiedAgents || 0) + (users.verifiedLoanOfficers || 0))}
          </strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">ZIP inventory</span>
          <strong className="admin-stat-value">{formatNum(zips.loaded)}</strong>
          <span className="admin-stat-hint">
            {zips.partial ? 'Still warming cache… · ' : ''}
            {formatNum(zips.payable)} payable · {formatNum(zips.remainingVsTarget)} vs target
          </span>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Claims</span>
          <strong className="admin-stat-value">{formatNum((zips.claimedByAgent || 0) + (zips.claimedByOfficer || 0))}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Listings</span>
          <strong className="admin-stat-value">{listings.total == null ? '—' : formatNum(listings.total)}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Waitlist entries</span>
          <strong className="admin-stat-value">{waitlist.total == null ? '—' : formatNum(waitlist.total)}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Active subscriptions</span>
          <strong className="admin-stat-value">{formatNum(payments.activeSubscriptions)}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Revenue recorded</span>
          <strong className="admin-stat-value">{formatMoney(payments.revenueRecorded)}</strong>
        </div>
      </section>

      <section className="admin-panel">
        <div className="admin-panel-head">
          <h3>Signups — recent window</h3>
        </div>
        {signups.length === 0 ? (
          <p className="admin-muted">No recent signups in this window.</p>
        ) : (
          <div className="admin-chart">
            {signups.map((d) => (
              <div key={d._id} className="admin-chart-col" title={`${d._id}: ${d.count}`}>
                <div
                  className="admin-chart-bar"
                  style={{ height: `${Math.max(8, (d.count / maxSignup) * 120)}px` }}
                />
                <span>{String(d._id).slice(5)}</span>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
