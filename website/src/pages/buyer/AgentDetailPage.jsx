import { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import * as userApi from '../../api/user';
import * as marketplaceApi from '../../api/marketplace';
import { unwrapObject, unwrapList } from '../../lib/api';
import { firstImageFromEntity, resolveMediaUrl } from '../../lib/media';

export function AgentDetailPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const stateAgent = location.state?.agent || null;
  const [agent, setAgent] = useState(stateAgent);
  const [properties, setProperties] = useState([]);
  const [loadingProperties, setLoadingProperties] = useState(false);
  const [error, setError] = useState('');
  const [selectedTab, setSelectedTab] = useState(0);

  const agentId = agent?._id || agent?.id || stateAgent?._id || stateAgent?.id;

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!agentId) return;
      try {
        const res = await userApi.getUserById(agentId);
        if (!live) return;
        const full = unwrapObject(res, ['user']) || stateAgent;
        setAgent(full);
      } catch (err) {
        if (!live) return;
        setError(err.message || 'Unable to load full agent details.');
      }
    };
    run();
    return () => { live = false; };
  }, [agentId]);

  useEffect(() => {
    if (!agentId) return;
    let live = true;
    setLoadingProperties(true);
    marketplaceApi.getAgentListings(agentId)
      .then((res) => {
        if (!live) return;
        const list = unwrapList(res, ['listings', 'data']) || res?.listings || res?.data || [];
        setProperties(Array.isArray(list) ? list : []);
      })
      .catch(() => { if (live) setProperties([]); })
      .finally(() => { if (live) setLoadingProperties(false); });
    return () => { live = false; };
  }, [agentId]);

  useEffect(() => {
    if (agentId) marketplaceApi.addAgentProfileView(agentId).catch(() => {});
  }, [agentId]);

  const profileImage = firstImageFromEntity(agent);
  const companyLogo = resolveMediaUrl(agent?.companyLogo || agent?.companyLogoUrl || '');
  const licensedStates = Array.isArray(agent?.licensedStates)
    ? agent.licensedStates
    : Array.isArray(agent?.LisencedStates)
      ? agent.LisencedStates
      : [];
  const serviceZipCodes = Array.isArray(agent?.serviceZipCodes)
    ? agent.serviceZipCodes
    : Array.isArray(agent?.serviceAreas)
      ? agent.serviceAreas
      : [];
  const claimedZipCodes = useMemo(() => {
    const fromClaimed = Array.isArray(agent?.claimedZipCodes)
      ? agent.claimedZipCodes.map((z) => (typeof z === 'string' ? z : (z?.zipCode || z?.postalCode || z?.zipcode || '')))
      : [];
    const fromZipCodes = Array.isArray(agent?.zipCodes)
      ? agent.zipCodes.map((z) => z?.zipCode || z?.postalCode || z?.zipcode || '').filter(Boolean)
      : [];
    return [...new Set([...fromClaimed, ...fromZipCodes])].filter(Boolean);
  }, [agent]);

  const expertise = useMemo(() => {
    if (Array.isArray(agent?.areasOfExpertise)) return agent.areasOfExpertise;
    if (Array.isArray(agent?.expertise)) return agent.expertise;
    return [];
  }, [agent]);

  const reviews = useMemo(() => {
    const arr = agent?.reviews || agent?.platformReviews || [];
    return Array.isArray(arr) ? arr : [];
  }, [agent]);

  const platformRating = agent?.platformRating ?? agent?.rating ?? agent?.ratings ?? 0;
  const platformReviewCount = agent?.platformReviewCount ?? agent?.reviewCount ?? reviews.length;

  const contactAgent = () => {
    if (agentId) marketplaceApi.addAgentContact(agentId).catch(() => {});
    navigate('/buyer-lead-form', { state: { agent } });
  };

  const startChat = () => {
    navigate('/app/messages', { state: { openChatWith: agent } });
  };

  const viewProperty = (prop) => {
    const listing = prop?.raw || prop;
    navigate('/listing-detail', { state: { listing } });
  };

  const formatProperty = (p) => {
    const raw = p?.raw || p;
    const price = raw?.price || (raw?.priceCents ? raw.priceCents / 100 : 0);
    const addr = raw?.streetAddress || raw?.address || [raw?.streetAddress, raw?.city, raw?.state, raw?.zipCode].filter(Boolean).join(', ');
    const img = firstImageFromEntity(raw);
    return {
      id: raw?._id || raw?.id,
      image: img,
      address: addr || 'Address not provided',
      price: price ? `$${Number(price).toLocaleString()}` : 'Price on request',
      beds: raw?.beds ?? raw?.bedrooms ?? raw?.propertyDetails?.bedrooms ?? 0,
      baths: raw?.baths ?? raw?.bathrooms ?? raw?.propertyDetails?.bathrooms ?? 0,
      sqft: raw?.sqft ?? raw?.squareFeet ?? raw?.propertyDetails?.squareFeet ?? '—',
      status: raw?.status === 'active' ? 'For Sale' : (raw?.status || '—'),
      rawStatus: raw?.status,
      isActive: raw?.isActive ?? (raw?.status === 'active'),
      raw: raw,
    };
  };

  const formattedProperties = useMemo(() => properties.map(formatProperty), [properties]);

  if (error) {
    return (
      <div className="page-body">
        <PageHeader title="Agent Profile" icon="person" />
        <p className="error-text">{error}</p>
      </div>
    );
  }

  if (!agent) {
    return (
      <div className="page-body">
        <PageHeader title="Agent Profile" icon="person" />
        <AnimatedLoader variant="card" label="Loading agent..." />
      </div>
    );
  }

  const name = agent?.fullname || agent?.name || 'Agent';
  const brokerage = agent?.CompanyName || agent?.companyName || agent?.brokerage || 'Licensed professional';

  return (
    <div className="page-body">
      <PageHeader title="Agent Profile" subtitle="Complete profile, reviews, and properties." icon="person" />

      <section className="glass-card agent-detail-hero">
        <div className="agent-detail-profile-row">
          <div className="agent-detail-avatar-wrap">
            {profileImage ? (
              <img src={profileImage} alt={name} className="agent-detail-avatar" />
            ) : (
              <div className="agent-detail-avatar-fallback">
                <IconGlyph name="person" filled />
              </div>
            )}
          </div>
          <div className="agent-detail-info">
            <h2 className="agent-detail-name">{name}</h2>
            <p className="agent-detail-brokerage">{brokerage}</p>
            <div className="agent-detail-rating">
              <IconGlyph name="star" filled />
              <span>{platformRating} ({platformReviewCount} reviews)</span>
            </div>
          </div>
          {companyLogo ? (
            <div className="agent-detail-logo-wrap">
              <img src={companyLogo} alt="Company" className="agent-detail-logo" />
            </div>
          ) : null}
          {agent?.isVerified ? (
            <span className="agent-detail-verified">
              <IconGlyph name="shield" filled />
              Verified
            </span>
          ) : null}
        </div>

        {agent?.bio ? (
          <div className="agent-detail-bio">
            <p>{agent.bio}</p>
          </div>
        ) : null}

        {expertise.length > 0 ? (
          <div className="agent-detail-expertise">
            <h4>Areas of Expertise</h4>
            <div className="agent-detail-expertise-pills">
              {expertise.map((area) => (
                <span key={area} className="agent-detail-expertise-pill">{area}</span>
              ))}
            </div>
          </div>
        ) : null}

        <div className="agent-detail-links">
          <h4>Professional Links</h4>
          <div className="agent-detail-links-list">
            {(agent?.websiteUrl || agent?.website_link) ? (
              <a href={(agent.websiteUrl || agent.website_link).startsWith('http') ? (agent.websiteUrl || agent.website_link) : `https://${agent.websiteUrl || agent.website_link}`} target="_blank" rel="noreferrer" className="agent-detail-link-item">
                <IconGlyph name="info" filled />
                <span>Website</span>
                <span className="icon-glyph material-symbols-rounded">open_in_new</span>
              </a>
            ) : null}
            {(agent?.googleReviewsUrl || agent?.google_reviews_link) ? (
              <a href={(agent.googleReviewsUrl || agent.google_reviews_link).startsWith('http') ? (agent.googleReviewsUrl || agent.google_reviews_link) : `https://${agent.googleReviewsUrl || agent.google_reviews_link}`} target="_blank" rel="noreferrer" className="agent-detail-link-item">
                <IconGlyph name="star" filled />
                <span>Google Reviews</span>
                <span className="icon-glyph material-symbols-rounded">open_in_new</span>
              </a>
            ) : null}
            {(agent?.thirdPartyReviewsUrl || agent?.thirdPartReviewLink) ? (
              <a href={(agent.thirdPartyReviewsUrl || agent.thirdPartReviewLink).startsWith('http') ? (agent.thirdPartyReviewsUrl || agent.thirdPartReviewLink) : `https://${agent.thirdPartyReviewsUrl || agent.thirdPartReviewLink}`} target="_blank" rel="noreferrer" className="agent-detail-link-item">
                <IconGlyph name="star" filled />
                <span>Client Reviews</span>
                <span className="icon-glyph material-symbols-rounded">open_in_new</span>
              </a>
            ) : null}
            {!(agent?.websiteUrl || agent?.website_link) && !(agent?.googleReviewsUrl || agent?.google_reviews_link) && !(agent?.thirdPartyReviewsUrl || agent?.thirdPartReviewLink) ? (
              <p className="agent-detail-links-empty">No professional links added yet</p>
            ) : null}
          </div>
        </div>

        <div className="agent-detail-reviews-section">
          <h4><IconGlyph name="shield" filled /> Get a Rebate Reviews</h4>
          {platformReviewCount > 0 ? (
            <>
              <div className="agent-detail-platform-rating">
                {[1, 2, 3, 4, 5].map((i) => (
                  <span key={i} className={`icon-glyph material-symbols-rounded ${i <= Math.round(platformRating) ? 'filled' : ''}`}>star</span>
                ))}
                <span>{platformRating} ({platformReviewCount} {platformReviewCount === 1 ? 'review' : 'reviews'})</span>
              </div>
              <p className="agent-detail-reviews-sub">From verified closed transactions on Get a Rebate</p>
            </>
          ) : (
            <p>No reviews yet from Get a Rebate transactions. Reviews will appear here after closing transactions through Get a Rebate.</p>
          )}
        </div>

        <div className="agent-detail-actions">
          <button type="button" className="btn agent-detail-btn-outline" onClick={contactAgent}>
            <IconGlyph name="phone" />
            Contact
          </button>
          <button type="button" className="btn primary agent-detail-btn-solid" onClick={startChat}>
            <IconGlyph name="messages" />
            Chat
          </button>
        </div>
      </section>

      <section className="glass-card agent-detail-tabs-wrap">
        <div className="agent-detail-tabs">
          {['Overview', 'Reviews', 'Properties'].map((label, idx) => (
            <button
              key={label}
              type="button"
              className={`agent-detail-tab ${selectedTab === idx ? 'active' : ''}`}
              onClick={() => setSelectedTab(idx)}
            >
              {label}
            </button>
          ))}
        </div>

        {selectedTab === 0 && (
          <div className="agent-detail-tab-content">
            <div className="agent-detail-section">
              <h4>Licensed States</h4>
              <div className="agent-detail-pills">
                {licensedStates.length ? licensedStates.map((s) => <span key={s} className="agent-detail-pill agent-detail-pill--blue">{s}</span>) : <p>Not provided</p>}
              </div>
            </div>
            {serviceZipCodes.length > 0 && (
              <div className="agent-detail-section">
                <h4>Service Areas</h4>
                <div className="agent-detail-pills">
                  {serviceZipCodes.map((z) => <span key={z} className="agent-detail-pill agent-detail-pill--green">{z}</span>)}
                </div>
              </div>
            )}
            {claimedZipCodes.length > 0 && (
              <div className="agent-detail-section">
                <h4>Claimed ZIP Codes</h4>
                <div className="agent-detail-pills">
                  {claimedZipCodes.map((z) => <span key={z} className="agent-detail-pill agent-detail-pill--green">{z}</span>)}
                </div>
              </div>
            )}
            <div className="agent-detail-section">
              <h4>Contact Information</h4>
              <div className="agent-detail-contact-list">
                <div className="agent-detail-contact-item">
                  <IconGlyph name="email" />
                  <div>
                    <span className="label">Email</span>
                    <span className="value">{agent?.email || 'N/A'}</span>
                  </div>
                </div>
                {agent?.phone ? (
                  <div className="agent-detail-contact-item">
                    <IconGlyph name="phone" />
                    <div>
                      <span className="label">Phone</span>
                      <span className="value">{agent.phone}</span>
                    </div>
                  </div>
                ) : null}
                <div className="agent-detail-contact-item">
                  <IconGlyph name="profile" />
                  <div>
                    <span className="label">License Number</span>
                    <span className="value">{agent?.liscenceNumber || agent?.licenseNumber || 'N/A'}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {selectedTab === 1 && (
          <div className="agent-detail-tab-content">
            <h4>Reviews ({reviews.length})</h4>
            {reviews.length ? (
              <div className="agent-detail-reviews-list">
                {reviews.map((r, i) => (
                  <div key={r?.id || i} className="agent-detail-review-card">
                    <div className="agent-detail-review-header">
                      <span className="agent-detail-review-name">{r?.reviewerName || r?.name || r?.userName || 'Anonymous'}</span>
                      <span className="agent-detail-review-date">{r?.date ? new Date(r.date).toLocaleDateString() : ''}</span>
                    </div>
                    <div className="agent-detail-review-stars">
                      {[1, 2, 3, 4, 5].map((s) => (
                        <span key={s} className={`icon-glyph material-symbols-rounded ${s <= (r?.rating ?? 0) ? 'filled' : ''}`}>star</span>
                      ))}
                    </div>
                    <p className="agent-detail-review-comment">{r?.comment || r?.review || r?.text || ''}</p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="agent-detail-empty">No reviews yet.</p>
            )}
          </div>
        )}

        {selectedTab === 2 && (
          <div className="agent-detail-tab-content">
            <h4>Properties ({formattedProperties.length})</h4>
            {loadingProperties ? (
              <AnimatedLoader variant="card" label="Loading properties..." />
            ) : formattedProperties.length ? (
              <div className="agent-detail-properties-list">
                {formattedProperties.map((prop) => (
                  <div key={prop.id} className="agent-detail-property-card" onClick={() => viewProperty(prop)}>
                    <div className="agent-detail-property-media">
                      {prop.image ? (
                        <img src={prop.image} alt={prop.address} />
                      ) : (
                        <div className="agent-detail-property-media-fallback">
                          <IconGlyph name="home" filled />
                        </div>
                      )}
                    </div>
                    <div className="agent-detail-property-body">
                      <h5>{prop.address}</h5>
                      <p className="agent-detail-property-price">{prop.price}</p>
                      <p className="agent-detail-property-meta">
                        {prop.beds} beds • {prop.baths} baths • {prop.sqft} sqft
                      </p>
                      <span className={`agent-detail-property-status ${prop.isActive ? 'active' : ''}`}>{prop.status}</span>
                      <button type="button" className="btn primary btn-sm" onClick={(e) => { e.stopPropagation(); viewProperty(prop); }}>View Details</button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="agent-detail-empty-state">
                <IconGlyph name="home" filled />
                <p>No Properties Listed</p>
                <span>This agent hasn&apos;t listed any properties yet</span>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
