import { useEffect, useMemo, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { StateSelect, parseLicensedStates } from '../../components/ui/StateSelect';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { KpiGrid, ListPanel } from '../shared/FeatureCards';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject, extractUserFromGetUserById } from '../../lib/api';
import * as chatApi from '../../api/chat';
import * as userApi from '../../api/user';
import * as zipApi from '../../api/zipcodes';
import { getZipClaimedMessage } from '../../api/zipcodes';
import { calculateLoanOfficerPriceForPopulation } from '../../lib/zipCodePricing';
import * as loansApi from '../../api/loans';
import { ChatThread } from '../../components/chat/ChatThread';
import { useToast } from '../../components/ui/ToastProvider';
import { FirstZipClaimDialog } from '../../components/dialogs/FirstZipClaimDialog';

const LOAN_OFFICER_ZIP_SKIPPED_KEY = 'loan_officer_zip_skipped';

export function LoanOfficerDashboardPage() {
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  const userId = resolveUserId(user);
  const [kpis, setKpis] = useState([
    { label: 'Claimed ZIP Codes', value: '0' },
    { label: 'Active Borrowers', value: '0' },
    { label: 'Application Starts', value: '0' },
    { label: 'Rebate-Ready Lenders', value: '100%' },
  ]);
  const firstZipFromAuth = user?.firstZipCodeClaimed;
  const [showZipDialog, setShowZipDialog] = useState(false);

  useEffect(() => {
    if (firstZipFromAuth === false && !localStorage.getItem(LOAN_OFFICER_ZIP_SKIPPED_KEY)) {
      setShowZipDialog(true);
    } else if (firstZipFromAuth === true || localStorage.getItem(LOAN_OFFICER_ZIP_SKIPPED_KEY)) {
      setShowZipDialog(false);
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
    if (opts.skipped) localStorage.setItem(LOAN_OFFICER_ZIP_SKIPPED_KEY, '1');
    setShowZipDialog(false);
    if (!opts.skipped) refreshUser?.();
  };

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        const [profileRes, loansRes] = await Promise.all([userApi.getUserById(userId), loansApi.getLoans(userId)]);
        if (!live) return;
        const userObj = extractUserFromGetUserById(profileRes);
        const profile = userObj?.loanOfficer || userObj;
        const loans = unwrapList(loansRes, ['loans', 'data']);
        const zipCodes = unwrapList(profile?.claimedZipCodes || profile?.zipCodes || [], []);

        setKpis([
          { label: 'Claimed ZIP Codes', value: String(zipCodes.length) },
          { label: 'Active Borrowers', value: String(loans.length) },
          { label: 'Application Starts', value: String(profile?.applicationStarts || 0) },
          { label: 'Rebate-Ready Lenders', value: '100%' },
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
    <div className="page-body">
      {showZipDialog && userId ? (
        <FirstZipClaimDialog role="loanOfficer" userId={userId} onClose={handleZipDialogClose} />
      ) : null}
      <PageHeader title="Loan Officer Dashboard" subtitle="Lender visibility, lead flow, and compliance readiness." icon="dashboard" />
      <KpiGrid items={kpis} />
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

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        const res = await chatApi.getThreads(userId);
        if (!live) return;
        const threads = unwrapList(res, ['threads', 'data']);
        setRows(
          threads.map((t) => {
            const other = t.otherUser || t.other_user || null;
            const otherUserId = other?._id || other?.id || other?.userId || null;
            return {
              id: t._id || t.id,
              name: other?.fullname || other?.name || 'Conversation',
              preview: t.lastMessage?.text || t.lastMessage?.message || 'No messages',
              unread: t.unreadCount || 0,
              otherUserId,
            };
          }),
        );
      } catch {
        if (live) setRows([]);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  const openThread = (row) => {
    setActiveThread(row);
  };

  return (
    <div className="page-body">
      <PageHeader title="Messages" subtitle="Stay responsive with buyer and agent conversations." icon="messages" />
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
      {activeThread ? (
        <ChatThread thread={activeThread} onClose={() => setActiveThread(null)} />
      ) : null}
    </div>
  );
}

export function LoanOfficerZipCodesPage() {
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
  const pendingKey = 'pending_loan_officer_zip_checkout';

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
      const rows = unwrapList(response, ['zipCodes', 'data', 'results']).map((z, i) => {
        const zipcode = z.postalCode || z.zipCode || z.zipcode;
        const population = Number(z.population || 0);
        const apiPrice = Number(z.calculatedPrice || z.price || 0);
        const price = (population > 0 ? calculateLoanOfficerPriceForPopulation(population) : apiPrice || 0).toFixed(2);
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
        role: 'loanofficer',
        population: String(population),
        userId,
        zipcode: zipRow.zipcode,
        price,
        state: stateCode,
        success_url: `${origin}/loan-officer/zip-codes`,
        cancel_url: `${origin}/loan-officer/zip-codes`,
        successUrl: `${origin}/loan-officer/zip-codes`,
        cancelUrl: `${origin}/loan-officer/zip-codes`,
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
      <PageHeader title="ZIP Codes" subtitle="Manage your subscribed market coverage." icon="location" />
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

export function LoanOfficerBillingPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        if (!live) return;
        const profile = unwrapObject(res, ['user', 'loanOfficer']);
        const subscriptions = unwrapList(profile?.subscriptions || [], []);
        setRows(subscriptions.map((s, i) => ({ id: s._id || s.id || `${i}`, name: s.subscriptionTier || 'Subscription', preview: `${s.subscriptionStatus || 'active'} • ${s.zipcode || s.zipCode || 'N/A'}` })));
      } catch {
        if (live) setRows([]);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  return (
    <div className="page-body">
      <PageHeader title="Billing" subtitle="Subscription and payment management." icon="billing" />
      <ListPanel title="Subscriptions" rows={rows} />
    </div>
  );
}

export function LoanOfficerChecklistsPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);

  useEffect(() => {
    let live = true;
    const run = async () => {
      if (!userId) return;
      try {
        const res = await loansApi.getLoans(userId);
        if (!live) return;
        const loans = unwrapList(res, ['loans', 'data']);
        setRows(loans.map((loan) => ({ id: loan._id || loan.id, name: loan.programName || loan.loanType || 'Loan Program', preview: [loan.apr, loan.status, loan.rateType].filter(Boolean).join(' • ') || 'Loan record' })));
      } catch {
        if (live) setRows([]);
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [userId]);

  const checklistRows = useMemo(() => rows.length ? rows : [
    { id: 'c1', name: 'Confirm lender rebate policy disclosure', preview: 'Checklist step' },
    { id: 'c2', name: 'Align fees and credit disclosures', preview: 'Checklist step' },
    { id: 'c3', name: 'Coordinate with title and agent before close', preview: 'Checklist step' },
  ], [rows]);

  return (
    <div className="page-body">
      <PageHeader title="Checklists" subtitle="Compliance checklist for smooth rebate closings." icon="checklist" />
      <section className="glass-card panel">
        <h3>Loan Officer Guide</h3>
        <p>View the full step-by-step checklist for profile setup, ZIP strategy, and rebate compliance.</p>
        <button type="button" className="btn primary" onClick={() => navigate('/loan-officer-checklist')}>
          Open Full Checklist
        </button>
      </section>
      <ListPanel title="Loan Programs" rows={checklistRows} />
    </div>
  );
}
