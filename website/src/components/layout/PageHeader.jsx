import { IconGlyph } from '../ui/IconGlyph';

export function PageHeader({ title, subtitle, icon = 'dashboard', actions = null }) {
  return (
    <header className="page-header glass-card">
      <div className="page-header-left">
        <div className="page-icon"><IconGlyph name={icon} filled /></div>
        <div>
          <small className="page-overline">GetaRebate</small>
          <h1>{title}</h1>
          {subtitle ? <p>{subtitle}</p> : null}
        </div>
      </div>
      {actions ? <div className="page-header-actions">{actions}</div> : null}
    </header>
  );
}
