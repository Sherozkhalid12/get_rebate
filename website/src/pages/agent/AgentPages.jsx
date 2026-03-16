import { useEffect, useMemo, useRef, useState } from 'react';
import { PageHeader } from '../../components/layout/PageHeader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { StateSelect, parseLicensedStates } from '../../components/ui/StateSelect';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { StatusWithLoader } from '../../components/ui/StatusWithLoader';
import { ActionTiles, KpiGrid, ListPanel } from '../shared/FeatureCards';
import { useToast } from '../../components/ui/ToastProvider';
import { useNavigate, useLocation, Link, useSearchParams } from 'react-router-dom';
import { FirstZipClaimDialog } from '../../components/dialogs/FirstZipClaimDialog';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject, extractUserFromGetUserById } from '../../lib/api';
import * as marketplaceApi from '../../api/marketplace';
import * as zipApi from '../../api/zipcodes';
import { getZipClaimedMessage, flattenZipCodeResponse, getSessionIdFromUrl } from '../../api/zipcodes';
import { calculatePriceForPopulation } from '../../lib/zipCodePricing';
import * as leadsApi from '../../api/leads';
import * as userApi from '../../api/user';
import * as chatApi from '../../api/chat';
import { ChatThread } from '../../components/chat/ChatThread';
import { parseThreadsToRows } from '../../lib/chatUtils';

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
    const skipped = localStorage.getItem(AGENT_ZIP_SKIPPED_KEY);
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
        const profile = extractUserFromGetUserById(res);
        const firstZipCodeClaimed = profile?.firstZipCodeClaimed;
        const skipped = localStorage.getItem(AGENT_ZIP_SKIPPED_KEY);
        if (!live) return;
        if (skipped || firstZipCodeClaimed === true) {
          setShowZipDialog(false);
        } else if (firstZipCodeClaimed === false || firstZipCodeClaimed === undefined) {
          setShowZipDialog(true);
        }
      } catch {
        if (live && !localStorage.getItem(AGENT_ZIP_SKIPPED_KEY)) {
          setShowZipDialog(true);
        }
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
          { label: 'Rebate Calculator', caption: 'Estimate buyer or seller rebate', onClick: () => navigate('/rebate-calculator') },
          { label: 'Rebate Checklist', caption: 'Open compliance checklist', onClick: () => navigate('/rebate-checklist') },
          { label: 'Profile Setup', caption: 'Improve buyer trust', onClick: () => navigate('/agent-checklist') },
          { label: 'Review Leads', caption: 'Respond quickly', onClick: () => navigate('/agent/leads') },
        ]}
      />
    </div>
  );
}

export function AgentMessagesPage() {
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [activeThread, setActiveThread] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchParams, setSearchParams] = useSearchParams();
  const startWithUserId = searchParams.get('userId') || searchParams.get('startChat');
  const [showNewChat, setShowNewChat] = useState(!!startWithUserId);
  const [newChatUserId, setNewChatUserId] = useState(startWithUserId || '');
  const [newChatCreating, setNewChatCreating] = useState(false);
  const [newChatError, setNewChatError] = useState('');

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

  useEffect(() => {
    if (startWithUserId) {
      setShowNewChat(true);
      setNewChatUserId(startWithUserId);
    }
  }, [startWithUserId]);

  const openThread = (row) => {
    setActiveThread(row);
  };

  const startNewChat = async () => {
    const otherId = String(newChatUserId || '').trim();
    if (!otherId || !userId) return;
    setNewChatCreating(true);
    setNewChatError('');
    try {
      const res = await chatApi.createThread(userId, otherId);
      const thread = res?.data || res?.thread || res;
      const threadId = thread?._id || thread?.id || res?._id || res?.id || res?.threadId;
      if (!threadId) throw new Error('Thread created but no ID returned.');
      const other = thread?.otherUser || thread?.other_user || (Array.isArray(thread?.otherParticipants) && thread.otherParticipants[0]) || null;
      const otherName = other?.fullname || other?.name || 'User';
      let displayName = otherName;
      try {
        const userRes = await userApi.getUserById(otherId);
        const u = extractUserFromGetUserById(userRes);
        displayName = u?.fullname || u?.name || otherName;
      } catch {
        // Use fallback name
      }
      const row = {
        id: threadId,
        name: displayName,
        preview: 'No messages yet',
        unread: 0,
        otherUserId: otherId,
      };
      setRows((prev) => [row, ...prev]);
      setShowNewChat(false);
      setNewChatUserId('');
      setActiveThread(row);
      setSearchParams((p) => {
        p.delete('userId');
        p.delete('startChat');
        return p;
      });
    } catch (err) {
      setNewChatError(err?.message || 'Failed to create conversation.');
    } finally {
      setNewChatCreating(false);
    }
  };

  if (activeThread) {
    return (
      <div className="page-body messages-full-chat">
        <ChatThread thread={activeThread} onClose={() => setActiveThread(null)} />
      </div>
    );
  }

  return (
    <div className="page-body">
      <PageHeader
        title="Messages"
        subtitle="Stay responsive with buyer and loan officer conversations."
        icon="messages"
        actions={
          <button className="btn tiny" type="button" onClick={() => { setShowNewChat(true); setNewChatError(''); setNewChatUserId(''); }}>
            New message
          </button>
        }
      />
      {showNewChat ? (
        <div className="glass-card panel" style={{ padding: '1rem', marginBottom: '1rem' }}>
          <h4>Start new conversation</h4>
          <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: '0.75rem' }}>
            Enter the user ID of the buyer, seller, or loan officer you want to message. You can find user IDs in your Leads or from the user&apos;s profile.
          </p>
          <input
            type="text"
            className="input"
            placeholder="User ID"
            value={newChatUserId}
            onChange={(e) => setNewChatUserId(e.target.value)}
            style={{ marginBottom: '0.5rem', maxWidth: '20rem' }}
          />
          {newChatError ? <p className="error-text" style={{ marginBottom: '0.5rem' }}>{newChatError}</p> : null}
          <div className="row" style={{ gap: '0.5rem' }}>
            <button className="btn tiny primary" type="button" onClick={startNewChat} disabled={newChatCreating || !newChatUserId.trim()}>
              {newChatCreating ? 'Creating...' : 'Start chat'}
            </button>
            <button
              className="btn tiny ghost"
              type="button"
              onClick={() => {
                setShowNewChat(false);
                setNewChatError('');
                setSearchParams((p) => {
                  p.delete('userId');
                  p.delete('startChat');
                  return p;
                });
              }}
            >
              Cancel
            </button>
          </div>
        </div>
      ) : null}
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

export function AgentZipCodesPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showToast } = useToast();
  const userId = resolveUserId(user);
  const [licensedStates, setLicensedStates] = useState([]);
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
  const pendingKey = 'pending_agent_zip_checkout';
  const stateStorageKey = 'agent_zip_state';
  const justClaimedRef = useRef(new Set());

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
      const zipsRaw = unwrapList(data?.claimedZipCodes || data?.zipCodes || [], []);
      const seen = new Set();
      const zips = zipsRaw.filter((z) => {
        const zipcode = z.zipCode || z.postalCode || z.zipcode;
        if (!zipcode || seen.has(String(zipcode))) return false;
        seen.add(String(zipcode));
        return true;
      });
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
      const claimedByAgent = enriched.filter((r) => r.claimedBy === 'agent').slice(0, 20);
      claimedByAgent.forEach((r) => checkWaitingListForZip(r.zipcode));
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
          const price = (population > 0 ? calculatePriceForPopulation(population) : apiPrice || 0).toFixed(2);
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
        enriched.filter((r) => r.claimedBy === 'agent').forEach((r) => checkWaitingListForZip(r.zipcode));
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
      if (!userId) {
        console.log('[ZIP Claim] Skipped: no userId');
        return;
      }
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
        showToast({ type: 'error', message: 'Payment session not found. If you were charged, please contact support with your receipt.' });
        return;
      }

      try {
        setStatus('Verifying payment...');
        let payment;
        try {
          payment = await zipApi.verifyPaymentSuccess(sessionId, pending.zipcode);
        } catch (verifyErr) {
          console.warn('[ZIP Claim] verifyPaymentSuccess with zip failed, trying without zip:', verifyErr.message);
          payment = await zipApi.verifyPaymentSuccess(sessionId);
        }
        if (payment?.success === false) throw new Error(payment?.message || 'Payment verification failed.');

        setStatus('Claiming ZIP code...');
        const claimPayload = {
          id: userId,
          userId,
          zipcode: pending.zipcode,
          zipCodeId: pending.zipCodeId || pending.zipcode,
          state: pending.state,
          population: String(pending.population || 0),
          price: pending.price,
        };
        await zipApi.claimZipCode(claimPayload);

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
      const fromParams = parsed.searchParams.get('session_id') || parsed.searchParams.get('sessionId') || '';
      if (fromParams) return fromParams;
      const match = url.match(/cs_(test_|live_)?[a-zA-Z0-9]+/);
      return match ? match[0] : '';
    } catch {
      return '';
    }
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
          const data = extractUserFromGetUserById(profileRes);
          const myZips = unwrapList(data?.claimedZipCodes || data?.zipCodes || [], []);
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

      const baseUrl = `${origin}/agent/zip-codes`;
      const successUrl = `${baseUrl}${baseUrl.includes('?') ? '&' : '?'}session_id={CHECKOUT_SESSION_ID}`;
      const checkoutPayload = {
        role: 'agent',
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
      const pendingData = {
        userId,
        zipcode: zipRow.zipcode,
        zipCodeId,
        state: stateCode,
        population,
        price,
        sessionId,
        createdAt: Date.now(),
      };
      localStorage.setItem(
        pendingKey,
        JSON.stringify(pendingData),
      );

      window.location.assign(checkoutUrl);
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to start Stripe payment for ZIP claim.' });
    } finally {
      setClaimingZipId(null);
      setStatus('');
    }
  };

  const joinWaitingList = async (row) => {
    if (!userId || !row?.zipcode) return;
    setJoiningWaitingListZip(row.zipcode);
    try {
      const displayName = user?.fullname || user?.name || user?.email || 'Agent';
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
    } finally {
      setReleasingZipId(null);
      setStatus('');
    }
  };

  const isReleasingZip = (row) => String(releasingZipId) === String(row.name);

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
    <div className="page-body">
      <PageHeader title="ZIP Code Management" subtitle="Claim and manage your market coverage areas." icon="location" />
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
          <button
            type="button"
            className={`zip-tab ${activeTab === 'available' ? 'active' : ''}`}
            onClick={() => setActiveTab('available')}
          >
            <span className="zip-tab-label">Available ZIP Codes</span>
            <span className="zip-tab-count">{availableRows.length}</span>
          </button>
          <button
            type="button"
            className={`zip-tab ${activeTab === 'claimed' ? 'active' : ''}`}
            onClick={() => setActiveTab('claimed')}
          >
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
                    const isClaimedByAgent = row.claimedBy === 'agent';
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
                        {isClaimedByAgent && <small className="zip-card-claimed-badge">Already claimed by an agent</small>}
                        <div className="zip-card-actions">
                          {isClaimedByAgent ? (
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
                  const isReleasing = isReleasingZip(row);
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

function mapListingToRow(x) {
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
}

export function AgentListingsPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();
  const { showToast } = useToast();
  const userId = resolveUserId(user);
  const newListingFromNav = location.state?.newListing;
  const [rows, setRows] = useState(() => (newListingFromNav ? [newListingFromNav] : []));
  const [loading, setLoading] = useState(false);
  const [editing, setEditing] = useState(null);
  const [savingEdit, setSavingEdit] = useState(false);
  const [deletingId, setDeletingId] = useState(null);
  const [removingIds, setRemovingIds] = useState(new Set());
  const [editForm, setEditForm] = useState(LISTING_EDIT_INITIAL_FORM);

  const loadListings = async () => {
    if (!userId) return;
    setLoading(true);
    try {
      const res = await marketplaceApi.getAgentListings(userId);
      const list = unwrapList(res, ['listings', 'data']);
      const mapped = list.map(mapListingToRow);
      const merged = newListingFromNav
        ? [newListingFromNav, ...mapped.filter((r) => r.id !== newListingFromNav.id)]
        : mapped;
      setRows(merged);
      if (newListingFromNav) {
        navigate(location.pathname, { replace: true, state: {} });
      }
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Unable to load listings.' });
      setRows(newListingFromNav ? [newListingFromNav] : []);
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
    setSavingEdit(true);
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
        existingPropertyPhotos: Array.isArray(editing?.raw?.propertyPhotos) ? editing.raw.propertyPhotos : [],
      });
      setEditing(null);
      setEditForm(LISTING_EDIT_INITIAL_FORM);
      showToast({ type: 'success', message: 'Listing updated.' });
      await loadListings();
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Listing update failed.' });
    } finally {
      setSavingEdit(false);
    }
  };

  const deleteListingRow = async (row) => {
    if (!row?.id) return;
    const idToDelete = row.id;
    setDeletingId(idToDelete);
    try {
      await marketplaceApi.deleteListing(idToDelete);
      setRemovingIds((prev) => new Set([...prev, idToDelete]));
      setDeletingId(null);
      if (editing?.id === idToDelete) {
        setEditing(null);
        setEditForm(LISTING_EDIT_INITIAL_FORM);
      }
      setTimeout(() => {
        setRows((prev) => prev.filter((r) => r.id !== idToDelete));
        setRemovingIds((prev) => {
          const next = new Set(prev);
          next.delete(idToDelete);
          return next;
        });
        showToast({ type: 'success', message: 'Listing deleted.' });
      }, 220);
    } catch (err) {
      setDeletingId(null);
      showToast({ type: 'error', message: err.message || 'Delete failed.' });
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
      {loading ? <AnimatedLoader variant="card" label="" /> : null}
      <ListPanel
        title={`Active Listings (${rows.length})`}
        rows={rows}
        getRowClassName={(row) => {
          if (removingIds.has(row.id)) return 'list-row-removing';
          if (deletingId === row.id) return 'list-row-deleting';
          return '';
        }}
        renderRight={(row) => (
          <div className="row row-gap-sm">
            <button className="btn tiny ghost" onClick={() => navigate('/listing-detail', { state: { listing: row.raw } })} disabled={deletingId === row.id}>Open</button>
            <button className="btn tiny" onClick={() => startEdit(row)} disabled={savingEdit || deletingId === row.id}>Edit</button>
            <button
              className="btn tiny ghost danger icon-only"
              type="button"
              onClick={() => deleteListingRow(row)}
              disabled={deletingId != null}
              title="Delete listing"
              aria-label="Delete listing"
            >
              {deletingId === row.id ? '…' : <IconGlyph name="delete" />}
            </button>
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
              <button className="btn primary" type="button" onClick={saveEdit} disabled={savingEdit}>Save Changes</button>
              <button className="btn ghost" type="button" onClick={() => setEditing(null)} disabled={savingEdit}>Cancel</button>
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
  const [loading, setLoading] = useState(true);

  const loadStats = async () => {
    if (!userId) return;
    setLoading(true);
    try {
      const res = await userApi.getUserById(userId);
      setProfile(unwrapObject(res, ['user']));
      setStatus('');
    } catch (err) {
      setStatus(err.message || 'Unable to load stats.');
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
        actions={<button className="btn tiny" onClick={loadStats} disabled={loading}>Refresh</button>}
      />
      {loading ? <AnimatedLoader variant="card" label="Loading analytics..." /> : null}
      {status && !loading ? <StatusWithLoader status={status} variant="card" /> : null}
      {!loading ? <ListPanel title="Performance" rows={rows} /> : null}
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

export function AgentBillingPage() {
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
      const p = unwrapObject(res, ['user']);
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
    <div className="page-body">
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

export function AgentLeadsPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [rows, setRows] = useState([]);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [actingLeadId, setActingLeadId] = useState(null);

  const loadLeads = async () => {
    if (!userId) return;
    setLoading(true);
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
    } finally {
      setLoading(false);
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
    setActingLeadId(row.id);
    setStatus(`Applying lead action: ${action}...`);
    try {
      if (action === 'complete') {
        const raw = row.raw || {};
        const buyerInfo = raw.currentUserId || raw.buyerInfo || raw.currentUser || raw.user || raw.buyer;
        const buyerId =
          (typeof buyerInfo === 'string' ? buyerInfo : null) ||
          buyerInfo?._id || buyerInfo?.id || buyerInfo?.userId ||
          raw.userId || raw.createdBy;
        const buyerRole = (typeof buyerInfo === 'object' && buyerInfo?.role) ? buyerInfo.role : 'buyer/seller';
        if (!buyerId) {
          setStatus('Buyer information not available for this lead.');
          return;
        }
        await leadsApi.markLeadComplete(row.id, { userId: String(buyerId), role: buyerRole });
      } else {
        await leadsApi.respondToLead(row.id, { agentId: userId, action });
      }
      setStatus(`Lead action '${action}' completed.`);
      await loadLeads();
    } catch (err) {
      setStatus(err.message || `Lead action '${action}' failed.`);
    } finally {
      setActingLeadId(null);
    }
  };

  return (
    <div className="page-body">
      <PageHeader
        title="Leads"
        subtitle="Manage buyer and seller lead response workflow."
        icon="leads"
        actions={<button className="btn tiny" onClick={loadLeads} disabled={loading}>Refresh</button>}
      />
      {loading ? <AnimatedLoader variant="card" label="Loading leads..." /> : null}
      {status && !loading ? <StatusWithLoader status={status} variant="card" /> : null}
      {!loading ? (
        <ListPanel
          title={`Incoming Leads (${rows.length})`}
          rows={rows}
          renderRight={(row) => {
            const acting = actingLeadId === row.id;
            return (
              <div className="row" style={{ alignItems: 'center', gap: '0.5rem' }}>
                {acting ? <AnimatedLoader variant="button" /> : null}
                <button className="btn tiny ghost" onClick={() => navigate('/lead-detail', { state: { lead: row.raw } })} disabled={acting}>Open</button>
                {(() => {
                  const raw = row.raw || {};
                  const buyerInfo = raw.currentUserId || raw.buyerInfo || raw.currentUser || raw.user || raw.buyer;
                  const buyerId = (typeof buyerInfo === 'string' ? buyerInfo : null) || buyerInfo?._id || buyerInfo?.id || buyerInfo?.userId || raw.userId || raw.createdBy;
                  return buyerId ? (
                    <button className="btn tiny ghost" onClick={() => navigate(`/agent/messages?userId=${encodeURIComponent(buyerId)}`)} disabled={acting}>Message</button>
                  ) : null;
                })()}
                <button className="btn tiny" onClick={() => actLead(row, 'accept')} disabled={acting}>Accept</button>
                <button className="btn tiny ghost" onClick={() => actLead(row, 'reject')} disabled={acting}>Reject</button>
                <button className="btn tiny" onClick={() => actLead(row, 'complete')} disabled={acting}>Complete</button>
              </div>
            );
          }}
        />
      ) : null}
    </div>
  );
}
