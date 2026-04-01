import { useState, useEffect, useRef } from 'react';
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { APP_NAME } from '../../lib/constants';
import { IconGlyph } from '../ui/IconGlyph';
import { ThemeToggle } from '../ui/ThemeToggle';
import { useAuth } from '../../context/AuthContext';
import { firstImageFromEntity } from '../../lib/media';
import { LogoutConfirmDialog } from '../dialogs/LogoutConfirmDialog';

const BRAND_LOGO = '/images/appbarlogo.png';

const navByRole = {
  buyerSeller: [
    { to: '/app', label: 'Home', icon: 'home' },
    { to: '/app/find-agents', label: 'Find Agents', icon: 'search' },
    { to: '/app/favorites', label: 'Favorites', icon: 'heart' },
    { to: '/app/messages', label: 'Messages', icon: 'messages' },
    { to: '/app/profile', label: 'Profile', icon: 'profile' },
  ],
  agent: [
    { to: '/agent', label: 'Dashboard', icon: 'dashboard' },
    { to: '/agent/edit-profile', label: 'Edit Profile', icon: 'profile' },
    { to: '/agent/messages', label: 'Messages', icon: 'messages' },
    { to: '/agent/zip-codes', label: 'ZIP Codes', icon: 'location' },
    { to: '/agent/listings', label: 'Listings', icon: 'listings' },
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
  const navigate = useNavigate();
  const { user, logout, role } = useAuth();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const drawerTriggerRef = useRef(null);
  const drawerCloseRef = useRef(null);
  const nav = navByRole[role] || navByRole.buyerSeller;
  const roleLabel =
    role === 'buyerSeller' ? 'Buyer / Seller' : role === 'agent' ? 'Agent' : 'Loan Officer';
  const displayName = user?.fullname || user?.name || user?.email || 'User';
  const displayInitial = (displayName || 'U').slice(0, 1).toUpperCase();
  const profileImage = firstImageFromEntity(user || {});

  const profilePath = role === 'buyerSeller' ? '/app/profile' : role === 'agent' ? '/agent/edit-profile' : '/loan-officer/edit-profile';

  const closeDrawer = () => {
    setDrawerOpen(false);
    drawerTriggerRef.current?.focus();
  };

  useEffect(() => {
    if (drawerOpen) {
      document.body.style.overflow = 'hidden';
      drawerCloseRef.current?.focus();
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [drawerOpen]);

  const handleNavClick = (to) => {
    closeDrawer();
    navigate(to);
  };

  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const handleLogoutClick = () => {
    closeDrawer();
    setShowLogoutConfirm(true);
  };

  const handleLogoutConfirm = () => {
    setShowLogoutConfirm(false);
    logout();
  };

  const handleLogoutCancel = () => {
    setShowLogoutConfirm(false);
  };

  return (
    <div className={`website-shell ${role === 'loanOfficer' ? 'website-shell--loan-officer' : ''}`}>
      {/* Drawer overlay (mobile) */}
      <div
        className={`drawer-overlay ${drawerOpen ? 'drawer-overlay--open' : ''}`}
        onClick={closeDrawer}
        onKeyDown={(e) => e.key === 'Escape' && closeDrawer()}
        role="button"
        tabIndex={-1}
        aria-hidden={!drawerOpen}
      />

      {/* Drawer panel (mobile) */}
      <aside className={`drawer-panel ${drawerOpen ? 'drawer-panel--open' : ''}`}>
        <div className="drawer-header">
          <Link className="drawer-brand" to={nav[0].to} onClick={closeDrawer}>
            <img src={BRAND_LOGO} alt="Get a Rebate Real Estate" className="app-brand-logo app-brand-logo--wide" />
          </Link>
          <button
            ref={drawerCloseRef}
            type="button"
            className="drawer-close"
            onClick={closeDrawer}
            aria-label="Close menu"
          >
            <IconGlyph name="close" />
          </button>
        </div>
        <div className="drawer-user">
          <button
            type="button"
            className="drawer-user-block"
            onClick={() => handleNavClick(profilePath)}
          >
            <div className="drawer-avatar">
              {profileImage ? (
                <img src={profileImage} alt={displayName} />
              ) : (
                displayInitial
              )}
            </div>
            <div className="drawer-user-meta">
              <strong>{displayName}</strong>
              <span>{roleLabel}</span>
            </div>
          </button>
        </div>
        <nav className="drawer-nav">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => `drawer-nav-link ${isActive ? 'active' : ''}`}
              onClick={closeDrawer}
            >
              <IconGlyph name={item.icon} filled />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="drawer-actions">
          <Link className="drawer-action-link" to="/notifications" onClick={closeDrawer}>
            <IconGlyph name="bell" filled />
            <span>Notifications</span>
          </Link>
          {role !== 'loanOfficer' && (
            <Link className="drawer-action-link" to="/proposals" onClick={closeDrawer}>
              <IconGlyph name="document" />
              <span>Proposals</span>
            </Link>
          )}
          <div className="drawer-theme">
            <ThemeToggle />
            <span>Theme</span>
          </div>
          <button
            type="button"
            className="drawer-logout"
            onClick={handleLogoutClick}
          >
            <IconGlyph name="logout" />
            <span>Log out</span>
          </button>
        </div>
      </aside>

      {/* Main header */}
      <header className="site-header glass-card">
        <div className="site-header-top">
          <div className="site-brand-wrap">
            <Link className="brand app-brand-link" to={nav[0].to}>
              <img src={BRAND_LOGO} alt="Get a Rebate Real Estate" className="app-brand-logo app-brand-logo--wide" />
            </Link>
            <p className="brand-sub">Find rebate-ready agents, homes, and lenders</p>
          </div>
          <div className="top-actions">
            <button
              ref={drawerTriggerRef}
              type="button"
              className="drawer-trigger"
              onClick={() => setDrawerOpen(true)}
              aria-label="Open menu"
            >
              <IconGlyph name="menu" />
            </button>
            <ThemeToggle />
            <Link className="icon-badge" to="/notifications" aria-label="Notifications">
              <IconGlyph name="bell" filled />
            </Link>
            {role !== 'loanOfficer' && (
              <Link className="pill-link hide-on-narrow" to="/proposals">Proposals</Link>
            )}
            <button
              type="button"
              className="top-user-block website-user desktop-only"
              onClick={() => navigate(profilePath)}
              aria-label="Go to profile"
            >
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
            </button>
            <button className="btn ghost tiny desktop-only" type="button" onClick={handleLogoutClick}>Log out</button>
          </div>
        </div>

        <nav className="site-nav desktop-nav">
          {nav.map((item) => (
            <NavLink key={item.to} to={item.to} className={({ isActive }) => `site-nav-link ${isActive ? 'active' : ''}`}>
              <IconGlyph name={item.icon} filled />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </header>

      <LogoutConfirmDialog
        open={showLogoutConfirm}
        onConfirm={handleLogoutConfirm}
        onCancel={handleLogoutCancel}
      />

      <main className="site-main">
        <section className="site-hero glass-card hero-desktop">
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
