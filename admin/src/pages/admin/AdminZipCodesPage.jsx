import { useCallback, useEffect, useState } from 'react';
import * as adminApi from '../../api/admin';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { PLATFORM_ZIP_TARGET } from '../../lib/zipPotentialByState';

function formatNum(n) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  return Number(n).toLocaleString();
}

const PAGE_SIZE = 10;

export function AdminZipCodesPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [data, setData] = useState(null);
  const [query, setQuery] = useState('');
  const [sortKey, setSortKey] = useState('remainingToLoad');
  const [page, setPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await adminApi.getZipCoveragePage({
        page,
        pageSize: PAGE_SIZE,
        filter: query,
        sortKey,
      });
      setData(res);
      // Prefetch next page quietly
      if (res?.meta?.hasNextPage) {
        adminApi.getZipCoveragePage({
          page: page + 1,
          pageSize: PAGE_SIZE,
          filter: query,
          sortKey,
        }).catch(() => {});
      }
    } catch (err) {
      setError(err?.message || 'Failed to load ZIP coverage');
    } finally {
      setLoading(false);
    }
  }, [page, query, sortKey]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    // Keep warming remaining states in background
    adminApi.prefetchZipCoverage({ concurrency: 3 });
  }, []);

  const s = data?.summary || {};
  const expl = data?.explanation || {};
  const meta = data?.meta || {};
  const states = data?.states || [];

  return (
    <div className="admin-page">
      <div className="admin-page-head">
        <div>
          <h2>Territory coverage</h2>
          <p>
            Loaded vs ~27k potential by state — same <code>getstateZip</code> data as the marketplace,
            cached for 30 minutes ({PAGE_SIZE} states per page).
          </p>
        </div>
      </div>

      <section className="admin-stat-grid">
        <div className="admin-stat-card">
          <span className="admin-stat-label">Loaded (cached states)</span>
          <strong className="admin-stat-value">{formatNum(s.loadedToday)}</strong>
          <span className="admin-stat-hint">
            {formatNum(s.statesLoaded)}/{formatNum(s.statesTotal)} states · {formatNum(s.coveragePct)}%
          </span>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Payable (w/ population)</span>
          <strong className="admin-stat-value">{formatNum(s.payableToday)}</strong>
          <span className="admin-stat-hint">{formatNum(s.loadedWithoutPopulation)} missing population</span>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Potential target</span>
          <strong className="admin-stat-value">{formatNum(s.potentialInRebateStates || PLATFORM_ZIP_TARGET)}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Remaining to load</span>
          <strong className="admin-stat-value">{formatNum(s.remainingToLoad)}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Claimed by agents</span>
          <strong className="admin-stat-value">{formatNum(s.claimedByAgent)}</strong>
        </div>
        <div className="admin-stat-card">
          <span className="admin-stat-label">Claimed by LOs</span>
          <strong className="admin-stat-value">{formatNum(s.claimedByOfficer)}</strong>
        </div>
      </section>

      <section className="admin-panel admin-panel--explain">
        <h3>Why ~14k today vs ~27k potential?</h3>
        <ul className="admin-explain-list">
          <li><strong>Available today:</strong> {expl.availableToday}</li>
          <li><strong>Potential:</strong> {expl.potentialTarget}</li>
          <li><strong>What blocks the rest:</strong> {expl.whatBlocksRemaining}</li>
          <li><strong>Timeline:</strong> {expl.etaNote}</li>
        </ul>
      </section>

      <form
        className="admin-filters"
        onSubmit={(e) => {
          e.preventDefault();
          setPage(1);
          load();
        }}
      >
        <label>
          Filter state
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="e.g. CA"
          />
        </label>
        <label>
          Sort by
          <select value={sortKey} onChange={(e) => { setSortKey(e.target.value); setPage(1); }}>
            <option value="remainingToLoad">Remaining to load</option>
            <option value="loaded">Loaded</option>
            <option value="potential">Potential</option>
            <option value="withPopulation">Payable</option>
            <option value="coveragePct">Coverage %</option>
            <option value="state">State</option>
          </select>
        </label>
        <button type="submit" className="btn primary">Apply</button>
      </form>

      {error ? <div className="admin-alert admin-alert--error">{error}</div> : null}

      {loading && !states.length ? (
        <AnimatedLoader label="Loading this page of states…" />
      ) : (
        <>
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>State</th>
                  <th>Potential</th>
                  <th>Loaded</th>
                  <th>Payable</th>
                  <th>No pop.</th>
                  <th>Remaining</th>
                  <th>Coverage</th>
                  <th>Agent claims</th>
                  <th>LO claims</th>
                </tr>
              </thead>
              <tbody>
                {states.map((row) => (
                  <tr key={row.state}>
                    <td><strong>{row.state}</strong></td>
                    <td>{formatNum(row.potential)}</td>
                    <td>{formatNum(row.loaded)}</td>
                    <td>{formatNum(row.withPopulation)}</td>
                    <td>{formatNum(row.withoutPopulation)}</td>
                    <td>{formatNum(row.remainingToLoad)}</td>
                    <td>
                      <div className="admin-bar" title={`${row.coveragePct}%`}>
                        <span style={{ width: `${Math.min(100, row.coveragePct)}%` }} />
                        <em>{row.coveragePct}%</em>
                      </div>
                    </td>
                    <td>{formatNum(row.claimedByAgent)}</td>
                    <td>{formatNum(row.claimedByOfficer)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="admin-pagination">
            <button
              type="button"
              className="btn ghost"
              disabled={!meta.hasPrevPage || loading}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Previous
            </button>
            <span>
              Page {meta.currentPage || page} of {meta.totalPages || 1}
              {loading ? ' · loading…' : ''}
            </span>
            <button
              type="button"
              className="btn ghost"
              disabled={!meta.hasNextPage || loading}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </button>
          </div>
        </>
      )}
    </div>
  );
}
