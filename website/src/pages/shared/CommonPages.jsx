import { useMemo, useState, useEffect } from 'react';
import { useLocation, Link } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject } from '../../lib/api';
import { allImagesFromEntity } from '../../lib/media';
import * as notificationApi from '../../api/notifications';
import * as proposalApi from '../../api/proposals';
import * as leadsApi from '../../api/leads';
import * as rebateApi from '../../api/rebate';
import * as marketplaceApi from '../../api/marketplace';
import * as loansApi from '../../api/loans';
import * as userApi from '../../api/user';
import * as zipApi from '../../api/zipcodes';
import { useToast } from '../../components/ui/ToastProvider';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { StateSelect, parseLicensedStates } from '../../components/ui/StateSelect';

const LISTING_INITIAL_FORM = {
  propertyTitle: '',
  description: '',
  price: '',
  streetAddress: '',
  city: '',
  state: '',
  zipCode: '',
  BACPercentage: '2.5',
  listingAgent: '', // '' = not selected, 'true'/'false' = selected (required like app)
  dualAgencyAllowed: 'false',
  status: 'active',
  propertyType: 'house',
  bedrooms: '',
  bathrooms: '',
  squareFeet: '',
  propertyFeatures: '',
  openHouses: [],
};

function buildListingPayload(form, userId) {
  const numericBac = Number.parseFloat(form.BACPercentage);
  const safeBac = Number.isFinite(numericBac) ? numericBac : 2.5;
  const propertyDetails = {
    type: form.propertyType || 'house',
    status: form.status || 'active',
    ...(form.squareFeet ? { squareFeet: form.squareFeet } : {}),
    ...(form.bedrooms ? { bedrooms: form.bedrooms } : {}),
    ...(form.bathrooms ? { bathrooms: form.bathrooms } : {}),
  };
  const features = String(form.propertyFeatures || '')
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean);

  return {
    propertyTitle: form.propertyTitle.trim(),
    description: form.description.trim(),
    price: form.price,
    BACPercentage: String(safeBac),
    listingAgent: String(form.listingAgent === 'true'),
    dualAgencyAllowed: String(form.dualAgencyAllowed === 'true'),
    streetAddress: form.streetAddress.trim(),
    city: form.city.trim(),
    state: form.state.trim(),
    zipCode: form.zipCode.trim(),
    id: userId,
    status: form.status || 'active',
    createdByRole: 'agent',
    propertyDetails,
    propertyFeatures: features,
    openHouses: [],
  };
}

function buildListingFormData(form, userId, photos) {
  const numericBac = Number.parseFloat(form.BACPercentage);
  const safeBac = Number.isFinite(numericBac) ? numericBac : 2.5;
  const fd = new FormData();

  fd.append('propertyTitle', (form.propertyTitle || '').trim());
  fd.append('description', (form.description || '').trim());
  fd.append('price', String(form.price || '').trim());
  fd.append('BACPercentage', String(safeBac));
  const isListingAgent = form.listingAgent === 'true';
  fd.append('listingAgent', String(isListingAgent));
  fd.append('dualAgencyAllowed', String(isListingAgent && form.dualAgencyAllowed === 'true'));
  fd.append('streetAddress', (form.streetAddress || '').trim());
  fd.append('city', (form.city || '').trim());
  fd.append('state', (form.state || '').trim());
  fd.append('zipCode', (form.zipCode || '').trim());
  fd.append('id', String(userId || ''));
  fd.append('status', form.status || 'active');
  fd.append('createdByRole', 'agent');

  const propertyDetails = {
    type: form.propertyType || 'house',
    status: form.status || 'active',
    ...(form.squareFeet ? { squareFeet: String(form.squareFeet).trim() } : {}),
    ...(form.bedrooms ? { bedrooms: String(form.bedrooms).trim() } : {}),
    ...(form.bathrooms ? { bathrooms: String(form.bathrooms).trim() } : {}),
  };
  fd.append('propertyDetails', JSON.stringify(propertyDetails));

  const features = String(form.propertyFeatures || '')
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean);
  fd.append('propertyFeatures', JSON.stringify(features));

  const openHousesPayload = (form.openHouses || []).map((oh) => ({
    date: oh.date,
    fromTime: oh.fromTime || '10:00 AM',
    toTime: oh.toTime || '2:00 PM',
    ...(oh.notes ? { specialNote: oh.notes } : {}),
  }));
  fd.append('openHouses', JSON.stringify(openHousesPayload));

  (photos || []).slice(0, 10).forEach((file) => {
    if (file) {
      fd.append('propertyPhotos', file);
    }
  });

  return fd;
}

export function NotificationsPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const { showToast } = useToast();

  const loadLive = async () => {
    if (!userId) return;
    setError('');
    try {
      const data = await notificationApi.getNotifications(userId);
      const parsed = unwrapList(data, ['notifications', 'data']).map((item) => ({
        id: item._id || item.id,
        title: item.title || 'Notification',
        text: item.message || item.body || '',
        time: item.createdAt ? new Date(item.createdAt).toLocaleString() : 'now',
      }));
      setRows(parsed);
    } catch (err) {
      const msg = err.message || 'Unable to load notifications.';
      setError(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  useEffect(() => {
    loadLive();
  }, [userId]);

  return (
    <div className="page-body">
      <PageHeader
        title="Notifications"
        subtitle="Live system updates for leads, proposals, and messages."
        icon="bell"
        actions={<button className="btn tiny" onClick={loadLive} type="button">Refresh</button>}
      />
      {error ? <p className="error-text">{error}</p> : null}
      <section className="glass-card panel">
        {rows.map((n) => (
          <div className="list-row" key={n.id}>
            <div>
              <strong>{n.title}</strong>
              <p>{n.text}</p>
            </div>
            <small>{n.time}</small>
          </div>
        ))}
      </section>
    </div>
  );
}

export function ProposalsPage() {
  const { user, role } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      setError('');
      try {
        const response = role === 'buyerSeller'
          ? await proposalApi.getUserProposals(userId)
          : await proposalApi.getProfessionalProposals(userId);

        if (!live) return;

        const proposals = unwrapList(response, ['proposals', 'data']);
        setRows(proposals.map((row) => ({
          id: row._id || row.id,
          professional: row.professionalName || row.userName || 'Proposal',
          status: row.status || 'pending',
          type: row.professionalType || row.type || 'service',
          updatedAt: row.updatedAt ? new Date(row.updatedAt).toLocaleDateString() : 'Today',
        })));
      } catch (err) {
        if (!live) return;
        setError(err.message || 'Unable to load proposals.');
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId, role]);

  return (
    <div className="page-body">
      <PageHeader title="Proposals" subtitle="Track pending, in-progress, completed, and reported services." icon="leads" />
      {error ? <p className="error-text">{error}</p> : null}
      <section className="glass-card panel">
        {rows.map((row) => (
          <div className="list-row" key={row.id}>
            <div>
              <strong>{row.professional}</strong>
              <p>{row.type} • Updated {row.updatedAt}</p>
            </div>
            <span className={`status ${String(row.status).toLowerCase().replace(' ', '-')}`}>{row.status}</span>
          </div>
        ))}
      </section>
    </div>
  );
}

export function LeadDetailPage() {
  const { user, role } = useAuth();
  const location = useLocation();
  const lead = location.state?.lead || null;
  const userId = resolveUserId(user);
  const [status, setStatus] = useState('');

  const act = async (action) => {
    const leadId = lead?._id || lead?.id;
    if (!leadId || !userId) return;
    setStatus('Updating lead...');
    try {
      if (action === 'complete') {
        await leadsApi.markLeadComplete(leadId, { userId, role });
      } else {
        await leadsApi.respondToLead(leadId, { agentId: userId, action, role });
      }
      setStatus(`Lead ${action} action sent.`);
    } catch (err) {
      setStatus(err.message || 'Lead action failed.');
    }
  };

  if (!lead) {
    return (
      <div className="page-body">
        <PageHeader title="Lead Detail" subtitle="Lead not found." icon="profile" />
        <section className="glass-card panel">
          <p>No lead details loaded.</p>
        </section>
      </div>
    );
  }

  const fullName = lead.fullName || lead.fullname || lead.name || 'Lead';
  const email = lead.email || '';
  const phone = lead.phone || '';
  const leadType = lead.leadType || 'Lead';
  const statusLabel = lead.leadStatus || lead.status || 'pending';
  const priceRange = lead.priceRange || lead.budgetRange || lead.budget || '';
  const timeframe = lead.timeFrame || lead.timeline || lead.timeframe || '';
  const preferredContact = lead.preferredContact || '';
  const property = lead.propertyInformation || {};
  const propertyAddress =
    property.propertyAddress ||
    property.address ||
    [property.streetAddress, property.city, property.zipCode].filter(Boolean).join(', ');
  const propertyCity = property.city || '';
  const propertyZip = property.zipCode || '';
  const propertyType = lead.propertyType || property.propertyType || '';
  const beds = lead.bedrooms || property.bedrooms || '';
  const baths = lead.bathrooms || property.bathrooms || '';
  const comments = lead.comments || lead.notes || '';

  return (
    <div className="page-body">
      <PageHeader title="Lead Detail" subtitle="Review requirements, preferences, and status updates." icon="profile" />
      <section className="glass-card panel">
        <h3>{fullName}</h3>
        <p>{leadType} • {statusLabel}</p>

        <div className="detail-grid">
          <article>
            <h4>Contact</h4>
            {email ? <p><strong>Email:</strong> {email}</p> : null}
            {phone ? <p><strong>Phone:</strong> {phone}</p> : null}
            {preferredContact ? <p><strong>Preferred Contact:</strong> {preferredContact}</p> : null}
          </article>

          <article>
            <h4>Property</h4>
            {propertyAddress ? <p><strong>Address:</strong> {propertyAddress}</p> : null}
            {[propertyCity, propertyZip].some(Boolean) ? (
              <p><strong>Location:</strong> {[propertyCity, propertyZip].filter(Boolean).join(', ')}</p>
            ) : null}
            {propertyType ? <p><strong>Type:</strong> {propertyType}</p> : null}
            {[beds, baths].some(Boolean) ? (
              <p><strong>Layout:</strong> {[beds && `${beds} bed`, baths && `${baths} bath`].filter(Boolean).join(' • ')}</p>
            ) : null}
          </article>

          <article>
            <h4>Timeline & Budget</h4>
            {priceRange ? <p><strong>Price Range:</strong> {priceRange}</p> : null}
            {timeframe ? <p><strong>Time Frame:</strong> {timeframe}</p> : null}
            {lead.bestTime ? <p><strong>Best Time:</strong> {lead.bestTime}</p> : null}
            {lead.preApproved ? <p><strong>Pre-approved:</strong> {lead.preApproved}</p> : null}
          </article>

          <article>
            <h4>Notes</h4>
            {comments ? <p>{comments}</p> : <p>No additional comments provided.</p>}
          </article>
        </div>

        {role === 'agent' ? (
          <div className="row">
            <button className="btn primary" type="button" onClick={() => act('accept')}>Accept</button>
            <button className="btn ghost" type="button" onClick={() => act('reject')}>Reject</button>
            <button className="btn tiny" type="button" onClick={() => act('complete')}>Mark Complete</button>
          </div>
        ) : null}
        {status ? <p>{status}</p> : null}
      </section>
    </div>
  );
}

export function RebateCalculatorPage() {
  const [price, setPrice] = useState('750000');
  const [estimate, setEstimate] = useState(null);
  const [error, setError] = useState('');

  const calculate = async () => {
    setError('');
    try {
      const payload = { price: Number(price), commissionPercentage: 3 };
      const response = await rebateApi.estimateRebate(payload);
      const data = response?.data || response;
      setEstimate(data);
    } catch (err) {
      setError(err.message || 'Unable to calculate rebate.');
      setEstimate(null);
    }
  };

  return (
    <div className="page-body">
      <PageHeader title="Rebate Calculator" subtitle="Estimate potential buyer rebate at closing." icon="calculator" />
      <section className="glass-card panel">
        <label htmlFor="price">Property Price</label>
        <input id="price" value={price} onChange={(e) => setPrice(e.target.value)} />
        <div className="row">
          <button className="btn primary" type="button" onClick={calculate}>Calculate</button>
        </div>
        {estimate ? <p className="calc-result">Estimated Rebate: ${Number(estimate?.estimatedRebate || estimate?.rebateAmount || 0).toLocaleString()}</p> : null}
        {error ? <p className="error-text">{error}</p> : null}
      </section>
    </div>
  );
}

export function BuyerLeadFormPage() {
  return <LeadForm title="Buyer Lead Form" subtitle="Capture buyer preferences, timeline, and contact details." leadType="buyer" />;
}

export function SellerLeadFormPage() {
  return <LeadForm title="Seller Lead Form" subtitle="Collect property details and selling goals." leadType="seller" />;
}

export function ListingDetailPage() {
  const location = useLocation();
  const listing = location.state?.listing || null;
  const openHouse = location.state?.openHouse || null;
  const { user, role } = useAuth();
  const userId = resolveUserId(user);
  const [status, setStatus] = useState('');
  const images = allImagesFromEntity(listing);
  const { showToast } = useToast();

  const resolveListingId = () => {
    if (!listing || typeof listing !== 'object') return null;
    return listing.listingId || listing._id || listing.id || null;
  };

  useEffect(() => {
    const id = resolveListingId();
    if (!id) return;
    marketplaceApi.addListingView(id).catch(() => {});
  }, [listing]);

  const contact = async () => {
    const id = resolveListingId();
    if (!id) return;
    setStatus('Contacting agent...');
    try {
      await marketplaceApi.addListingContact(id);
      if (userId) {
        await leadsApi.createLead({ leadType: 'buyer', userId, listingId: id, propertyAddress: listing?.address || listing?.title });
      }
      setStatus('Contact request sent.');
      showToast({ type: 'success', message: 'Contact request sent.' });
    } catch (err) {
      const msg = err.message || 'Unable to contact agent.';
      setStatus(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  const save = async () => {
    const id = resolveListingId();
    if (!id || !userId) return;
    setStatus('Saving listing...');
    try {
      await marketplaceApi.likeListing({ userId, listingId: id, listing });
      setStatus('Listing saved to favorites.');
      showToast({ type: 'success', message: 'Listing saved to favorites.' });
    } catch (err) {
      const msg = err.message || 'Unable to save listing.';
      setStatus(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  return (
    <div className="page-body">
      <PageHeader title="Listing Detail" subtitle="Property media, pricing, features, open-house data, and contact options." icon="listings" />
      <section className="glass-card panel">
        <div className="detail-gallery">
          {images.length ? (
            images.map((img, i) => (
              <img key={`${img}-${i}`} src={img} alt={`Listing ${i + 1}`} className="detail-gallery-image" />
            ))
          ) : (
            <div className="detail-image-fallback detail-gallery-empty">No Property Images</div>
          )}
        </div>
        <h3>{listing?.propertyTitle || listing?.streetAddress || listing?.address || listing?.title || 'Listing'}</h3>
        <p>{listing?.description || listing?.notes || 'No listing description available.'}</p>
        <p>
          {[
            listing?.beds || listing?.bedrooms ? `${listing?.beds || listing?.bedrooms} bed` : null,
            listing?.baths || listing?.bathrooms ? `${listing?.baths || listing?.bathrooms} bath` : null,
            listing?.sqft || listing?.squareFeet ? `${listing?.sqft || listing?.squareFeet} sqft` : null,
            listing?.price || listing?.priceCents ? `$${Number(listing?.price || (listing?.priceCents ? listing.priceCents / 100 : 0)).toLocaleString()}` : null,
          ].filter(Boolean).join(' • ') || 'No listing details loaded.'}
        </p>
        <p>{[listing?.streetAddress, listing?.city, listing?.state, listing?.zipCode].filter(Boolean).join(', ')}</p>
        <p>Dual Agency Allowed: {String(Boolean(listing?.dualAgencyAllowed))}</p>
        <p>BAC: {listing?.BACPercentage ?? listing?.bacPercent ?? listing?.bac ?? 'N/A'}%</p>

        {(openHouse || (Array.isArray(listing?.openHouses) && listing.openHouses.length > 0)) ? (
          <div className="detail-openhouse">
            <h4>Open House{listing?.openHouses?.length > 1 ? 's' : ''}</h4>
            {(openHouse ? [openHouse] : listing.openHouses).map((oh, i) => {
              const dateVal = oh?.startTime || oh?.startDateTime || oh?.date;
              const fromVal = oh?.fromTime || (oh?.startTime ? new Date(oh.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null);
              const toVal = oh?.toTime || (oh?.endTime ? new Date(oh.endTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : null);
              return (
                <div key={oh?._id || oh?.id || i} className="detail-openhouse-item">
                  <p><strong>Date:</strong> {dateVal ? new Date(dateVal).toLocaleDateString() : 'N/A'}</p>
                  <p><strong>Time:</strong> {fromVal || 'TBA'}{toVal ? ` – ${toVal}` : ''}</p>
                  {oh?.notes ? <p><strong>Notes:</strong> {oh.notes}</p> : null}
                </div>
              );
            })}
          </div>
        ) : null}

        {role === 'buyerSeller' ? (
          <div className="row">
            <button className="btn primary" type="button" onClick={contact}>Contact Agent</button>
            <button className="btn ghost" type="button" onClick={save}>Save Listing</button>
          </div>
        ) : null}
        {status ? <p>{status}</p> : null}
      </section>
    </div>
  );
}

export function AddListingPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [form, setForm] = useState(LISTING_INITIAL_FORM);
  const [status, setStatus] = useState('');
  const [photos, setPhotos] = useState([]);
  const [claimedZips, setClaimedZips] = useState([]);
  const [licensedStates, setLicensedStates] = useState([]);
  const [citiesForState, setCitiesForState] = useState([]);
  const [loadingCities, setLoadingCities] = useState(false);
  const { showToast } = useToast();

  useEffect(() => {
    let live = true;
    const load = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        const data = unwrapObject(res, ['user']) || res;
        const states = parseLicensedStates(data);
        const zips = unwrapList(data?.claimedZipCodes || data?.zipCodes || [], []);
        if (live) {
          const normalizedZips = zips.map((z) => ({
            zipCode: z.zipCode || z.postalCode || z.zipcode,
            state: (z.state || '').length === 2 ? (z.state || '').toUpperCase() : z.state,
            city: z.city || z.cityName || z.placeName || '',
          })).filter((z) => z.zipCode);
          setClaimedZips(normalizedZips);
          setLicensedStates(states.length > 0 ? states : [...new Set(normalizedZips.map((z) => (z.state || '').toUpperCase()).filter(Boolean))]);
        }
      } catch {
        if (live) {
          setLicensedStates([]);
          setClaimedZips([]);
        }
      }
    };
    load();
    return () => { live = false; };
  }, [userId]);

  useEffect(() => {
    if (!form.state) {
      setCitiesForState([]);
      return;
    }
    const fromClaimed = claimedZips
      .filter((z) => (z.state || '').toUpperCase() === form.state.toUpperCase())
      .map((z) => (z.city || '').trim())
      .filter(Boolean);
    let live = true;
    const load = async () => {
      setLoadingCities(true);
      try {
        const res = await zipApi.getStateZipCodes('US', form.state);
        const rows = unwrapList(res, ['zipCodes', 'data', 'results']) || [];
        const fromApi = rows.map((z) => (z.city || '').trim()).filter(Boolean);
        const cities = [...new Set([...fromClaimed, ...fromApi])].sort();
        if (live) setCitiesForState(cities);
      } catch {
        if (live) setCitiesForState(fromClaimed.length ? [...new Set(fromClaimed)].sort() : []);
      } finally {
        if (live) setLoadingCities(false);
      }
    };
    load();
    return () => { live = false; };
  }, [form.state]);

  const validateForm = () => {
    if (!form.propertyTitle?.trim()) {
      showToast({ type: 'error', message: 'Please enter a property title' });
      return false;
    }
    if (!form.description?.trim()) {
      showToast({ type: 'error', message: 'Please enter a property description' });
      return false;
    }
    if (!form.price?.trim()) {
      showToast({ type: 'error', message: 'Please enter a price' });
      return false;
    }
    const price = Number.parseFloat(String(form.price).trim());
    if (!Number.isFinite(price) || price <= 0) {
      showToast({ type: 'error', message: 'Please enter a valid price' });
      return false;
    }
    if (!form.streetAddress?.trim()) {
      showToast({ type: 'error', message: 'Please enter a street address' });
      return false;
    }
    if (!form.city?.trim()) {
      showToast({ type: 'error', message: 'Please enter a city' });
      return false;
    }
    if (!form.state?.trim()) {
      showToast({ type: 'error', message: 'Please enter a state' });
      return false;
    }
    const zipInClaimed = claimedZips.some((z) => z.zipCode === form.zipCode);
    if (!form.zipCode?.trim() || !zipInClaimed) {
      showToast({ type: 'error', message: 'Please select a ZIP code from your claimed areas' });
      return false;
    }
    if (form.listingAgent !== 'true' && form.listingAgent !== 'false') {
      showToast({ type: 'error', message: 'Please confirm if you are the listing agent for this property' });
      return false;
    }
    const bac = Number.parseFloat(form.BACPercentage);
    if (!Number.isFinite(bac) || bac < 0.5 || bac > 5) {
      showToast({ type: 'error', message: 'BAC must be between 0.5% and 5%' });
      return false;
    }
    if (photos.length > 10) {
      showToast({ type: 'error', message: 'Maximum 10 photos allowed' });
      return false;
    }
    if ((form.openHouses || []).length > 4) {
      showToast({ type: 'error', message: 'Maximum 4 open houses allowed' });
      return false;
    }
    return true;
  };

  const submit = async () => {
    if (!userId) return;
    if (!validateForm()) return;
    setStatus('Creating listing...');
    try {
      const payload = buildListingFormData(form, userId, photos);
      await marketplaceApi.createListing(payload);
      setStatus('Listing created.');
      setForm({ ...LISTING_INITIAL_FORM, openHouses: [] });
      setPhotos([]);
      showToast({ type: 'success', message: 'Listing created successfully.' });
    } catch (err) {
      const msg = err.message || 'Unable to create listing.';
      setStatus(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  const addOpenHouse = () => {
    const oh = form.openHouses || [];
    if (oh.length >= 4) {
      showToast({ type: 'info', message: 'Maximum of 4 open houses allowed' });
      return;
    }
    const today = new Date().toISOString().slice(0, 10);
    setForm((p) => ({ ...p, openHouses: [...(p.openHouses || []), { date: today, fromTime: '10:00 AM', toTime: '2:00 PM', notes: '' }] }));
  };

  const removeOpenHouse = (idx) => {
    setForm((p) => ({ ...p, openHouses: (p.openHouses || []).filter((_, i) => i !== idx) }));
  };

  const updateOpenHouse = (idx, field, value) => {
    setForm((p) => {
      const oh = [...(p.openHouses || [])];
      if (oh[idx]) oh[idx] = { ...oh[idx], [field]: value };
      return { ...p, openHouses: oh };
    });
  };

  const handleListingAgentChange = (val) => {
    setForm((p) => ({
      ...p,
      listingAgent: val,
      dualAgencyAllowed: val === 'false' ? 'false' : p.dualAgencyAllowed,
    }));
  };

  const handleStateChange = (stateCode) => {
    setForm((p) => ({ ...p, state: stateCode, city: '', zipCode: '' }));
  };

  const handleCityChange = (city) => {
    setForm((p) => ({ ...p, city, zipCode: '' }));
  };

  const isListingAgent = form.listingAgent === 'true';

  const zipsForStateAndCity = claimedZips.filter((z) => {
    const matchState = (z.state || '').toUpperCase() === (form.state || '').toUpperCase();
    const matchCity = !form.city || (z.city || '').toLowerCase() === form.city.toLowerCase();
    return matchState && matchCity;
  });

  const bacVal = Math.min(5, Math.max(0.5, Number.parseFloat(form.BACPercentage) || 2.5));

  return (
    <div className="page-body">
      <PageHeader title="Add Listing" subtitle="Create a listing tied to your claimed ZIP coverage." icon="listings" />
      <section className="glass-card panel add-listing-form listing-form-grid">
        <div className="add-listing-section">
          <h4>Basic Information</h4>
          <div className="form-field">
            <label>Property Title *</label>
            <input
              placeholder="e.g., Beautiful 3BR Condo in Manhattan"
              value={form.propertyTitle}
              onChange={(e) => setForm((prev) => ({ ...prev, propertyTitle: e.target.value }))}
            />
          </div>
          <div className="form-field">
            <label>Description *</label>
            <textarea
              placeholder="Describe your property in detail..."
              rows={4}
              value={form.description}
              onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))}
            />
          </div>
        </div>

        <div className="add-listing-section">
          <h4>Price & Commission</h4>
          <div className="form-field">
            <label>Price *</label>
            <input
              placeholder="e.g., 1250000"
              type="number"
              min="1"
              value={form.price}
              onChange={(e) => setForm((prev) => ({ ...prev, price: e.target.value }))}
            />
          </div>
          <div className="form-field bac-slider-wrap">
            <label>
              Buyer Agent Commission (BAC)
              <span className="bac-slider-value">{bacVal.toFixed(1)}%</span>
            </label>
            <input
              type="range"
              min="0.5"
              max="5"
              step="0.1"
              value={bacVal}
              onChange={(e) => setForm((prev) => ({ ...prev, BACPercentage: e.target.value }))}
            />
            <div className="slider-labels">
              <span>0.5%</span>
              <span>5%</span>
            </div>
          </div>
        </div>

        <div className="add-listing-section">
          <h4>Location</h4>
          <div className="form-field">
            <label>Street Address *</label>
            <input
              placeholder="e.g., 123 Park Avenue"
              value={form.streetAddress}
              onChange={(e) => setForm((prev) => ({ ...prev, streetAddress: e.target.value }))}
            />
          </div>
          <div className="form-field">
            <label>ZIP Code * (select from claimed areas – auto-fills city & state)</label>
            {claimedZips.length === 0 ? (
              <p className="form-hint">
                <Link to="/agent/zip-codes">Claim a ZIP code</Link> before adding a listing.
              </p>
            ) : (
              <select
                value={form.zipCode}
                onChange={(e) => {
                  const zip = claimedZips.find((z) => z.zipCode === e.target.value);
                  setForm((p) => ({
                    ...p,
                    zipCode: e.target.value,
                    state: zip?.state || p.state,
                    city: zip?.city || p.city,
                  }));
                  if (zip && !zip.city && zip.state) {
                    zipApi.getStateZipCodes('US', zip.state).then((res) => {
                      const rows = unwrapList(res, ['zipCodes', 'data', 'results']) || [];
                      const match = rows.find((r) => (r.postalCode || r.zipCode || r.zipcode) === zip.zipCode);
                      if (match?.city) {
                        setForm((prev) => (prev.zipCode === zip.zipCode ? { ...prev, city: match.city } : prev));
                      }
                    }).catch(() => {});
                  }
                }}
              >
                <option value="">Select ZIP code</option>
                {(zipsForStateAndCity.length > 0 ? zipsForStateAndCity : claimedZips).map((z) => (
                  <option key={z.zipCode} value={z.zipCode}>
                    {z.zipCode} {z.city ? `(${z.city})` : ''} • {z.state}
                  </option>
                ))}
              </select>
            )}
          </div>
          <div className="form-field">
            <label>State * (auto-filled from ZIP)</label>
            {licensedStates.length === 0 ? (
              <input value={form.state || ''} placeholder="Select ZIP first" readOnly className="input-readonly" />
            ) : (
              <StateSelect
                value={form.state}
                onChange={handleStateChange}
                placeholder="Select state"
                states={licensedStates}
              />
            )}
          </div>
          <div className="form-field">
            <label>City * (auto-filled from ZIP)</label>
            {!form.state ? (
              <input value={form.city} placeholder="Select ZIP first" readOnly />
            ) : loadingCities && !form.city ? (
              <input placeholder="Loading..." readOnly />
            ) : citiesForState.length > 0 || form.city ? (
              <select
                value={form.city}
                onChange={(e) => handleCityChange(e.target.value)}
              >
                <option value="">Select city</option>
                {[...new Set([...(form.city ? [form.city] : []), ...citiesForState])].sort().map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            ) : (
              <input
                value={form.city}
                placeholder="e.g., New York"
                onChange={(e) => setForm((prev) => ({ ...prev, city: e.target.value }))}
              />
            )}
          </div>
        </div>

        <div className="add-listing-section">
          <h4>Property Details</h4>
          <div className="listing-grid-3">
            <div className="form-field">
              <label>Bedrooms</label>
              <input
                type="number"
                placeholder="—"
                value={form.bedrooms}
                onChange={(e) => setForm((prev) => ({ ...prev, bedrooms: e.target.value }))}
              />
            </div>
            <div className="form-field">
              <label>Bathrooms</label>
              <input
                type="number"
                placeholder="—"
                value={form.bathrooms}
                onChange={(e) => setForm((prev) => ({ ...prev, bathrooms: e.target.value }))}
              />
            </div>
            <div className="form-field">
              <label>Square Feet</label>
              <input
                type="number"
                placeholder="—"
                value={form.squareFeet}
                onChange={(e) => setForm((prev) => ({ ...prev, squareFeet: e.target.value }))}
              />
            </div>
          </div>
          <div className="listing-grid-2">
            <div className="form-field">
              <label>Property Type</label>
              <select
                value={form.propertyType}
                onChange={(e) => setForm((prev) => ({ ...prev, propertyType: e.target.value }))}
              >
                <option value="house">House</option>
                <option value="condo">Condo</option>
                <option value="townhouse">Townhouse</option>
                <option value="multi-family">Multi Family</option>
                <option value="land">Land</option>
              </select>
            </div>
            <div className="form-field">
              <label>Status</label>
              <select
                value={form.status}
                onChange={(e) => setForm((prev) => ({ ...prev, status: e.target.value }))}
              >
                <option value="active">Active</option>
                <option value="draft">Draft</option>
                <option value="pending">Pending</option>
                <option value="sold">Sold</option>
              </select>
            </div>
          </div>
          <div className="form-field">
            <label>Property Features (comma separated)</label>
            <input
              placeholder="e.g., Pool, Garage, Garden"
              value={form.propertyFeatures}
              onChange={(e) => setForm((prev) => ({ ...prev, propertyFeatures: e.target.value }))}
            />
          </div>
        </div>

        <div className="add-listing-section">
          <h4>Listing Agent Verification</h4>
          <div className="listing-grid-2">
            <div className="form-field">
              <label>Are you the listing agent? *</label>
              <select
                value={form.listingAgent}
                onChange={(e) => handleListingAgentChange(e.target.value)}
              >
                <option value="">Select...</option>
                <option value="true">Yes, I am the listing agent</option>
                <option value="false">No, I&apos;m listing another agent&apos;s property</option>
              </select>
            </div>
            <div className="form-field">
              <label>Dual Agency Allowed</label>
              <select
                value={form.dualAgencyAllowed}
                onChange={(e) => setForm((prev) => ({ ...prev, dualAgencyAllowed: e.target.value }))}
                disabled={!isListingAgent}
              >
                <option value="false">No</option>
                <option value="true">Yes</option>
              </select>
              {!isListingAgent && <small className="form-hint">Not available when not listing agent</small>}
            </div>
          </div>
        </div>

        <div className="add-listing-section">
          <h4>Property Photos (up to 10)</h4>
          <div className="form-field">
            <label htmlFor="listing-photos">Upload Photos</label>
            <input
              id="listing-photos"
              type="file"
              accept="image/*"
              multiple
              onChange={(e) => {
                const files = Array.from(e.target.files || []).slice(0, 10);
                setPhotos(files);
              }}
            />
            {photos.length ? <small>{photos.length} photo(s) selected (max 10)</small> : null}
          </div>
        </div>

        <div className="add-listing-section">
          <h4>Open Houses (max 4)</h4>
          {(form.openHouses || []).map((oh, idx) => (
            <div key={idx} className="open-house-entry">
              <div className="open-house-header">
                <span>Open House #{idx + 1}</span>
                <button type="button" className="btn tiny ghost" onClick={() => removeOpenHouse(idx)}>Remove</button>
              </div>
              <div className="listing-grid-3">
                <div className="form-field">
                  <label>Date</label>
                  <input
                    type="date"
                    value={oh.date || ''}
                    onChange={(e) => updateOpenHouse(idx, 'date', e.target.value)}
                  />
                </div>
                <div className="form-field">
                  <label>From</label>
                  <input
                    placeholder="10:00 AM"
                    value={oh.fromTime || ''}
                    onChange={(e) => updateOpenHouse(idx, 'fromTime', e.target.value)}
                  />
                </div>
                <div className="form-field">
                  <label>To</label>
                  <input
                    placeholder="2:00 PM"
                    value={oh.toTime || ''}
                    onChange={(e) => updateOpenHouse(idx, 'toTime', e.target.value)}
                  />
                </div>
              </div>
              <div className="form-field">
                <input
                  placeholder="Special notes (optional)"
                  value={oh.notes || ''}
                  onChange={(e) => updateOpenHouse(idx, 'notes', e.target.value)}
                />
              </div>
            </div>
          ))}
          {(form.openHouses || []).length < 4 && (
            <button type="button" className="btn ghost" onClick={addOpenHouse}>Add Open House</button>
          )}
        </div>

        <div className="add-listing-section">
          <button className="btn primary" type="button" onClick={submit} style={{ width: '100%', padding: '0.9rem' }}>
            Create Listing
          </button>
          {status ? <p style={{ marginTop: '0.75rem', fontSize: '0.9rem', color: 'var(--muted)' }}>{status}</p> : null}
        </div>
      </section>
    </div>
  );
}

export function AddLoanPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [form, setForm] = useState({ programName: '', rateType: '', apr: '', minDownPayment: '', notes: '' });
  const [status, setStatus] = useState('');

  const submit = async () => {
    if (!userId) return;
    setStatus('Creating loan...');
    try {
      await loansApi.createLoan({ ...form, loanOfficerId: userId });
      setStatus('Loan program created.');
      setForm({ programName: '', rateType: '', apr: '', minDownPayment: '', notes: '' });
    } catch (err) {
      setStatus(err.message || 'Unable to create loan program.');
    }
  };

  return (
    <div className="page-body">
      <PageHeader title="Add Loan Program" subtitle="Publish new mortgage products for buyers." icon="billing" />
      <FormCard form={form} onChange={setForm} fields={[
        ['programName', 'Program Name'],
        ['rateType', 'Rate Type'],
        ['apr', 'APR'],
        ['minDownPayment', 'Min Down Payment'],
        ['notes', 'Notes'],
      ]} onSubmit={submit} status={status} />
    </div>
  );
}

export function ChecklistPage() {
  return <ChecklistTemplate title="Buyer / Seller Checklist" items={['Pre-approval completed', 'Agent selected', 'Disclosure docs reviewed']} />;
}

export function RebateChecklistPage() {
  return <ChecklistTemplate title="Rebate Compliance Checklist" items={['Rebate disclosure signed', 'Loan officer policy confirmed', 'Closing statement reviewed']} />;
}

const AGENT_CHECKLIST = [
  'Complete Your Profile: Fill out your agent profile with accurate information including your brokerage, license number, licensed states, specialties, and professional bio. A complete profile helps buyers and sellers find and trust you.',
  'Add Your Contact & Listing Information: Ensure your contact details are correct and include any relevant links (such as your website or listings). This information is visible to buyers and sellers viewing your profile.',
  'Claim ZIP Codes: Select and claim ZIP codes in your licensed states where you want to appear in buyer and seller searches. You can claim up to 6 ZIP codes. Pricing is based on population tiers, ranging from $7.99 to $49.99 per month per ZIP code.',
  'Respond to Inquiries Promptly: When buyers or sellers contact you through the platform, respond quickly. Timely responses increase trust and improve conversion into real clients.',
  'Work with Buyers: Represent buyers in home purchases and clearly explain how rebates may apply. Rebates typically come from the commission offered by the seller, listing broker, or builder and often appear as a credit at closing.',
  'Work with Sellers: Assist sellers with listing and selling their homes. Savings for sellers are usually provided through a reduced listing fee, depending on the agreement.',
  'Verify Rebate Eligibility: Confirm that rebates are permitted in the applicable state and that the transaction structure supports them. Coordinate with lenders and title/closing companies when rebates are involved.',
  'Coordinate with Loan Officers: Work closely with loan officers to ensure buyers are pre-approved and that rebate structures align with loan requirements.',
  'Coordinate with Title Companies: Communicate with title and closing companies regarding rebate credits when applicable to ensure a smooth closing process.',
  'Use In-App Messaging Professionally: Communicate clearly and professionally with buyers, sellers, and loan officers using the in-app messaging system, then transition to direct communication as needed.',
  'Update Your Profile Regularly: Keep your profile information current, including licensed states, specialties, contact details, and any changes to your brokerage.',
  'Build Your Reputation: Encourage satisfied buyers and sellers to leave reviews on your profile. Strong reviews improve visibility and trust on the platform.',
];

const AGENT_PLATFORM_OVERVIEW = `This platform connects you with buyers and sellers searching for real estate professionals in specific ZIP codes. By claiming ZIP codes, your profile becomes visible in searches, allowing you to generate leads and build relationships.

Key Points:
• Buyers and sellers can view your agent profile
• You appear in searches based on claimed ZIP codes
• Users can contact you through in-app messaging
• Rebates may apply depending on state rules and transaction structure
• You work directly with buyers, sellers, lenders, and title companies outside the app
• The platform helps you get discovered and generate leads, while transactions occur in real life`;

const AGENT_TIPS = [
  'Keep your profile complete and accurate',
  'Respond quickly to buyer and seller inquiries',
  'Claim ZIP codes where you actively work',
  'Be clear and transparent about rebates',
  'Coordinate early with lenders and title companies',
  'Maintain professional communication',
  'Encourage clients to leave reviews',
];

const LOAN_OFFICER_CHECKLIST = [
  'Complete Your Profile: Fill out your loan officer profile with accurate information including your company, license number, licensed states, specialty products, and professional bio. A complete profile helps buyers and agents find and trust you.',
  'Add Your Mortgage Application Link: Include your mortgage application URL in your profile. This link is visible to buyers and agents who view your profile, allowing them to easily access your mortgage application process.',
  'Claim ZIP Codes: Select and claim ZIP codes in your licensed states where you want to appear in buyer and seller searches. You can claim up to 6 ZIP codes. The cost is based on population tiers, ranging from $3.99 to $26.99 per month per ZIP code.',
  'Respond to Inquiries: When buyers or agents contact you through the platform, respond promptly. The platform provides opportunities, but most of your work happens outside the app through your mortgage application link and direct communication.',
  'Work with Buyers: Help buyers get pre-approved for mortgages and guide them through the loan process. Use your mortgage application link to process applications outside the platform.',
  'Collaborate with Agents: Agents on the platform may refer buyers to you. Work with agents to ensure smooth transactions and help buyers secure financing for their home purchases.',
  'Verify Rebate Eligibility: When working with buyers who are receiving rebates, ensure your lender allows real estate rebates. All loan officers on this platform have confirmed their lenders permit rebates.',
  'Coordinate with Title Companies: Communicate with title/closing companies about rebate transactions when applicable. Ensure all parties understand how rebates affect the loan and closing process.',
  'Review Special Financing Programs: If buyers are using special financing programs (first-time homebuyer grants, state/city programs), verify these programs allow rebates. Some programs may restrict or prohibit rebates.',
  'Maintain Professional Communication: Use the in-app messaging system to communicate with buyers and agents. Keep conversations professional and helpful, then transition to your mortgage application process outside the platform.',
  'Update Your Profile Regularly: Keep your profile information current, including your mortgage application link, specialty products, and any changes to your licensed states or company information.',
  'Build Your Reputation: Encourage satisfied buyers and agents to leave reviews on your profile. Positive reviews help increase your visibility and trustworthiness on the platform.',
];

const LOAN_OFFICER_PLATFORM_OVERVIEW = `This platform connects you with buyers and agents who are looking for mortgage services. While the platform provides opportunities and connections, most of your actual loan processing work happens outside the app through your mortgage application link and direct communication.

Key Points:
• Buyers and agents can view your profile and see your mortgage application link
• They can chat with you through the in-app messaging system
• Your mortgage application link is prominently displayed on your profile
• The platform helps you get discovered, but loan processing happens through your external mortgage application system
• You work with buyers and agents in real life to provide mortgage services
• All loan officers on this platform have confirmed their lenders allow real estate rebates`;

const LOAN_OFFICER_TIPS = [
  'Keep your profile complete and up-to-date',
  'Respond quickly to messages from buyers and agents',
  'Make sure your mortgage application link is working and accessible',
  'Claim ZIP codes in areas where you actively work',
  'Encourage satisfied clients to leave reviews',
  'Be transparent about rebate eligibility with buyers',
  'Coordinate effectively with agents and title companies',
];

export function AgentChecklistPage() {
  return (
    <div className="page-body">
      <PageHeader title="Agent Checklist" subtitle="Professional checklist for compliant rebate transactions" icon="checklist" />
      <AgentChecklistContent />
    </div>
  );
}

export function LoanOfficerChecklistPage() {
  return (
    <div className="page-body">
      <PageHeader title="Loan Officer Checklist" subtitle="Your step-by-step guide to success" icon="checklist" />
      <LoanOfficerChecklistContent />
    </div>
  );
}

function AgentChecklistContent() {
  return (
    <div className="checklist-flow">
      <section className="glass-card panel checklist-header checklist-agent">
        <div className="checklist-header-inner">
          <div className="checklist-icon-wrap">
            <IconGlyph name="checklist" filled />
          </div>
          <div>
            <h3>Agent Compliance Guide</h3>
            <p>Professional checklist for profile setup, ZIP strategy, lead response, and rebate compliance</p>
          </div>
        </div>
        <div className="checklist-info-box checklist-agent">
          <IconGlyph name="info" />
          <span>Use this checklist as your operating standard for profile setup, ZIP strategy, lead response, and rebate compliance coordination.</span>
        </div>
      </section>

      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title"><IconGlyph name="lightbulb" /> How the Platform Works</h3>
        <div className="checklist-platform-overview">{AGENT_PLATFORM_OVERVIEW}</div>
      </section>

      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title"><IconGlyph name="assignment" /> Agent Checklist</h3>
        <ol className="checklist-items checklist-agent">
          {AGENT_CHECKLIST.map((item, i) => (
            <li key={i} className="checklist-item">
              <span className="checklist-num">{i + 1}</span>
              <span className="checklist-text">{item}</span>
            </li>
          ))}
        </ol>
      </section>

      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title"><IconGlyph name="star" /> Tips for Success</h3>
        <ul className="checklist-tips checklist-agent">
          {AGENT_TIPS.map((tip, i) => (
            <li key={i}><IconGlyph name="checkCircle" />{tip}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}

function LoanOfficerChecklistContent() {
  return (
    <div className="checklist-flow">
      <section className="glass-card panel checklist-header checklist-lo">
        <div className="checklist-header-inner">
          <div className="checklist-icon-wrap checklist-lo">
            <IconGlyph name="checklist" filled />
          </div>
          <div>
            <h3>Loan Officer Guide</h3>
            <p>Your step-by-step guide to success</p>
          </div>
        </div>
        <div className="checklist-info-box checklist-lo">
          <IconGlyph name="info" />
          <span>This platform connects you with opportunities. Most of your loan processing work happens outside the app through your mortgage application link.</span>
        </div>
      </section>

      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title checklist-lo"><IconGlyph name="lightbulb" /> How the Platform Works</h3>
        <div className="checklist-platform-overview">{LOAN_OFFICER_PLATFORM_OVERVIEW}</div>
      </section>

      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title checklist-lo"><IconGlyph name="assignment" /> Loan Officer Checklist</h3>
        <ol className="checklist-items checklist-lo">
          {LOAN_OFFICER_CHECKLIST.map((item, i) => (
            <li key={i} className="checklist-item">
              <span className="checklist-num">{i + 1}</span>
              <span className="checklist-text">{item}</span>
            </li>
          ))}
        </ol>
      </section>

      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title checklist-lo"><IconGlyph name="star" /> Tips for Success</h3>
        <ul className="checklist-tips checklist-lo">
          {LOAN_OFFICER_TIPS.map((tip, i) => (
            <li key={i}><IconGlyph name="checkCircle" />{tip}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}

function LeadForm({ title, subtitle, leadType }) {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const location = useLocation();
  const contextAgent = location.state?.agent || null;
  const contextListing = location.state?.listing || null;
  const contextLoanOfficer = location.state?.loanOfficer || null;

  const [form, setForm] = useState({
    fullname: user?.fullname || user?.name || '',
    email: user?.email || '',
    phone: user?.phone || '',
    zipCode: '',
    budgetRange: '',
    timeline: '',
    notes: '',
  });
  const [status, setStatus] = useState('');
  const { showToast } = useToast();

  const submit = async () => {
    setStatus('Submitting lead...');
    try {
      await leadsApi.createLead({
        ...form,
        leadType,
        userId,
        buyerId: userId,
        agentId: contextAgent?._id || contextAgent?.id,
        loanOfficerId: contextLoanOfficer?._id || contextLoanOfficer?.id,
        listingId: contextListing?.listingId || contextListing?._id || contextListing?.id,
        propertyAddress: contextListing?.address || contextListing?.title,
      });
      setStatus('Lead submitted successfully.');
      showToast({ type: 'success', message: 'Lead submitted successfully.' });
    } catch (err) {
      const msg = err.message || 'Unable to submit lead.';
      setStatus(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  return (
    <div className="page-body">
      <PageHeader title={title} subtitle={subtitle} icon="profile" />
      <FormCard
        form={form}
        onChange={setForm}
        fields={[
          ['fullname', 'Full Name'],
          ['email', 'Email'],
          ['phone', 'Phone'],
          ['zipCode', 'Desired ZIP'],
          ['budgetRange', 'Budget Range'],
          ['timeline', 'Timeline'],
          ['notes', 'Additional Notes'],
        ]}
        onSubmit={submit}
        status={status}
      />
    </div>
  );
}

function ChecklistTemplate({ title, items }) {
  return (
    <div className="page-body">
      <PageHeader title={title} subtitle="Step-by-step workflow to reduce closing friction." icon="checklist" />
      <section className="glass-card panel">
        <ul className="clean-list">
          {items.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}

function FormCard({ fields, form, onChange, onSubmit, status }) {
  return (
    <section className="glass-card panel form-stack">
      {fields.map(([key, label]) => (
        <input
          key={key}
          placeholder={label}
          value={form[key] || ''}
          onChange={(e) => onChange((prev) => ({ ...prev, [key]: e.target.value }))}
        />
      ))}
      <button className="btn primary" type="button" onClick={onSubmit}>Submit</button>
      {status ? <small>{status}</small> : null}
    </section>
  );
}
