import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { IconGlyph } from '../ui/IconGlyph';

export function PremiumLandingFrame({ containerRef, className = '', children }) {
  return (
    <div ref={containerRef} className={`lp2-root ${className}`}>
      <div className="lp2-bg" aria-hidden="true" />
      <div className="lp2-container">{children}</div>
    </div>
  );
}

export function PremiumLandingHeader({
  brandTo = '/',
  brandLabel = null,
  links = [],
  actions,
  rightSlot,
}) {
  return (
    <header className="lp2-header lp2-surface">
      <Link to={brandTo} className="lp2-brand">
        <img src="/images/appbarlogo.png" alt="Get a Rebate Real Estate" className="lp2-brand-logo lp2-brand-logo--wide" />
        {brandLabel ? <span className="lp2-brand-label">{brandLabel}</span> : null}
      </Link>

      {links?.length ? (
        <nav className="lp2-nav" aria-label="Primary">
          {links.map((l) => (
            <a key={l.href} className="lp2-nav-link" href={l.href}>
              {l.label}
            </a>
          ))}
        </nav>
      ) : (
        <span />
      )}

      <div className="lp2-header-actions">
        {actions}
        {rightSlot}
      </div>
    </header>
  );
}

export function PremiumLandingFooter() {
  const year = useMemo(() => new Date().getFullYear(), []);

  return (
    <footer className="lp2-footer lp2-surface">
      <div className="lp2-footer-top">
        <div className="lp2-footer-brand">
          <img src="/images/appbarlogo.png" alt="Get a Rebate Real Estate" className="lp2-footer-logo lp2-footer-logo--wide" />
        </div>
        <div className="lp2-footer-links" aria-label="Footer">
          <Link to="/privacy-policy">Privacy</Link>
          <Link to="/terms-of-service">Terms</Link>
          <Link to="/about-legal">Legal</Link>
          <Link to="/help-support">Support</Link>
        </div>
      </div>
      <div className="lp2-footer-bottom">
        <span>© {year}</span>
        <span className="lp2-footer-sep" aria-hidden="true" />
        <span>Built for modern rebate-first transactions</span>
      </div>
    </footer>
  );
}

export function FaqAccordion({ items = [] }) {
  const [openIndex, setOpenIndex] = useState(0);
  if (!items?.length) return null;

  return (
    <div className="lp2-accordion" role="list">
      {items.map((faq, idx) => {
        const isOpen = idx === openIndex;
        const triggerId = `faq-trigger-${idx}`;
        const panelId = `faq-panel-${idx}`;
        return (
          <div key={faq.q} className={`lp2-accordion-item ${isOpen ? 'open' : ''}`} role="listitem">
            <button
              id={triggerId}
              type="button"
              className="lp2-accordion-trigger"
              aria-expanded={isOpen}
              aria-controls={panelId}
              onClick={() => setOpenIndex((cur) => (cur === idx ? -1 : idx))}
            >
              <span className="lp2-accordion-left">
                <span className="lp2-accordion-icon">
                  <IconGlyph name={faq.icon || 'info'} filled />
                </span>
                <span className="lp2-accordion-q">{faq.q}</span>
              </span>
              <span className="lp2-accordion-chevron" aria-hidden="true">
                <IconGlyph name="chevronDown" filled={false} />
              </span>
            </button>

            <div
              id={panelId}
              className="lp2-accordion-panel"
              role="region"
              aria-labelledby={triggerId}
              hidden={!isOpen}
            >
              {typeof faq.a === 'string' ? <p>{faq.a}</p> : faq.a}
            </div>
          </div>
        );
      })}
    </div>
  );
}
