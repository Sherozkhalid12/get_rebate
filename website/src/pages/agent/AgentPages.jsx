import { useEffect, useMemo, useState } from 'react';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { StateSelect, parseLicensedStates } from '../../components/ui/StateSelect';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { ActionTiles, KpiGrid, ListPanel } from '../shared/FeatureCards';
import { useToast } from '../../components/ui/ToastProvider';
import { useNavigate, Link } from 'react-router-dom';
import { FirstZipClaimDialog } from '../../components/dialogs/FirstZipClaimDialog';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject, extractUserFromGetUserById } from '../../lib/api';
import * as marketplaceApi from '../../api/marketplace';
import * as zipApi from '../../api/zipcodes';
import { getZipClaimedMessage } from '../../api/zipcodes';
import { calculatePriceForPopulation } from '../../lib/zipCodePricing';
import * as leadsApi from '../../api/leads';
import * as userApi from '../../api/user';

const LISTING_EDIT_INITIAL_FORM = {
  propertyTitle: '',
  description: '',
  price: '',
  streetAddress: '',
  city: '',
  state: '',
  zipCode: '',
  BACPercentage: '2.5',
  listingAgent: 'false',
  dualAgencyAllowed: 'false',
  status: 'active',
  propertyType: 'house',
  bedrooms: '',
  bathrooms: '',
  squareFeet: '',
  propertyFeatures: '',
};

function parseApiBoolean(value, fallback = false) {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true') return true;
    if (normalized === 'false') return false;
  }
  return fallback;
}

const AGENT_ZIP_SKIPPED_KEY = 'agent_zip_skipped';

export function AgentDashboardPage() {
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  const userId = resolveUserId(user);
  const [kpis, setKpis] = useState([
    { label: 'Claimed ZIP Codes', value: '0' },
    { label: 'Monthly Leads', value: '0' },
    { label: 'Listing Views', value: '0' },
    { label: 'Contact Rate', value: '0%' },
  ]);
  const firstZipFromAuth = user?.firstZipCodeClaimed;
  const [showZipDialog, setShowZipDialog] = useState(false);

  useEffect(() => {
    if (firstZipFromAuth === false && !localStorage.getItem(AGENT_ZIP_SKIPPED_KEY)) {
      setShowZipDialog(true);
    } else if (firstZipFromAuth === true || localStorage.getItem(AGENT_ZIP_SKIPPED_KEY)) {
      setShowZipDialog(false);
    }
  }, [firstZipFromAuth]);

  useEffect(() => {
    let live = true;
    const check = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        const profile = extractUserFromGetUserById(res);
        const firstZipCodeClaimed = profile?.firstZipCodeClaimed;
        const skipped = localStorage.getItem(AGENT_ZIP_SKIPPED_KEY);
        if (!live) return;
        if (firstZipCodeClaimed === false && !skipped) {
          setShowZipDialog(true);
        } else if (firstZipCodeClaimed === true || skipped) {
          setShowZipDialog(false);
        }
      } catch {
        // ignore
      }
    };
    check();
  }, [userId]);

  const handleZipDialogClose = (opts = {}) => {
    if (opts.skipped) localStorage.setItem(AGENT_ZIP_SKIPPED_KEY, '1');
    setShowZipDialog(false);
    if (!opts.skipped) refreshUser?.();
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        const [profileRes, leadsRes] = await Promise.all([
          userApi.getUserById(userId),
          leadsApi.getLeadsByAgentId(userId),
        ]);
        if (!live) return;

        const profile = extractUserFromGetUserById(profileRes);
        const leads = unwrapList(leadsRes, ['leads', 'data']);
        const zips = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);
        const searches = Number(profile?.searchesAppearedIn || profile?.searchCount || 0);
        const contacts = Number(profile?.contacts || 0);
        const contactRate = searches > 0 ? `${((contacts / searches) * 100).toFixed(1)}%` : '0%';

        setKpis([
          { label: 'Claimed ZIP Codes', value: String(zips.length) },
          { label: 'Monthly Leads', value: String(leads.length) },
          { label: 'Listing Views', value: String(profile?.listingViews || 0) },
          { label: 'Contact Rate', value: contactRate },
        ]);
      } catch {
        // Keep safe defaults.
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  return (
    <div className="page-body">
      {showZipDialog && userId ? (
        <FirstZipClaimDialog role="agent" userId={userId} onClose={handleZipDialogClose} />
      ) : null}
      <PageHeader title="Agent Dashboard" subtitle="Performance, leads, and rebate workflow operations." icon="dashboard" />
      <KpiGrid items={kpis} />
      <ActionTiles
        items={[
          { label: 'Edit Profile', caption: 'Update licensed states & details', onClick: () => navigate('/agent/edit-profile') },
          { label: 'Add Listing', caption: 'Create a new listing', onClick: () => navigate('/add-listing') },
          { label: 'Rebate Checklist', caption: 'Open compliance checklist', onClick: () => navigate('/rebate-checklist') },
          { label: 'Profile Setup', caption: 'Improve buyer trust', onClick: () => navigate('/agent-checklist') },
          { label: 'Review Leads', caption: 'Respond quickly', onClick: () => navigate('/agent/leads') },
        ]}
      />
    </div>
  );
}

export function AgentZipCodesPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showToast } = useToast();
  const userId = resolveUserId(user);
  const [licensedStates, setLicensedStates] = useState([]);
  const [stateCode, setStateCode] = useState('NY');
  const [zipSearch, setZipSearch] = useState('');
  const [status, setStatus] = useState('');
  const [claimedRows, setClaimedRows] = useState([]);
  const [stateZipRows, setStateZipRows] = useState([]);
  const [loadingAvailable, setLoadingAvailable] = useState(false);
  const pendingKey = 'pending_agent_zip_checkout';

  const loadClaimed = async () => {
    if (!userId) return;
    try {
      const res = await userApi.getUserById(userId);
      const data = extractUserFromGetUserById(res);
      const states = parseLicensedStates(data);
      setLicensedStates(states);
      if (states.length > 0) {
        setStateCode((prev) => (states.includes(prev) ? prev : states[0]));
      }
      const zips = unwrapList(data?.claimedZipCodes || data?.zipCodes || [], []);
      const subscriptions = unwrapList(data?.subscriptions || [], []);
      setClaimedRows(zips.map((z, i) => {
        const zipcode = z.zipCode || z.postalCode || z.zipcode;
        const matchedSub = subscriptions.find((s) => (s.zipcode || s.zipCode) === zipcode);
        return {
          id: z._id || z.id || `${i}`,
          name: zipcode,
          preview: [z.city, z.state].filter(Boolean).join(', ') || 'Active claim',
          state: z.state || stateCode,
          stripeSubscriptionId: matchedSub?.stripeSubscriptionId || matchedSub?._id || '',
        };
      }));
    } catch {
      setClaimedRows([]);
    }
  };

  const loadStateZipCodes = async () => {
    if (!userId || !stateCode) return;
    setLoadingAvailable(true);
    try {
      const response = await zipApi.getStateZipCodes('US', stateCode);
      const rows = unwrapList(response, ['zipCodes', 'data', 'results']).map((z, i) => {
        const zipcode = z.postalCode || z.zipCode || z.zipcode;
        const population = Number(z.population || 0);
        const apiPrice = Number(z.calculatedPrice || z.price || 0);
        const price = (population > 0 ? calculatePriceForPopulation(population) : apiPrice || 0).toFixed(2);
        return {
          id: z._id || z.id || `${stateCode}-${zipcode || i}`,
          zipcode,
          state: z.state || stateCode,
          city: z.city || '',
          population,
          price,
          name: zipcode,
          preview: `${z.city || 'Unknown city'}, ${z.state || stateCode} • Pop: ${population.toLocaleString()} • $${price}/mo`,
        };
      }).filter((r) => r.zipcode);
      setStateZipRows(rows);
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to fetch ZIP codes for selected state.' });
      setStateZipRows([]);
    } finally {
      setLoadingAvailable(false);
    }
  };

  useEffect(() => {
    loadClaimed();
  }, [userId]);

  useEffect(() => {
    loadStateZipCodes();
  }, [userId, stateCode]);

  useEffect(() => {
    const zip = String(zipSearch || '').trim();
    if (zip.length !== 5 || !/^\d{5}$/.test(zip) || !stateCode) return;
    const t = setTimeout(async () => {
      try {
        await zipApi.validateZipCode(zip, stateCode);
        const stateName = US_STATES.find((s) => s.code === stateCode)?.name || stateCode;
        showToast({ type: 'success', message: `ZIP ${zip} is valid for ${stateName} (${stateCode})` });
      } catch (err) {
        showToast({ type: 'error', message: err.message || `ZIP ${zip} is not valid for ${stateCode}` });
      }
    }, 500);
    return () => clearTimeout(t);
  }, [zipSearch, stateCode]);

  useEffect(() => {
    const finalizePending = async () => {
      if (!userId) return;
      const pendingRaw = localStorage.getItem(pendingKey);
      if (!pendingRaw) return;

      try {
        const pending = JSON.parse(pendingRaw);
        if (!pending || pending.userId !== userId) return;

        const params = new URLSearchParams(window.location.search);
        const sessionId =
          params.get('session_id') ||
          params.get('sessionId') ||
          params.get('checkout_session_id') ||
          pending.sessionId;

        if (!sessionId) return;

        setStatus('Verifying Stripe payment...');
        const payment = await zipApi.verifyPaymentSuccess(sessionId, pending.zipcode);
        if (payment?.success === false) throw new Error(payment?.message || 'Payment verification failed.');

        await zipApi.claimZipCode({
          id: userId,
          userId,
          zipcode: pending.zipcode,
          zipCodeId: pending.zipCodeId || pending.zipcode,
          state: pending.state,
          population: String(pending.population || 0),
          price: pending.price,
        });

        localStorage.removeItem(pendingKey);
        const cleanUrl = `${window.location.pathname}${window.location.hash || ''}`;
        window.history.replaceState({}, document.title, cleanUrl);
        showToast({ type: 'success', message: `ZIP ${pending.zipcode} claimed successfully.` });
        await loadClaimed();
        await loadStateZipCodes();
      } catch (err) {
        showToast({ type: 'error', message: err.message || 'Unable to finalize ZIP claim after payment.' });
      }
    };

    finalizePending();
  }, [userId]);

  const extractSessionIdFromUrl = (url) => {
    try {
      const parsed = new URL(url);
      return parsed.searchParams.get('session_id') || '';
    } catch {
      return '';
    }
  };

  const claimZip = async (zipRow) => {
    if (!userId || !zipRow?.zipcode) return;
    setStatus('Checking ZIP claim status...');
    try {
      const statusResponse = await zipApi.getZipClaimStatus(zipRow.zipcode);
      const claimedBy = statusResponse?.claimedBy;
      if (claimedBy) {
        const msg = getZipClaimedMessage(zipRow.zipcode, claimedBy) || `ZIP ${zipRow.zipcode} is already claimed.`;
        showToast({ type: 'error', message: msg });
        return;
      }

      setStatus('Preparing Stripe checkout...');
      await zipApi.validateZipCode(zipRow.zipcode, stateCode);
      const population = Number(zipRow.population || 0);
      const price = Number(zipRow.price || 0).toFixed(2);
      const origin = window.location.origin;

      const checkoutPayload = {
        role: 'agent',
        population: String(population),
        userId,
        zipcode: zipRow.zipcode,
        price,
        state: stateCode,
        success_url: `${origin}/agent/zip-codes`,
        cancel_url: `${origin}/agent/zip-codes`,
        successUrl: `${origin}/agent/zip-codes`,
        cancelUrl: `${origin}/agent/zip-codes`,
      };

      const checkoutRes = await zipApi.createCheckoutSession(checkoutPayload);
      const checkoutUrl = checkoutRes?.url || checkoutRes?.data?.url;
      let sessionId = checkoutRes?.sessionId || checkoutRes?.data?.sessionId || '';
      if (!sessionId && checkoutUrl) {
        sessionId = extractSessionIdFromUrl(checkoutUrl) || '';
      }
      if (!checkoutUrl) throw new Error('Invalid Stripe checkout URL.');

      const zipCodeId = zipRow.id || zipRow.zipcode;
      localStorage.setItem(
        pendingKey,
        JSON.stringify({
          userId,
          zipcode: zipRow.zipcode,
          zipCodeId,
          state: stateCode,
          population,
          price,
          sessionId,
          createdAt: Date.now(),
        }),
      );

      window.location.assign(checkoutUrl);
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to start Stripe payment for ZIP claim.' });
    }
  };

  const releaseZip = async (z) => {
    if (!userId) return;
    setStatus('Releasing ZIP...');
    try {
      if (z.stripeSubscriptionId) {
        await zipApi.cancelSubscription({
          subscriptionId: z.stripeSubscriptionId,
          userId,
        });
      }

      await zipApi.releaseZipCode({
        id: userId,
        userId,
        zipcode: z.name,
        zipCodeId: z.id || z.name,
        state: z.state || stateCode,
      });
      showToast({ type: 'success', message: `ZIP ${z.name} released.` });
      await loadClaimed();
      await loadStateZipCodes();
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'ZIP release failed.' });
    }
  };

  const claimedSet = useMemo(
    () => new Set(claimedRows.map((row) => String(row.name))),
    [claimedRows],
  );

  const availableRows = useMemo(
    () =>
      stateZipRows
        .filter((row) => !claimedSet.has(String(row.zipcode)))
        .filter((row) => (zipSearch ? String(row.zipcode).includes(zipSearch.trim()) : true))
        .map((row) => ({ ...row, name: row.zipcode })),
    [stateZipRows, claimedSet, zipSearch],
  );

  return (
    <div className="page-body">
      <PageHeader title="ZIP Code Management" subtitle="Claim and manage visibility areas." icon="location" />
      <section className="glass-card search-panel search-panel-zip">
        <label className="zip-search-label">Select State to View ZIP Codes</label>
        <StateSelect value={stateCode} onChange={setStateCode} placeholder="Select state" states={licensedStates.length > 0 ? licensedStates : undefined} />
        <ZipInputWithLocation
          value={zipSearch}
          onChange={(e) => setZipSearch(e.target.value)}
          placeholder="Search ZIP in selected state"
          onLocationPicked={() => {}}
          onLocationError={(msg) => showToast({ type: 'error', message: msg })}
        />
        <button className="btn primary" type="button" onClick={loadStateZipCodes}>Refresh ZIPs</button>
      </section>
      {status ? <p>{status}</p> : null}

      <section className="glass-card panel zip-panel">
        <div className="zip-panel-head">
          <h3>{loadingAvailable ? 'Available ZIPs (Loading...)' : `Available ZIPs (${availableRows.length})`}</h3>
          <small>Scrollable list</small>
        </div>
        <div className="zip-scroll-area">
          <div className="zip-grid">
            {availableRows.map((row) => (
              <article key={row.id} className="zip-card">
                <div className="zip-card-top">
                  <strong>{row.zipcode}</strong>
                  <span>${row.price}</span>
                </div>
                <p>{row.city || 'Unknown city'}, {row.state}</p>
                <small>Population: {Number(row.population || 0).toLocaleString()}</small>
                <div className="zip-card-actions">
                  <button className="btn tiny" onClick={() => claimZip(row)}>Claim & Buy</button>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="glass-card panel zip-panel">
        <div className="zip-panel-head">
          <h3>Claimed ZIPs ({claimedRows.length})</h3>
          <small>Scrollable list</small>
        </div>
        <div className="zip-scroll-area zip-scroll-area-sm">
          <div className="list-rows">
            {claimedRows.map((row) => (
              <div className="list-row" key={row.id}>
                <div>
                  <strong>{row.name}</strong>
                  <p>{row.preview}</p>
                </div>
                <button className="btn tiny danger" onClick={() => releaseZip(row)}>Release</button>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}

export function AgentListingsPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState('');
  const [editing, setEditing] = useState(null);
  const [editForm, setEditForm] = useState(LISTING_EDIT_INITIAL_FORM);

  const loadListings = async () => {
    if (!userId) return;
    setLoading(true);
    try {
      const res = await marketplaceApi.getAgentListings(userId);
      const list = unwrapList(res, ['listings', 'data']);
      setRows(list.map((x) => {
        const desc = (x.description || x.notes || '').trim();
        const descSnippet = desc.length > 60 ? `${desc.slice(0, 60)}…` : desc;
        const location = [x.city, x.state, x.zipCode].filter(Boolean).join(', ');
        const ohCount = Array.isArray(x.openHouses) ? x.openHouses.length : 0;
        const parts = [
          x.price ? `$${Number(x.price).toLocaleString()}` : null,
          location || null,
          x.status || null,
          ohCount > 0 ? `${ohCount} Open House${ohCount > 1 ? 's' : ''}` : null,
        ].filter(Boolean);
        return {
          id: x._id || x.id,
          name: x.propertyTitle || x.streetAddress || x.address || x.title || 'Listing',
          preview: descSnippet ? `${descSnippet} • ${parts.join(' • ')}` : parts.join(' • '),
          raw: x,
        };
      }));
    } catch (err) {
      setStatus(err.message || 'Unable to load listings.');
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId || !live) return;
      try {
        await loadListings();
      } catch {
        if (live) setRows([]);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  const startEdit = (row) => {
    const raw = row?.raw || {};
    const details = raw.propertyDetails || {};
    const detailsType = typeof details === 'string' ? null : details.type;
    const detailsStatus = typeof details === 'string' ? null : details.status;
    const detailsBeds = typeof details === 'string' ? null : details.bedrooms;
    const detailsBaths = typeof details === 'string' ? null : details.bathrooms;
    const detailsSqft = typeof details === 'string' ? null : details.squareFeet;
    const features = Array.isArray(raw.propertyFeatures)
      ? raw.propertyFeatures.join(', ')
      : '';
    setEditing(row);
    setEditForm({
      propertyTitle: raw.propertyTitle || raw.title || row.name || '',
      description: raw.description || raw.notes || '',
      price: raw.price || (raw.priceCents ? raw.priceCents / 100 : ''),
      streetAddress: raw.streetAddress || raw.address || '',
      city: raw.city || '',
      state: raw.state || '',
      zipCode: raw.zipCode || raw.zipcode || '',
      BACPercentage: String(raw.BACPercentage || raw.bacPercent || raw.bac || 2.5),
      listingAgent: String(parseApiBoolean(raw.listingAgent, false)),
      dualAgencyAllowed: String(parseApiBoolean(raw.dualAgencyAllowed, false)),
      status: raw.status || detailsStatus || 'active',
      propertyType: raw.propertyType || detailsType || 'house',
      bedrooms: raw.bedrooms || raw.beds || detailsBeds || '',
      bathrooms: raw.bathrooms || raw.baths || detailsBaths || '',
      squareFeet: raw.squareFeet || raw.sqft || detailsSqft || '',
      propertyFeatures: features,
    });
  };

  const saveEdit = async () => {
    if (!editing?.id) return;
    setStatus('Updating listing...');
    try {
      const numericBac = Number.parseFloat(editForm.BACPercentage);
      const safeBac = Number.isFinite(numericBac) ? numericBac : 2.5;
      await marketplaceApi.updateListing(editing.id, {
        propertyTitle: editForm.propertyTitle.trim(),
        description: editForm.description.trim(),
        price: editForm.price,
        BACPercentage: String(safeBac),
        listingAgent: String(editForm.listingAgent === 'true'),
        dualAgencyAllowed: String(editForm.dualAgencyAllowed === 'true'),
        streetAddress: editForm.streetAddress.trim(),
        city: editForm.city.trim(),
        state: editForm.state.trim(),
        zipCode: editForm.zipCode.trim(),
        id: userId,
        status: editForm.status || 'active',
        createdByRole: 'agent',
        propertyDetails: {
          type: editForm.propertyType || 'house',
          status: editForm.status || 'active',
          ...(editForm.squareFeet ? { squareFeet: editForm.squareFeet } : {}),
          ...(editForm.bedrooms ? { bedrooms: editForm.bedrooms } : {}),
          ...(editForm.bathrooms ? { bathrooms: editForm.bathrooms } : {}),
        },
        propertyFeatures: String(editForm.propertyFeatures || '')
          .split(',')
          .map((x) => x.trim())
          .filter(Boolean),
        openHouses: Array.isArray(editing?.raw?.openHouses) ? editing.raw.openHouses : [],
      });
      setStatus('Listing updated successfully.');
      setEditing(null);
      setEditForm(LISTING_EDIT_INITIAL_FORM);
      await loadListings();
    } catch (err) {
      setStatus(err.message || 'Listing update failed.');
    }
  };

  return (
    <div className="page-body">
      <PageHeader
        title="My Listings"
        subtitle="Create and manage listing inventory."
        icon="listings"
        actions={
          <div className="row">
            <button className="btn tiny" type="button" onClick={loadListings}>Refresh</button>
            <button className="btn tiny primary" type="button" onClick={() => navigate('/add-listing')}>Add Listing</button>
          </div>
        }
      />
      {loading ? <p>Loading listings...</p> : null}
      {status ? <p>{status}</p> : null}
      <ListPanel
        title={`Active Listings (${rows.length})`}
        rows={rows}
        renderRight={(row) => (
          <div className="row">
            <button className="btn tiny ghost" onClick={() => navigate('/listing-detail', { state: { listing: row.raw } })}>Open</button>
            <button className="btn tiny" onClick={() => startEdit(row)}>Edit</button>
          </div>
        )}
      />

      {editing ? (
        <div className="dialog-backdrop" role="presentation" onClick={() => setEditing(null)}>
          <section className="glass-card panel form-stack listing-edit-dialog" role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}>
            <h3>Edit Listing: {editing.name}</h3>
            <input value={editForm.propertyTitle} onChange={(e) => setEditForm((p) => ({ ...p, propertyTitle: e.target.value }))} placeholder="Property Title" />
            <textarea value={editForm.description} onChange={(e) => setEditForm((p) => ({ ...p, description: e.target.value }))} placeholder="Description" rows={4} />
            <input type="number" value={editForm.price} onChange={(e) => setEditForm((p) => ({ ...p, price: e.target.value }))} placeholder="Price" />
            <input value={editForm.streetAddress} onChange={(e) => setEditForm((p) => ({ ...p, streetAddress: e.target.value }))} placeholder="Street Address" />
            <div className="listing-grid-2">
              <input value={editForm.city} onChange={(e) => setEditForm((p) => ({ ...p, city: e.target.value }))} placeholder="City" />
              <input value={editForm.state} onChange={(e) => setEditForm((p) => ({ ...p, state: e.target.value }))} placeholder="State" />
            </div>
            <input value={editForm.zipCode} onChange={(e) => setEditForm((p) => ({ ...p, zipCode: e.target.value }))} placeholder="ZIP Code" />
            <div className="listing-grid-3">
              <input type="number" value={editForm.bedrooms} onChange={(e) => setEditForm((p) => ({ ...p, bedrooms: e.target.value }))} placeholder="Bedrooms" />
              <input type="number" value={editForm.bathrooms} onChange={(e) => setEditForm((p) => ({ ...p, bathrooms: e.target.value }))} placeholder="Bathrooms" />
              <input type="number" value={editForm.squareFeet} onChange={(e) => setEditForm((p) => ({ ...p, squareFeet: e.target.value }))} placeholder="Square Feet" />
            </div>
            <div className="listing-grid-3">
              <input type="number" step="0.1" value={editForm.BACPercentage} onChange={(e) => setEditForm((p) => ({ ...p, BACPercentage: e.target.value }))} placeholder="BAC %" />
              <select value={editForm.listingAgent} onChange={(e) => setEditForm((p) => ({ ...p, listingAgent: e.target.value }))}>
                <option value="false">Listing Agent: No</option>
                <option value="true">Listing Agent: Yes</option>
              </select>
              <select value={editForm.dualAgencyAllowed} onChange={(e) => setEditForm((p) => ({ ...p, dualAgencyAllowed: e.target.value }))}>
                <option value="false">Dual Agency: No</option>
                <option value="true">Dual Agency: Yes</option>
              </select>
            </div>
            <div className="listing-grid-2">
              <select value={editForm.propertyType} onChange={(e) => setEditForm((p) => ({ ...p, propertyType: e.target.value }))}>
                <option value="house">Property Type: House</option>
                <option value="condo">Property Type: Condo</option>
                <option value="townhouse">Property Type: Townhouse</option>
                <option value="multi-family">Property Type: Multi Family</option>
                <option value="land">Property Type: Land</option>
              </select>
              <select value={editForm.status} onChange={(e) => setEditForm((p) => ({ ...p, status: e.target.value }))}>
                <option value="active">Status: Active</option>
                <option value="draft">Status: Draft</option>
                <option value="pending">Status: Pending</option>
                <option value="sold">Status: Sold</option>
              </select>
            </div>
            <input value={editForm.propertyFeatures} onChange={(e) => setEditForm((p) => ({ ...p, propertyFeatures: e.target.value }))} placeholder="Property Features (comma separated)" />
            <div className="row">
              <button className="btn primary" type="button" onClick={saveEdit}>Save Changes</button>
              <button className="btn ghost" type="button" onClick={() => setEditing(null)}>Cancel</button>
            </div>
          </section>
        </div>
      ) : null}
    </div>
  );
}

export function AgentStatsPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [profile, setProfile] = useState(null);
  const [status, setStatus] = useState('');

  const loadStats = async () => {
    if (!userId) return;
    try {
      const res = await userApi.getUserById(userId);
      setProfile(unwrapObject(res, ['user']));
      setStatus('');
    } catch (err) {
      setStatus(err.message || 'Unable to load stats.');
      setProfile(null);
    }
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        await loadStats();
      } catch {
        if (live) setProfile(null);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  const rows = useMemo(() => ([
    { id: 's1', name: 'Searches Appeared In', preview: String(profile?.searchesAppearedIn || profile?.searchCount || 0) },
    { id: 's2', name: 'Profile Views', preview: String(profile?.profileViews || 0) },
    { id: 's3', name: 'Contacts', preview: String(profile?.contacts || 0) },
    { id: 's4', name: 'Website Clicks', preview: String(profile?.websiteClicks || 0) },
  ]), [profile]);

  return (
    <div className="page-body">
      <PageHeader
        title="Analytics"
        subtitle="Views, searches, contacts, and conversion trends."
        icon="stats"
        actions={<button className="btn tiny" onClick={loadStats}>Refresh</button>}
      />
      {status ? <p>{status}</p> : null}
      <ListPanel title="Performance" rows={rows} />
    </div>
  );
}

export function AgentBillingPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [subs, setSubs] = useState([]);
  const [status, setStatus] = useState('');

  const loadBilling = async () => {
    if (!userId) return;
    try {
      const res = await userApi.getUserById(userId);
      const profile = unwrapObject(res, ['user']);
      const subscriptions = unwrapList(profile?.subscriptions || [], []);
      setSubs(subscriptions.map((s, i) => ({
        id: s._id || s.id || `${i}`,
        name: s.subscriptionTier || 'Subscription',
        preview: `${s.subscriptionStatus || 'active'} • ${s.zipcode || s.zipCode || 'N/A'}`,
        raw: s,
      })));
      setStatus('');
    } catch (err) {
      setStatus(err.message || 'Unable to load billing.');
      setSubs([]);
    }
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        await loadBilling();
      } catch {
        if (live) setSubs([]);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  const cancelSub = async (row) => {
    if (!userId) return;
    const raw = row?.raw || {};
    const subscriptionId = raw?.stripeSubscriptionId || raw?._id || raw?.id;
    if (!subscriptionId) {
      setStatus('Subscription ID missing for cancel action.');
      return;
    }

    setStatus('Cancelling subscription...');
    try {
      await zipApi.cancelSubscription({ subscriptionId, userId });
      setStatus('Subscription cancelled.');
      await loadBilling();
    } catch (err) {
      setStatus(err.message || 'Cancel subscription failed.');
    }
  };

  return (
    <div className="page-body">
      <PageHeader
        title="Billing & Subscriptions"
        subtitle="Manage ZIP subscriptions and invoices."
        icon="billing"
        actions={<button className="btn tiny" onClick={loadBilling}>Refresh</button>}
      />
      {status ? <p>{status}</p> : null}
      <ListPanel
        title={`Subscriptions (${subs.length})`}
        rows={subs}
        renderRight={(row) => <button className="btn tiny danger" onClick={() => cancelSub(row)}>Cancel</button>}
      />
    </div>
  );
}

export function AgentLeadsPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [status, setStatus] = useState('');

  const loadLeads = async () => {
    if (!userId) return;
    try {
      const res = await leadsApi.getLeadsByAgentId(userId);
      const leads = unwrapList(res, ['leads', 'data']);
      setRows(leads.map((lead) => {
        const city = lead.city || lead.propertyInformation?.city || '';
        const zip = lead.zipCode || lead.propertyInformation?.zipCode || '';
        const price = lead.priceRange || lead.budgetRange || lead.budget || '';
        const timeframe = lead.timeFrame || lead.timeline || '';
        const status = lead.leadStatus || lead.status || '';
        return {
          id: lead._id || lead.id,
          name: `${lead.leadType || 'Lead'} • ${city || zip}`.trim(),
          preview: [price, timeframe, status].filter(Boolean).join(' • '),
          raw: lead,
        };
      }));
      setStatus('');
    } catch (err) {
      setStatus(err.message || 'Unable to load leads.');
      setRows([]);
    }
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        await loadLeads();
      } catch {
        if (live) setRows([]);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  const actLead = async (row, action) => {
    if (!row?.id || !userId) return;
    setStatus(`Applying lead action: ${action}...`);
    try {
      if (action === 'complete') {
        await leadsApi.markLeadComplete(row.id, { userId, role: 'agent' });
      } else {
        await leadsApi.respondToLead(row.id, { agentId: userId, action });
      }
      setStatus(`Lead action '${action}' completed.`);
      await loadLeads();
    } catch (err) {
      setStatus(err.message || `Lead action '${action}' failed.`);
    }
  };

  return (
    <div className="page-body">
      <PageHeader
        title="Leads"
        subtitle="Manage buyer and seller lead response workflow."
        icon="leads"
        actions={<button className="btn tiny" onClick={loadLeads}>Refresh</button>}
      />
      {status ? <p>{status}</p> : null}
      <ListPanel
        title={`Incoming Leads (${rows.length})`}
        rows={rows}
        renderRight={(row) => (
          <div className="row">
            <button className="btn tiny ghost" onClick={() => navigate('/lead-detail', { state: { lead: row.raw } })}>Open</button>
            <button className="btn tiny" onClick={() => actLead(row, 'accept')}>Accept</button>
            <button className="btn tiny ghost" onClick={() => actLead(row, 'reject')}>Reject</button>
            <button className="btn tiny" onClick={() => actLead(row, 'complete')}>Complete</button>
          </div>
        )}
      />
    </div>
  );
}
