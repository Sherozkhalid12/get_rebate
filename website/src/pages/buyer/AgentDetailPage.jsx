import { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import * as userApi from '../../api/user';
import { unwrapObject } from '../../lib/api';
import { firstImageFromEntity, resolveMediaUrl } from '../../lib/media';

export function AgentDetailPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const stateAgent = location.state?.agent || null;
  const [agent, setAgent] = useState(stateAgent);
  const [error, setError] = useState('');

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
    return () => {
      live = false;
    };
  }, [agentId]);

  const profileImage = firstImageFromEntity(agent);
  const companyLogo = resolveMediaUrl(agent?.companyLogo || agent?.companyLogoUrl || '');
  const licensedStates = Array.isArray(agent?.licensedStates)
    ? agent.licensedStates
    : Array.isArray(agent?.LisencedStates)
      ? agent.LisencedStates
      : [];

  const expertise = useMemo(() => {
    if (Array.isArray(agent?.areasOfExpertise)) return agent.areasOfExpertise;
    if (Array.isArray(agent?.expertise)) return agent.expertise;
    return [];
  }, [agent]);

  return (
    <div className="page-body">
      <PageHeader title="Agent Details" subtitle="Complete profile information as shown in the app." icon="profile" />
      {error ? <p className="error-text">{error}</p> : null}

      <section className="glass-card panel detail-hero">
        <div className="detail-image-wrap">
          {profileImage ? (
            <img src={profileImage} alt="Agent" className="detail-image" />
          ) : (
            <div className="detail-image-fallback">No Image</div>
          )}
        </div>
        <div className="detail-content">
          <h3>{agent?.fullname || agent?.name || 'Agent'}</h3>
          <p>{agent?.CompanyName || agent?.companyName || agent?.brokerage || 'Brokerage not provided'}</p>
          <p>
            Rating: {agent?.rating || agent?.ratings || 0} ({agent?.reviewCount || (Array.isArray(agent?.reviews) ? agent.reviews.length : 0)} reviews)
          </p>
          <p>License: {agent?.liscenceNumber || agent?.licenseNumber || 'N/A'}</p>
          <p>Phone: {agent?.phone || 'N/A'}</p>
          <p>Email: {agent?.email || 'N/A'}</p>
        </div>
      </section>

      <section className="glass-card panel detail-grid">
        <article>
          <h3>Bio</h3>
          <p>{agent?.bio || 'No bio added yet.'}</p>
        </article>
        <article>
          <h3>Licensed States</h3>
          <p>{licensedStates.length ? licensedStates.join(', ') : 'Not provided'}</p>
        </article>
        <article>
          <h3>Service Areas</h3>
          <p>{Array.isArray(agent?.serviceAreas) && agent.serviceAreas.length ? agent.serviceAreas.join(', ') : 'Not provided'}</p>
        </article>
        <article>
          <h3>Expertise</h3>
          <p>{expertise.length ? expertise.join(', ') : 'Not provided'}</p>
        </article>
        <article>
          <h3>Dual Agency</h3>
          <p>State: {String(Boolean(agent?.isDualAgencyAllowedInState))}</p>
          <p>Brokerage: {String(Boolean(agent?.isDualAgencyAllowedAtBrokerage))}</p>
        </article>
        <article>
          <h3>Links</h3>
          {agent?.website_link || agent?.websiteUrl ? <p><a href={agent.website_link || agent.websiteUrl} target="_blank" rel="noreferrer">Website</a></p> : <p>Website: N/A</p>}
          {agent?.google_reviews_link || agent?.googleReviewsUrl ? <p><a href={agent.google_reviews_link || agent.googleReviewsUrl} target="_blank" rel="noreferrer">Google Reviews</a></p> : <p>Google reviews: N/A</p>}
          {agent?.thirdPartReviewLink || agent?.thirdPartyReviewsUrl ? <p><a href={agent.thirdPartReviewLink || agent.thirdPartyReviewsUrl} target="_blank" rel="noreferrer">External Reviews</a></p> : <p>External reviews: N/A</p>}
        </article>
      </section>

      {companyLogo ? (
        <section className="glass-card panel">
          <h3>Company Logo</h3>
          <div className="detail-logo-wrap">
            <img src={companyLogo} alt="Company Logo" className="detail-logo" />
          </div>
        </section>
      ) : null}

      <section className="row">
        <button
          className="btn primary"
          type="button"
          onClick={() => navigate('/buyer-lead-form', { state: { agent } })}
        >
          Contact Agent
        </button>
      </section>
    </div>
  );
}
