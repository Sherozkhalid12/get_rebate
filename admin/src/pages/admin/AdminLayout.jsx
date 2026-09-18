import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { LogoutConfirmDialog } from '../../components/dialogs/LogoutConfirmDialog';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { prefetchZipCoverage, prefetchPayments } from '../../api/admin';

const NAV = [
  { to: '/', label: 'Dashboard', icon: 'dashboard', end: true },
  { to: '/users', label: 'Users', icon: 'profile' },
  { to: '/zip-codes', label: 'ZIP Coverage', icon: 'location' },
  { to: '/payments', label: 'Payments', icon: 'billing' },
  { to: '/analytics', label: 'Analytics', icon: 'listings' },
];

export function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [confirmLogout, setConfirmLogout] = useState(false);
  const name = user?.fullname || user?.name || user?.email || 'Admin';

  const clock = useMemo(
    () =>
      new Intl.DateTimeFormat(undefined, {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
      }).format(new Date()),
    [],
  );

  useEffect(() => {
    prefetchZipCoverage({ concurrency: 3 });
    prefetchPayments();
  }, []);

  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div className="admin-brand">
          <img src="/images/appbarlogo.png" alt="GetaRebate" className="admin-brand-logo" />
          <div>
            <strong>GetaRebate</strong>
            <span>Command Center</span>
          </div>
        </div>

        <div>
          <p className="admin-nav-label">Workspace</p>
          <nav className="admin-nav">
            {NAV.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                className={({ isActive }) => `admin-nav-link${isActive ? ' is-active' : ''}`}
              >
                <IconGlyph name={item.icon} />
                <span>{item.label}</span>
              </NavLink>
            ))}
          </nav>
        </div>

        <div className="admin-sidebar-foot">
          <div className="admin-user-chip">
            <span className="admin-user-avatar">{(name || 'A').slice(0, 1).toUpperCase()}</span>
            <div>
              <strong>{name}</strong>
              <span>Administrator</span>
            </div>
          </div>
          <button type="button" className="admin-logout" onClick={() => setConfirmLogout(true)}>
            Log out
          </button>
        </div>
      </aside>

      <div className="admin-main">
        <header className="admin-topbar">
          <div>
            <p className="admin-eyebrow">GetaRebate operations</p>
            <h1>Back office</h1>
          </div>
          <div className="admin-topbar-actions">
            <span className="admin-live-pill">Live · {clock}</span>
          </div>
        </header>
        <main className="admin-content">
          <Outlet />
        </main>
      </div>

      <LogoutConfirmDialog
        open={confirmLogout}
        onConfirm={() => {
          setConfirmLogout(false);
          logout();
          navigate('/login');
        }}
        onCancel={() => setConfirmLogout(false)}
      />
    </div>
  );
}
