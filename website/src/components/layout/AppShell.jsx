import { Link, NavLink, Outlet } from 'react-router-dom';
import { APP_NAME } from '../../lib/constants';
import { IconGlyph } from '../ui/IconGlyph';
import { useAuth } from '../../context/AuthContext';
import { firstImageFromEntity } from '../../lib/media';

const navByRole = {
  buyerSeller: [
    { to: '/app', label: 'Home', icon: 'home' },
    { to: '/app/favorites', label: 'Favorites', icon: 'heart' },
    { to: '/app/messages', label: 'Messages', icon: 'messages' },
    { to: '/app/profile', label: 'Profile', icon: 'profile' },
  ],
  agent: [
    { to: '/agent', label: 'Dashboard', icon: 'dashboard' },
    { to: '/agent/edit-profile', label: 'Edit Profile', icon: 'profile' },
    { to: '/agent/zip-codes', label: 'ZIP Codes', icon: 'location' },
    { to: '/agent/listings', label: 'Listings', icon: 'listings' },
    { to: '/agent/stats', label: 'Stats', icon: 'stats' },
    { to: '/agent/billing', label: 'Billing', icon: 'billing' },
    { to: '/agent/leads', label: 'Leads', icon: 'leads' },
  ],
  loanOfficer: [
    { to: '/loan-officer', label: 'Dashboard', icon: 'dashboard' },
    { to: '/loan-officer/edit-profile', label: 'Edit Profile', icon: 'profile' },
    { to: '/loan-officer/messages', label: 'Messages', icon: 'messages' },
    { to: '/loan-officer/zip-codes', label: 'ZIP Codes', icon: 'location' },
    { to: '/loan-officer/billing', label: 'Billing', icon: 'billing' },
    { to: '/loan-officer/checklists', label: 'Checklists', icon: 'checklist' },
  ],
};

export function AppShell() {
  const { user, logout, role } = useAuth();
  const nav = navByRole[role] || navByRole.buyerSeller;
  const roleLabel =
    role === 'buyerSeller' ? 'Buyer / Seller' : role === 'agent' ? 'Agent' : 'Loan Officer';
  const displayName = user?.fullname || user?.name || user?.email || 'User';
  const displayInitial = (displayName || 'U').slice(0, 1).toUpperCase();
  const profileImage = firstImageFromEntity(user || {});

  return (
    <div className="website-shell">
      <header className="site-header glass-card">
        <div className="site-header-top">
          <div className="site-brand-wrap">
            <Link className="brand" to={nav[0].to}>{APP_NAME}</Link>
            <p className="brand-sub">Find rebate-ready agents, homes, and lenders</p>
          </div>
          <div className="top-actions">
            <Link className="icon-badge" to="/notifications" aria-label="Notifications">
              <IconGlyph name="bell" filled />
            </Link>
            <Link className="pill-link" to="/proposals">Proposals</Link>
            <div className="top-user-block website-user">
              <div className="top-avatar">
                {profileImage ? (
                  <img src={profileImage} alt={displayName} className="top-avatar-img" />
                ) : (
                  displayInitial
                )}
              </div>
              <div className="top-user-meta">
                <strong className="top-user-name">{displayName}</strong>
                <p className="top-user-role">{roleLabel}</p>
              </div>
            </div>
            <button className="btn ghost tiny" type="button" onClick={logout}>Log out</button>
          </div>
        </div>

        <nav className="site-nav">
          {nav.map((item) => (
            <NavLink key={item.to} to={item.to} className={({ isActive }) => `site-nav-link ${isActive ? 'active' : ''}`}>
              <IconGlyph name={item.icon} filled />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </header>

      <main className="site-main">
        <section className="site-hero glass-card">
          <p className="site-hero-kicker">GetaRebate Platform</p>
          <h2>Smarter Real Estate Journey With Verified Rebate Professionals</h2>
          <p>
            Browse opportunities, connect with trusted experts, and manage your process in one premium web experience.
          </p>
        </section>
        <Outlet />
      </main>
    </div>
  );
}
