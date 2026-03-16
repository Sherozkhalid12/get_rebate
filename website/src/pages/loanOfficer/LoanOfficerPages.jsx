import { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { StateSelect, parseLicensedStates } from '../../components/ui/StateSelect';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { StatusWithLoader } from '../../components/ui/StatusWithLoader';
import { ActionTiles, KpiGrid, ListPanel } from '../shared/FeatureCards';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject, extractUserFromGetUserById } from '../../lib/api';
import * as chatApi from '../../api/chat';
import { parseThreadsToRows } from '../../lib/chatUtils';
import * as userApi from '../../api/user';
import * as zipApi from '../../api/zipcodes';
import { getZipClaimedMessage, flattenZipCodeResponse, getSessionIdFromUrl } from '../../api/zipcodes';
import { calculateLoanOfficerPriceForPopulation } from '../../lib/zipCodePricing';
import { ChatThread } from '../../components/chat/ChatThread';
import { useToast } from '../../components/ui/ToastProvider';
import { FirstZipClaimDialog } from '../../components/dialogs/FirstZipClaimDialog';
import { BUYER_CHECKLIST, REBATE_CHECKLIST_BUYING } from '../shared/CommonPages';

const LOAN_OFFICER_ZIP_SKIPPED_KEY = 'loan_officer_zip_skipped';

export function LoanOfficerDashboardPage() {
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  const userId = resolveUserId(user);
  const [kpis, setKpis] = useState([
    { label: 'Views', value: '0' },
    { label: 'Contacts', value: '0' },
    { label: 'Reviews', value: '0' },
    { label: 'Claimed ZIP Codes', value: '0' },
  ]);
  const firstZipFromAuth = user?.firstZipCodeClaimed;
  const [showZipDialog, setShowZipDialog] = useState(false);

  useEffect(() => {
    const skipped = localStorage.getItem(LOAN_OFFICER_ZIP_SKIPPED_KEY);
    if (skipped) {
      setShowZipDialog(false);
      return;
    }
    if (firstZipFromAuth === true) {
      setShowZipDialog(false);
      return;
    }
    if (firstZipFromAuth === false || firstZipFromAuth === undefined) {
      setShowZipDialog(true);
    }
  }, [firstZipFromAuth]);

  useEffect(() => {
    let live = true;
    const check = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        const userObj = extractUserFromGetUserById(res);
        const profile = userObj?.loanOfficer || userObj;
        const firstZipCodeClaimed = profile?.firstZipCodeClaimed;
        const skipped = localStorage.getItem(LOAN_OFFICER_ZIP_SKIPPED_KEY);
        if (!live) return;
        if (skipped || firstZipCodeClaimed === true) {
          setShowZipDialog(false);
        } else if (firstZipCodeClaimed === false || firstZipCodeClaimed === undefined) {
          setShowZipDialog(true);
        }
      } catch {
        if (live && !localStorage.getItem(LOAN_OFFICER_ZIP_SKIPPED_KEY)) {
          setShowZipDialog(true);
        }
      }
    };
    check();
  }, [userId]);

  const handleZipDialogClose = (opts = {}) => {
    if (opts.skipped) localStorage.setItem(LOAN_OFFICER_ZIP_SKIPPED_KEY, '1');
    setShowZipDialog(false);
    if (!opts.skipped) refreshUser?.();
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        const profileRes = await userApi.getUserById(userId);
        if (!live) return;
        const userObj = extractUserFromGetUserById(profileRes);
        const profile = userObj?.loanOfficer || userObj;
        const zipCodes = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);
        const views = Number(profile?.profileViews ?? profile?.views ?? 0);
        const contacts = Number(profile?.contacts ?? 0);
        const reviews = Number(profile?.reviewCount ?? (Array.isArray(profile?.reviews) ? profile.reviews.length : 0));

        setKpis([
          { label: 'Views', value: String(views) },
          { label: 'Contacts', value: String(contacts) },
          { label: 'Reviews', value: String(reviews) },
          { label: 'Claimed ZIP Codes', value: String(zipCodes.length) },
        ]);
      } catch {
        // Keep defaults.
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  return (
    <div className="page-body page-body--loan-officer">
      {showZipDialog && userId ? (
        <FirstZipClaimDialog role="loanOfficer" userId={userId} onClose={handleZipDialogClose} />
      ) : null}
      <PageHeader title="Loan Officer Dashboard" subtitle="Profile visibility, contacts, and reviews." icon="dashboard" />
      <KpiGrid items={kpis} variant="loanOfficer" />
      <ActionTiles
        items={[
          { label: 'Rebate Calculator', caption: 'Estimate buyer or seller rebate', onClick: () => navigate('/rebate-calculator') },
          { label: 'Profile & Setup Guide', caption: 'Step-by-step checklist', onClick: () => navigate('/loan-officer-checklist') },
          { label: 'Edit Profile', caption: 'Update lender details', onClick: () => navigate('/loan-officer/edit-profile') },
        ]}
      />
      <section className="glass-card panel">
        <h3>Rebate-Friendly Lender Verified</h3>
        <p>
          Keep your lender policy status visible so buyers can proceed with confidence that rebate credits are supported at closing.
        </p>
        <button type="button" className="btn primary" onClick={() => navigate('/loan-officer/edit-profile')}>
          Edit Profile
        </button>
      </section>
    </div>
  );
}

export function LoanOfficerMessagesPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [activeThread, setActiveThread] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadThreads = async () => {
    if (!userId) return;
    setLoading(true);
    setError('');
    try {
      const res = await chatApi.getThreads(userId);
      const parsed = parseThreadsToRows(res, userId);
      setRows(parsed);
    } catch (err) {
      setError(err?.message || 'Unable to load conversations.');
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!userId) {
      setLoading(false);
      return;
    }
    loadThreads();
  }, [userId]);

  const openThread = (row) => {
    setActiveThread(row);
  };

  if (activeThread) {
    return (
      <div className="page-body messages-full-chat">
        <ChatThread thread={activeThread} onClose={() => setActiveThread(null)} />
      </div>
    );
  }

  return (
    <div className="page-body page-body--loan-officer">
      <PageHeader title="Messages" subtitle="Stay responsive with buyer and agent conversations." icon="messages" />
      {error ? (
        <div className="glass-card panel" style={{ padding: '1rem' }}>
          <p className="error-text">{error}</p>
          <button className="btn tiny" type="button" onClick={loadThreads}>
            Retry
          </button>
        </div>
      ) : loading ? (
        <div className="glass-card panel" style={{ padding: '2rem', textAlign: 'center' }}>
          <p>Loading conversations...</p>
        </div>
      ) : (
        <ListPanel
          title="Conversations"
          rows={rows}
          renderRight={(row) => (
            <div className="row">
              {row.unread ? <span className="pill">{row.unread}</span> : null}
              <button className="btn tiny" type="button" onClick={() => openThread(row)}>
                Open
              </button>
            </div>
          )}
        />
      )}
      {!loading && !error && (
        <button className="btn ghost tiny" type="button" onClick={loadThreads} style={{ marginTop: '0.5rem' }}>
          Refresh
        </button>
      )}
    </div>
  );
}

export function LoanOfficerZipCodesPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showToast } = useToast();
  const userId = resolveUserId(user);
  const [licensedStates, setLicensedStates] = useState([]);
  const pendingKey = 'pending_loan_officer_zip_checkout';
  const stateStorageKey = 'lo_zip_state';
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
  const [stateCode, setStateCodeState] = useState(getInitialState);
  const setStateCode = (v) => {
    setStateCodeState((prev) => {
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
  const [activeTab, setActiveTab] = useState('available');
  const justClaimedRef = useRef(new Set());

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
      const profile = userObj?.loanOfficer || userObj;
      const states = parseLicensedStates(profile);
      setLicensedStates(states);
      if (states.length > 0) {
        setStateCode((prev) => (states.includes(prev) ? prev : states[0]));
      }
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
      const rows = unwrapList(response, ['zipCodes', 'data', 'results']).map((z, i) => {
        const zipcode = z.postalCode || z.zipCode || z.zipcode;
        const population = Number(z.population || 0);
        const apiPrice = Number(z.calculatedPrice || z.price || 0);
        const price = (population > 0 ? calculateLoanOfficerPriceForPopulation(population) : apiPrice || 0).toFixed(2);
        const claimedBy = z.claimedBy || (z.claimedByAgent ? 'agent' : z.claimedByOfficer || z.claimedByLoanOfficer ? 'loanOfficer' : null);
        return {
          id: z._id || z.id || `${stateCode}-${zipcode || i}`,
          zipcode,
          state: z.state || stateCode,
          city: z.city || '',
          population,
          price,
          name: zipcode,
          claimedBy,
          preview: `${z.city || 'Unknown city'}, ${z.state || stateCode} • Pop: ${population.toLocaleString()} • $${price}/mo`,
        };
      }).filter((r) => r.zipcode);
      const enriched = await enrichClaimStatus(rows, 50);
      setStateZipRows(enriched);
      const claimedByOfficer = enriched.filter((r) => r.claimedBy === 'loanOfficer').slice(0, 20);
      claimedByOfficer.forEach((r) => checkWaitingListForZip(r.zipcode));
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
        const rows = flat.map((z, i) => {
          const zipcode = z.postalCode || z.zipCode || z.zipcode;
          const population = Number(z.population || 0);
          const apiPrice = Number(z.calculatedPrice || z.price || 0);
          const price = (population > 0 ? calculateLoanOfficerPriceForPopulation(population) : apiPrice || 0).toFixed(2);
          const dist = z.distance != null ? Number(z.distance).toFixed(1) : null;
          const distStr = dist ? ` • ${dist} mi` : '';
          const claimedBy = z.claimedBy || (z.claimedByAgent ? 'agent' : z.claimedByOfficer || z.claimedByLoanOfficer ? 'loanOfficer' : null);
          return {
            id: z._id || z.id || `${stateCode}-${zipcode || i}`,
            zipcode,
            state: z.state || stateCode,
            city: z.city || '',
            population,
            price,
            distance: dist,
            name: zipcode,
            claimedBy,
            preview: `${z.city || 'Unknown city'}, ${z.state || stateCode} • Pop: ${population.toLocaleString()}${distStr} • $${price}/mo`,
          };
        }).filter((r) => r.zipcode);
        const enriched = await enrichClaimStatus(rows, rows.length);
        setSearchZipRows(enriched);
        enriched.filter((r) => r.claimedBy === 'loanOfficer').forEach((r) => checkWaitingListForZip(r.zipcode));
      } catch (err) {
        showToast({ type: 'error', message: err.message || 'ZIP search failed.' });
        setSearchZipRows([]);
      } finally {
        setLoadingSearch(false);
      }
    }, 400);
    return () => clearTimeout(t);
  }, [zipSearch, stateCode]);

  useEffect(() => {
    const finalizePending = async () => {
      console.log('[ZIP Claim LO] finalizePending start', { userId, url: window.location.href });
      if (!userId) return;
      const pendingRaw = localStorage.getItem(pendingKey);
      if (!pendingRaw) return;

      let pending;
      try {
        pending = JSON.parse(pendingRaw);
      } catch {
        localStorage.removeItem(pendingKey);
        return;
      }
      if (!pending || pending.userId !== userId) return;

      const sessionId = getSessionIdFromUrl() || pending.sessionId;

      if (!sessionId) {
        console.error('[ZIP Claim LO] No sessionId');
        showToast({ type: 'error', message: 'Payment session not found. If you were charged, please contact support with your receipt.' });
        return;
      }

      try {
        setStatus('Verifying payment...');
        let payment;
        try {
          payment = await zipApi.verifyPaymentSuccess(sessionId, pending.zipcode);
        } catch (verifyErr) {
          payment = await zipApi.verifyPaymentSuccess(sessionId);
        }
        if (payment?.success === false) throw new Error(payment?.message || 'Payment verification failed.');

        setStatus('Claiming ZIP code...');
        await zipApi.claimLoanOfficerZipCode({
          id: userId,
          userId,
          zipcode: pending.zipcode,
          zipCodeId: pending.zipCodeId || pending.zipcode,
          state: pending.state,
          population: String(pending.population || 0),
          price: pending.price,
        });

        localStorage.removeItem(pendingKey);
        justClaimedRef.current = new Set([...justClaimedRef.current, pending.zipcode]);
        setStateCode(pending.state || stateCode);
        sessionStorage.setItem(stateStorageKey, pending.state || stateCode);
        const cleanUrl = `${window.location.pathname}${window.location.hash || ''}`;
        window.history.replaceState({}, document.title, cleanUrl);
        setStatus('');
        setActiveTab('claimed');
        setClaimedRows((prev) => {
          if (prev.some((r) => String(r.name) === String(pending.zipcode))) return prev;
          return [...prev, { id: pending.zipcode, name: pending.zipcode, preview: `${pending.state || ''} • Just claimed`, state: pending.state }];
        });
        showToast({ type: 'success', message: `ZIP ${pending.zipcode} claimed successfully.` });
        await loadClaimed();
        await loadStateZipCodes();
      } catch (err) {
        setStatus('');
        const msg = err?.message || '';
        if (/claimed|already claimed/i.test(msg)) {
          justClaimedRef.current = new Set([...justClaimedRef.current, pending.zipcode]);
          setStateCode(pending.state || stateCode);
          setActiveTab('claimed');
          setClaimedRows((prev) => {
            if (prev.some((r) => String(r.name) === String(pending.zipcode))) return prev;
            return [...prev, { id: pending.zipcode, name: pending.zipcode, preview: `${pending.state || ''} • Just claimed`, state: pending.state }];
          });
          showToast({ type: 'success', message: `ZIP ${pending.zipcode} claimed successfully.` });
          await loadClaimed();
          await loadStateZipCodes();
        } else {
          showToast({ type: 'error', message: msg || 'Unable to finalize ZIP claim after payment.' });
        }
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

  const joinWaitingList = async (row) => {
    if (!userId || !row?.zipcode) return;
    setJoiningWaitingListZip(row.zipcode);
    try {
      const displayName = user?.fullname || user?.name || user?.email || 'Loan Officer';
      await zipApi.joinWaitingList({
        name: displayName,
        email: user?.email || '',
        zipCode: row.zipcode,
        userId,
      });
      setWaitingListJoined((prev) => new Set([...prev, row.zipcode]));
      showToast({ type: 'success', message: 'Added to waiting list.' });
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to join waiting list.' });
    } finally {
      setJoiningWaitingListZip(null);
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

  const claimZip = async (zipRow) => {
    if (!userId || !zipRow?.zipcode) return;
    setClaimingZipId(zipRow.id);
    setStatus('Checking availability...');
    try {
      const statusResponse = await zipApi.getZipClaimStatus(zipRow.zipcode, userId);
      const claimedBy = statusResponse?.claimedBy;
      if (claimedBy) {
        if (getSessionIdFromUrl()) {
          await loadClaimed();
          await loadStateZipCodes();
          setActiveTab('claimed');
          return;
        }
        const fromCache = claimedRows.some((r) => String(r.name) === String(zipRow.zipcode));
        if (fromCache) {
          showToast({ type: 'success', message: `You've already claimed ZIP ${zipRow.zipcode}.` });
          await loadClaimed();
          await loadStateZipCodes();
          setActiveTab('claimed');
          return;
        }
        try {
          const profileRes = await userApi.getUserById(userId);
          const userObj = extractUserFromGetUserById(profileRes);
          const profile = userObj?.loanOfficer || userObj;
          const myZips = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);
          const zipStr = String(zipRow.zipcode);
          const isMine = myZips.some((z) => String(z.zipCode || z.postalCode || z.zipcode) === zipStr);
          if (isMine) {
            showToast({ type: 'success', message: `You've already claimed ZIP ${zipRow.zipcode}.` });
            await loadClaimed();
            await loadStateZipCodes();
            setActiveTab('claimed');
            return;
          }
        } catch {
          /* ignore profile check errors */
        }
        const sessionId = getSessionIdFromUrl();
        const pendingRaw = localStorage.getItem(pendingKey);
        if (sessionId && pendingRaw) {
          try {
            const p = JSON.parse(pendingRaw);
            if (p?.zipcode === zipRow.zipcode) return;
          } catch {}
        }
        if (justClaimedRef.current.has(String(zipRow.zipcode))) {
          showToast({ type: 'success', message: `You've already claimed ZIP ${zipRow.zipcode}.` });
          await loadClaimed();
          await loadStateZipCodes();
          setActiveTab('claimed');
          return;
        }
        const msg = getZipClaimedMessage(zipRow.zipcode, claimedBy) || `ZIP ${zipRow.zipcode} is already claimed.`;
        showToast({ type: 'error', message: msg });
        return;
      }

      setStatus('Creating checkout session...');
      const population = Number(zipRow.population || 0);
      const price = Number(zipRow.price || 0).toFixed(2);
      const origin = window.location.origin;

      const baseUrl = `${origin}/loan-officer/zip-codes`;
      const successUrl = `${baseUrl}${baseUrl.includes('?') ? '&' : '?'}session_id={CHECKOUT_SESSION_ID}`;
      const checkoutPayload = {
        role: 'loanofficer',
        population: String(population),
        userId,
        zipcode: zipRow.zipcode,
        price,
        state: stateCode,
        success_url: successUrl,
        cancel_url: baseUrl,
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
        await zipApi.cancelSubscription({
          subscriptionId: z.stripeSubscriptionId,
          userId,
        });
      }

      await zipApi.releaseLoanOfficerZipCode({
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
    } finally {
      setReleasingZipId(null);
      setStatus('');
    }
  };

  const claimedSet = useMemo(
    () => new Set(claimedRows.map((row) => String(row.name))),
    [claimedRows],
  );

  const displayRows = searchZipRows !== null ? searchZipRows : stateZipRows;
  const availableRows = useMemo(
    () =>
      displayRows
        .filter((row) => !claimedSet.has(String(row.zipcode)))
        .map((row) => ({ ...row, name: row.zipcode })),
    [displayRows, claimedSet],
  );

  return (
    <div className="page-body page-body--loan-officer">
      <PageHeader title="ZIP Codes" subtitle="Manage your subscribed market coverage." icon="location" />
      <section className="glass-card search-panel search-panel-zip zip-search-section">
        <label className="zip-search-label">Select state & search ZIP</label>
        <StateSelect value={stateCode} onChange={setStateCode} placeholder="Select state" states={licensedStates.length > 0 ? licensedStates : undefined} />
        <ZipInputWithLocation
          value={zipSearch}
          onChange={(e) => setZipSearch(e.target.value)}
          placeholder="Enter 5-digit ZIP"
          onLocationPicked={() => {}}
          onLocationError={(msg) => showToast({ type: 'error', message: msg })}
        />
        <button className="btn primary" type="button" onClick={loadStateZipCodes} disabled={loadingAvailable}>
          Refresh
        </button>
      </section>
      <div className="zip-tabs-wrap glass-card">
        <div className="zip-tabs">
          <button type="button" className={`zip-tab ${activeTab === 'available' ? 'active' : ''}`} onClick={() => setActiveTab('available')}>
            <span className="zip-tab-label">Available ZIP Codes</span>
            <span className="zip-tab-count">{availableRows.length}</span>
          </button>
          <button type="button" className={`zip-tab ${activeTab === 'claimed' ? 'active' : ''}`} onClick={() => setActiveTab('claimed')}>
            <span className="zip-tab-label">Claimed ZIP Codes</span>
            <span className="zip-tab-count">{claimedRows.length}</span>
          </button>
        </div>

        {activeTab === 'available' ? (
          <section className="zip-tab-panel">
            {(loadingAvailable || loadingSearch) ? (
              <AnimatedLoader variant="card" label="" />
            ) : (
              <div className="zip-grid zip-grid-pro">
                {availableRows.length === 0 ? (
                  <div className="zip-empty-state">
                    <p>No available ZIP codes in this state.</p>
                    <p className="zip-empty-hint">Select a different state or search by ZIP to find codes you can claim.</p>
                  </div>
                ) : (
                  availableRows.map((row) => {
                    const isClaimedByOfficer = row.claimedBy === 'loanOfficer';
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
                        {isClaimedByOfficer && <small className="zip-card-claimed-badge">Already claimed by a loan officer</small>}
                        <div className="zip-card-actions">
                          {isClaimedByOfficer ? (
                            <>
                              {hasJoined ? (
                                <button className="btn ghost small" type="button" onClick={() => showWaitingListModal(row.zipcode)}>
                                  See waiting list
                                </button>
                              ) : (
                                <button className="btn ghost small" type="button" onClick={() => joinWaitingList(row)} disabled={isJoining}>
                                  Join waiting list
                                </button>
                              )}
                            </>
                          ) : (
                            <button className="btn primary small" onClick={() => claimZip(row)} disabled={claimingZipId != null}>
                              Claim & Checkout
                            </button>
                          )}
                        </div>
                      </article>
                    );
                  })
                )}
              </div>
            )}
          </section>
        ) : (
          <section className="zip-tab-panel">
            <div className="zip-claimed-list">
              {claimedRows.length === 0 ? (
                <div className="zip-empty-state">
                  <p>You haven&apos;t claimed any ZIP codes yet.</p>
                  <p className="zip-empty-hint">Switch to Available ZIP Codes to claim and subscribe.</p>
                </div>
              ) : (
                claimedRows.map((row) => {
                  const isReleasing = String(releasingZipId) === String(row.name);
                  return (
                    <div className={`zip-claimed-row ${isReleasing ? 'releasing' : ''}`} key={row.id}>
                      <div className="zip-claimed-info">
                        <strong className="zip-claimed-code">{row.name}</strong>
                        <p>{row.preview}</p>
                      </div>
                      <button className="btn ghost danger small" onClick={() => releaseZip(row)} disabled={releasingZipId != null}>
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
                })
              )}
            </div>
          </section>
        )}
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
}

function formatBillingDate(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
  } catch {
    return String(iso);
  }
}

function formatCurrency(amount) {
  if (amount == null || amount === '') return '—';
  const n = Number(amount);
  if (Number.isNaN(n)) return String(amount);
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);
}

function formatTier(tier) {
  if (!tier) return '—';
  const m = String(tier).match(/tier_(\d+)/i);
  return m ? `Tier ${m[1]}` : tier;
}

export function LoanOfficerBillingPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [profile, setProfile] = useState(null);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [cancellingId, setCancellingId] = useState(null);

  const loadBilling = async () => {
    if (!userId) return;
    setLoading(true);
    try {
      const res = await userApi.getUserById(userId);
      const p = unwrapObject(res, ['user', 'loanOfficer']);
      setProfile(p);
      setStatus('');
    } catch (err) {
      setStatus(err.message || 'Unable to load billing.');
      setProfile(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        await loadBilling();
      } catch {
        if (live) setProfile(null);
      }
    };
    run();
    return () => { live = false; };
  }, [userId]);

  const [activeTab, setActiveTab] = useState('active');
  const subscriptions = unwrapList(profile?.subscriptions || [], []);
  const active = subscriptions.filter((s) => (s.subscriptionStatus || '').toLowerCase() === 'active');
  const cancelled = subscriptions.filter((s) => (s.subscriptionStatus || '').toLowerCase() === 'cancelled');
  const expired = subscriptions.filter((s) => (s.subscriptionStatus || '').toLowerCase() === 'expired');

  const paymentHistory = useMemo(() => {
    const seen = new Set();
    return subscriptions
      .filter((s) => s.amountPaid != null && s.createdAt)
      .filter((s) => {
        const key = `${s.stripeSubscriptionId || s._id}-${s.createdAt}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 50);
  }, [subscriptions]);

  const cancelSub = async (sub) => {
    if (!userId) return;
    const subscriptionId = sub?.stripeSubscriptionId || sub?._id || sub?.id;
    if (!subscriptionId) {
      setStatus('Subscription ID missing.');
      return;
    }
    setCancellingId(sub._id || sub.id);
    setStatus('');
    try {
      await zipApi.cancelSubscription({ subscriptionId, userId });
      setActiveTab('cancelled');
      setProfile((prev) => {
        if (!prev) return prev;
        const subs = [...(prev.subscriptions || [])];
        const idx = subs.findIndex((s) => (s._id || s.id) === (sub._id || sub.id) || s.stripeSubscriptionId === subscriptionId);
        if (idx >= 0) {
          subs[idx] = { ...subs[idx], subscriptionStatus: 'cancelled' };
        }
        return { ...prev, subscriptions: subs };
      });
    } catch (err) {
      setStatus(err.message || 'Cancel failed.');
      await loadBilling();
    } finally {
      setCancellingId(null);
    }
  };

  const renderSubCard = (sub, showCancel = false) => {
    const zip = sub.zipcode || sub.zipCode || '';
    const city = sub.city || '';
    const state = sub.state || '';
    const pop = sub.population != null ? Number(sub.population).toLocaleString() : '—';
    const isCancelling = cancellingId === (sub._id || sub.id);
    return (
      <div key={sub._id || sub.id} className="billing-sub-card glass-card">
        <div className="billing-sub-header">
          <div className="billing-sub-title-wrap">
            <strong className="billing-sub-title">{zip ? `ZIP ${zip}` : 'Subscription'}</strong>
            {(city || state) ? <span className="billing-sub-meta">{[city, state].filter(Boolean).join(', ')}</span> : null}
          </div>
          <span className={`billing-sub-badge billing-sub-badge-${(sub.subscriptionStatus || '').toLowerCase()}`}>
            {(sub.subscriptionStatus || '').toLowerCase()}
          </span>
        </div>
        <div className="billing-sub-details">
          <div className="billing-sub-row">
            <span className="billing-sub-label">Tier</span>
            <span className="billing-sub-value">{formatTier(sub.subscriptionTier)}</span>
          </div>
          <div className="billing-sub-row">
            <span className="billing-sub-label">Population</span>
            <span className="billing-sub-value">{pop}</span>
          </div>
          <div className="billing-sub-row">
            <span className="billing-sub-label">Amount</span>
            <span className="billing-sub-value">{formatCurrency(sub.amountPaid)}/mo</span>
          </div>
          <div className="billing-sub-row">
            <span className="billing-sub-label">Start</span>
            <span className="billing-sub-value">{formatBillingDate(sub.subscriptionStart)}</span>
          </div>
          <div className="billing-sub-row">
            <span className="billing-sub-label">End</span>
            <span className="billing-sub-value">{formatBillingDate(sub.subscriptionEnd)}</span>
          </div>
        </div>
        {showCancel ? (
          <div className="billing-sub-actions">
            <button
              type="button"
              className="btn tiny danger"
              onClick={() => cancelSub(sub)}
              disabled={isCancelling !== false}
            >
              {isCancelling ? <AnimatedLoader variant="button" /> : 'Cancel'}
            </button>
          </div>
        ) : null}
      </div>
    );
  };

  return (
    <div className="page-body page-body--loan-officer">
      <PageHeader
        title="Billing & Subscriptions"
        subtitle="Manage ZIP subscriptions, invoices, and payment history."
        icon="billing"
        actions={<button className="btn tiny" onClick={loadBilling} disabled={loading}>Refresh</button>}
      />
      {loading ? <AnimatedLoader variant="card" label="Loading billing..." /> : null}
      {status && !loading ? <StatusWithLoader status={status} variant="card" /> : null}
      {!loading && profile ? (
        <>
          <section className="billing-tabs-section glass-card">
            <div className="billing-tabs">
              <button
                type="button"
                className={`billing-tab ${activeTab === 'active' ? 'active' : ''}`}
                onClick={() => setActiveTab('active')}
              >
                Active ({active.length})
              </button>
              <button
                type="button"
                className={`billing-tab ${activeTab === 'cancelled' ? 'active' : ''}`}
                onClick={() => setActiveTab('cancelled')}
              >
                Cancelled ({cancelled.length})
              </button>
              <button
                type="button"
                className={`billing-tab ${activeTab === 'expired' ? 'active' : ''}`}
                onClick={() => setActiveTab('expired')}
              >
                Expired ({expired.length})
              </button>
            </div>
            <div className="billing-tab-panel">
              {activeTab === 'active' && (
                active.length ? (
                  <div className="billing-sub-grid">
                    {active.map((s) => renderSubCard(s, true))}
                  </div>
                ) : (
                  <p className="billing-empty">No active subscriptions.</p>
                )
              )}
              {activeTab === 'cancelled' && (
                cancelled.length ? (
                  <div className="billing-sub-grid">
                    {cancelled.map((s) => renderSubCard(s, false))}
                  </div>
                ) : (
                  <p className="billing-empty">No cancelled subscriptions.</p>
                )
              )}
              {activeTab === 'expired' && (
                expired.length ? (
                  <div className="billing-sub-grid">
                    {expired.map((s) => renderSubCard(s, false))}
                  </div>
                ) : (
                  <p className="billing-empty">No expired subscriptions.</p>
                )
              )}
            </div>
          </section>

          <section className="billing-section glass-card">
            <h3>Payment history</h3>
            {paymentHistory.length ? (
              <div className="billing-payment-table-wrap">
                <table className="billing-payment-table">
                  <thead>
                    <tr>
                      <th>Date</th>
                      <th>Description</th>
                      <th>Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paymentHistory.map((p) => (
                      <tr key={p._id || p.stripeSubscriptionId || p.createdAt}>
                        <td>{formatBillingDate(p.createdAt)}</td>
                        <td>
                          {p.zipcode || p.zipCode ? `ZIP ${p.zipcode || p.zipCode}` : 'Subscription'} • {formatTier(p.subscriptionTier)}
                        </td>
                        <td>{formatCurrency(p.amountPaid)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="billing-empty">No payment history yet.</p>
            )}
          </section>
        </>
      ) : null}
    </div>
  );
}

export function LoanOfficerChecklistsPage() {
  const navigate = useNavigate();

  return (
    <div className="page-body page-body--loan-officer">
      <PageHeader title="Buyer & Agent Checklists" subtitle="View the checklists that buyers and agents see, so you know what they're working with." icon="checklist" />
      <section className="glass-card panel checklist-lo-card">
        <div className="checklist-lo-card-header">
          <IconGlyph name="checklist" filled />
          <div>
            <h3>Real Estate Agent Rebate Checklist – Buying/Building</h3>
            <p>Follow these steps to ensure compliance when working with a buyer who will receive a real estate commission rebate. (Continue providing your standard services—such as MLS searches, showings, negotiations, and client support—as usual.)</p>
          </div>
        </div>
        <ol className="checklist-items checklist-lo">
          {REBATE_CHECKLIST_BUYING.map((item, i) => (
            <li key={i} className="checklist-item"><span className="checklist-num">{i + 1}</span><span className="checklist-text">{item}</span></li>
          ))}
        </ol>
      </section>
      <section className="glass-card panel checklist-lo-card checklist-lo-card--green">
        <div className="checklist-lo-card-header">
          <IconGlyph name="checklist" filled />
          <div>
            <h3>Homebuyer Checklist (with Rebate!)</h3>
            <p>Consumer-friendly checklist that buyers see.</p>
          </div>
        </div>
        <ol className="checklist-items checklist-lo">
          {BUYER_CHECKLIST.map((item, i) => (
            <li key={i} className="checklist-item"><span className="checklist-num">{i + 1}</span><span className="checklist-text">{item.replace(/\n\n/g, ' ')}</span></li>
          ))}
        </ol>
        <button type="button" className="btn primary" onClick={() => navigate('/checklist?type=buyer')}>
          View Buyer Version
        </button>
      </section>
      <section className="glass-card panel">
        <h3>Loan Officer Guide</h3>
        <p>View the full step-by-step checklist for profile setup, ZIP strategy, and rebate compliance.</p>
        <button type="button" className="btn primary" onClick={() => navigate('/loan-officer-checklist')}>
          Open Full Checklist
        </button>
      </section>
    </div>
  );
}
