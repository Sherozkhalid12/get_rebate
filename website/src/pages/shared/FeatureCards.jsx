import { IconGlyph } from '../../components/ui/IconGlyph';

export function KpiGrid({ items }) {
  return (
    <section className="kpi-grid">
      {items.map((item) => (
        <article key={item.label} className="kpi-card glass-card">
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

export function ListPanel({ title, rows, renderRight }) {
  return (
    <section className="glass-card panel">
      <h3>{title}</h3>
      <div className="list-rows">
        {rows.map((row) => (
          <div className="list-row" key={row.id}>
            <div>
              <strong>{row.title || row.name}</strong>
              <p>{row.subtitle || row.preview || row.text}</p>
            </div>
            {renderRight ? renderRight(row) : <IconGlyph name="search" />}
          </div>
        ))}
      </div>
    </section>
  );
}
