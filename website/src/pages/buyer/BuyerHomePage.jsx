import { useEffect, useMemo, useState, useCallback, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { ActionTiles, KpiGrid } from '../shared/FeatureCards';
import { AgentCard } from '../../components/buyer/AgentCard';
import { LoanOfficerCard } from '../../components/buyer/LoanOfficerCard';
import { ListingCard } from '../../components/buyer/ListingCard';
import { OpenHouseCard } from '../../components/buyer/OpenHouseCard';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { useToast } from '../../components/ui/ToastProvider';
import { resolveUserId, unwrapList } from '../../lib/api';
import { useAuth } from '../../context/AuthContext';
import * as marketplaceApi from '../../api/marketplace';
import * as zipApi from '../../api/zipcodes';

function toPrice(value, cents) {
  if (typeof value === 'number' && value > 0) return value;
  if (typeof cents === 'number' && cents > 0) return cents / 100;
  const asNum = Number(value);
  return Number.isFinite(asNum) && asNum > 0 ? asNum : 0;
}

function normalizeAgent(item) {
  return {
    id: item?._id || item?.id,
    raw: item,
  };
}

function normalizeListing(item) {
  return {
    id: item?._id || item?.id,
    raw: item,
  };
}

function normalizeOpenHouse(listing, openHouse, index) {
  return {
    id: openHouse?._id || openHouse?.id || `${listing?._id || listing?.id || 'listing'}-${index}`,
    raw: { listing, openHouse },
  };
}

function normalizeLoanOfficer(item) {
  return {
    id: item?._id || item?.id,
    raw: item,
  };
}

function getClaimedZips(entity) {
  const claimed = entity?.claimedZipCodes;
  if (Array.isArray(claimed)) {
    return claimed.map((z) => (typeof z === 'string' ? z : (z?.zipCode || z?.postalCode || z?.zipcode || ''))).filter(Boolean);
  }
  const zips = entity?.zipCodes;
  if (Array.isArray(zips)) {
    return zips.map((z) => (z?.zipCode || z?.postalCode || z?.zipcode || '')).filter(Boolean);
  }
  return [];
}

function filterAgentsByZipMap(rows, zipMap) {
  if (!zipMap || Object.keys(zipMap).length === 0) return rows;
  return rows.filter((row) => {
    const zips = getClaimedZips(row?.raw);
    return zips.some((z) => zipMap[String(z).trim()] != null);
  });
}

function filterLoanOfficersByZipMap(rows, zipMap) {
  if (!zipMap || Object.keys(zipMap).length === 0) return rows;
  return rows.filter((row) => {
    const zips = getClaimedZips(row?.raw);
    return zips.some((z) => zipMap[String(z).trim()] != null);
  });
}

function filterListingsByZipMap(rows, zipMap) {
  if (!zipMap || Object.keys(zipMap).length === 0) return rows;
  return rows.filter((row) => {
    const source = row?.raw?.listing || row?.raw;
    const val = source?.zipCode || source?.zipcode || source?.postalCode || source?.address?.zip;
    return val && zipMap[String(val).trim()] != null;
  });
}

const TAB_CONFIG = [
  { key: 'agents', label: 'Agents', icon: 'person', color: 'blue' },
  { key: 'homes', label: 'Homes for Sale', icon: 'home', color: 'purple' },
  { key: 'openHouses', label: 'Open Houses', icon: 'event', color: 'orange' },
  { key: 'loanOfficers', label: 'Loan Officers', icon: 'accountBalance', color: 'green' },
];

const EMPTY_STATE_CONFIG = {
  agents: {
    title: 'No agents found',
    subtitle: 'Try searching in a different ZIP code or expand your search area.',
    icon: 'person',
  },
  homes: {
    title: 'No listings found',
    subtitle: 'Try searching by ZIP code or city to discover listings.',
    icon: 'home',
  },
  openHouses: {
    title: 'No open houses found',
    subtitle: 'Try searching by ZIP code or city to discover upcoming open houses.',
    icon: 'event',
  },
  loanOfficers: {
    title: 'No loan officers found',
    subtitle: 'Try searching in a different ZIP code or expand your search area.',
    icon: 'accountBalance',
  },
};

export function BuyerHomePage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();
  const { showToast } = useToast();
  const [zipCode, setZipCode] = useState('');
  const [activeTab, setActiveTab] = useState('agents');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [agents, setAgents] = useState([]);
  const [listings, setListings] = useState([]);
  const [openHouses, setOpenHouses] = useState([]);
  const [loanOfficers, setLoanOfficers] = useState([]);
  const [favoriteIds, setFavoriteIds] = useState(new Set());
  const [within10MilesMap, setWithin10MilesMap] = useState({});

  const userId = resolveUserId(user);
  const showToastRef = useRef(showToast);
  showToastRef.current = showToast;

  const load = useCallback(async (zip = '') => {
    setLoading(true);
    setError('');
    let zipMap = {};
    if (zip && /^\d{5}$/.test(String(zip).trim())) {
      try {
        zipMap = await zipApi.getZipCodesWithinMiles(zip.trim(), 10);
        setWithin10MilesMap(zipMap);
      } catch (e) {
        setWithin10MilesMap({});
      }
    } else {
      setWithin10MilesMap({});
    }

    const results = await Promise.allSettled([
      marketplaceApi.getAllAgents(1),
      marketplaceApi.getListings(),
      marketplaceApi.getLoanOfficers(),
    ]);

    const [agentRes, listingRes, loanRes] = results.map((r) => (r.status === 'fulfilled' ? r.value : null));

    const rawAgents = agentRes ? unwrapList(agentRes, ['agents', 'data']) : [];
    const rawListings = listingRes ? unwrapList(listingRes, ['listings', 'data']) : [];
    const rawLoanOfficers = loanRes ? unwrapList(loanRes, ['loanOfficers', 'data']) : [];

    const normalizedOpenHouses = [];
    rawListings.forEach((listing) => {
      const ohs = Array.isArray(listing?.openHouses) ? listing.openHouses : [];
      ohs.forEach((oh, idx) => normalizedOpenHouses.push(normalizeOpenHouse(listing, oh, idx)));
    });

    setAgents(rawAgents.map(normalizeAgent));
    setListings(rawListings.map(normalizeListing));
    setOpenHouses(normalizedOpenHouses);
    setLoanOfficers(rawLoanOfficers.map(normalizeLoanOfficer));

    if (userId) {
      const favs = new Set();
      rawAgents.forEach((a) => {
        const id = a?._id || a?.id;
        const likes = a?.likes;
        if (id && Array.isArray(likes) && likes.includes(userId)) favs.add(`agent-${id}`);
      });
      rawLoanOfficers.forEach((a) => {
        const id = a?._id || a?.id;
        const likes = a?.likes;
        if (id && Array.isArray(likes) && likes.includes(userId)) favs.add(`lo-${id}`);
      });
      rawListings.forEach((a) => {
        const id = a?._id || a?.id;
        const likes = a?.likes;
        if (id && Array.isArray(likes) && likes.includes(userId)) favs.add(`listing-${id}`);
      });
      setFavoriteIds(favs);
    }

    const failures = results.filter((r) => r.status === 'rejected');
    if (failures.length > 0) {
      const msg = failures.length === 3 ? 'Unable to load data. Please try again.' : 'Some data could not be loaded.';
      setError(msg);
      showToastRef.current({ type: 'error', message: msg });
    } else if (zip && Object.keys(zipMap).length > 0) {
      showToastRef.current({ type: 'success', message: `Found results for ZIP ${zip}` });
      if (zip) marketplaceApi.addAgentSearch(zip).catch(() => {});
    }
    setLoading(false);
  }, [userId]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    const tabFromState = location.state?.tab;
    if (tabFromState && TAB_CONFIG.some((t) => t.key === tabFromState)) {
      setActiveTab(tabFromState);
    }
  }, [location.state?.tab]);

  useEffect(() => {
    const prefillZip = location.state?.prefillZip || location.state?.zip;
    if (prefillZip && String(prefillZip).trim()) {
      setZipCode(String(prefillZip).trim());
      setActiveTab('agents');
      load(String(prefillZip).trim());
    }
  }, [location.state?.prefillZip, location.state?.zip]);

  const openRow = useCallback(async (row) => {
    if (!row?.id) return;

    if (activeTab === 'agents') {
      await marketplaceApi.addAgentProfileView(row.id).catch(() => {});
      navigate('/agent-detail', { state: { agent: row.raw } });
      return;
    }

    if (activeTab === 'homes') {
      await marketplaceApi.addListingView(row.id).catch(() => {});
      navigate('/listing-detail', { state: { listing: row.raw } });
      return;
    }

    if (activeTab === 'openHouses') {
      const listingId = row?.raw?.listing?._id || row?.raw?.listing?.id;
      if (listingId) {
        marketplaceApi.addListingView(listingId).catch(() => {});
        marketplaceApi.addListingSearch(listingId).catch(() => {});
      }
      navigate('/listing-detail', { state: { listing: row.raw.listing, openHouse: row.raw.openHouse } });
      return;
    }

    navigate('/loan-officer-detail', { state: { loanOfficer: row.raw } });
  }, [activeTab, navigate]);

  const favoriteRow = useCallback(async (row) => {
    if (!row?.id) return;
    if (!userId) {
      showToast({ type: 'error', message: 'Please sign in to save favorites' });
      return;
    }
    if (activeTab === 'agents') {
      const wasFav = favoriteIds.has(`agent-${row.id}`);
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        if (next.has(`agent-${row.id}`)) next.delete(`agent-${row.id}`);
        else next.add(`agent-${row.id}`);
        return next;
      });
      try {
        await marketplaceApi.likeAgent(row.id, userId);
        showToast({ type: 'success', message: wasFav ? 'Removed from favorites' : 'Added to favorites' });
      } catch (e) {
        setFavoriteIds((prev) => {
          const next = new Set(prev);
          if (wasFav) next.add(`agent-${row.id}`);
          else next.delete(`agent-${row.id}`);
          return next;
        });
        showToast({ type: 'error', message: e?.message || 'Could not update favorite' });
      }
      return;
    }
    if (activeTab === 'homes' || activeTab === 'openHouses') {
      const listing = row?.raw?.listing || row?.raw;
      const listingId = listing?._id || listing?.id;
      if (!listingId) return;
      const wasFav = favoriteIds.has(`listing-${listingId}`);
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        if (next.has(`listing-${listingId}`)) next.delete(`listing-${listingId}`);
        else next.add(`listing-${listingId}`);
        return next;
      });
      try {
        await marketplaceApi.likeListing({ userId, listingId, listing });
        showToast({ type: 'success', message: wasFav ? 'Removed from favorites' : 'Saved listing' });
      } catch (e) {
        setFavoriteIds((prev) => {
          const next = new Set(prev);
          if (wasFav) next.add(`listing-${listingId}`);
          else next.delete(`listing-${listingId}`);
          return next;
        });
        showToast({ type: 'error', message: e?.message || 'Could not save listing' });
      }
      return;
    }
    const wasFav = favoriteIds.has(`lo-${row.id}`);
    setFavoriteIds((prev) => {
      const next = new Set(prev);
      if (next.has(`lo-${row.id}`)) next.delete(`lo-${row.id}`);
      else next.add(`lo-${row.id}`);
      return next;
    });
    try {
      await marketplaceApi.likeLoanOfficer(row.id, userId);
      showToast({ type: 'success', message: wasFav ? 'Removed from favorites' : 'Added to favorites' });
    } catch (e) {
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        if (wasFav) next.add(`lo-${row.id}`);
        else next.delete(`lo-${row.id}`);
        return next;
      });
      showToast({ type: 'error', message: e?.message || 'Could not update favorite' });
    }
  }, [activeTab, userId, favoriteIds, showToast]);

  const tabData = useMemo(() => {
    const zipMap = within10MilesMap;
    return {
      agents: filterAgentsByZipMap(agents, zipMap),
      homes: filterListingsByZipMap(listings, zipMap),
      openHouses: filterListingsByZipMap(openHouses, zipMap),
      loanOfficers: filterLoanOfficersByZipMap(loanOfficers, zipMap),
    };
  }, [agents, listings, openHouses, loanOfficers, within10MilesMap]);

  const kpis = useMemo(() => [
    { label: 'Agents Found', value: String(tabData.agents.length) },
    { label: 'Listings Found', value: String(tabData.homes.length) },
    { label: 'Open Houses', value: String(tabData.openHouses.length) },
    { label: 'Loan Officers', value: String(tabData.loanOfficers.length) },
  ], [tabData]);

  const currentTabConfig = TAB_CONFIG.find((t) => t.key === activeTab);
  const isEmpty = tabData[activeTab].length === 0;

  return (
    <div className="page-body">
      <PageHeader title="Home" subtitle="Find agents, homes, open houses, and rebate-friendly lenders." icon="home" />

      <section className="glass-card buyer-search-panel">
        <div className="buyer-search-copy">
          <h3>Search by ZIP Code</h3>
          <p>Enter your location and discover local rebate-ready professionals and properties.</p>
        </div>
        <div className="buyer-search-controls">
          <ZipInputWithLocation
            value={zipCode}
            onChange={(e) => setZipCode(e.target.value)}
            placeholder="Enter ZIP code (e.g. 10001)"
            onLocationError={(msg) => showToast({ type: 'error', message: msg })}
            onLocationPicked={({ zip }) => {
              if (zip) load(zip);
            }}
          />
          <button
            className="btn primary"
            type="button"
            onClick={() => {
              const z = zipCode.trim();
              if (z && !/^\d{5}$/.test(z)) {
                showToast({ type: 'error', message: 'Please enter a valid 5-digit ZIP code' });
                return;
              }
              load(z || '');
            }}
          >
            Search
          </button>
          {zipCode.trim() && (
            <button
              className="btn ghost"
              type="button"
              onClick={() => {
                setZipCode('');
                load('');
                showToast({ type: 'info', message: 'Showing all results' });
              }}
            >
              Clear
            </button>
          )}
        </div>
      </section>

      <KpiGrid items={kpis} />

      <ActionTiles
        items={[
          { label: 'Rebate Calculator', caption: 'Estimate your closing credit', onClick: () => navigate('/rebate-calculator') },
          { label: 'Full Survey', caption: 'Leave reviews after closing', onClick: () => navigate('/post-closing-survey') },
          { label: 'Buying Checklist', caption: 'Stay compliant end-to-end', onClick: () => navigate('/checklist?type=buyer') },
          { label: 'Selling Checklist', caption: 'Track every milestone', onClick: () => navigate('/checklist?type=seller') },
        ]}
      />

      <section className="glass-card buyer-market">
        <div className="buyer-home-tabs">
          {TAB_CONFIG.map((tab) => (
            <button
              key={tab.key}
              type="button"
              className={`buyer-home-tab buyer-home-tab--${tab.color} ${activeTab === tab.key ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.key)}
            >
              <span className="buyer-home-tab-icon">
                <IconGlyph name={tab.icon} filled={activeTab === tab.key} />
              </span>
              <span className="buyer-home-tab-label">{tab.label}</span>
            </button>
          ))}
        </div>

        {loading ? <AnimatedLoader variant="card" label="Loading data..." /> : null}
        {error ? <p className="error-text">{error}</p> : null}

        {!loading && !error && isEmpty && (
          <div className={`buyer-empty-state buyer-empty-state--${currentTabConfig?.color || 'blue'}`}>
            <div className="buyer-empty-state-icon">
              <IconGlyph name={EMPTY_STATE_CONFIG[activeTab]?.icon || 'search'} filled />
            </div>
            <h3 className="buyer-empty-state-title">{EMPTY_STATE_CONFIG[activeTab]?.title || 'No results'}</h3>
            <p className="buyer-empty-state-subtitle">{EMPTY_STATE_CONFIG[activeTab]?.subtitle || 'Try adjusting your search.'}</p>
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'agents' && (
          <div className="buyer-cards-grid buyer-cards-grid--profile">
            {tabData.agents.map((item) => (
              <AgentCard
                key={item.id}
                agent={item.raw}
                isFavorite={favoriteIds.has(`agent-${item.id}`)}
                onTap={() => openRow(item)}
                onContact={() => { marketplaceApi.addAgentContact(item.id).catch(() => {}); navigate('/buyer-lead-form', { state: { agent: item.raw } }); }}
                onToggleFavorite={() => favoriteRow(item)}
              />
            ))}
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'loanOfficers' && (
          <div className="buyer-cards-grid buyer-cards-grid--profile">
            {tabData.loanOfficers.map((item) => (
              <LoanOfficerCard
                key={item.id}
                loanOfficer={item.raw}
                isFavorite={favoriteIds.has(`lo-${item.id}`)}
                onTap={() => openRow(item)}
                onContact={() => { navigate('/buyer-lead-form', { state: { loanOfficer: item.raw } }); }}
                onToggleFavorite={() => favoriteRow(item)}
              />
            ))}
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'homes' && (
          <div className="buyer-cards-grid buyer-cards-grid--listing">
            {tabData.homes.map((item) => (
              <ListingCard
                key={item.id}
                listing={item.raw}
                isFavorite={favoriteIds.has(`listing-${item.id}`)}
                onTap={() => openRow(item)}
                onToggleFavorite={() => favoriteRow(item)}
              />
            ))}
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'openHouses' && (
          <div className="buyer-cards-grid buyer-cards-grid--listing">
            {tabData.openHouses.map((item) => (
              <OpenHouseCard
                key={item.id}
                listing={item.raw.listing}
                openHouse={item.raw.openHouse}
                isFavorite={favoriteIds.has(`listing-${item.raw.listing?._id || item.raw.listing?.id}`)}
                onTap={() => openRow(item)}
                onToggleFavorite={() => favoriteRow(item)}
              />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
