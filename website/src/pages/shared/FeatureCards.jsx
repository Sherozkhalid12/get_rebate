import { IconGlyph } from '../../components/ui/IconGlyph';

export function KpiGrid({ items, variant }) {
  const gridClass = variant === 'loanOfficer' ? 'kpi-grid kpi-grid--loan-officer' : 'kpi-grid';
  const cardClass = variant === 'loanOfficer' ? 'kpi-card kpi-card--loan-officer glass-card' : 'kpi-card glass-card';
  return (
    <section className={gridClass}>
      {items.map((item) => (
        <article key={item.label} className={cardClass}>
          <div className="kpi-head">
            <span className="kpi-dot" />
            <IconGlyph name="stats" filled />
          </div>
          <p>{item.label}</p>
          <strong>{item.value}</strong>
        </article>
      ))}
    </section>
  );
}

export function ActionTiles({ items }) {
  return (
    <section className="action-tiles">
      {items.map((item) => (
        <button key={item.label} className="tile" type="button" onClick={item.onClick}>
          <div className="tile-top">
            <IconGlyph name="dashboard" filled />
            <IconGlyph name="search" />
          </div>
          <span>{item.label}</span>
          <small>{item.caption}</small>
        </button>
      ))}
    </section>
  );
}

export function ListPanel({ title, rows, renderRight, getRowClassName }) {
  return (
    <section className="glass-card panel">
      <h3>{title}</h3>
      <div className="list-rows">
        {(rows || []).map((row, idx) => {
          let extraClass = '';
          if (getRowClassName && row) {
            try {
              extraClass = getRowClassName(row) || '';
            } catch {
              extraClass = '';
            }
          }
          return (
          <div className={`list-row ${extraClass}`.trim()} key={row?.id ?? row?.name ?? `row-${idx}`}>
            <div>
              <strong>{row.title || row.name}</strong>
              <p>{row.subtitle || row.preview || row.text}</p>
            </div>
            {renderRight ? renderRight(row) : <IconGlyph name="search" />}
          </div>
          );
        })}
      </div>
    </section>
  );
}
