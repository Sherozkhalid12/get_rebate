import { useEffect, useMemo, useState, useCallback, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AgentCard } from '../../components/buyer/AgentCard';
import { useToast } from '../../components/ui/ToastProvider';
import { resolveUserId, unwrapList } from '../../lib/api';
import { useAuth } from '../../context/AuthContext';
import * as marketplaceApi from '../../api/marketplace';
import * as zipApi from '../../api/zipcodes';

function normalizeAgent(item) {
  return { id: item?._id || item?.id, raw: item };
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

export function FindAgentsPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();
  const { showToast } = useToast();
  const [zipCode, setZipCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [agents, setAgents] = useState([]);
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

    try {
      const res = await marketplaceApi.getAllAgents(1);
      const rawAgents = unwrapList(res, ['agents', 'data']) || [];
      setAgents(rawAgents.map(normalizeAgent));

      if (userId) {
        const favs = new Set();
        rawAgents.forEach((a) => {
          const id = a?._id || a?.id;
          const likes = a?.likes;
          if (id && Array.isArray(likes) && likes.includes(userId)) favs.add(`agent-${id}`);
        });
        setFavoriteIds(favs);
      }

      if (zip && Object.keys(zipMap).length > 0) {
        showToastRef.current({ type: 'success', message: `Found agents for ZIP ${zip}` });
        marketplaceApi.addAgentSearch(zip).catch(() => {});
      }
    } catch (e) {
      setError(e?.message || 'Unable to load agents.');
      showToastRef.current({ type: 'error', message: e?.message || 'Unable to load agents.' });
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    const prefillZip = location.state?.prefillZip || location.state?.zip;
    if (prefillZip && String(prefillZip).trim()) {
      setZipCode(String(prefillZip).trim());
      load(String(prefillZip).trim());
    }
  }, [location.state?.prefillZip, location.state?.zip]);

  const handleSearch = () => {
    const z = zipCode.trim();
    if (z && !/^\d{5}$/.test(z)) {
      showToastRef.current({ type: 'error', message: 'Please enter a valid 5-digit ZIP code' });
      return;
    }
    load(z || '');
  };

  const openRow = useCallback((row) => {
    if (!row?.id) return;
    marketplaceApi.addAgentProfileView(row.id).catch(() => {});
    navigate('/agent-detail', { state: { agent: row.raw } });
  }, [navigate]);

  const favoriteRow = useCallback(async (row) => {
    if (!row?.id) return;
    if (!userId) {
      showToastRef.current({ type: 'error', message: 'Please sign in to save favorites' });
      return;
    }
    const wasFav = favoriteIds.has(`agent-${row.id}`);
    setFavoriteIds((prev) => {
      const next = new Set(prev);
      if (next.has(`agent-${row.id}`)) next.delete(`agent-${row.id}`);
      else next.add(`agent-${row.id}`);
      return next;
    });
    try {
      await marketplaceApi.likeAgent(row.id, userId);
      showToastRef.current({ type: 'success', message: wasFav ? 'Removed from favorites' : 'Added to favorites' });
    } catch (e) {
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        if (wasFav) next.add(`agent-${row.id}`);
        else next.delete(`agent-${row.id}`);
        return next;
      });
      showToastRef.current({ type: 'error', message: e?.message || 'Could not update favorite' });
    }
  }, [userId, favoriteIds]);

  const tabData = useMemo(() => filterAgentsByZipMap(agents, within10MilesMap), [agents, within10MilesMap]);
  const isEmpty = tabData.length === 0;
  const hasZipFilter = zipCode.trim() && /^\d{5}$/.test(zipCode.trim());

  return (
    <div className="page-body">
      <PageHeader
        title="Find Agents Near You"
        subtitle={hasZipFilter ? `Agents in ${zipCode.trim()} (within 10 miles)` : 'Search by ZIP code to find rebate-friendly agents'}
        icon="person"
      />

      <section className="glass-card buyer-search-panel">
        <div className="buyer-search-copy">
          <h3>Search by ZIP Code</h3>
          <p>Enter your location to discover local rebate-ready agents. Same search as the app.</p>
        </div>
        <div className="buyer-search-controls">
          <ZipInputWithLocation
            value={zipCode}
            onChange={(e) => setZipCode(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            placeholder="Enter ZIP code (e.g. 10001)"
            onLocationError={(msg) => showToastRef.current({ type: 'error', message: msg })}
            onLocationPicked={({ zip }) => {
              if (zip) load(zip);
            }}
          />
          <button className="btn primary" type="button" onClick={handleSearch}>
            Search
          </button>
          {zipCode.trim() && (
            <button
              className="btn ghost"
              type="button"
              onClick={() => {
                setZipCode('');
                load('');
                showToastRef.current({ type: 'info', message: 'Showing all agents' });
              }}
            >
              Clear
            </button>
          )}
        </div>
      </section>

      {loading ? <AnimatedLoader variant="card" label="Loading agents..." /> : null}
      {error ? <p className="error-text">{error}</p> : null}

      {!loading && !error && isEmpty && (
        <div className="buyer-empty-state buyer-empty-state--blue">
          <div className="buyer-empty-state-icon">
            <IconGlyph name="person" filled />
          </div>
          <h3 className="buyer-empty-state-title">No agents found</h3>
          <p className="buyer-empty-state-subtitle">
            {hasZipFilter ? 'Try searching in a different ZIP code or expand your search area.' : 'Try searching by ZIP code to find agents in your area.'}
          </p>
        </div>
      )}

      {!loading && !error && !isEmpty && (
        <section className="glass-card buyer-market">
          <div className="buyer-cards-grid buyer-cards-grid--profile">
            {tabData.map((item) => (
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
        </section>
      )}
    </div>
  );
}
