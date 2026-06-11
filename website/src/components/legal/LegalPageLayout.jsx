import { Link } from 'react-router-dom';
import { PremiumLandingFooter, PremiumLandingFrame } from '../landing/PremiumLandingKit';
import { IconGlyph } from '../ui/IconGlyph';
import { LEGAL_LAST_UPDATED } from '../../content/legalContent';

export function LegalPageLayout({ title, subtitle, icon = 'shield', children }) {
  return (
    <PremiumLandingFrame className="legal-page-root">
      <header className="legal-topbar lp2-surface">
        <Link to="/" className="legal-topbar__brand">
          <img src="/images/appbarlogo.png" alt="GetaRebate" className="legal-topbar__logo" />
        </Link>
        <nav className="legal-topbar__nav" aria-label="Legal navigation">
          <Link to="/privacy-policy">Privacy</Link>
          <Link to="/terms-of-service">Terms</Link>
          <Link to="/help-support">Support</Link>
          <Link to="/about-legal">Legal</Link>
        </nav>
        <div className="legal-topbar__actions">
          <Link to="/auth" className="btn ghost legal-topbar__cta">
            Sign in
          </Link>
        </div>
      </header>

      <main className="legal-page">
        <div className="legal-hero glass-card">
          <div className="legal-hero__icon" aria-hidden="true">
            <IconGlyph name={icon} />
          </div>
          <div className="legal-hero__text">
            <h1>{title}</h1>
            {subtitle ? <p className="legal-hero__subtitle">{subtitle}</p> : null}
          </div>
        </div>

        <p className="legal-updated glass-card">
          <IconGlyph name="event" />
          <span>Last updated: {LEGAL_LAST_UPDATED}</span>
        </p>

        <div className="legal-page__body">{children}</div>
      </main>

      <PremiumLandingFooter />
    </PremiumLandingFrame>
  );
}

export function LegalSection({ title, body, links }) {
  return (
    <section className="legal-section glass-card">
      <h2>{title}</h2>
      {body.split('\n\n').map((paragraph) => (
        <p key={paragraph.slice(0, 48)}>{paragraph}</p>
      ))}
      {links?.length ? (
        <ul className="legal-section__links">
          {links.map((link) => (
            <li key={link.href}>
              <Link to={link.href}>{link.label}</Link>
            </li>
          ))}
        </ul>
      ) : null}
    </section>
  );
}
