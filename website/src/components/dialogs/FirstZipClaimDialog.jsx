import { useEffect, useMemo, useState } from 'react';
import { createPortal } from 'react-dom';
import { Link } from 'react-router-dom';
import { StateSelect, parseLicensedStates } from '../ui/StateSelect';
import { ZipInputWithLocation } from '../ui/ZipInputWithLocation';
import { AnimatedLoader } from '../ui/AnimatedLoader';
import { IconGlyph } from '../ui/IconGlyph';
import { US_STATES } from '../../lib/constants';
import { unwrapList, extractUserFromGetUserById } from '../../lib/api';
import { calculatePriceForPopulation } from '../../lib/zipCodePricing';
import { calculateLoanOfficerPriceForPopulation } from '../../lib/zipCodePricing';
import * as userApi from '../../api/user';
import * as zipApi from '../../api/zipcodes';
import { getZipClaimedMessage, flattenZipCodeResponse, getSessionIdFromUrl } from '../../api/zipcodes';
import { useToast } from '../ui/ToastProvider';
import { useAuth } from '../../context/AuthContext';

export function FirstZipClaimDialog({ role, userId, onClose }) {
  const { showToast } = useToast();
  const { user } = useAuth();
  const isAgent = role === 'agent';
  const pendingKey = isAgent ? 'pending_agent_zip_checkout' : 'pending_loan_officer_zip_checkout';
  const zipCodesPath = isAgent ? '/agent/zip-codes' : '/loan-officer/zip-codes';

  const stateStorageKey = isAgent ? 'agent_zip_state' : 'lo_zip_state';
  const getInitialState = () => {
    const pendingRaw = localStorage.getItem(pendingKey);
    if (pendingRaw) {
      try {
        const p = JSON.parse(pendingRaw);
        if (p?.state) return p.state;
      } catch {}
    }
    return sessionStorage.getItem(stateStorageKey) || '';
  };
  const [licensedStates, setLicensedStates] = useState([]);
  const [stateCode, setStateCodeRaw] = useState(getInitialState);
  const setStateCode = (v) => {
    setStateCodeRaw((prev) => {
      const val = typeof v === 'function' ? v(prev) : v;
      if (val) sessionStorage.setItem(stateStorageKey, val);
      return val ?? prev;
    });
  };
  const [zipSearch, setZipSearch] = useState('');
  const [status, setStatus] = useState('');
  const [claimedRows, setClaimedRows] = useState([]);
  const [stateZipRows, setStateZipRows] = useState([]);
  const [searchZipRows, setSearchZipRows] = useState(null);
  const [loadingAvailable, setLoadingAvailable] = useState(false);
  const [loadingSearch, setLoadingSearch] = useState(false);
  const [claimingZipId, setClaimingZipId] = useState(null);
  const [releasingZipId, setReleasingZipId] = useState(null);
  const [joiningWaitingListZip, setJoiningWaitingListZip] = useState(null);
  const [waitingListJoined, setWaitingListJoined] = useState(new Set());
  const [waitingListModalZip, setWaitingListModalZip] = useState(null);
  const [waitingListEntries, setWaitingListEntries] = useState([]);
  const [loadingWaitingList, setLoadingWaitingList] = useState(false);

  const enrichClaimStatus = async (rows, limit = 50) => {
    const toEnrich = rows.filter((r) => r.claimedBy == null).slice(0, limit);
    if (toEnrich.length === 0) return rows;
    const batchSize = 5;
    const out = [...rows];
    for (let i = 0; i < toEnrich.length; i += batchSize) {
      const batch = toEnrich.slice(i, i + batchSize);
      const results = await Promise.allSettled(batch.map((r) => zipApi.getZipClaimStatus(r.zipcode, userId)));
      results.forEach((res, j) => {
        if (res.status === 'fulfilled' && res.value?.claimedBy) {
          const idx = out.findIndex((o) => o.zipcode === batch[j].zipcode);
          if (idx >= 0) out[idx] = { ...out[idx], claimedBy: res.value.claimedBy };
        }
      });
    }
    return out;
  };

  const loadClaimed = async () => {
    if (!userId) return;
    try {
      const res = await userApi.getUserById(userId);
      const userObj = extractUserFromGetUserById(res);
      const profile = isAgent ? userObj : (userObj?.loanOfficer || userObj);
      const states = parseLicensedStates(profile);
      setLicensedStates(states);
      if (states.length > 0) setStateCode((prev) => (states.includes(prev) ? prev : states[0]));
      const zipsRaw = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);
      const seen = new Set();
      const zips = zipsRaw.filter((z) => {
        const zipcode = z.zipCode || z.postalCode || z.zipcode;
        if (!zipcode || seen.has(String(zipcode))) return false;
        seen.add(String(zipcode));
        return true;
      });
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
        const claimedBy = z.claimedBy || (z.claimedByAgent ? 'agent' : z.claimedByOfficer || z.claimedByLoanOfficer ? 'loanOfficer' : null);
        return {
          id: z._id || z.id || `${stateCode}-${zipcode || i}`,
          zipcode,
          state: z.state || stateCode,
          city: z.city || '',
          population,
          price,
          claimedBy,
          name: zipcode,
          preview: `${z.city || 'Unknown city'}, ${z.state || stateCode} • Pop: ${population.toLocaleString()} • $${price}/mo`,
        };
      }).filter((r) => r.zipcode);
      const enriched = await enrichClaimStatus(rows, 50);
      setStateZipRows(enriched);
      enriched.filter((r) => r.claimedBy === 'agent' || r.claimedBy === 'loanOfficer').forEach((r) => checkWaitingListForZip(r.zipcode));
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
    const zip = String(zipSearch || '').trim();
    if (zip.length !== 5 && zip.length > 0) return;
    if (zip.length === 0) {
      setSearchZipRows(null);
      return;
    }
    if (!/^\d{5}$/.test(zip) || !stateCode) return;
    const t = setTimeout(async () => {
      setLoadingSearch(true);
      try {
        const response = await zipApi.searchZipCode('US', stateCode, zip);
        const flat = flattenZipCodeResponse(response);
        const calcPrice = isAgent ? calculatePriceForPopulation : calculateLoanOfficerPriceForPopulation;
        const rows = flat.map((z, i) => {
          const zipcode = z.postalCode || z.zipCode || z.zipcode;
          const population = Number(z.population || 0);
          const apiPrice = Number(z.calculatedPrice || z.price || 0);
          const price = (population > 0 ? calcPrice(population) : apiPrice || 0).toFixed(2);
          const dist = z.distance != null ? Number(z.distance).toFixed(1) : null;
          const claimedBy = z.claimedBy || (z.claimedByAgent ? 'agent' : z.claimedByOfficer || z.claimedByLoanOfficer ? 'loanOfficer' : null);
          return {
            id: z._id || z.id || `${stateCode}-${zipcode || i}`,
            zipcode,
            state: z.state || stateCode,
            city: z.city || '',
            population,
            price,
            distance: dist,
            claimedBy,
            name: zipcode,
            preview: `${z.city || 'Unknown city'}, ${z.state || stateCode} • Pop: ${population.toLocaleString()}${dist != null ? ` • ${dist} mi` : ''} • $${price}/mo`,
          };
        }).filter((r) => r.zipcode);
        const enriched = await enrichClaimStatus(rows, rows.length);
        setSearchZipRows(enriched);
        enriched.filter((r) => r.claimedBy === 'agent' || r.claimedBy === 'loanOfficer').forEach((r) => checkWaitingListForZip(r.zipcode));
      } catch (err) {
        showToast({ type: 'error', message: err.message || 'ZIP search failed.' });
        setSearchZipRows([]);
      } finally {
        setLoadingSearch(false);
      }
    }, 400);
    return () => clearTimeout(t);
  }, [zipSearch, stateCode, isAgent]);

  useEffect(() => {
    const finalizePending = async () => {
      if (!userId) return;
      const pendingRaw = localStorage.getItem(pendingKey);
      if (!pendingRaw) return;
      try {
        const pending = JSON.parse(pendingRaw);
        if (!pending || pending.userId !== userId) return;
        const sessionId = getSessionIdFromUrl() || pending.sessionId;
        if (!sessionId) {
          showToast({ type: 'error', message: 'Payment session not found. If you were charged, please contact support with your receipt.' });
          return;
        }
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
      } finally {
        setStatus('');
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
    setClaimingZipId(zipRow.id);
    setStatus('Checking ZIP claim status...');
    try {
      const statusResponse = await zipApi.getZipClaimStatus(zipRow.zipcode, userId);
      const claimedBy = statusResponse?.claimedBy;
      if (claimedBy) {
        if (getSessionIdFromUrl()) {
          await loadClaimed();
          await loadStateZipCodes();
          return;
        }
        const fromCache = claimedRows.some((r) => String(r.name) === String(zipRow.zipcode));
        if (fromCache) {
          showToast({ type: 'success', message: `You've already claimed ZIP ${zipRow.zipcode}.` });
          await loadClaimed();
          await loadStateZipCodes();
          return;
        }
        try {
          const profileRes = await userApi.getUserById(userId);
          const userObj = extractUserFromGetUserById(profileRes);
          const profile = isAgent ? userObj : (userObj?.loanOfficer || userObj);
          const myZips = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);
          const zipStr = String(zipRow.zipcode);
          const isMine = myZips.some((z) => String(z.zipCode || z.postalCode || z.zipcode) === zipStr);
          if (isMine) {
            showToast({ type: 'success', message: `You've already claimed ZIP ${zipRow.zipcode}.` });
            await loadClaimed();
            await loadStateZipCodes();
            return;
          }
        } catch {
          /* ignore */
        }
        const sessionId = getSessionIdFromUrl();
        const pendingRaw = localStorage.getItem(pendingKey);
        if (sessionId && pendingRaw) {
          try {
            const p = JSON.parse(pendingRaw);
            if (p?.zipcode === zipRow.zipcode) return;
          } catch {}
        }
        const msg = getZipClaimedMessage(zipRow.zipcode, claimedBy) || `ZIP ${zipRow.zipcode} is already claimed.`;
        showToast({ type: 'error', message: `${msg} Use "Join waiting list" to be notified when it becomes available.` });
        return;
      }
      setStatus('Preparing checkout...');
      await zipApi.validateZipCode(zipRow.zipcode, stateCode);
      const population = Number(zipRow.population || 0);
      const price = Number(zipRow.price || 0).toFixed(2);
      const origin = window.location.origin;
      const baseUrl = `${origin}${zipCodesPath}`;
      const successUrl = `${baseUrl}${baseUrl.includes('?') ? '&' : '?'}session_id={CHECKOUT_SESSION_ID}`;
      const checkoutPayload = {
        role: isAgent ? 'agent' : 'loanofficer',
        population: String(population),
        userId,
        zipcode: zipRow.zipcode,
        price,
        state: stateCode,
        success_url: successUrl,
        cancel_url: baseUrl,
        successUrl,
        cancelUrl: baseUrl,
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
    } finally {
      setClaimingZipId(null);
      setStatus('');
    }
  };

  const releaseZip = async (z) => {
    if (!userId) return;
    setReleasingZipId(z.name);
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
      showToast({ type: 'success', message: `ZIP ${z.name} released. You can claim it again or another ZIP.` });
      await loadClaimed();
      await loadStateZipCodes();
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'ZIP release failed.' });
    } finally {
      setReleasingZipId(null);
      setStatus('');
    }
  };

  const joinWaitingList = async (row) => {
    if (!userId || !row?.zipcode) return;
    if (waitingListJoined.has(row.zipcode)) {
      showToast({ type: 'info', message: `You're already on the waiting list for ZIP ${row.zipcode}.` });
      return;
    }
    setJoiningWaitingListZip(row.zipcode);
    try {
      const displayName = user?.fullname || user?.name || user?.email || (isAgent ? 'Agent' : 'Loan Officer');
      await zipApi.joinWaitingList({
        name: displayName,
        email: user?.email || '',
        zipCode: row.zipcode,
        userId,
      });
      setWaitingListJoined((prev) => new Set([...prev, row.zipcode]));
      showToast({ type: 'success', message: `Added to waiting list for ZIP ${row.zipcode}. You'll be notified when it becomes available.` });
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to join waiting list.' });
    } finally {
      setJoiningWaitingListZip(null);
    }
  };

  const checkWaitingListForZip = async (zipcode) => {
    try {
      const entries = await zipApi.getWaitingListEntries(zipcode);
      const list = Array.isArray(entries) ? entries : unwrapList(entries, ['entries', 'data']);
      const isIn = list.some((e) => String(e.userId || e.user_id) === String(userId));
      if (isIn) setWaitingListJoined((prev) => new Set([...prev, zipcode]));
    } catch {
      /* ignore */
    }
  };

  const showWaitingListModal = async (zipcode) => {
    setWaitingListModalZip(zipcode);
    setLoadingWaitingList(true);
    setWaitingListEntries([]);
    try {
      const res = await zipApi.getWaitingListEntries(zipcode);
      const list = Array.isArray(res) ? res : unwrapList(res, ['entries', 'data']);
      setWaitingListEntries(list);
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to load waiting list.' });
    } finally {
      setLoadingWaitingList(false);
    }
  };

  const closeWaitingListModal = () => {
    setWaitingListModalZip(null);
    setWaitingListEntries([]);
  };

  const claimedSet = useMemo(() => new Set(claimedRows.map((r) => String(r.name))), [claimedRows]);
  const displayRows = searchZipRows !== null ? searchZipRows : stateZipRows;
  const availableRows = useMemo(
    () =>
      displayRows
        .filter((r) => !claimedSet.has(String(r.zipcode)))
        .map((r) => ({ ...r, name: r.zipcode })),
    [displayRows, claimedSet],
  );

  const licensedStateNames = licensedStates.map((code) => US_STATES.find((s) => s.code === code)?.name || code);

  const handleLocationPicked = (data) => {
    if (data?.zip) setZipSearch(data.zip);
    if (data?.state) setStateCode(data.state);
  };

  const content = (
    <div className="first-zip-dialog-overlay" role="dialog" aria-modal="true" aria-labelledby="first-zip-dialog-title">
      <div className="first-zip-dialog first-zip-dialog-spacious">
        <div className="first-zip-dialog-header">
          <h2 id="first-zip-dialog-title">Get Started – Claim Your First ZIP Code</h2>
          <p>To begin receiving leads and unlock all features, you must claim at least one ZIP code. Select a state and search or browse available ZIPs below.</p>
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
          <section className="glass-card search-panel search-panel-zip zip-search-section first-zip-search-section">
            <label className="zip-search-label">Select state & search ZIP</label>
            <StateSelect value={stateCode} onChange={setStateCode} placeholder="Select state" states={licensedStates.length > 0 ? licensedStates : undefined} />
            <ZipInputWithLocation
              value={zipSearch}
              onChange={(e) => setZipSearch(e.target?.value ?? '')}
              placeholder="Enter 5-digit ZIP"
              onLocationPicked={handleLocationPicked}
              onLocationError={(msg) => showToast({ type: 'error', message: msg })}
            />
            <button type="button" className="btn primary" onClick={loadStateZipCodes} disabled={loadingAvailable}>
              Refresh
            </button>
          </section>
          <section className="glass-card panel zip-panel first-zip-panel">
            <div className="zip-panel-head">
              <h3>{(loadingAvailable || loadingSearch) ? 'Loading...' : `Available ZIPs (${availableRows.length})${searchZipRows !== null ? ' — search results' : ''}`}</h3>
            </div>
            <div className="first-zip-scroll-area">
              {(loadingAvailable || loadingSearch) ? (
                <AnimatedLoader variant="card" label="" />
              ) : availableRows.length === 0 ? (
                <div className="zip-empty-state">
                  <p>No available ZIP codes in this state.</p>
                  <p className="zip-empty-hint">Select a different state or search by ZIP to find codes you can claim.</p>
                </div>
              ) : (
                <div className="zip-grid zip-grid-pro">
                  {availableRows.map((row) => {
                    const isClaimedByOther = Boolean(row.claimedBy);
                    const hasJoined = waitingListJoined.has(row.zipcode);
                    const isJoining = joiningWaitingListZip === row.zipcode;
                    return (
                      <article key={row.id} className="zip-card zip-card-pro">
                        <div className="zip-card-top">
                          <strong className="zip-code-badge">{row.zipcode}</strong>
                          <span className="zip-price">${row.price}<small>/mo</small></span>
                        </div>
                        <p className="zip-card-location">{row.city || 'Unknown city'}, {row.state}</p>
                        <small className="zip-card-meta">Population: {Number(row.population || 0).toLocaleString()}{row.distance != null ? ` • ${row.distance} mi away` : ''}</small>
                        {isClaimedByOther && (
                          <small className="zip-card-claimed-badge">
                            {row.claimedBy === 'agent' ? 'Already claimed by an agent' : row.claimedBy === 'loanOfficer' ? 'Already claimed by a Loan Officer' : 'Already claimed'}
                          </small>
                        )}
                        <div className="zip-card-actions">
                          {isClaimedByOther ? (
                            <>
                              {hasJoined ? (
                                <button type="button" className="btn ghost small" onClick={() => showWaitingListModal(row.zipcode)}>
                                  See waiting list
                                </button>
                              ) : (
                                <button type="button" className="btn ghost small" onClick={() => joinWaitingList(row)} disabled={isJoining}>
                                  Join waiting list
                                </button>
                              )}
                            </>
                          ) : (
                            <button type="button" className="btn primary small" onClick={() => claimZip(row)} disabled={claimingZipId != null}>
                              Claim & Checkout
                            </button>
                          )}
                        </div>
                      </article>
                    );
                  })}
                </div>
              )}
            </div>
          </section>
          <section className="glass-card panel zip-panel first-zip-claimed-section">
            <div className="zip-panel-head"><h3>Claimed ZIPs ({claimedRows.length})</h3></div>
            <div className="first-zip-claimed-scroll">
              {claimedRows.length === 0 ? (
                <p className="zip-empty-hint">Your claimed ZIP codes will appear here.</p>
              ) : (
                <div className="list-rows">
                  {claimedRows.map((row) => {
                    const isReleasing = String(releasingZipId) === String(row.name);
                    return (
                      <div className={`list-row first-zip-list-row ${isReleasing ? 'releasing' : ''}`} key={row.id}>
                        <div><strong>{row.name}</strong><p>{row.preview}</p></div>
                        <button type="button" className="btn tiny danger" onClick={() => releaseZip(row)} disabled={releasingZipId != null}>
                          <span className="release-btn-content">
                            {isReleasing ? (
                              <>
                                <span className="release-spinner" aria-hidden />
                                Releasing…
                              </>
                            ) : (
                              'Release'
                            )}
                          </span>
                        </button>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </section>
          {claimedRows.length > 0 ? (
            <button type="button" className="btn primary first-zip-done" onClick={() => onClose({ skipped: false })}>Done – Go to Dashboard</button>
          ) : null}
        </div>
      </div>

      {waitingListModalZip ? (
        <div className="modal-overlay" onClick={closeWaitingListModal} role="presentation">
          <div className="modal-dialog glass-card" onClick={(e) => e.stopPropagation()} role="dialog">
            <div className="modal-header">
              <h3>Waiting list – ZIP {waitingListModalZip}</h3>
              <button type="button" className="btn ghost icon" onClick={closeWaitingListModal} aria-label="Close">
                <IconGlyph name="close" />
              </button>
            </div>
            <div className="modal-body">
              {loadingWaitingList ? (
                <AnimatedLoader variant="card" label="" />
              ) : waitingListEntries.length === 0 ? (
                <p className="text-muted">No entries yet.</p>
              ) : (
                <ul className="waiting-list-entries">
                  {waitingListEntries.map((e, i) => (
                    <li key={e._id || e.id || i}>
                      <span className="entry-name">{e.name || e.email || 'Unknown'}</span>
                      {e.email ? <span className="entry-email">{e.email}</span> : null}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );

  return createPortal(content, document.body);
}
