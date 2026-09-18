import { useCallback, useEffect, useState } from 'react';
import * as adminApi from '../../api/admin';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

function formatDate(value) {
  if (!value) return '—';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? String(value) : d.toLocaleDateString();
}

export function AdminUsersPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [users, setUsers] = useState([]);
  const [meta, setMeta] = useState({ total: 0, totalPages: 1, currentPage: 1 });
  const [userType, setUserType] = useState('both');
  const [verified, setVerified] = useState('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [busyId, setBusyId] = useState(null);
  const [toast, setToast] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await adminApi.getUsersByType({
        userType,
        verified: verified === 'all' ? undefined : verified,
        search: search.trim(),
        page,
        limit: 20,
      });
      setUsers(res?.users || []);
      setMeta({
        total: res?.total || 0,
        totalPages: res?.totalPages || 1,
        currentPage: res?.currentPage || page,
        hasNextPage: res?.hasNextPage,
        hasPrevPage: res?.hasPrevPage,
      });
    } catch (err) {
      setError(err?.message || 'Failed to load users');
      setUsers([]);
    } finally {
      setLoading(false);
    }
  }, [userType, verified, search, page]);

  useEffect(() => {
    load();
  }, [load]);

  const onToggle = async (userId) => {
    setBusyId(userId);
    setToast('');
    try {
      const res = await adminApi.toggleVerification(userId);
      setToast(res?.message || 'Updated');
      await load();
    } catch (err) {
      setToast(err?.message || 'Toggle failed');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="admin-page">
      <div className="admin-page-head">
        <div>
          <h2>Professionals</h2>
          <p>Review agents and loan officers, filter by status, and approve verification with one click.</p>
        </div>
      </div>

      <form
        className="admin-filters"
        onSubmit={(e) => {
          e.preventDefault();
          setPage(1);
          load();
        }}
      >
        <label>
          Type
          <select value={userType} onChange={(e) => { setUserType(e.target.value); setPage(1); }}>
            <option value="both">Agents + Loan officers</option>
            <option value="agent">Agents</option>
            <option value="loanofficer">Loan officers</option>
          </select>
        </label>
        <label>
          Verified
          <select value={verified} onChange={(e) => { setVerified(e.target.value); setPage(1); }}>
            <option value="all">All</option>
            <option value="true">Verified</option>
            <option value="false">Unverified</option>
          </select>
        </label>
        <label className="admin-filters-grow">
          Search
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Name, email, phone, license…"
          />
        </label>
        <button type="submit" className="btn primary">Apply</button>
      </form>

      {toast ? <div className="admin-alert">{toast}</div> : null}
      {error ? <div className="admin-alert admin-alert--error">{error}</div> : null}

      {loading ? (
        <AnimatedLoader label="Loading users…" />
      ) : (
        <>
          <p className="admin-muted">{meta.total.toLocaleString()} professionals</p>
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>License</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {users.length === 0 ? (
                  <tr><td colSpan={7} className="admin-muted">No users match these filters.</td></tr>
                ) : users.map((u) => (
                  <tr key={u._id}>
                    <td>{u.fullname || '—'}</td>
                    <td>{u.email || '—'}</td>
                    <td><span className="admin-pill">{u.role}</span></td>
                    <td>{u.liscenceNumber || '—'}</td>
                    <td>
                      <span className={`admin-pill ${u.verified ? 'admin-pill--ok' : 'admin-pill--warn'}`}>
                        {u.verified ? 'Verified' : 'Unverified'}
                      </span>
                    </td>
                    <td>{formatDate(u.createdAt)}</td>
                    <td>
                      <button
                        type="button"
                        className="btn ghost sm"
                        disabled={busyId === u._id}
                        onClick={() => onToggle(u._id)}
                      >
                        {busyId === u._id ? '…' : u.verified ? 'Unverify' : 'Verify'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="admin-pagination">
            <button type="button" className="btn ghost" disabled={!meta.hasPrevPage} onClick={() => setPage((p) => Math.max(1, p - 1))}>
              Previous
            </button>
            <span>Page {meta.currentPage} of {meta.totalPages}</span>
            <button type="button" className="btn ghost" disabled={!meta.hasNextPage} onClick={() => setPage((p) => p + 1)}>
              Next
            </button>
          </div>
        </>
      )}
    </div>
  );
}
