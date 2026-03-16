import { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import * as marketplaceApi from '../../api/marketplace';
import { firstImageFromEntity, resolveMediaUrl } from '../../lib/media';

export function LoanOfficerDetailPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const stateLO = location.state?.loanOfficer || null;
  const [loanOfficer, setLoanOfficer] = useState(stateLO);
  const [error, setError] = useState('');
  const [selectedTab, setSelectedTab] = useState(0);

  const loId = loanOfficer?._id || loanOfficer?.id || stateLO?._id || stateLO?.id;

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!loId) return;
      try {
        const res = await marketplaceApi.getLoanOfficerById(loId);
        if (!live) return;
        const full = res?.loanOfficer || res?.data || res || stateLO;
        setLoanOfficer(full);
      } catch (err) {
        if (!live) return;
        setLoanOfficer(stateLO);
      }
    };
    run();
    return () => { live = false; };
  }, [loId]);

  const profileImage = firstImageFromEntity(loanOfficer);
  const companyLogo = resolveMediaUrl(loanOfficer?.companyLogo || loanOfficer?.companyLogoUrl || '');
  const licensedStates = Array.isArray(loanOfficer?.licensedStates)
    ? loanOfficer.licensedStates
    : Array.isArray(loanOfficer?.LisencedStates)
      ? loanOfficer.LisencedStates
      : [];
  const claimedZipCodes = useMemo(() => {
    const fromClaimed = Array.isArray(loanOfficer?.claimedZipCodes)
      ? loanOfficer.claimedZipCodes.map((z) => (typeof z === 'string' ? z : (z?.zipCode || z?.postalCode || z?.zipcode || '')))
      : [];
    const fromZipCodes = Array.isArray(loanOfficer?.zipCodes)
      ? loanOfficer.zipCodes.map((z) => z?.zipCode || z?.postalCode || z?.zipcode || '').filter(Boolean)
      : [];
    return [...new Set([...fromClaimed, ...fromZipCodes])].filter(Boolean);
  }, [loanOfficer]);

  const reviews = useMemo(() => {
    const arr = loanOfficer?.reviews || loanOfficer?.platformReviews || [];
    return Array.isArray(arr) ? arr : [];
  }, [loanOfficer]);

  const programs = useMemo(() => {
    const arr = loanOfficer?.loanPrograms || loanOfficer?.specialtyProducts || loanOfficer?.areasOfExpertise || [];
    return Array.isArray(arr) ? arr : [];
  }, [loanOfficer]);

  const platformRating = loanOfficer?.platformRating ?? loanOfficer?.rating ?? loanOfficer?.ratings ?? 0;
  const platformReviewCount = loanOfficer?.platformReviewCount ?? loanOfficer?.reviewCount ?? reviews.length;
  const allowsRebates = Boolean(loanOfficer?.allowsRebates ?? loanOfficer?.rebateFriendly);

  const contactLO = () => {
    navigate('/buyer-lead-form', { state: { loanOfficer } });
  };

  const startChat = () => {
    navigate('/app/messages', { state: { openChatWith: loanOfficer } });
  };

  const applyMortgage = () => {
    const url = loanOfficer?.mortgageApplicationUrl || loanOfficer?.applicationUrl || '';
    if (url) {
      const href = url.startsWith('http') ? url : `https://${url}`;
      window.open(href, '_blank');
    }
  };

  if (error) {
    return (
      <div className="page-body">
        <PageHeader title="Loan Officer Profile" icon="accountBalance" />
        <p className="error-text">{error}</p>
      </div>
    );
  }

  if (!loanOfficer) {
    return (
      <div className="page-body">
        <PageHeader title="Loan Officer Profile" icon="accountBalance" />
        <AnimatedLoader variant="card" label="Loading loan officer..." />
      </div>
    );
  }

  const name = loanOfficer?.fullname || loanOfficer?.name || 'Loan Officer';
  const company = loanOfficer?.CompanyName || loanOfficer?.companyName || loanOfficer?.company || 'Mortgage professional';

  return (
    <div className="page-body">
      <PageHeader title="Loan Officer Profile" subtitle="Complete profile, reviews, and loan programs." icon="accountBalance" />

      <section className="glass-card loan-officer-detail-hero">
        <div className="loan-officer-detail-profile-row">
          <div className="loan-officer-detail-avatar-wrap">
            {profileImage ? (
              <img src={profileImage} alt={name} className="loan-officer-detail-avatar" />
            ) : (
              <div className="loan-officer-detail-avatar-fallback">
                <IconGlyph name="accountBalance" filled />
              </div>
            )}
          </div>
          <div className="loan-officer-detail-info">
            <h2 className="loan-officer-detail-name">{name}</h2>
            <p className="loan-officer-detail-company">{company}</p>
            <div className="loan-officer-detail-rating">
              <IconGlyph name="star" filled />
              <span>{platformRating} ({platformReviewCount} reviews)</span>
            </div>
          </div>
          {companyLogo ? (
            <div className="loan-officer-detail-logo-wrap">
              <img src={companyLogo} alt="Company" className="loan-officer-detail-logo" />
            </div>
          ) : null}
          {loanOfficer?.isVerified ? (
            <span className="loan-officer-detail-verified">
              <IconGlyph name="shield" filled />
              Verified
            </span>
          ) : null}
        </div>

        {loanOfficer?.bio ? (
          <div className="loan-officer-detail-bio">
            <p>{loanOfficer.bio}</p>
          </div>
        ) : null}

        {allowsRebates && (
          <div className="loan-officer-detail-rebate-badge">
            <IconGlyph name="checkCircle" filled />
            <div>
              <strong>Rebate-Friendly Lender Verified</strong>
              <p>This loan officer has confirmed their lender allows real estate commission rebates to be credited to buyers at closing, appearing directly on the Closing Disclosure or Settlement Statement.</p>
            </div>
          </div>
        )}

        <div className="loan-officer-detail-reviews-section">
          <h4><IconGlyph name="shield" filled /> Get a Rebate Reviews</h4>
          {platformReviewCount > 0 ? (
            <>
              <div className="loan-officer-detail-platform-rating">
                {[1, 2, 3, 4, 5].map((i) => (
                  <span key={i} className={`icon-glyph material-symbols-rounded ${i <= Math.round(platformRating) ? 'filled' : ''}`}>star</span>
                ))}
                <span>{platformRating} ({platformReviewCount} {platformReviewCount === 1 ? 'review' : 'reviews'})</span>
              </div>
              <p className="loan-officer-detail-reviews-sub">From verified closed transactions on Get a Rebate</p>
            </>
          ) : (
            <p>No reviews yet from Get a Rebate transactions. Reviews will appear here after closing transactions through Get a Rebate.</p>
          )}
        </div>

        {(loanOfficer?.mortgageApplicationUrl || loanOfficer?.applicationUrl) ? (
          <button type="button" className="btn primary loan-officer-detail-apply-btn" onClick={applyMortgage}>
            <IconGlyph name="link" />
            Apply for a Mortgage
          </button>
        ) : null}

        <div className="loan-officer-detail-actions">
          <button type="button" className="btn primary loan-officer-detail-btn-solid" onClick={contactLO}>
            <IconGlyph name="phone" />
            Contact
          </button>
          <button type="button" className="btn loan-officer-detail-btn-outline" onClick={startChat}>
            <IconGlyph name="messages" />
            Chat
          </button>
        </div>
      </section>

      <section className="glass-card loan-officer-detail-tabs-wrap">
        <div className="loan-officer-detail-tabs">
          {['Overview', 'Reviews', 'Loan Programs'].map((label, idx) => (
            <button
              key={label}
              type="button"
              className={`loan-officer-detail-tab ${selectedTab === idx ? 'active' : ''}`}
              onClick={() => setSelectedTab(idx)}
            >
              {label}
            </button>
          ))}
        </div>

        {selectedTab === 0 && (
          <div className="loan-officer-detail-tab-content">
            <div className="loan-officer-detail-section">
              <h4>Licensed States</h4>
              <div className="loan-officer-detail-pills">
                {licensedStates.length ? licensedStates.map((s) => <span key={s} className="loan-officer-detail-pill">{s}</span>) : <p>Not provided</p>}
              </div>
            </div>
            <div className="loan-officer-detail-section">
              <h4>Claimed ZIP Codes</h4>
              <div className="loan-officer-detail-pills">
                {claimedZipCodes.length ? claimedZipCodes.map((z) => <span key={z} className="loan-officer-detail-pill loan-officer-detail-pill--blue">{z}</span>) : <p>No claimed ZIP codes available.</p>}
              </div>
            </div>
            <div className="loan-officer-detail-section">
              <h4>Contact Information</h4>
              <div className="loan-officer-detail-contact-list">
                <div className="loan-officer-detail-contact-item">
                  <IconGlyph name="email" />
                  <div>
                    <span className="label">Email</span>
                    <span className="value">{loanOfficer?.email || 'N/A'}</span>
                  </div>
                </div>
                {loanOfficer?.phone ? (
                  <div className="loan-officer-detail-contact-item">
                    <IconGlyph name="phone" />
                    <div>
                      <span className="label">Phone</span>
                      <span className="value">{loanOfficer.phone}</span>
                    </div>
                  </div>
                ) : null}
                <div className="loan-officer-detail-contact-item">
                  <IconGlyph name="profile" />
                  <div>
                    <span className="label">License Number</span>
                    <span className="value">{loanOfficer?.liscenceNumber || loanOfficer?.licenseNumber || 'N/A'}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {selectedTab === 1 && (
          <div className="loan-officer-detail-tab-content">
            <h4>Reviews ({reviews.length})</h4>
            {reviews.length ? (
              <div className="loan-officer-detail-reviews-list">
                {reviews.map((r, i) => (
                  <div key={r?.id || i} className="loan-officer-detail-review-card">
                    <div className="loan-officer-detail-review-header">
                      <span className="loan-officer-detail-review-name">{r?.reviewerName || r?.name || r?.userName || 'Anonymous'}</span>
                      <span className="loan-officer-detail-review-date">{r?.date ? new Date(r.date).toLocaleDateString() : ''}</span>
                    </div>
                    <div className="loan-officer-detail-review-stars">
                      {[1, 2, 3, 4, 5].map((s) => (
                        <span key={s} className={`icon-glyph material-symbols-rounded ${s <= (r?.rating ?? 0) ? 'filled' : ''}`}>star</span>
                      ))}
                    </div>
                    <p className="loan-officer-detail-review-comment">{r?.comment || r?.review || r?.text || ''}</p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="loan-officer-detail-empty">No reviews yet.</p>
            )}
          </div>
        )}

        {selectedTab === 2 && (
          <div className="loan-officer-detail-tab-content">
            <h4>Areas of Expertise & Specialty Products</h4>
            {programs.length ? (
              <div className="loan-officer-detail-programs-list">
                {programs.map((prog, i) => (
                  <div key={prog?.id || i} className="loan-officer-detail-program-card">
                    <h5>{typeof prog === 'string' ? prog : (prog?.name || prog?.title || 'Program')}</h5>
                    {prog?.description ? <p>{prog.description}</p> : null}
                  </div>
                ))}
              </div>
            ) : (
              <div className="loan-officer-detail-empty-state">
                <IconGlyph name="info" filled />
                <p>No specialty products specified</p>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
