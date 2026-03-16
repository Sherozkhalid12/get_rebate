import { useMemo, useState, useEffect } from 'react';
import { useLocation, Link, useNavigate, useSearchParams } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject } from '../../lib/api';
import { allImagesFromEntity, firstImageFromEntity } from '../../lib/media';
import * as notificationApi from '../../api/notifications';
import * as proposalApi from '../../api/proposals';
import * as leadsApi from '../../api/leads';
import * as surveyApi from '../../api/survey';
import * as rebateApi from '../../api/rebate';
import * as marketplaceApi from '../../api/marketplace';
import * as loansApi from '../../api/loans';
import * as userApi from '../../api/user';
import * as zipApi from '../../api/zipcodes';
import { useToast } from '../../components/ui/ToastProvider';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
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
  bedrooms: '',
  bathrooms: '',
  squareFeet: '',
  propertyFeatures: '',
  openHouses: [],
};

const FREE_LISTING_LIMIT = 3;
const ADDITIONAL_LISTING_PRICE = 9.99;

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
  fd.append('status', 'active');
  fd.append('createdByRole', 'agent');

  const propertyDetails = {
    type: 'house',
    status: 'active',
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
  const [loading, setLoading] = useState(true);
  const { showToast } = useToast();

  const loadLive = async () => {
    if (!userId) return;
    setError('');
    setLoading(true);
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
    } finally {
      setLoading(false);
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
        actions={<button className="btn tiny" onClick={loadLive} type="button" disabled={loading}>Refresh</button>}
      />
      {loading ? <AnimatedLoader variant="card" label="Loading notifications..." /> : null}
      {error && !loading ? <p className="error-text">{error}</p> : null}
      {!loading ? <section className="glass-card panel">
        {rows.map((n) => (
          <div className="list-row" key={n.id}>
            <div>
              <strong>{n.title}</strong>
              <p>{n.text}</p>
            </div>
            <small>{n.time}</small>
          </div>
        ))}
      </section> : null}
    </div>
  );
}

function mapToProposalRow(row) {
  return {
    id: row._id || row.id,
    professional: row.professionalName || row.userName || row.agentName || row.leadType || 'Proposal',
    status: row.status || row.leadStatus || 'pending',
    type: row.professionalType || row.type || row.leadType || 'service',
    updatedAt: row.updatedAt ? new Date(row.updatedAt).toLocaleDateString() : 'Today',
  };
}

export function ProposalsPage() {
  const { user, role } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      setError('');
      setLoading(true);
      try {
        const response = role === 'buyerSeller'
          ? await proposalApi.getUserProposals(userId)
          : await proposalApi.getProfessionalProposals(userId);

        if (!live) return;

        const proposals = unwrapList(response, ['proposals', 'data']);
        setRows(proposals.map(mapToProposalRow));
      } catch (err) {
        if (!live) return;
        const is404 = err?.message?.includes('404') || err?.message?.toLowerCase().includes('endpoint not found') || err?.message?.toLowerCase().includes('not found');
        if (is404) {
          try {
            const leadsRes = await leadsApi.getLeadsByAgentId(userId);
            const leads = unwrapList(leadsRes, ['leads', 'data']);
            setRows(leads.map((lead) => mapToProposalRow({
              _id: lead._id,
              id: lead._id || lead.id,
              professionalName: lead.agentName || lead.professionalName || lead.userName,
              leadStatus: lead.leadStatus || lead.status,
              leadType: lead.leadType || 'Lead',
              updatedAt: lead.updatedAt || lead.createdAt,
            })));
            setError('');
          } catch (leadsErr) {
            setError(leadsErr.message || 'Unable to load proposals.');
            setRows([]);
          }
        } else {
          setError(err.message || 'Unable to load proposals.');
          setRows([]);
        }
      } finally {
        if (live) setLoading(false);
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
      {loading ? <AnimatedLoader variant="card" label="Loading proposals..." /> : null}
      {error && !loading ? <p className="error-text">{error}</p> : null}
      {!loading ? <section className="glass-card panel">
        {rows.map((row) => (
          <div className="list-row" key={row.id}>
            <div>
              <strong>{row.professional}</strong>
              <p>{row.type} • Updated {row.updatedAt}</p>
            </div>
            <span className={`status ${String(row.status).toLowerCase().replace(' ', '-')}`}>{row.status}</span>
          </div>
        ))}
      </section> : null}
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
        const buyerInfo = lead.currentUserId || lead.buyerInfo || lead.currentUser || lead.user || lead.buyer;
        const buyerId =
          (typeof buyerInfo === 'string' ? buyerInfo : null) ||
          buyerInfo?._id || buyerInfo?.id || buyerInfo?.userId ||
          lead.userId || lead.createdBy;
        const buyerRole = (typeof buyerInfo === 'object' && buyerInfo?.role) ? buyerInfo.role : 'buyer/seller';
        if (role === 'agent') {
          if (!buyerId) {
            setStatus('Buyer information not available for this lead.');
            return;
          }
          await leadsApi.markLeadComplete(leadId, { userId: String(buyerId), role: buyerRole });
        } else {
          await leadsApi.markLeadComplete(leadId, { userId, role: role === 'buyerSeller' ? 'buyer/seller' : role });
        }
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

const REBATE_FALLBACK_STATES = [
  'AZ', 'AR', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA',
  'HI', 'ID', 'IL', 'IN', 'KY', 'ME', 'MD', 'MA',
  'MI', 'MN', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM',
  'NY', 'NC', 'ND', 'OH', 'PA', 'RI', 'SC', 'SD',
  'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
];

function toNum(v) {
  if (v == null) return null;
  if (typeof v === 'number' && !Number.isNaN(v)) return v;
  const s = String(v).replace(/[^0-9.+-]/g, '').trim();
  const n = parseFloat(s);
  return Number.isFinite(n) ? n : null;
}

function parseRebateResponse(data) {
  const d = data?.estimate ?? data;
  const calc = data?.calculation;
  const details = data?.detailedAmounts;
  const simpl = data?.simplifiedForContract;

  const range = d?.estimatedRebateRange ?? d;
  let minRebate = range?.min != null ? toNum(range.min) : toNum(d?.minRebate);
  const maxRebateRaw = range?.max ?? d?.maxRebate;
  const isOrMore = maxRebateRaw != null && String(maxRebateRaw).toLowerCase().includes('more');
  let maxRebate = isOrMore ? null : (maxRebateRaw != null ? toNum(maxRebateRaw) : null);

  if (calc && (calc.rebateAmount != null || calc.sellerSavings != null)) {
    const amt = toNum(calc.rebateAmount ?? calc.sellerSavings ?? (details && (details.rebateAmount ?? details.sellerSavings)));
    if (amt != null) minRebate = minRebate ?? amt;
  }

  const commRange = d?.commissionRangeForTier ?? d;
  const minComm = toNum(commRange?.min ?? d?.minCommission ?? calc?.originalCommissionRate ?? calc?.commissionRate);
  const maxComm = toNum(commRange?.max ?? d?.maxCommission);

  const fmt = (v) => (v == null ? null : (typeof v === 'string' ? v : String(v)));

  return {
    success: data?.success !== false,
    tier: fmt(d?.tier ?? calc?.rebateTier),
    rebatePercentage: toNum(d?.rebatePercentage ?? calc?.rebatePercentage),
    minRebate,
    maxRebate,
    isOrMore,
    minCommission: minComm,
    maxCommission: maxComm,
    rebateAmountFormatted: fmt(calc?.rebateAmount ?? details?.rebateAmount),
    totalCommissionFormatted: fmt(calc?.totalCommission ?? details?.totalCommission),
    netAgentCommissionFormatted: fmt(calc?.netAgentCommission ?? details?.netAgentCommission),
    sellerSavingsFormatted: fmt(calc?.sellerSavings ?? details?.sellerSavings),
    originalCommissionAmountFormatted: fmt(calc?.originalCommissionAmount ?? details?.originalCommissionAmount),
    newCommissionAmountFormatted: fmt(calc?.newCommissionAmount ?? details?.newCommissionAmount),
    effectiveCommissionRateFormatted: fmt(calc?.effectiveCommissionRate ?? details?.effectiveCommissionRate),
    listingFeeForContract: fmt(simpl?.listingFee ?? calc?.listingFeeForContract),
    simplifiedNote: fmt(simpl?.note ?? calc?.simplifiedNote),
    simplifiedInstructions: fmt(simpl?.instructions ?? calc?.simplifiedInstructions),
    notes: Array.isArray(data?.notes) ? data.notes.map(String) : (data?.notes ? [String(data.notes)] : null),
    warnings: Array.isArray(data?.warnings) ? data.warnings.map(String) : (data?.warnings ? [String(data.warnings)] : null),
    instructions: Array.isArray(data?.instructions) ? data.instructions.map(String) : (data?.instructions ? [String(data.instructions)] : null),
  };
}

function ensureCurrency(val) {
  if (!val || typeof val !== 'string') return val;
  if (val.startsWith('$')) return val;
  const n = parseFloat(val.replace(/[^0-9.]/g, ''));
  return Number.isFinite(n) ? `$${Math.round(n).toLocaleString()}` : val;
}

export function RebateCalculatorPage() {
  const location = useLocation();
  const initialMode = location.state?.mode;
  const [mode, setMode] = useState(initialMode === 2 ? 2 : initialMode === 1 ? 1 : 0); // 0=Estimated, 1=Actual, 2=Seller Conversion
  const [price, setPrice] = useState('750000');
  const [commission, setCommission] = useState('3');
  const [originalCommission, setOriginalCommission] = useState('3');
  const [state, setState] = useState('CA');
  const [allowedStates, setAllowedStates] = useState(REBATE_FALLBACK_STATES);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    rebateApi.getAllowedStates()
      .then((states) => { if (states?.length) setAllowedStates(states.sort()); })
      .catch(() => {});
  }, []);

  const calculate = async () => {
    setError('');
    setResult(null);
    const priceStr = String(price || '').replace(/,/g, '').trim();
    const commStr = String(commission || '').trim();
    const origStr = String(originalCommission || '').trim() || commStr;
    if (!priceStr || !commStr || !state) {
      setError('Please enter price, commission, and state.');
      return;
    }
    const priceNum = Number.parseFloat(priceStr);
    if (!Number.isFinite(priceNum) || priceNum <= 0) {
      setError('Please enter a valid price.');
      return;
    }
    setLoading(true);
    try {
      let data;
      if (mode === 0) {
        data = await rebateApi.estimateRebate({ price: priceStr, commission: commStr, state: state.toUpperCase() });
      } else if (mode === 1) {
        data = await rebateApi.calculateExactRebate({ price: priceStr, commission: commStr, state: state.toUpperCase() });
      } else {
        data = await rebateApi.calculateSellerRate({ price: priceStr, commission: origStr, originalCommission: origStr, state: state.toUpperCase() });
      }
      const res = parseRebateResponse(data?.data ?? data);
      setResult(res);
    } catch (err) {
      setError(err?.message || 'Unable to calculate.');
      setResult(null);
    } finally {
      setLoading(false);
    }
  };

  const priceNum = Number(String(price || '').replace(/,/g, ''));
  const commVal = mode === 2 ? originalCommission : commission;
  const hasInputs = priceNum > 0 && commVal && state;

  return (
    <div className="page-body">
      <PageHeader title="Rebate Calculator" subtitle="Estimate potential buyer rebate at closing." icon="calculator" />
      <section className="glass-card panel rebate-calc-panel">
        <div className="rebate-calc-tabs">
          {['Estimated', 'Actual', 'Seller Conversion'].map((label, idx) => (
            <button
              key={label}
              type="button"
              className={`rebate-calc-tab ${mode === idx ? 'active' : ''}`}
              onClick={() => setMode(idx)}
            >
              {label}
            </button>
          ))}
        </div>
        <div className="rebate-calc-form">
          <label htmlFor="rebate-price">Sales Price</label>
          <input id="rebate-price" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="e.g. 750,000" />
          <label htmlFor="rebate-state">State</label>
          <select id="rebate-state" value={state} onChange={(e) => setState(e.target.value)}>
            {allowedStates.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          {mode === 2 ? (
            <>
              <label htmlFor="rebate-orig-comm">Listing Agent Commission (LAC) %</label>
              <input id="rebate-orig-comm" type="text" value={originalCommission} onChange={(e) => setOriginalCommission(e.target.value)} placeholder="e.g. 2.5, 3.0" />
            </>
          ) : (
            <>
              <label htmlFor="rebate-comm">Buyer Agent Commission (BAC) %</label>
              <input id="rebate-comm" type="text" value={commission} onChange={(e) => setCommission(e.target.value)} placeholder="e.g. 2.5, 3.0" />
            </>
          )}
          <button className="btn primary" type="button" onClick={calculate} disabled={loading || !hasInputs}>
            {loading ? 'Calculating...' : 'Calculate'}
          </button>
        </div>
        {error ? <p className="error-text">{error}</p> : null}
        {result && result.success && !error ? (
          <div className="rebate-calc-result">
            <div className="rebate-result-header">
              <div className="rebate-result-icon">
                <IconGlyph name="calculator" filled />
              </div>
              <h3 className="rebate-result-title">
                {mode === 0 ? 'Estimated Rebate Results' : mode === 1 ? 'Exact Rebate Results' : 'Seller Conversion Results'}
              </h3>
            </div>

            {mode === 0 && (
              <div className="rebate-result-card rebate-result-estimated">
                {result.tier ? <span className="rebate-tier-badge">{result.tier}</span> : null}
                {result.rebatePercentage != null ? (
                  <div className="rebate-result-block">
                    <span className="rebate-label">Rebate Percentage</span>
                    <span className="rebate-value rebate-value-large">{result.rebatePercentage}%</span>
                  </div>
                ) : null}
                {(result.minRebate != null || result.maxRebate != null) && (
                  <div className="rebate-highlight-box">
                    <span className="rebate-label">Estimated Rebate Range</span>
                    <span className="rebate-value rebate-value-emphasis">
                      {result.minRebate != null ? `$${Math.round(result.minRebate).toLocaleString()}` : ''}
                      {result.isOrMore || result.maxRebate == null ? (result.minRebate != null ? ' or more' : '') : ` – $${Math.round(result.maxRebate).toLocaleString()}`}
                    </span>
                  </div>
                )}
                {(result.minCommission != null || result.maxCommission != null) && (
                  <div className="rebate-result-row">
                    <span className="rebate-label">Commission Range for Tier</span>
                    <span className="rebate-value">
                      {result.maxCommission != null
                        ? `${result.minCommission?.toFixed(2) ?? ''}% – ${result.maxCommission.toFixed(2)}%`
                        : `${result.minCommission?.toFixed(2) ?? ''}% or more`}
                    </span>
                  </div>
                )}
              </div>
            )}

            {mode === 1 && (
              <div className="rebate-result-card rebate-result-actual">
                {result.tier ? <span className="rebate-tier-badge">{result.tier}</span> : null}
                {result.rebatePercentage != null && (
                  <div className="rebate-result-row">
                    <span className="rebate-label">Rebate Percentage</span>
                    <span className="rebate-value rebate-value-green">{result.rebatePercentage}%</span>
                  </div>
                )}
                {(result.rebateAmountFormatted || result.minRebate != null) && (
                  <div className="rebate-highlight-box">
                    <span className="rebate-label">Your Rebate Amount</span>
                    <span className="rebate-value rebate-value-emphasis">
                      {ensureCurrency(result.rebateAmountFormatted) || `$${Math.round(result.minRebate || 0).toLocaleString()}`}
                    </span>
                  </div>
                )}
                {result.totalCommissionFormatted && (
                  <div className="rebate-result-row">
                    <span className="rebate-label">Total Commission</span>
                    <span className="rebate-value">{ensureCurrency(result.totalCommissionFormatted)}</span>
                  </div>
                )}
                {result.netAgentCommissionFormatted && (
                  <div className="rebate-result-row rebate-result-row-bold">
                    <span className="rebate-label">Net Agent Commission</span>
                    <span className="rebate-value rebate-value-blue">{ensureCurrency(result.netAgentCommissionFormatted)}</span>
                  </div>
                )}
              </div>
            )}

            {mode === 2 && (
              <div className="rebate-result-seller-wrap">
                <div className="rebate-result-card rebate-result-seller">
                  {result.tier ? <span className="rebate-tier-badge">{result.tier}</span> : null}
                  {result.rebatePercentage != null && (
                    <div className="rebate-result-row">
                      <span className="rebate-label">Rebate Percentage</span>
                      <span className="rebate-value rebate-value-green">{result.rebatePercentage}%</span>
                    </div>
                  )}
                  {result.originalCommissionAmountFormatted && (
                    <div className="rebate-result-row">
                      <span className="rebate-label">Original Commission</span>
                      <span className="rebate-value">{ensureCurrency(result.originalCommissionAmountFormatted)}</span>
                    </div>
                  )}
                  {result.newCommissionAmountFormatted && (
                    <div className="rebate-result-row">
                      <span className="rebate-label">New Commission Amount</span>
                      <span className="rebate-value rebate-value-blue">{ensureCurrency(result.newCommissionAmountFormatted)}</span>
                    </div>
                  )}
                  {(result.sellerSavingsFormatted || result.minRebate != null) && (
                    <div className="rebate-highlight-box">
                      <span className="rebate-label">Your Savings</span>
                      <span className="rebate-value rebate-value-emphasis">
                        {ensureCurrency(result.sellerSavingsFormatted) || `$${Math.round(result.minRebate || 0).toLocaleString()}`}
                      </span>
                    </div>
                  )}
                  {result.effectiveCommissionRateFormatted && (
                    <div className="rebate-result-row rebate-result-row-bold">
                      <span className="rebate-label">Effective Commission Rate</span>
                      <span className="rebate-value rebate-value-blue">
                        {result.effectiveCommissionRateFormatted.endsWith('%') ? result.effectiveCommissionRateFormatted : `${result.effectiveCommissionRateFormatted}%`}
                      </span>
                    </div>
                  )}
                </div>
                {(result.listingFeeForContract || result.simplifiedNote || result.simplifiedInstructions) && (
                  <div className="rebate-contract-box">
                    <h4 className="rebate-contract-title">For Your Listing Agreement</h4>
                    {result.listingFeeForContract && (
                      <div className="rebate-result-row rebate-result-row-bold">
                        <span className="rebate-label">Listing Fee</span>
                        <span className="rebate-value rebate-value-blue">{result.listingFeeForContract}</span>
                      </div>
                    )}
                    {result.simplifiedNote && <p className="rebate-contract-note">{result.simplifiedNote}</p>}
                    {result.simplifiedInstructions && <p className="rebate-contract-instr">{result.simplifiedInstructions}</p>}
                  </div>
                )}
              </div>
            )}

            {result.notes?.length > 0 && (
              <details className="rebate-notes-section">
                <summary>Additional Information</summary>
                <ul>{result.notes.map((n, i) => <li key={i}>{n}</li>)}</ul>
              </details>
            )}
            {result.instructions?.length > 0 && (
              <details className="rebate-notes-section">
                <summary>Instructions</summary>
                <ul>{result.instructions.map((n, i) => <li key={i}>{n}</li>)}</ul>
              </details>
            )}
            {result.warnings?.length > 0 && (
              <div className="rebate-warnings-section">
                <strong>Warnings</strong>
                <ul className="rebate-warnings">{result.warnings.map((w, i) => <li key={i}>{w}</li>)}</ul>
              </div>
            )}

            <div className="rebate-result-actions">
              <Link to="/app/find-agents" className="btn primary rebate-find-agents">
                <IconGlyph name="leads" />
                Find Agents
              </Link>
            </div>
          </div>
        ) : result && !result.success ? (
          <p className="error-text">Calculation could not be completed. Please check your inputs.</p>
        ) : hasInputs ? (
          <p className="rebate-empty-hint">Tap Calculate to see results</p>
        ) : (
          <p className="rebate-empty-hint">Enter price, commission, and state to calculate</p>
        )}
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

export function AddListingPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [form, setForm] = useState(LISTING_INITIAL_FORM);
  const [photos, setPhotos] = useState([]);
  const [claimedZips, setClaimedZips] = useState([]);
  const [licensedStates, setLicensedStates] = useState([]);
  const [citiesForState, setCitiesForState] = useState([]);
  const [loadingCities, setLoadingCities] = useState(false);
  const [listingCountForZip, setListingCountForZip] = useState(0);
  const [loadingListingCount, setLoadingListingCount] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [buyingSlot, setBuyingSlot] = useState(false);
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
    if (!form.zipCode || !userId) {
      setListingCountForZip(0);
      return;
    }
    let live = true;
    setLoadingListingCount(true);
    zipApi.getZipListingsCount(userId, form.zipCode)
      .then((count) => { if (live) setListingCountForZip(count); })
      .catch(() => { if (live) setListingCountForZip(0); })
      .finally(() => { if (live) setLoadingListingCount(false); });
    return () => { live = false; };
  }, [form.zipCode, userId]);

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

  const canAddFreeListing = listingCountForZip < FREE_LISTING_LIMIT;
  const remainingFree = Math.max(0, FREE_LISTING_LIMIT - listingCountForZip);

  const submit = async () => {
    if (!userId) return;
    if (!validateForm()) return;
    if (!canAddFreeListing) {
      showToast({ type: 'error', message: `You've used your ${FREE_LISTING_LIMIT} free listings for this ZIP. Buy an additional slot to add more.` });
      return;
    }
    setSubmitting(true);
    try {
      const payload = buildListingFormData(form, userId, photos);
      const res = await marketplaceApi.createListing(payload);
      const created = res?.listing ?? res?.data ?? res;
      const newListing = {
        id: created?._id ?? created?.id ?? `new-${Date.now()}`,
        name: form.propertyTitle?.trim() || created?.propertyTitle || 'Listing',
        preview: [form.city, form.state, form.zipCode].filter(Boolean).join(', ') + (form.price ? ` • $${Number(form.price).toLocaleString()}` : ''),
        raw: created || { propertyTitle: form.propertyTitle, city: form.city, state: form.state, zipCode: form.zipCode, price: form.price },
      };
      setForm({ ...LISTING_INITIAL_FORM, openHouses: [] });
      setPhotos([]);
      setListingCountForZip((c) => c + 1);
      showToast({ type: 'success', message: 'Listing created.' });
      navigate('/agent/listings', { state: { newListing } });
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to create listing.' });
    } finally {
      setSubmitting(false);
    }
  };

  const handleBuySlot = async () => {
    if (!userId) return;
    setBuyingSlot(true);
    try {
      const res = await marketplaceApi.createListingCheckout(userId);
      const url = res?.url || res?.data?.url;
      if (url) {
        window.location.assign(url);
      } else {
        showToast({ type: 'error', message: 'Unable to start checkout.' });
      }
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to buy slot.' });
    } finally {
      setBuyingSlot(false);
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
          {form.zipCode && (
            <div className="form-field listing-limit-info">
              {loadingListingCount ? (
                <small className="form-hint">Loading…</small>
              ) : (
                <small className="form-hint">
                  ZIP {form.zipCode}: {listingCountForZip}/{FREE_LISTING_LIMIT} free listings used.
                  {remainingFree > 0 ? ` ${remainingFree} free remaining.` : ' Buy an additional slot.'}
                </small>
              )}
            </div>
          )}
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
              <div className="form-field-loader"><AnimatedLoader variant="inline" label="Loading cities..." /></div>
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
          {!canAddFreeListing ? (
            <div className="listing-limit-reached">
              <p>You&apos;ve used your {FREE_LISTING_LIMIT} free listings for this ZIP code. Additional listings cost ${ADDITIONAL_LISTING_PRICE.toFixed(2)} per listing.</p>
              <button className="btn primary" type="button" onClick={handleBuySlot} disabled={buyingSlot} style={{ width: '100%', padding: '0.9rem' }}>
                Buy Listing Slot
              </button>
            </div>
          ) : (
            <button className="btn primary" type="button" onClick={submit} disabled={submitting} style={{ width: '100%', padding: '0.9rem' }}>
              Create Listing
            </button>
          )}
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

// App checklist data - matches lib/app/modules/checklist/controllers/checklist_controller.dart
export const BUYER_CHECKLIST = [
  'Get Pre-Approved\n\nFind a loan officer on our site who allows a rebate to be applied. Or, confirm your loan officer allows rebates.\n\nGet your pre-approval letter and know your budget.',
  'Choose Your Agent\n\nEvery agent on our site has agreed to give you a rebate when you work with them. You must work with an agent from this site in order to get a rebate.',
  'Search for Homes\n\nTour homes, compare, and pick your favorite. All homes listed on our site will note a likely rebate range if you were to buy that home. A rebate will work on any home for sale, even ones not listed on this site, where the seller, builder and/or listing agent is sharing part of the commission with the agent working with the Buyer. The rebate comes from that commission.',
  'Make an Offer\n\nWork with your agent to submit your offer and negotiate terms. You and your agent should include the BAC (Buyer Agent Commission) directly on the purchase agreement. Once you finalize the sales price and the BAC, you will be able to calculate your exact rebate.',
  'Inspection & Appraisal\n\nGet a home inspection and review results.\n\nYour lender will handle the appraisal.',
  'Finalize Financing & Rebate\n\nConfirm with your agent and lender that your rebate will appear on the closing disclosure.',
  'Closing Day\n\nSign papers, get your keys and your rebate — then celebrate!',
  'Leave Feedback (after closing)\n\nPlease leave feedback for your Agent and/or Loan Officer from this site. Leaving feedback helps recognize agents and loan officers who did a great job and builds their reputation on our site. Your review also helps future buyers and sellers choose trusted agents and loan officers who provide great service and honor their rebate commitment.',
];

// App rebate checklist data - matches lib/app/modules/rebate_checklist/controllers/rebate_checklist_controller.dart
export const REBATE_CHECKLIST_BUYING = [
  'Confirm State Eligibility: Verify that the buyer is purchasing or building in a state that allows real estate rebates. These 10 states currently do not allow real estate rebates: Alabama, Alaska, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, Tennessee, and Iowa.',
  'Prepare a Buyer Representation Agreement as you normally would and include the addendum below (or a similar version approved by your broker). (See attached sample form.)',
  'Verify Loan Officer and Lender Participation: Ensure the buyer is pre-approved with a loan officer whose lender allows real estate rebates. (Agents and buyers can search this site for a list of confirmed loan officers.)',
  'Coordinate Seller Concessions and Rebate Limits: Confirm with the buyer\'s loan officer whether "seller concessions" will be requested in the offer. Determine the maximum amount allowed, including the rebate, to ensure the buyer receives the full benefit. Some lenders handle seller concessions and rebates separately—clarify how the lender manages this. It\'s often helpful to review the numbers with the loan officer before submitting the offer.',
  'Review Special Financing Programs: If the buyer is using special financing programs (e.g., first-time homebuyer grants, state or city programs), note that some may restrict or prohibit rebates. Buyers must work with programs and lenders that allow rebates. Make sure buyers understand how their financing decisions may affect rebate eligibility.',
  'For New Construction Purchases: Confirm with the builder that rebates are allowed. Most builders permit them, but some may restrict or prohibit them. If an issue arises, contact us for alternative ideas to try.',
  'Notify the Title or Closing Company Early: Inform the title or closing company that the transaction will include a rebate. Experienced closers will know how to properly document this, though some may need to confirm internal procedures. The rebate should appear on the settlement statement as a credit to the buyer.',
  'Calculate and Verify the Rebate Amount: Use the Rebate Calculator on the site to determine the rebate amount. Buyers also have access to this tool. Because the rebate may change during negotiations, confirm the final amount once the offer is accepted and all contingencies are removed.',
  'Include Rebate Disclosure and Commission Split in the Offer: When submitting an offer, include the rebate disclosure and commission split language (or broker-approved equivalent).',
];

export const REBATE_CHECKLIST_SELLING = [
  'Confirm Rebate Eligibility: Verify that the property is located in a state that allows real estate rebates. Currently, 11 states do not allow rebates when selling: Alabama, Alaska, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, Tennessee, New Jersey, and Iowa.',
  'Complete your listing agreement as you normally would. Then, include and complete a Listing Agent Rebate Disclosure Addendum/Amendment to document the rebate option you and the Seller have selected. (You may use the sample document provided below or your own broker-approved language.) Be sure that both you and the Seller(s) sign the Rebate Addendum/Amendment and that it is included with the signed listing agreement.',
  'Notify the Title/Closing Company: Contact the title or closing company early to let them know a rebate will be part of the transaction. Confirm any special documentation or instructions they may require. The rebate should appear on the settlement statement as a credit to the Seller if the rebate option is chosen.',
  'Confirm Final Rebate or Fee Reduction Amount: Use the "Seller Conversion" calculator tab in the Rebate Calculator on GetaRebate.com to determine the correct amount or fee. Adjust the amount if the final commission or negotiated terms change.',
  'After Closing: Encourage the Seller to leave feedback on your GetaRebate.com profile — this helps build your reputation and visibility. If a rebate was given, the actual rebate amount will show on the settlement statement and the closer should point it out to the Seller at closing. If you used the lower listing fee option, use the calculator to show what that savings equates to. It\'s best that the seller knows the dollar amount they ended up saving so they can tell friends to refer you to!',
];

const SELLER_CHECKLIST = [
  'Choose Your Agent\n\nAll agents on our site have agreed to offer a rebate when you work with them.\n\nThe rebate can either be a credit to you at closing, or, the easiest option is to adjust the listing fee by calculating in the rebate.\n\nSelect an experienced agent who knows your market.',
  'Prepare Your Home\n\nDeclutter, clean, and make small repairs.\n\nBoost curb appeal with simple touches (fresh paint, yard cleanup).',
  'Set the Price\n\nReview a market analysis with your agent.\n\nPrice your home competitively to attract buyers.',
  'List & Market Your Home\n\nYour agent will list your home on the MLS and major websites.\n\nKeep your home showing-ready at all times.',
  'Review Offers\n\nCompare offers carefully — not just price, but terms and timing.\n\nWork with your agent to negotiate the best deal.',
  'Inspection & Appraisal\n\nBe prepared for the buyer\'s inspection and possible repair requests.\n\nCooperate with the appraiser for smooth processing.',
  'Closing Preparation\n\nReview your closing statement and confirm your rebate amount.\n\nGather keys, warranties, and utility info for the buyer.',
  'Closing Day\n\nSign documents, hand over the keys, and enjoy your rebate savings!',
  'Leave Feedback (after closing)\n\nPlease leave feedback for your Agent from this site. Leaving feedback helps recognize agents who did a great job and builds their reputation on our site. Your review also helps future buyers and sellers choose trusted agents who provide great service and honor their rebate commitment.',
];

const BUYER_ACTIONS = { 0: 'search_loan_officer', 1: 'search_agents', 2: 'search_homes', 3: 'calculate_rebate', 7: 'leave_review' };
const SELLER_ACTIONS = { 0: 'search_agents', 8: 'leave_review' };

function ChecklistConsumer({ type, navigate }) {
  const isBuyer = type !== 'seller';
  const items = isBuyer ? BUYER_CHECKLIST : SELLER_CHECKLIST;
  const actions = isBuyer ? BUYER_ACTIONS : SELLER_ACTIONS;
  const title = isBuyer ? 'Home Buyer Checklist (with Rebate!)' : 'Home Seller Checklist (with Rebate!)';
  const subtitle = isBuyer
    ? 'Follow these steps to buy a home and receive your rebate!'
    : 'Follow these steps to sell your home and save on fees!';

  const handleAction = (action) => {
    if (action === 'search_loan_officer') navigate('/app', { state: { tab: 'loanOfficers' } });
    else if (action === 'search_agents') navigate('/app', { state: { tab: 'agents' } });
    else if (action === 'search_homes') navigate('/app', { state: { tab: 'homes' } });
    else if (action === 'calculate_rebate') navigate('/rebate-calculator');
    else if (action === 'leave_review') navigate('/post-closing-survey');
  };

  const actionLabels = {
    search_loan_officer: 'Search for Loan Officers',
    search_agents: 'Search for Agents',
    search_homes: 'Search for Homes',
    calculate_rebate: 'Calculate Rebate',
    leave_review: 'Leave Review',
  };

  return (
    <div className="page-body">
      <PageHeader title={title} subtitle={subtitle} icon="checklist" />
      <section className="glass-card panel checklist-consumer">
        <div className="checklist-consumer-header">
          <IconGlyph name="checklist" filled />
          <div>
            <h3>{title}</h3>
            <p>{subtitle}</p>
          </div>
        </div>
        <ol className="checklist-consumer-items">
          {items.map((text, idx) => (
            <li key={idx} className="checklist-consumer-item">
              <span className="checklist-num">{idx + 1}</span>
              <div className="checklist-text-wrap">
                <span className="checklist-text">{text}</span>
                {actions[idx] && (
                  <button
                    type="button"
                    className="btn outline checklist-action"
                    onClick={() => handleAction(actions[idx])}
                  >
                    {actionLabels[actions[idx]]}
                  </button>
                )}
              </div>
            </li>
          ))}
        </ol>
        <div className="checklist-consumer-note">
          <IconGlyph name="info" />
          <p>
            {isBuyer
              ? 'The rebate will typically be a credit to you at closing and will be clearly displayed on the Settlement Statement at closing. It is possible that a rebate will not be allowed depending on loan programs, choice of builder, etc. but it is rare if you and your agent follow the necessary steps. All Agents on this site have access to a more detailed checklist so rebate compliance is met.'
              : 'Most agents and sellers will elect to go with the instant lower listing fee calculating in the rebate. See the rebate calculator. If you elect to go with the rebate at closing on the Settlement Statement, all Agents on this site have access to a more detailed checklist so rebate compliance is met.'}
          </p>
          {!isBuyer && (
            <button type="button" className="btn outline" onClick={() => navigate('/rebate-calculator', { state: { mode: 2 } })}>
              See Rebate Calculator
            </button>
          )}
        </div>
      </section>
    </div>
  );
}

export function ChecklistPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const type = searchParams.get('type') || 'buyer';
  return <ChecklistConsumer type={type} navigate={navigate} />;
}

function professionalToItem(p) {
  return {
    id: p.id,
    name: p.name,
    type: p.type,
    company: p.company,
    profileImage: p.profileImage,
    leadId: p.leadId,
    completedAt: p.completedAt,
  };
}

export function PostClosingSurveyPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const navigate = useNavigate();
  const [agents, setAgents] = useState([]);
  const [loanOfficers, setLoanOfficers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTab, setSelectedTab] = useState(0);
  const [selectedProfessional, setSelectedProfessional] = useState(null);
  const [agentSearch, setAgentSearch] = useState('');
  const [loSearch, setLoSearch] = useState('');
  const [surveyStep, setSurveyStep] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  // Agent survey state
  const [rebateAmount, setRebateAmount] = useState('');
  const [receivedExpectedRebate, setReceivedExpectedRebate] = useState('');
  const [rebateAppliedAsCredit, setRebateAppliedAsCredit] = useState('');
  const [rebateAppliedOther, setRebateAppliedOther] = useState('');
  const [signedRebateDisclosure, setSignedRebateDisclosure] = useState('');
  const [receivingRebateEasy, setReceivingRebateEasy] = useState('');
  const [agentRecommended, setAgentRecommended] = useState('');
  const [agentComment, setAgentComment] = useState('');
  const [agentRating, setAgentRating] = useState(2.5);
  // Loan officer survey state
  const [loSatisfaction, setLoSatisfaction] = useState(2.5);
  const [loExplainedOptions, setLoExplainedOptions] = useState('');
  const [loCommunication, setLoCommunication] = useState('');
  const [loRebateHelp, setLoRebateHelp] = useState('');
  const [loEase, setLoEase] = useState('');
  const [loProfessional, setLoProfessional] = useState('');
  const [loClosedOnTime, setLoClosedOnTime] = useState('');
  const [loRecommend, setLoRecommend] = useState('');
  const [loLoanType, setLoLoanType] = useState('');
  const [loLoanTypeOther, setLoLoanTypeOther] = useState('');
  const [loComment, setLoComment] = useState('');
  const { showToast } = useToast();

  useEffect(() => {
    if (selectedProfessional) {
      setSurveyStep(0);
      setRebateAmount('');
      setReceivedExpectedRebate('');
      setRebateAppliedAsCredit('');
      setRebateAppliedOther('');
      setSignedRebateDisclosure('');
      setReceivingRebateEasy('');
      setAgentRecommended('');
      setAgentComment('');
      setAgentRating(2.5);
      setLoSatisfaction(2.5);
      setLoExplainedOptions('');
      setLoCommunication('');
      setLoRebateHelp('');
      setLoEase('');
      setLoProfessional('');
      setLoClosedOnTime('');
      setLoRecommend('');
      setLoLoanType('');
      setLoLoanTypeOther('');
      setLoComment('');
    }
  }, [selectedProfessional?.id]);

  useEffect(() => {
    let live = true;
    const load = async () => {
      if (!userId) {
        setLoading(false);
        return;
      }
      setLoading(true);
      try {
        const [agentsRes, loRes] = await Promise.allSettled([
          marketplaceApi.getAllAgents(1),
          marketplaceApi.getLoanOfficers(),
        ]);

        const agentsData = agentsRes.status === 'fulfilled' ? agentsRes.value : null;
        const rawAgents = unwrapList(agentsData, ['agents', 'data']) || (agentsData?.agents ?? agentsData?.data ?? []);
        const agentList = (rawAgents || []).map((a) => professionalToItem({
          id: a?._id || a?.id,
          name: a?.fullname || a?.name || 'Agent',
          type: 'agent',
          company: a?.company,
          profileImage: a?.profilePic || a?.profileImage,
          leadId: null,
          completedAt: a?.lastActiveAt || a?.createdAt,
        })).filter((x) => x.id).sort((a, b) => (a.name || '').localeCompare(b.name || '', undefined, { sensitivity: 'base' }));

        const los = loRes.status === 'fulfilled' ? unwrapList(loRes.value, ['loanOfficers', 'data']) : [];
        const loList = (los || []).map((lo) => professionalToItem({
          id: lo?._id || lo?.id,
          name: lo?.fullname || lo?.name || 'Loan Officer',
          type: 'loanOfficer',
          company: lo?.company,
          profileImage: lo?.profilePic || lo?.profileImage,
          leadId: null,
          completedAt: lo?.lastActiveAt || lo?.createdAt,
        })).filter((l) => l.id).sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));

        if (live) {
          setAgents(agentList);
          setLoanOfficers(loList);
        }
      } catch {
        if (live) {
          setAgents([]);
          setLoanOfficers([]);
        }
      } finally {
        if (live) setLoading(false);
      }
    };
    load();
    return () => { live = false; };
  }, [userId]);

  const filterBySearch = (list, q) => {
    const qq = (q || '').trim().toLowerCase();
    if (!qq) return list;
    return list.filter((p) =>
      (p.name || '').toLowerCase().includes(qq) ||
      (p.company || '').toLowerCase().includes(qq)
    );
  };

  const filteredAgents = filterBySearch(agents, agentSearch);
  const filteredLos = filterBySearch(loanOfficers, loSearch);
  const professionals = selectedTab === 0 ? filteredAgents : filteredLos;
  const hasAny = agents.length > 0 || loanOfficers.length > 0;

  const isAgentSurvey = selectedProfessional?.type === 'agent';
  const totalSteps = isAgentSurvey ? 8 : 10;

  const canProceed = () => {
    if (isAgentSurvey) {
      switch (surveyStep) {
        case 0: return Number(rebateAmount) > 0;
        case 1: return !!receivedExpectedRebate;
        case 4: return !!receivingRebateEasy;
        case 7: return agentRating > 0;
        default: return true;
      }
    } else {
      return surveyStep === 0 ? loSatisfaction > 0 : true;
    }
  };

  const handleSurveyBack = () => {
    if (surveyStep > 0) setSurveyStep((s) => s - 1);
    else setSelectedProfessional(null);
  };

  const handleSurveyNext = () => {
    if (surveyStep < totalSteps - 1) setSurveyStep((s) => s + 1);
  };

  const handleSurveySubmit = async () => {
    if (!userId || !selectedProfessional) return;
    setSubmitting(true);
    const rating = isAgentSurvey ? agentRating : loSatisfaction;
    const comment = isAgentSurvey ? agentComment : loComment;
    const reviewText = comment?.trim() || (isAgentSurvey ? 'Great support and communication throughout the process.' : 'Excellent loan guidance and professional support.');
    try {
      if (isAgentSurvey) {
        const rebateMethod = rebateAppliedAsCredit === 'Other' && rebateAppliedOther?.trim()
          ? rebateAppliedOther.trim()
          : (rebateAppliedAsCredit || 'Other');
        await surveyApi.submitAgentSurvey({
          userId,
          rebateFromAgent: Number(rebateAmount) || 0,
          receivedExpectedRebate: receivedExpectedRebate || 'Not sure',
          rebateAppliedAsCreditClosing: rebateMethod,
          signedRebateDisclosure: signedRebateDisclosure || 'Not sure',
          receivingRebateEasy: receivingRebateEasy || 'Neutral',
          agentRecommended: agentRecommended || 'Not sure',
          ...(comment?.trim() ? { comment: comment.trim() } : {}),
          rating,
        });
      } else {
        await surveyApi.submitLoanSurvey({
          userId,
          loSatisfaction,
          loExplainedOptions: loExplainedOptions || '',
          loCommunication: loCommunication || '',
          loRebateHelp: loRebateHelp || '',
          loEase: loEase || '',
          loProfessional: loProfessional || '',
          loClosedOnTime: loClosedOnTime || '',
          loRecommend: loRecommend || '',
          rating,
        });
      }
      try {
        await surveyApi.addReview({
          currentUserId: userId,
          agentId: selectedProfessional.id,
          rating: Math.round(rating),
          review: reviewText,
        });
      } catch (_) {}
      showToast({ type: 'success', message: 'Thank you! Your review has been submitted successfully.' });
      setSelectedProfessional(null);
      setSurveyStep(0);
      navigate('/app');
    } catch (err) {
      showToast({ type: 'error', message: err?.message || 'Failed to submit survey.' });
    } finally {
      setSubmitting(false);
    }
  };

  const RadioGroup = ({ options, value, onChange, hasOther, otherValue, onOtherChange }) => (
    <div className="survey-radio-group">
      {options.map((opt) => (
        <label key={opt} className="survey-radio-option">
          <input type="radio" name={`q-${surveyStep}`} checked={value === opt} onChange={() => onChange(opt)} />
          <span>{opt}</span>
        </label>
      ))}
      {hasOther && value === 'Other' && (
        <input
          type="text"
          className="survey-other-input"
          placeholder="Please explain"
          value={otherValue}
          onChange={(e) => onOtherChange?.(e.target.value)}
        />
      )}
    </div>
  );

  const QuestionCard = ({ title, required, children }) => (
    <div className={`survey-question-card ${required ? 'required' : ''}`}>
      <h4>{title}{required ? ' *' : ''}</h4>
      {children}
    </div>
  );

  if (selectedProfessional) {
    return (
      <div className="page-body">
        <div className="post-survey-page-wrap">
        <PageHeader
          title={isAgentSurvey ? 'Rate Your Agent' : 'Rate Loan Officer'}
          subtitle="Leave feedback after closing"
          icon="star"
        />
        <section className="glass-card panel post-survey-form">
          <div className="post-survey-form-header">
            <div className="post-survey-avatar-wrap">
              {selectedProfessional.profileImage ? (
                <img src={firstImageFromEntity({ profilePic: selectedProfessional.profileImage }) || ''} alt="" className="post-survey-avatar" onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling?.classList.remove('hidden'); }} />
              ) : null}
              <div className={`post-survey-avatar-placeholder ${selectedProfessional.profileImage ? 'hidden' : ''}`}>
                <IconGlyph name={isAgentSurvey ? 'person' : 'accountBalance'} />
              </div>
            </div>
            <div>
              <h3>{selectedProfessional.name}</h3>
              {selectedProfessional.company ? <p className="post-survey-company">{selectedProfessional.company}</p> : null}
            </div>
          </div>
          <div className="survey-progress">
            <div className="survey-progress-row">
              <span>Question {surveyStep + 1} of {totalSteps}</span>
              <span className="survey-progress-pct">{Math.round(((surveyStep + 1) / totalSteps) * 100)}%</span>
            </div>
            <div className="survey-progress-bar">
              <div className="survey-progress-fill" style={{ width: `${((surveyStep + 1) / totalSteps) * 100}%` }} />
            </div>
          </div>
          <div className="survey-questions">
            {isAgentSurvey ? (
              <>
                {surveyStep === 0 && (
                  <QuestionCard title="How much was your rebate from your agent?" required>
                    <input type="number" placeholder="0.00" value={rebateAmount} onChange={(e) => setRebateAmount(e.target.value)} className="survey-money-input" />
                  </QuestionCard>
                )}
                {surveyStep === 1 && (
                  <QuestionCard title="Did you receive the rebate you expected?" required>
                    <RadioGroup options={['Yes', 'No', 'Not sure']} value={receivedExpectedRebate} onChange={setReceivedExpectedRebate} />
                  </QuestionCard>
                )}
                {surveyStep === 2 && (
                  <QuestionCard title="Was rebate applied as credit at closing?">
                    <RadioGroup options={['Yes', 'No', 'Other', 'Lower listing fee (selling only)']} value={rebateAppliedAsCredit} onChange={setRebateAppliedAsCredit} hasOther otherValue={rebateAppliedOther} onOtherChange={setRebateAppliedOther} />
                  </QuestionCard>
                )}
                {surveyStep === 3 && (
                  <QuestionCard title="Did you sign the rebate disclosure?">
                    <RadioGroup options={['Yes', 'No', 'Not sure']} value={signedRebateDisclosure} onChange={setSignedRebateDisclosure} />
                  </QuestionCard>
                )}
                {surveyStep === 4 && (
                  <QuestionCard title="Was receiving your rebate easy?" required>
                    <RadioGroup options={['Very easy', 'Somewhat easy', 'Neutral', 'Difficult']} value={receivingRebateEasy} onChange={setReceivingRebateEasy} />
                  </QuestionCard>
                )}
                {surveyStep === 5 && (
                  <QuestionCard title="Would you recommend your agent?">
                    <RadioGroup options={['Definitely', 'Probably', 'Not sure', 'Probably not', 'Definitely not']} value={agentRecommended} onChange={setAgentRecommended} />
                  </QuestionCard>
                )}
                {surveyStep === 6 && (
                  <QuestionCard title="Anything else to share?">
                    <textarea placeholder="Optional comments..." rows={4} value={agentComment} onChange={(e) => setAgentComment(e.target.value)} />
                  </QuestionCard>
                )}
                {surveyStep === 7 && (
                  <QuestionCard title="Overall satisfaction with agent" required>
                    <div className="survey-slider-wrap">
                      <span className="survey-slider-value">{agentRating.toFixed(1)} / 5.0</span>
                      <input type="range" min="0.5" max="5" step="0.1" value={agentRating} onChange={(e) => setAgentRating(parseFloat(e.target.value))} />
                      <div className="survey-slider-labels"><span>Poor</span><span>Excellent</span></div>
                    </div>
                  </QuestionCard>
                )}
              </>
            ) : (
              <>
                {surveyStep === 0 && (
                  <QuestionCard title="How satisfied with loan officer?" required>
                    <div className="survey-slider-wrap">
                      <span className="survey-slider-value">{loSatisfaction.toFixed(1)} / 5.0</span>
                      <input type="range" min="0.5" max="5" step="0.1" value={loSatisfaction} onChange={(e) => setLoSatisfaction(parseFloat(e.target.value))} />
                      <div className="survey-slider-labels"><span>Poor</span><span>Excellent</span></div>
                    </div>
                  </QuestionCard>
                )}
                {surveyStep === 1 && (
                  <QuestionCard title="Explained loan options clearly?">
                    <RadioGroup options={['Yes', 'Somewhat', 'No']} value={loExplainedOptions} onChange={setLoExplainedOptions} />
                  </QuestionCard>
                )}
                {surveyStep === 2 && (
                  <QuestionCard title="Communication clear & timely?">
                    <RadioGroup options={['Always', 'Most of time', 'Occasionally', 'Rarely']} value={loCommunication} onChange={setLoCommunication} />
                  </QuestionCard>
                )}
                {surveyStep === 3 && (
                  <QuestionCard title="Helped with rebate?">
                    <RadioGroup options={['Yes', 'Somewhat', 'No', 'Not applicable']} value={loRebateHelp} onChange={setLoRebateHelp} />
                  </QuestionCard>
                )}
                {surveyStep === 4 && (
                  <QuestionCard title="Loan process easy?">
                    <RadioGroup options={['Very easy', 'Somewhat easy', 'Neutral', 'Difficult']} value={loEase} onChange={setLoEase} />
                  </QuestionCard>
                )}
                {surveyStep === 5 && (
                  <QuestionCard title="Knowledgeable & professional?">
                    <RadioGroup options={['Yes', 'Somewhat', 'No']} value={loProfessional} onChange={setLoProfessional} />
                  </QuestionCard>
                )}
                {surveyStep === 6 && (
                  <QuestionCard title="Closed on time?">
                    <RadioGroup options={['Yes', 'No', 'Not sure']} value={loClosedOnTime} onChange={setLoClosedOnTime} />
                  </QuestionCard>
                )}
                {surveyStep === 7 && (
                  <QuestionCard title="Recommend loan officer?">
                    <RadioGroup options={['Definitely', 'Probably', 'Not sure', 'Probably not', 'Definitely not']} value={loRecommend} onChange={setLoRecommend} />
                  </QuestionCard>
                )}
                {surveyStep === 8 && (
                  <QuestionCard title="Loan type?">
                    <RadioGroup options={['Conventional', 'FHA', 'VA', 'USDA', 'Jumbo', 'Other']} value={loLoanType} onChange={setLoLoanType} hasOther otherValue={loLoanTypeOther} onOtherChange={setLoLoanTypeOther} />
                  </QuestionCard>
                )}
                {surveyStep === 9 && (
                  <QuestionCard title="Additional comments?">
                    <textarea placeholder="Optional comments..." rows={4} value={loComment} onChange={(e) => setLoComment(e.target.value)} />
                  </QuestionCard>
                )}
              </>
            )}
          </div>
          <div className="survey-nav">
            <button type="button" className="btn ghost" onClick={handleSurveyBack} disabled={submitting}>
              {surveyStep === 0 ? 'Back to Selection' : 'Back'}
            </button>
            {surveyStep === totalSteps - 1 ? (
              <button type="button" className="btn primary" onClick={handleSurveySubmit} disabled={submitting || !canProceed()}>
                {submitting ? 'Submitting...' : 'Submit'}
              </button>
            ) : (
              <button type="button" className="btn primary" onClick={handleSurveyNext} disabled={!canProceed()}>
                Next
              </button>
            )}
          </div>
        </section>
        </div>
      </div>
    );
  }

  return (
    <div className="page-body">
      <div className="post-survey-page-wrap">
      <PageHeader
        title="Select Professional to Review"
        subtitle="Pick an Agent or Loan Officer and submit your feedback after closing"
        icon="star"
      />
      {loading ? <AnimatedLoader variant="card" label="Loading professionals..." /> : null}
      {!loading && !hasAny ? (
        <section className="glass-card panel post-survey-empty">
          <div className="post-survey-empty-icon">
            <IconGlyph name="info" />
          </div>
          <h3>No Professionals Available</h3>
          <p>No agents or loan officers are available to review at this time.</p>
          <button type="button" className="btn primary" onClick={() => navigate('/app')}>Back to Home</button>
        </section>
      ) : null}
      {!loading && hasAny ? (
        <section className="glass-card panel post-survey-panel">
          <div className="post-survey-tabs">
            <button type="button" className={`post-survey-tab ${selectedTab === 0 ? 'active agent' : ''}`} onClick={() => setSelectedTab(0)}>
              Agents ({agents.length})
            </button>
            <button type="button" className={`post-survey-tab ${selectedTab === 1 ? 'active lo' : ''}`} onClick={() => setSelectedTab(1)}>
              Loan Officers ({loanOfficers.length})
            </button>
          </div>
          <div className="post-survey-search">
            <input
              type="search"
              placeholder={selectedTab === 0 ? 'Search agents' : 'Search loan officers'}
              value={selectedTab === 0 ? agentSearch : loSearch}
              onChange={(e) => (selectedTab === 0 ? setAgentSearch(e.target.value) : setLoSearch(e.target.value))}
            />
          </div>
          {professionals.length === 0 ? (
            <p className="post-survey-no-match">
              {selectedTab === 0 ? 'No matching agents found' : 'No matching loan officers found'}
            </p>
          ) : (
            <ul className="post-survey-list">
              {professionals.map((p) => (
                <li key={p.id}>
                  <button type="button" className="post-survey-card" onClick={() => setSelectedProfessional(p)}>
                    <div className="post-survey-card-avatar">
                      {p.profileImage ? (
                        <img src={firstImageFromEntity({ profilePic: p.profileImage }) || ''} alt="" onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling?.classList.remove('hidden'); }} />
                      ) : null}
                      <div className={`post-survey-card-placeholder ${p.profileImage ? 'hidden' : ''}`}>
                        <IconGlyph name={p.type === 'agent' ? 'person' : 'accountBalance'} />
                      </div>
                    </div>
                    <div className="post-survey-card-info">
                      <span className="post-survey-name">{p.name}</span>
                      {p.company ? <span className="post-survey-company">{p.company}</span> : null}
                      <span className={`post-survey-type-badge small ${p.type === 'agent' ? 'agent' : 'lo'}`}>
                        {p.type === 'agent' ? 'Agent' : 'Loan Officer'}
                      </span>
                    </div>
                    <span className="post-survey-card-arrow">
                      <IconGlyph name="openInNew" />
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </section>
      ) : null}
      </div>
    </div>
  );
}

export function RebateChecklistPage() {
  return (
    <div className="page-body">
      <PageHeader title="Rebate Checklist" subtitle="Agent and loan officer rebate compliance checklists" icon="checklist" />
      <section className="glass-card panel checklist-section">
        <h3 className="checklist-section-title"><IconGlyph name="checklist" /> Rebate Checklists</h3>
        <div className="checklist-cards-grid">
          <div className="checklist-card checklist-card--blue">
            <div className="checklist-card-header">
              <IconGlyph name="checklist" filled />
              <h4>Real Estate Agent Rebate Checklist – Buying/Building (Agent view)</h4>
            </div>
            <ol className="checklist-items">
              {REBATE_CHECKLIST_BUYING.map((item, i) => (
                <li key={i} className="checklist-item"><span className="checklist-num">{i + 1}</span><span className="checklist-text">{item}</span></li>
              ))}
            </ol>
          </div>
          <div className="checklist-card checklist-card--green">
            <div className="checklist-card-header">
              <IconGlyph name="checklist" filled />
              <h4>Rebate Checklist for Selling (Agent view)</h4>
            </div>
            <ol className="checklist-items">
              {REBATE_CHECKLIST_SELLING.map((item, i) => (
                <li key={i} className="checklist-item"><span className="checklist-num">{i + 1}</span><span className="checklist-text">{item}</span></li>
              ))}
            </ol>
          </div>
        </div>
      </section>
    </div>
  );
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
  const contextPropertyAddress = location.state?.propertyAddress || null;

  const [form, setForm] = useState({
    fullname: user?.fullname || user?.name || '',
    email: user?.email || '',
    phone: user?.phone || '',
    zipCode: '',
    budgetRange: '',
    timeline: '',
    notes: '',
    preferredContact: 'Email',
    bestTime: '',
    lookingTo: 'Buy existing home',
    currentlyLiving: '',
    propertyType: '',
    priceRange: '',
    bedrooms: '',
    bathrooms: '',
    timeFrame: '',
    workingWithAgent: '',
    preApproved: '',
    searchForLoanOfficers: '',
    rebateAwareness: '',
    howHeard: '',
  });
  const [status, setStatus] = useState('');
  const { showToast } = useToast();

  const agentId = contextAgent?._id || contextAgent?.id;
  const loanOfficerId = contextLoanOfficer?._id || contextLoanOfficer?.id;
  const listingId = contextListing?.listingId || contextListing?._id || contextListing?.id;
  const propertyAddress = contextPropertyAddress
    || (typeof contextListing?.address === 'string' ? contextListing.address : null)
    || contextListing?.title
    || (contextListing?.streetAddress ? [contextListing.streetAddress, contextListing.city, contextListing.state, contextListing.zipCode].filter(Boolean).join(', ') : null);

  const submit = async () => {
    if (!userId) {
      showToast({ type: 'error', message: 'Please sign in to submit a lead.' });
      return;
    }
    if (leadType === 'buyer' && !agentId && !loanOfficerId) {
      showToast({ type: 'error', message: 'Agent or Loan Officer is required. Go to Home or Find Agents, then tap Contact on an agent.' });
      return;
    }
    if (leadType === 'buyer' && agentId && !form.fullname?.trim()) {
      showToast({ type: 'error', message: 'Full name is required.' });
      return;
    }
    if (leadType === 'buyer' && agentId && !form.email?.trim()) {
      showToast({ type: 'error', message: 'Email is required.' });
      return;
    }
    if (leadType === 'buyer' && agentId && !form.phone?.trim()) {
      showToast({ type: 'error', message: 'Phone is required.' });
      return;
    }
    setStatus('Submitting lead...');
    try {
      const payload = {
        leadType,
        agentId: agentId || undefined,
        currentUserId: userId,
        userId,
        buyerId: userId,
        loanOfficerId: loanOfficerId || undefined,
        listingId: listingId || undefined,
        propertyAddress: propertyAddress || undefined,
        fullName: form.fullname?.trim(),
        fullname: form.fullname?.trim(),
        email: form.email?.trim(),
        phone: form.phone?.trim(),
        preferredContact: (form.preferredContact || 'email').toLowerCase(),
        bestTime: form.bestTime || undefined,
        buyingOrBuilding: form.lookingTo?.toLowerCase().includes('build') ? 'building' : 'buying',
        propertyType: form.propertyType || undefined,
        priceRange: form.priceRange || form.budgetRange || undefined,
        bedrooms: form.bedrooms ? parseInt(form.bedrooms, 10) : undefined,
        bathrooms: form.bathrooms ? parseFloat(form.bathrooms) : undefined,
        timeFrame: form.timeFrame || form.timeline || undefined,
        workingWithAgent: form.workingWithAgent?.toLowerCase() === 'yes',
        preApproved: form.preApproved || undefined,
        searchForLoanOfficers: form.searchForLoanOfficers || undefined,
        rebateAwareness: form.rebateAwareness || undefined,
        howHeard: form.howHeard || undefined,
        comments: form.notes?.trim() || undefined,
      };
      await leadsApi.createLead(payload);
      setStatus('Lead submitted successfully.');
      showToast({ type: 'success', message: 'A local agent will contact you soon.' });
    } catch (err) {
      const msg = err.message || 'Unable to submit lead.';
      setStatus(msg);
      showToast({ type: 'error', message: msg });
    }
  };

  return (
    <div className="page-body">
      <PageHeader title={title} subtitle={subtitle} icon="profile" />
      <section className="glass-card panel form-stack lead-form-card">
        <h4>Contact Information</h4>
        <FormCard
          form={form}
          onChange={setForm}
          fields={[
            ['fullname', 'Full Name *'],
            ['email', 'Email *'],
            ['phone', 'Phone *'],
            ['preferredContact', 'Preferred Contact (Call, Text, Email)'],
            ['zipCode', 'Where are you planning to buy? (ZIP)'],
            ['budgetRange', 'Budget / Price Range'],
            ['timeline', 'Time Frame'],
            ['notes', 'Anything else you\'d like your agent to know?'],
          ]}
          onSubmit={submit}
          status={status}
        />
        {(contextAgent || contextLoanOfficer) && (
          <p className="lead-form-context">
            {contextAgent ? `Connecting with agent: ${contextAgent?.fullname || contextAgent?.name || 'Agent'}` : null}
            {contextLoanOfficer ? `Connecting with loan officer: ${contextLoanOfficer?.fullname || contextLoanOfficer?.name || 'Loan Officer'}` : null}
          </p>
        )}
      </section>
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
