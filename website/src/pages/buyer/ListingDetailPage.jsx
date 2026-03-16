import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapObject } from '../../lib/api';
import { allImagesFromEntity, firstImageFromEntity } from '../../lib/media';
import { calculateRebateRange, isRebateRestricted, REBATE_WORDING } from '../../lib/rebate';
import * as marketplaceApi from '../../api/marketplace';
import * as leadsApi from '../../api/leads';
import * as userApi from '../../api/user';
import { useToast } from '../../components/ui/ToastProvider';

function toPrice(listing) {
  const p = listing?.price ?? (listing?.priceCents ? listing.priceCents / 100 : 0);
  return Number(p) || 0;
}

function toBac(listing) {
  const b = listing?.BACPercentage ?? listing?.bacPercent ?? listing?.bac ?? 2.5;
  return Number(b) || 2.5;
}

function formatAddress(listing) {
  if (typeof listing?.address === 'string') return listing.address;
  const addr = listing?.address;
  if (addr?.street && addr?.city) {
    return `${addr.street}, ${addr.city}, ${addr.state || ''} ${addr.zip || ''}`.trim();
  }
  return [listing?.streetAddress, listing?.city, listing?.state, listing?.zipCode].filter(Boolean).join(', ') || 'Address not provided';
}

function getState(listing) {
  const addr = listing?.address;
  if (addr?.state) return addr.state;
  return listing?.state || '';
}

export function ListingDetailPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, role } = useAuth();
  const userId = resolveUserId(user);
  const listing = location.state?.listing || null;
  const openHouse = location.state?.openHouse || null;
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [status, setStatus] = useState('');
  const [contactAgentOpen, setContactAgentOpen] = useState(false);
  const [contactAgentData, setContactAgentData] = useState({ agent: null, loading: true, error: '' });
  const [listingAgent, setListingAgent] = useState(null);
  const { showToast } = useToast();

  const agentId = listing?.agentId || listing?.createdBy || listing?.userId
    || listing?.agent?._id || listing?.agent?.id
    || listing?.listingAgentId;

  const images = allImagesFromEntity(listing);
  const listingId = listing?.listingId || listing?._id || listing?.id;

  useEffect(() => {
    if (listingId) marketplaceApi.addListingView(listingId).catch(() => {});
  }, [listingId]);

  useEffect(() => {
    if (!agentId) {
      if (listing?.agent && typeof listing.agent === 'object') setListingAgent(listing.agent);
      else setListingAgent(null);
      return;
    }
    if (listing?.agent && typeof listing.agent === 'object') {
      setListingAgent(listing.agent);
      return;
    }
    let live = true;
    userApi.getUserById(agentId)
      .then((res) => {
        if (!live) return;
        const full = unwrapObject(res, ['user']) || res;
        setListingAgent(full);
      })
      .catch(() => { if (live) setListingAgent(null); });
    return () => { live = false; };
  }, [agentId, listing?.agent]);

  useEffect(() => {
    if (!contactAgentOpen) return;
    if (listingAgent) {
      setContactAgentData({ agent: listingAgent, loading: false, error: '' });
      return;
    }
    if (listing?.agent && typeof listing.agent === 'object') {
      setContactAgentData({ agent: listing.agent, loading: false, error: '' });
      return;
    }
    if (!agentId) {
      setContactAgentData({ agent: null, loading: false, error: 'Agent information not available for this listing.' });
      return;
    }
    setContactAgentData({ agent: null, loading: true, error: '' });
    let live = true;
    userApi.getUserById(agentId)
      .then((res) => {
        if (!live) return;
        const full = unwrapObject(res, ['user']) || res;
        setContactAgentData({ agent: full, loading: false, error: '' });
      })
      .catch((err) => {
        if (!live) return;
        setContactAgentData({ agent: null, loading: false, error: err?.message || 'Could not load agent.' });
      });
    return () => { live = false; };
  }, [contactAgentOpen, agentId, listing?.agent, listingAgent]);

  const price = toPrice(listing);
  const bacPercent = toBac(listing);
  const dualAgencyAllowed = Boolean(listing?.dualAgencyAllowed);
  const dualAgencyCommissionPercent = listing?.dualAgencyCommissionPercent != null ? listing.dualAgencyCommissionPercent / 100 : null;

  const rebateRange = listing
    ? calculateRebateRange({
        listPrice: price,
        bacPercentage: bacPercent,
        allowsDualAgency: dualAgencyAllowed,
        dualAgencyCommissionPercent,
      })
    : null;

  const restricted = isRebateRestricted(getState(listing));
  const address = formatAddress(listing);

  const openHouses = openHouse ? [openHouse] : (Array.isArray(listing?.openHouses) ? listing.openHouses : []);

  const openContactAgentDialog = () => {
    if (!agentId) {
      showToast({ type: 'error', message: 'Listing agent information not available.' });
      return;
    }
    marketplaceApi.addListingContact(listingId).catch(() => {});
    setContactAgentOpen(true);
  };

  const createLead = () => {
    const agent = listingAgent || (agentId ? { _id: agentId, id: agentId } : null);
    navigate('/buyer-lead-form', { state: { listing, agent, propertyAddress: address } });
  };

  const saveListing = async () => {
    if (!userId) {
      showToast({ type: 'error', message: 'Please sign in to save listings' });
      return;
    }
    if (!listingId) return;
    setStatus('Saving...');
    try {
      await marketplaceApi.likeListing({ userId, listingId, listing });
      setStatus('');
      showToast({ type: 'success', message: 'Listing saved to favorites.' });
    } catch (err) {
      const msg = err.message || 'Unable to save listing.';
      setStatus(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  const findAgents = () => {
    const zip = listing?.zipCode || listing?.address?.zip || listing?.address?.zipCode || '';
    navigate('/app/find-agents', { state: { prefillZip: zip || undefined, zip, fromListing: listing } });
  };

  if (!listing) {
    return (
      <div className="page-body">
        <PageHeader title="Listing Detail" icon="home" />
        <div className="listing-detail-empty">
          <IconGlyph name="home" filled />
          <p>Listing not found</p>
        </div>
      </div>
    );
  }

  return (
    <div className="page-body">
      <PageHeader title="Listing Detail" subtitle="Property details, rebate estimate, and contact options." icon="listings" />

      <section className="listing-detail-hero">
        <div className="listing-detail-carousel-wrap">
          {images.length > 0 ? (
            <>
              <div className="listing-detail-carousel">
                {images.map((img, i) => (
                  <div
                    key={`${img}-${i}`}
                    className="listing-detail-slide"
                    style={{
                      backgroundImage: `url(${img})`,
                      transform: `translateX(${(i - currentImageIndex) * 100}%)`,
                    }}
                  />
                ))}
              </div>
              {images.length > 1 && (
                <>
                  <div className="listing-detail-carousel-dots">
                    {images.map((_, i) => (
                      <button
                        key={i}
                        type="button"
                        className={`listing-detail-dot ${i === currentImageIndex ? 'active' : ''}`}
                        onClick={() => setCurrentImageIndex(i)}
                        aria-label={`Image ${i + 1}`}
                      />
                    ))}
                  </div>
                  <div className="listing-detail-carousel-counter">
                    {currentImageIndex + 1} / {images.length}
                  </div>
                </>
              )}
            </>
          ) : (
            <div className="listing-detail-carousel-fallback">
              <IconGlyph name="home" filled />
              <span>No images</span>
            </div>
          )}
        </div>
      </section>

      <section className="listing-detail-content">
        <div className="listing-detail-price-section">
          <h2 className="listing-detail-price">
            {price ? `$${price.toLocaleString()}` : 'Price on request'}
          </h2>
          <div className="listing-detail-address">
            <IconGlyph name="location" />
            <span>{address}</span>
          </div>
          <div className="listing-detail-tags">
            <span className={`listing-detail-tag ${dualAgencyAllowed ? 'dual' : ''}`}>
              <IconGlyph name="shield" />
              {dualAgencyAllowed ? 'Dual Agency Allowed' : 'No Dual Agency'}
            </span>
          </div>
        </div>

        {restricted && (
          <div className="listing-detail-restricted-notice">
            <IconGlyph name="info" filled />
            <div>
              <strong>Rebates Not Permitted in {getState(listing)}</strong>
              <p>{REBATE_WORDING.restrictedStateNotice}</p>
            </div>
          </div>
        )}

        <div className="listing-detail-rebate-notice">
          <IconGlyph name="info" filled />
          <span>
            {restricted ? 'Estimated Rebate Range (for reference — not applicable in this state)' : 'Estimated Rebate Range'}
          </span>
        </div>
        <p className="listing-detail-rebate-disclaimer">{REBATE_WORDING.estimatedRebateRangeNotice}</p>

        {rebateRange && (
          <div className={`listing-detail-rebate-cards ${rebateRange.hasDualAgencyOption ? 'dual' : ''}`}>
            <div className="listing-detail-rebate-card">
              <h4>When you work with an Agent from this site</h4>
              <p className="listing-detail-rebate-amount">{rebateRange.standardRebateRangeText}</p>
              <p className="listing-detail-rebate-sub">{REBATE_WORDING.standardRebateSubtitle}</p>
            </div>
            {rebateRange.hasDualAgencyOption && (
              <div className="listing-detail-rebate-card listing-detail-rebate-card--dual">
                <h4>With The Listing Agent</h4>
                <p className="listing-detail-rebate-amount">{rebateRange.dualAgencyRebateRangeText}</p>
                <p className="listing-detail-rebate-sub">{REBATE_WORDING.dualAgencyRebateSubtitle}</p>
              </div>
            )}
          </div>
        )}

        <div className="listing-detail-important-notice">
          <IconGlyph name="info" filled />
          <div>
            <strong>Important Notice</strong>
            <p>{REBATE_WORDING.importantNotice}</p>
          </div>
        </div>

        <div className="listing-detail-pros-cons">
          <h4>Working with a Buyer&apos;s Agent vs. Listing Agent</h4>
          <div className="listing-detail-pros-cons-grid">
            <div className="listing-detail-pros-card">
              <h5>Buyer&apos;s Agent</h5>
              <ul>
                <li>Represents your interests exclusively</li>
                <li>Negotiates on your behalf</li>
                <li>Can help you secure a rebate</li>
                <li>Full representation throughout the transaction</li>
              </ul>
            </div>
            <div className="listing-detail-cons-card">
              <h5>Listing Agent Only</h5>
              <ul>
                <li>Represents the seller, not you</li>
                <li>No dedicated advocacy for your interests</li>
                <li>Rebate may be limited or unavailable</li>
                <li>Potential conflict of interest</li>
              </ul>
            </div>
          </div>
        </div>

        {openHouses.length > 0 && (
          <div className="listing-detail-openhouse-section">
            <h4><IconGlyph name="event" filled /> Open House{openHouses.length > 1 ? 's' : ''}</h4>
            {openHouses.map((oh, i) => {
              const dateVal = oh?.startTime || oh?.startDateTime || oh?.date;
              const fromVal = oh?.fromTime || (oh?.startTime ? new Date(oh.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null);
              const toVal = oh?.toTime || (oh?.endTime ? new Date(oh.endTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null);
              return (
                <div key={oh?._id || oh?.id || i} className="listing-detail-openhouse-item">
                  <p><strong>Date:</strong> {dateVal ? new Date(dateVal).toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' }) : 'N/A'}</p>
                  <p><strong>Time:</strong> {fromVal || 'TBA'}{toVal ? ` – ${toVal}` : ''}</p>
                  {oh?.notes ? <p><strong>Notes:</strong> {oh.notes}</p> : null}
                </div>
              );
            })}
          </div>
        )}

        <div className="listing-detail-meta">
          <p>{listing?.propertyTitle || listing?.description || 'Property details'}</p>
          {[listing?.beds || listing?.bedrooms, listing?.baths || listing?.bathrooms, listing?.sqft || listing?.squareFeet].filter(Boolean).length > 0 && (
            <p className="listing-detail-meta-row">
              {[listing?.beds || listing?.bedrooms ? `${listing?.beds || listing?.bedrooms} Beds` : null, listing?.baths || listing?.bathrooms ? `${listing?.baths || listing?.bathrooms} Baths` : null, listing?.sqft || listing?.squareFeet ? `${listing?.sqft || listing?.squareFeet} sqft` : null].filter(Boolean).join(' • ')}
            </p>
          )}
        </div>

        {listingAgent && agentId && (
          <div className="listing-detail-agent-card">
            <h4><IconGlyph name="person" filled /> Listing Agent</h4>
            <div className="listing-detail-agent-preview">
              {firstImageFromEntity(listingAgent) ? (
                <img src={firstImageFromEntity(listingAgent)} alt="" className="listing-detail-agent-avatar" />
              ) : (
                <div className="listing-detail-agent-avatar-fallback">
                  <IconGlyph name="person" filled />
                </div>
              )}
              <div className="listing-detail-agent-info">
                <strong>{listingAgent?.fullname || listingAgent?.name || 'Agent'}</strong>
                <span>{listingAgent?.CompanyName || listingAgent?.companyName || listingAgent?.brokerage || ''}</span>
              </div>
              <button type="button" className="btn primary" onClick={openContactAgentDialog}>
                <IconGlyph name="phone" />
                Contact Listing Agent
              </button>
            </div>
          </div>
        )}

        <div className="listing-detail-actions">
          <button type="button" className="btn primary listing-detail-btn-primary" onClick={findAgents}>
            <IconGlyph name="search" />
            Find Agents Near This Property
          </button>
          {role === 'buyerSeller' && (
            <>
              <button type="button" className="btn primary" onClick={createLead}>
                <IconGlyph name="profile" />
                I am interested in this property
              </button>
              {(!listingAgent && agentId) ? (
                <button type="button" className="btn ghost listing-detail-btn-secondary" onClick={openContactAgentDialog}>
                  <IconGlyph name="phone" />
                  Contact Listing Agent
                </button>
              ) : null}
              <button type="button" className="btn ghost" onClick={saveListing}>
                <IconGlyph name="heart" />
                Save Listing
              </button>
            </>
          )}
        </div>
        {status ? <p className="listing-detail-status">{status}</p> : null}

        {contactAgentOpen && (
          <div className="modal-overlay" onClick={() => setContactAgentOpen(false)} role="dialog" aria-modal="true">
            <div className="modal-dialog glass-card" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Listing Agent</h3>
                <button type="button" className="btn ghost tiny" onClick={() => setContactAgentOpen(false)} aria-label="Close">
                  <span className="icon-glyph material-symbols-rounded">close</span>
                </button>
              </div>
              <div className="modal-body">
                {contactAgentData.loading ? (
                  <AnimatedLoader variant="card" label="Loading agent details..." />
                ) : contactAgentData.error ? (
                  <p className="error-text">{contactAgentData.error}</p>
                ) : !contactAgentData.agent ? (
                  <p>Agent information not available.</p>
                ) : (
                  (() => {
                    const a = contactAgentData.agent;
                    const name = a?.fullname || a?.name || 'Agent';
                    const brokerage = a?.CompanyName || a?.companyName || a?.brokerage || '';
                    const profileImg = firstImageFromEntity(a);
                    const rating = a?.platformRating ?? a?.rating ?? a?.ratings ?? 0;
                    const reviewCount = a?.platformReviewCount ?? a?.reviewCount ?? 0;
                    const phone = a?.phone || '';
                    const email = a?.email || '';
                    const licenseNum = a?.liscenceNumber || a?.licenseNumber || '';
                    const website = a?.websiteUrl || a?.website_link || '';
                    const licensedStates = Array.isArray(a?.licensedStates) ? a.licensedStates : [];
                    return (
                      <div className="contact-agent-dialog">
                        <div className="contact-agent-header">
                          {profileImg ? (
                            <img src={profileImg} alt={name} className="contact-agent-avatar" />
                          ) : (
                            <div className="contact-agent-avatar-fallback">
                              <IconGlyph name="person" filled />
                            </div>
                          )}
                          <div className="contact-agent-info">
                            <h4>{name}</h4>
                            {brokerage ? <p className="contact-agent-brokerage">{brokerage}</p> : null}
                            {reviewCount > 0 && (
                              <div className="contact-agent-rating">
                                <IconGlyph name="star" filled />
                                <span>{rating} ({reviewCount} reviews)</span>
                              </div>
                            )}
                          </div>
                        </div>
                        {a?.bio ? (
                          <div className="contact-agent-bio">
                            <h5>About</h5>
                            <p>{a.bio}</p>
                          </div>
                        ) : null}
                        <div className="contact-agent-details">
                          <h5>Contact Information</h5>
                          {phone ? (
                            <div className="contact-agent-row">
                              <IconGlyph name="phone" />
                              <a href={`tel:${phone.replace(/\D/g, '')}`}>{phone}</a>
                            </div>
                          ) : null}
                          <div className="contact-agent-row">
                            <IconGlyph name="email" />
                            <a href={email ? `mailto:${email}?subject=Inquiry about Property Listing` : '#'}>{email || 'N/A'}</a>
                          </div>
                          {licenseNum ? (
                            <div className="contact-agent-row">
                              <IconGlyph name="profile" />
                              <span>License: {licenseNum}</span>
                            </div>
                          ) : null}
                          {licensedStates.length > 0 ? (
                            <div className="contact-agent-row">
                              <IconGlyph name="location" />
                              <span>Licensed: {licensedStates.join(', ')}</span>
                            </div>
                          ) : null}
                          {website ? (
                            <div className="contact-agent-row">
                              <IconGlyph name="info" />
                              <a href={website.startsWith('http') ? website : `https://${website}`} target="_blank" rel="noreferrer">Website</a>
                            </div>
                          ) : null}
                        </div>
                        <div className="contact-agent-actions">
                          <button type="button" className="btn ghost" onClick={() => { setContactAgentOpen(false); navigate('/agent-detail', { state: { agent: a } }); }}>
                            <IconGlyph name="person" />
                            View Profile
                          </button>
                          <button type="button" className="btn primary" onClick={() => { setContactAgentOpen(false); navigate('/app/messages', { state: { openChatWith: a } }); }}>
                            <IconGlyph name="messages" />
                            Send Message
                          </button>
                        </div>
                      </div>
                    );
                  })()
                )}
              </div>
            </div>
          </div>
        )}
      </section>
    </div>
  );
}
