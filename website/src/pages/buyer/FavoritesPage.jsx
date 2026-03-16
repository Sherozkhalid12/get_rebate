import { useEffect, useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { AgentCard } from '../../components/buyer/AgentCard';
import { LoanOfficerCard } from '../../components/buyer/LoanOfficerCard';
import { ListingCard } from '../../components/buyer/ListingCard';
import { OpenHouseCard } from '../../components/buyer/OpenHouseCard';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList } from '../../lib/api';
import * as marketplaceApi from '../../api/marketplace';

const TAB_CONFIG = [
  { key: 'agents', label: 'Agents', icon: 'person', color: 'blue' },
  { key: 'homes', label: 'Homes for Sale', icon: 'home', color: 'purple' },
  { key: 'openHouses', label: 'Open Houses', icon: 'event', color: 'orange' },
  { key: 'loanOfficers', label: 'Loan Officers', icon: 'accountBalance', color: 'green' },
];

function filterByLikes(items, userId, idKey = '_id') {
  return items.filter((item) => {
    const likes = item?.likes;
    return Array.isArray(likes) && likes.includes(userId);
  });
}

function normalizeOpenHouse(listing, openHouse, index) {
  return {
    id: openHouse?._id || openHouse?.id || `${listing?._id || listing?.id || 'listing'}-${index}`,
    raw: { listing, openHouse },
  };
}

export function FavoritesPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const userId = resolveUserId(user);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [agents, setAgents] = useState([]);
  const [loanOfficers, setLoanOfficers] = useState([]);
  const [listings, setListings] = useState([]);
  const [openHouses, setOpenHouses] = useState([]);
  const [activeTab, setActiveTab] = useState('agents');

  useEffect(() => {
    if (!userId) {
      setLoading(false);
      return;
    }
    let live = true;
    setLoading(true);
    setError('');
    Promise.allSettled([
      marketplaceApi.getAllAgents(1),
      marketplaceApi.getLoanOfficers(),
      marketplaceApi.getListings(),
    ])
      .then(([agentRes, loRes, listingRes]) => {
        if (!live) return;
        const rawAgents = agentRes.status === 'fulfilled' ? unwrapList(agentRes.value, ['agents', 'data']) : [];
        const rawLOs = loRes.status === 'fulfilled' ? unwrapList(loRes.value, ['loanOfficers', 'data']) : [];
        const rawListings = listingRes.status === 'fulfilled' ? unwrapList(listingRes.value, ['listings', 'data']) : [];

        const favAgents = filterByLikes(rawAgents, userId).map((a) => ({ id: a?._id || a?.id, raw: a }));
        const favLOs = filterByLikes(rawLOs, userId).map((l) => ({ id: l?._id || l?.id, raw: l }));
        const favListingIds = new Set();
        rawListings.forEach((l) => {
          const likes = l?.likes;
          if (Array.isArray(likes) && likes.includes(userId)) favListingIds.add(l?._id || l?.id);
        });
        const favListings = rawListings
          .filter((l) => favListingIds.has(l?._id || l?.id))
          .map((l) => ({ id: l?._id || l?.id, raw: l }));

        const normalizedOH = [];
        rawListings.forEach((listing) => {
          const ohs = Array.isArray(listing?.openHouses) ? listing.openHouses : [];
          ohs.forEach((oh, idx) => {
            const lid = listing?._id || listing?.id;
            if (lid && favListingIds.has(lid)) normalizedOH.push(normalizeOpenHouse(listing, oh, idx));
          });
        });

        setAgents(favAgents);
        setLoanOfficers(favLOs);
        setListings(favListings);
        setOpenHouses(normalizedOH);
      })
      .catch((e) => {
        if (live) setError(e?.message || 'Unable to load favorites.');
      })
      .finally(() => {
        if (live) setLoading(false);
      });
    return () => { live = false; };
  }, [userId]);

  const favoriteIds = useMemo(() => {
    const s = new Set();
    agents.forEach((a) => s.add(`agent-${a.id}`));
    loanOfficers.forEach((l) => s.add(`lo-${l.id}`));
    listings.forEach((l) => s.add(`listing-${l.id}`));
    openHouses.forEach((oh) => {
      const lid = oh?.raw?.listing?._id || oh?.raw?.listing?.id;
      if (lid) s.add(`listing-${lid}`);
    });
    return s;
  }, [agents, loanOfficers, listings, openHouses]);

  const tabData = useMemo(() => ({
    agents,
    homes: listings,
    openHouses,
    loanOfficers,
  }), [agents, listings, openHouses, loanOfficers]);

  const openRow = (row, type) => {
    if (!row?.id) return;
    if (type === 'agents') {
      marketplaceApi.addAgentProfileView(row.id).catch(() => {});
      navigate('/agent-detail', { state: { agent: row.raw } });
    } else if (type === 'homes' || type === 'openHouses') {
      const listing = row?.raw?.listing || row?.raw;
      const lid = listing?._id || listing?.id;
      if (lid) marketplaceApi.addListingView(lid).catch(() => {});
      if (type === 'openHouses') {
        navigate('/listing-detail', { state: { listing: row.raw.listing, openHouse: row.raw.openHouse } });
      } else {
        navigate('/listing-detail', { state: { listing: row.raw } });
      }
    } else {
      navigate('/loan-officer-detail', { state: { loanOfficer: row.raw } });
    }
  };

  const favoriteRow = async (row, type) => {
    if (!userId) return;
    if (type === 'agents') {
      const wasFav = favoriteIds.has(`agent-${row.id}`);
      try {
        await marketplaceApi.likeAgent(row.id, userId);
        setAgents((prev) => (wasFav ? prev.filter((a) => a.id !== row.id) : prev));
      } catch {
        // Revert on error - would need to reload
      }
    } else if (type === 'loanOfficers') {
      const wasFav = favoriteIds.has(`lo-${row.id}`);
      try {
        await marketplaceApi.likeLoanOfficer(row.id, userId);
        setLoanOfficers((prev) => (wasFav ? prev.filter((l) => l.id !== row.id) : prev));
      } catch {
        // Revert
      }
    } else {
      const listing = row?.raw?.listing || row?.raw;
      const lid = listing?._id || listing?.id;
      if (!lid) return;
      try {
        await marketplaceApi.likeListing({ userId, listingId: lid, listing });
        setListings((prev) => prev.filter((l) => (l?.raw?._id || l?.raw?.id) !== lid));
        setOpenHouses((prev) => prev.filter((oh) => (oh?.raw?.listing?._id || oh?.raw?.listing?.id) !== lid));
      } catch {
        // Revert - would need reload
      }
    }
  };

  const currentData = tabData[activeTab] || [];
  const isEmpty = currentData.length === 0;
  const currentConfig = TAB_CONFIG.find((t) => t.key === activeTab);

  return (
    <div className="page-body">
      <PageHeader title="Favorites" subtitle="Your saved agents, lenders, and listings." icon="heart" />

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

        {loading ? <AnimatedLoader variant="card" label="Loading favorites..." /> : null}
        {error ? <p className="error-text">{error}</p> : null}

        {!loading && !error && isEmpty && (
          <div className={`buyer-empty-state buyer-empty-state--${currentConfig?.color || 'blue'}`}>
            <div className="buyer-empty-state-icon">
              <IconGlyph name="heart" filled />
            </div>
            <h3 className="buyer-empty-state-title">No favorites yet</h3>
            <p className="buyer-empty-state-subtitle">
              Save agents, loan officers, and listings from the Home or Find Agents page to see them here.
            </p>
            <button type="button" className="btn primary" onClick={() => navigate('/app')}>
              Browse Home
            </button>
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'agents' && (
          <div className="buyer-cards-grid buyer-cards-grid--profile">
            {currentData.map((item) => (
              <AgentCard
                key={item.id}
                agent={item.raw}
                isFavorite={favoriteIds.has(`agent-${item.id}`)}
                onTap={() => openRow(item, 'agents')}
                onContact={() => { marketplaceApi.addAgentContact(item.id).catch(() => {}); navigate('/buyer-lead-form', { state: { agent: item.raw } }); }}
                onToggleFavorite={() => favoriteRow(item, 'agents')}
              />
            ))}
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'loanOfficers' && (
          <div className="buyer-cards-grid buyer-cards-grid--profile">
            {currentData.map((item) => (
              <LoanOfficerCard
                key={item.id}
                loanOfficer={item.raw}
                isFavorite={favoriteIds.has(`lo-${item.id}`)}
                onTap={() => openRow(item, 'loanOfficers')}
                onContact={() => { navigate('/buyer-lead-form', { state: { loanOfficer: item.raw } }); }}
                onToggleFavorite={() => favoriteRow(item, 'loanOfficers')}
              />
            ))}
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'homes' && (
          <div className="buyer-cards-grid buyer-cards-grid--listing">
            {currentData.map((item) => (
              <ListingCard
                key={item.id}
                listing={item.raw}
                isFavorite={favoriteIds.has(`listing-${item.id}`)}
                onTap={() => openRow(item, 'homes')}
                onToggleFavorite={() => favoriteRow(item, 'homes')}
              />
            ))}
          </div>
        )}

        {!loading && !error && !isEmpty && activeTab === 'openHouses' && (
          <div className="buyer-cards-grid buyer-cards-grid--listing">
            {currentData.map((item) => (
              <OpenHouseCard
                key={item.id}
                listing={item.raw.listing}
                openHouse={item.raw.openHouse}
                isFavorite={favoriteIds.has(`listing-${item.raw.listing?._id || item.raw.listing?.id}`)}
                onTap={() => openRow(item, 'openHouses')}
                onToggleFavorite={() => favoriteRow(item, 'openHouses')}
              />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
