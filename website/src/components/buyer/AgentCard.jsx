import { IconGlyph } from '../ui/IconGlyph';
import { firstImageFromEntity } from '../../lib/media';

export function AgentCard({ agent, isFavorite, onTap, onContact, onToggleFavorite }) {
  const name = agent?.fullname || agent?.name || 'Agent';
  const company = agent?.CompanyName || agent?.companyName || 'Licensed professional';
  const rating = agent?.rating ?? agent?.ratings ?? 0;
  const reviewCount = agent?.reviewCount ?? (Array.isArray(agent?.reviews) ? agent.reviews.length : 0);
  const licensedStates = Array.isArray(agent?.licensedStates)
    ? agent.licensedStates
    : Array.isArray(agent?.LisencedStates)
      ? agent.LisencedStates
      : [];
  const image = firstImageFromEntity(agent);

  return (
    <article className="buyer-agent-card" onClick={onTap}>
      <div className="buyer-agent-card-inner buyer-agent-card-inner--sticky-actions">
        <div className="buyer-agent-card-header">
          <div className="buyer-agent-card-avatar-wrap buyer-agent-card-avatar-wrap--blue">
            {image ? (
              <img src={image} alt={name} className="buyer-agent-card-avatar" />
            ) : (
              <span className="buyer-agent-card-avatar-fallback">
                <IconGlyph name="person" filled />
              </span>
            )}
          </div>
          <div className="buyer-agent-card-info">
            <h4 className="buyer-agent-card-name">{name}</h4>
            <p className="buyer-agent-card-company">{company}</p>
            <div className="buyer-agent-card-rating">
              <IconGlyph name="star" filled />
              <span>{rating}</span>
              <span className="buyer-agent-card-reviews">({reviewCount} reviews)</span>
            </div>
          </div>
          <button
            type="button"
            className="buyer-agent-card-fav"
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
          <div className="buyer-agent-card-states">
            {licensedStates.map((state) => (
              <span key={state} className="buyer-agent-card-state-pill buyer-agent-card-state-pill--blue">
                {state}
              </span>
            ))}
          </div>
        )}

        {agent?.bio && (
          <p className="buyer-agent-card-bio">{agent.bio}</p>
        )}

        <div className="buyer-agent-card-actions">
          <button type="button" className="btn buyer-agent-card-btn-outline" onClick={(e) => { e.stopPropagation(); onTap?.(); }}>
            View Profile
          </button>
          <button type="button" className="btn primary buyer-agent-card-btn-solid" onClick={(e) => { e.stopPropagation(); onContact?.(); }}>
            Contact
          </button>
        </div>
      </div>
    </article>
  );
}
