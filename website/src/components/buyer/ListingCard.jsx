import { IconGlyph } from '../ui/IconGlyph';
import { firstImageFromEntity } from '../../lib/media';

function toPrice(value, cents) {
  if (typeof value === 'number' && value > 0) return value;
  if (typeof cents === 'number' && cents > 0) return cents / 100;
  const asNum = Number(value);
  return Number.isFinite(asNum) && asNum > 0 ? asNum : 0;
}

export function ListingCard({ listing, isFavorite, onTap, onToggleFavorite }) {
  const price = toPrice(listing?.price, listing?.priceCents);
  const address = listing?.address || listing?.streetAddress || listing?.title || 'Listing';
  const beds = listing?.beds || listing?.bedrooms || 0;
  const baths = listing?.baths || listing?.bathrooms || 0;
  const dualAgency = listing?.dualAgencyAllowed ?? listing?.dualAgency;
  const image = firstImageFromEntity(listing);

  return (
    <article className="buyer-listing-card" onClick={onTap}>
      <div className="buyer-listing-card-media-wrap">
        {image ? (
          <img src={image} alt={address} className="buyer-listing-card-media" />
        ) : (
          <div className="buyer-listing-card-media-fallback">
            <IconGlyph name="home" filled />
          </div>
        )}
        <button
          type="button"
          className="buyer-listing-card-fav"
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
      <div className="buyer-listing-card-body">
        <p className="buyer-listing-card-price">
          {price ? `$${Number(price).toLocaleString()}` : 'Price on request'}
        </p>
        <h4 className="buyer-listing-card-address">{address}</h4>
        {(beds > 0 || baths > 0) && (
          <p className="buyer-listing-card-meta">
            {[beds ? `${beds} Beds` : null, baths ? `${baths} Baths` : null].filter(Boolean).join(' • ')}
          </p>
        )}
        {(dualAgency === true || dualAgency === false) && (
          <span className={`buyer-listing-card-chip ${dualAgency ? 'buyer-listing-card-chip--dual' : ''}`}>
            {dualAgency ? 'Dual Agency Allowed' : 'No Dual Agency'}
          </span>
        )}
        <button type="button" className="btn primary buyer-listing-card-btn" onClick={(e) => { e.stopPropagation(); onTap?.(); }}>
          View Details
        </button>
      </div>
    </article>
  );
}
