import { IconGlyph } from '../ui/IconGlyph';
import { firstImageFromEntity } from '../../lib/media';

function toPrice(value, cents) {
  if (typeof value === 'number' && value > 0) return value;
  if (typeof cents === 'number' && cents > 0) return cents / 100;
  const asNum = Number(value);
  return Number.isFinite(asNum) && asNum > 0 ? asNum : 0;
}

export function OpenHouseCard({ listing, openHouse, isFavorite, onTap, onToggleFavorite }) {
  const price = toPrice(listing?.price, listing?.priceCents);
  const address = listing?.address || listing?.streetAddress || 'Open House Property';
  const start = openHouse?.startTime || openHouse?.startDateTime || openHouse?.date;
  const end = openHouse?.endTime || openHouse?.toTime;
  const dateLabel = start ? new Date(start).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' }) : 'Open House';
  const timeLabel = (start || end)
    ? `${start ? new Date(start).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}${end ? ` - ${new Date(end).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : ''}`
    : 'Time to be announced';
  const notes = openHouse?.notes;
  const image = firstImageFromEntity(listing);

  return (
    <article className="buyer-openhouse-card" onClick={onTap}>
      <div className="buyer-openhouse-card-media-wrap">
        {image ? (
          <img src={image} alt={address} className="buyer-openhouse-card-media" />
        ) : (
          <div className="buyer-openhouse-card-media-fallback">
            <IconGlyph name="event" filled />
          </div>
        )}
        <span className="buyer-openhouse-card-badge">
          <IconGlyph name="event" filled />
          Open House
        </span>
        <button
          type="button"
          className="buyer-openhouse-card-fav"
          onClick={(e) => {
            e.stopPropagation();
            onToggleFavorite?.();
          }}
          aria-label={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
        >
          <span className={`icon-glyph material-symbols-rounded ${isFavorite ? 'filled' : ''}`}>
            {isFavorite ? 'favorite' : 'favorite_border'}
          </span>
        </button>
      </div>
      <div className="buyer-openhouse-card-body">
        {price ? <p className="buyer-openhouse-card-price">${Number(price).toLocaleString()}</p> : null}
        <h4 className="buyer-openhouse-card-address">{address}</h4>
        <div className="buyer-openhouse-card-datetime">
          <IconGlyph name="event" filled />
          <div>
            <span className="buyer-openhouse-card-date">{dateLabel}</span>
            <span className="buyer-openhouse-card-time">{timeLabel}</span>
          </div>
        </div>
        {notes && (
          <p className="buyer-openhouse-card-notes">{notes}</p>
        )}
        <button type="button" className="btn buyer-openhouse-card-btn" onClick={(e) => { e.stopPropagation(); onTap?.(); }}>
          View Details
        </button>
      </div>
    </article>
  );
}
