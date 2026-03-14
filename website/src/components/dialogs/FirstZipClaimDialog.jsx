import { useEffect, useMemo, useState } from 'react';
import { createPortal } from 'react-dom';
import { Link } from 'react-router-dom';
import { StateSelect, parseLicensedStates } from '../ui/StateSelect';
import { ZipInputWithLocation } from '../ui/ZipInputWithLocation';
import { US_STATES } from '../../lib/constants';
import { unwrapList, extractUserFromGetUserById } from '../../lib/api';
import { calculatePriceForPopulation } from '../../lib/zipCodePricing';
import { calculateLoanOfficerPriceForPopulation } from '../../lib/zipCodePricing';
import * as userApi from '../../api/user';
import * as zipApi from '../../api/zipcodes';
import { getZipClaimedMessage } from '../../api/zipcodes';
import { useToast } from '../ui/ToastProvider';

export function FirstZipClaimDialog({ role, userId, onClose }) {
  const { showToast } = useToast();
  const isAgent = role === 'agent';
  const pendingKey = isAgent ? 'pending_agent_zip_checkout' : 'pending_loan_officer_zip_checkout';
  const zipCodesPath = isAgent ? '/agent/zip-codes' : '/loan-officer/zip-codes';

  const [licensedStates, setLicensedStates] = useState([]);
  const [stateCode, setStateCode] = useState('NY');
  const [zipSearch, setZipSearch] = useState('');
  const [status, setStatus] = useState('');
  const [claimedRows, setClaimedRows] = useState([]);
  const [stateZipRows, setStateZipRows] = useState([]);
  const [loadingAvailable, setLoadingAvailable] = useState(false);

  const loadClaimed = async () => {
    if (!userId) return;
    try {
      const res = await userApi.getUserById(userId);
      const userObj = extractUserFromGetUserById(res);
      const profile = isAgent ? userObj : (userObj?.loanOfficer || userObj);
      const states = parseLicensedStates(profile);
      setLicensedStates(states);
      if (states.length > 0) setStateCode((prev) => (states.includes(prev) ? prev : states[0]));
      const zips = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);
      const subscriptions = unwrapList(profile?.subscriptions || [], []);
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
      const calcPrice = isAgent ? calculatePriceForPopulation : calculateLoanOfficerPriceForPopulation;
      const rows = unwrapList(response, ['zipCodes', 'data', 'results']).map((z, i) => {
        const zipcode = z.postalCode || z.zipCode || z.zipcode;
        const population = Number(z.population || 0);
        const apiPrice = Number(z.calculatedPrice || z.price || 0);
        const price = (population > 0 ? calcPrice(population) : apiPrice || 0).toFixed(2);
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
      showToast({ type: 'error', message: err.message || 'Unable to fetch ZIP codes.' });
      setStateZipRows([]);
    } finally {
      setLoadingAvailable(false);
    }
  };

  useEffect(() => { loadClaimed(); }, [userId]);
  useEffect(() => { loadStateZipCodes(); }, [userId, stateCode]);

  useEffect(() => {
    const finalizePending = async () => {
      if (!userId) return;
      const pendingRaw = localStorage.getItem(pendingKey);
      if (!pendingRaw) return;
      try {
        const pending = JSON.parse(pendingRaw);
        if (!pending || pending.userId !== userId) return;
        const params = new URLSearchParams(window.location.search);
        const sessionId = params.get('session_id') || params.get('sessionId') || params.get('checkout_session_id') || pending.sessionId;
        if (!sessionId) return;
        setStatus('Verifying payment...');
        const payment = await zipApi.verifyPaymentSuccess(sessionId, pending.zipcode);
        if (payment?.success === false) throw new Error(payment?.message || 'Payment verification failed.');
        const claimPayload = {
          id: userId,
          userId,
          zipcode: pending.zipcode,
          zipCodeId: pending.zipCodeId || pending.zipcode,
          state: pending.state,
          population: String(pending.population || 0),
          price: pending.price,
        };
        if (isAgent) {
          await zipApi.claimZipCode(claimPayload);
        } else {
          await zipApi.claimLoanOfficerZipCode(claimPayload);
        }
        localStorage.removeItem(pendingKey);
        window.history.replaceState({}, document.title, window.location.pathname);
        showToast({ type: 'success', message: `ZIP ${pending.zipcode} claimed successfully.` });
        await loadClaimed();
        await loadStateZipCodes();
      } catch (err) {
        showToast({ type: 'error', message: err.message || 'Unable to finalize ZIP claim.' });
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
        const msg = getZipClaimedMessage(zipRow.zipcode, claimedBy) || `ZIP ${zipRow.zipcode} is already claimed by ${claimedBy}.`;
        showToast({ type: 'error', message: msg });
        return;
      }
      setStatus('Preparing checkout...');
      await zipApi.validateZipCode(zipRow.zipcode, stateCode);
      const population = Number(zipRow.population || 0);
      const price = Number(zipRow.price || 0).toFixed(2);
      const origin = window.location.origin;
      const checkoutPayload = {
        role: isAgent ? 'agent' : 'loanofficer',
        population: String(population),
        userId,
        zipcode: zipRow.zipcode,
        price,
        state: stateCode,
        success_url: `${origin}${zipCodesPath}`,
        cancel_url: `${origin}${zipCodesPath}`,
        successUrl: `${origin}${zipCodesPath}`,
        cancelUrl: `${origin}${zipCodesPath}`,
      };
      const checkoutRes = await zipApi.createCheckoutSession(checkoutPayload);
      const checkoutUrl = checkoutRes?.url || checkoutRes?.data?.url;
      let sessionId = checkoutRes?.sessionId || checkoutRes?.data?.sessionId || '';
      if (!sessionId && checkoutUrl) sessionId = extractSessionIdFromUrl(checkoutUrl) || '';
      if (!checkoutUrl) throw new Error('Invalid checkout URL.');
      const zipCodeId = zipRow.id || zipRow.zipcode;
      localStorage.setItem(pendingKey, JSON.stringify({
        userId,
        zipcode: zipRow.zipcode,
        zipCodeId,
        state: stateCode,
        population,
        price,
        sessionId,
        createdAt: Date.now(),
      }));
      window.location.assign(checkoutUrl);
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to start payment.' });
    }
  };

  const releaseZip = async (z) => {
    if (!userId) return;
    setStatus('Releasing ZIP...');
    try {
      if (z.stripeSubscriptionId) {
        await zipApi.cancelSubscription({ subscriptionId: z.stripeSubscriptionId, userId });
      }
      if (isAgent) {
        await zipApi.releaseZipCode({ id: userId, userId, zipcode: z.name, zipCodeId: z.id || z.name, state: z.state || stateCode });
      } else {
        await zipApi.releaseLoanOfficerZipCode({ id: userId, userId, zipcode: z.name, zipCodeId: z.id || z.name, state: z.state || stateCode });
      }
      showToast({ type: 'success', message: `ZIP ${z.name} released.` });
      await loadClaimed();
      await loadStateZipCodes();
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'ZIP release failed.' });
    }
  };

  const claimedSet = useMemo(() => new Set(claimedRows.map((r) => String(r.name))), [claimedRows]);
  const availableRows = useMemo(
    () =>
      stateZipRows
        .filter((r) => !claimedSet.has(String(r.zipcode)))
        .filter((r) => (zipSearch ? String(r.zipcode).includes(zipSearch.trim()) : true))
        .map((r) => ({ ...r, name: r.zipcode })),
    [stateZipRows, claimedSet, zipSearch],
  );

  const licensedStateNames = licensedStates.map((code) => US_STATES.find((s) => s.code === code)?.name || code);

  const content = (
    <div className="first-zip-dialog-overlay" role="dialog" aria-modal="true" aria-labelledby="first-zip-dialog-title">
      <div className="first-zip-dialog">
        <div className="first-zip-dialog-header">
          <h2 id="first-zip-dialog-title">Get Started – Claim Your First ZIP Code</h2>
          <p>To begin receiving leads and unlock all features, you must claim at least one ZIP code. Follow the prompts below to get started.</p>
          <button type="button" className="btn ghost first-zip-dialog-skip" onClick={() => onClose({ skipped: true })}>Skip for now</button>
        </div>
        <div className="first-zip-dialog-body">
          {licensedStates.length > 0 ? (
            <section className="glass-card panel zip-demo-section">
              <h4>Your Licensed States</h4>
              <p className="zip-demo-hint">States you selected during sign up:</p>
              <div className="zip-demo-state-chips">
                {licensedStateNames.map((name) => (
                  <span key={name} className="zip-state-chip">{name}</span>
                ))}
              </div>
            </section>
          ) : (
            <section className="glass-card panel zip-demo-section zip-demo-warning">
              <p>No licensed states found. Please <Link to={isAgent ? '/agent/edit-profile' : '/loan-officer/edit-profile'} onClick={() => onClose({ skipped: true })}>update your profile</Link> first.</p>
            </section>
          )}
          <section className="glass-card search-panel search-panel-zip">
            <label className="zip-search-label">Select State to View ZIP Codes</label>
            <StateSelect value={stateCode} onChange={setStateCode} placeholder="Select state" states={licensedStates.length > 0 ? licensedStates : undefined} />
            <ZipInputWithLocation value={zipSearch} onChange={(e) => setZipSearch(e.target?.value ?? '')} placeholder="Search ZIP" onLocationError={(msg) => showToast({ type: 'error', message: msg })} />
            <button type="button" className="btn primary" onClick={loadStateZipCodes}>Refresh ZIPs</button>
          </section>
          {status ? <p className="first-zip-status">{status}</p> : null}
          <section className="glass-card panel zip-panel">
            <div className="zip-panel-head">
              <h3>{loadingAvailable ? 'Available ZIPs (Loading...)' : `Available ZIPs (${availableRows.length})`}</h3>
            </div>
            <div className="zip-scroll-area">
              <div className="zip-grid">
                {availableRows.map((row) => (
                  <article key={row.id} className="zip-card">
                    <div className="zip-card-top"><strong>{row.zipcode}</strong><span>${row.price}</span></div>
                    <p>{row.city || 'Unknown city'}, {row.state}</p>
                    <small>Population: {Number(row.population || 0).toLocaleString()}</small>
                    <div className="zip-card-actions">
                      <button type="button" className="btn tiny" onClick={() => claimZip(row)}>Claim & Buy</button>
                    </div>
                  </article>
                ))}
              </div>
            </div>
          </section>
          <section className="glass-card panel zip-panel">
            <div className="zip-panel-head"><h3>Claimed ZIPs ({claimedRows.length})</h3></div>
            <div className="zip-scroll-area zip-scroll-area-sm">
              <div className="list-rows">
                {claimedRows.map((row) => (
                  <div className="list-row" key={row.id}>
                    <div><strong>{row.name}</strong><p>{row.preview}</p></div>
                    <button type="button" className="btn tiny danger" onClick={() => releaseZip(row)}>Release</button>
                  </div>
                ))}
              </div>
            </div>
          </section>
          {claimedRows.length > 0 ? (
            <button type="button" className="btn primary first-zip-done" onClick={() => onClose({ skipped: false })}>Done – Go to Dashboard</button>
          ) : null}
        </div>
      </div>
    </div>
  );

  return createPortal(content, document.body);
}
