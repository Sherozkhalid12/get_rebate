import { IconGlyph } from '../ui/IconGlyph';
import { firstImageFromEntity } from '../../lib/media';

export function LoanOfficerCard({ loanOfficer, isFavorite, onTap, onContact, onToggleFavorite }) {
  const name = loanOfficer?.fullname || loanOfficer?.name || 'Loan Officer';
  const company = loanOfficer?.CompanyName || loanOfficer?.companyName || 'Mortgage professional';
  const rating = loanOfficer?.rating ?? loanOfficer?.ratings ?? 0;
  const reviewCount = loanOfficer?.reviewCount ?? (Array.isArray(loanOfficer?.reviews) ? loanOfficer.reviews.length : 0);
  const licensedStates = Array.isArray(loanOfficer?.licensedStates)
    ? loanOfficer.licensedStates
    : Array.isArray(loanOfficer?.LisencedStates)
      ? loanOfficer.LisencedStates
      : [];
  const image = firstImageFromEntity(loanOfficer);

  return (
    <article className="buyer-loan-officer-card" onClick={onTap}>
      <div className="buyer-loan-officer-card-inner buyer-loan-officer-card-inner--sticky-actions">
        <div className="buyer-loan-officer-card-header">
          <div className="buyer-loan-officer-card-avatar-wrap buyer-loan-officer-card-avatar-wrap--green">
            {image ? (
              <img src={image} alt={name} className="buyer-loan-officer-card-avatar" />
            ) : (
              <span className="buyer-loan-officer-card-avatar-fallback">
                <IconGlyph name="accountBalance" filled />
              </span>
            )}
          </div>
          <div className="buyer-loan-officer-card-info">
            <h4 className="buyer-loan-officer-card-name">{name}</h4>
            <p className="buyer-loan-officer-card-company">{company}</p>
            <div className="buyer-loan-officer-card-rating">
              <IconGlyph name="star" filled />
              <span>{rating}</span>
              <span className="buyer-loan-officer-card-reviews">({reviewCount} reviews)</span>
            </div>
          </div>
          <button
            type="button"
            className="buyer-loan-officer-card-fav"
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

        {licensedStates.length > 0 && (
          <div className="buyer-loan-officer-card-states">
            {licensedStates.map((state) => (
              <span key={state} className="buyer-loan-officer-card-state-pill buyer-loan-officer-card-state-pill--green">
                {state}
              </span>
            ))}
          </div>
        )}

        {loanOfficer?.bio && (
          <p className="buyer-loan-officer-card-bio">{loanOfficer.bio}</p>
        )}

        <div className="buyer-loan-officer-card-actions">
          <button type="button" className="btn buyer-loan-officer-card-btn-outline" onClick={(e) => { e.stopPropagation(); onTap?.(); }}>
            View Profile
          </button>
          <button type="button" className="btn buyer-loan-officer-card-btn-solid" onClick={(e) => { e.stopPropagation(); onContact?.(); }}>
            Contact
          </button>
        </div>
      </div>
    </article>
  );
}
