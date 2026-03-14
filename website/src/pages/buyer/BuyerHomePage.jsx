import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { ActionTiles, KpiGrid } from '../shared/FeatureCards';
import { resolveUserId, unwrapList } from '../../lib/api';
import { firstImageFromEntity } from '../../lib/media';
import { useAuth } from '../../context/AuthContext';
import * as marketplaceApi from '../../api/marketplace';

function toPrice(value, cents) {
  if (typeof value === 'number' && value > 0) return value;
  if (typeof cents === 'number' && cents > 0) return cents / 100;
  const asNum = Number(value);
  return Number.isFinite(asNum) && asNum > 0 ? asNum : 0;
}

function normalizeAgent(item) {
  return {
    id: item?._id || item?.id,
    title: item?.fullname || item?.name || 'Agent',
    subtitle: item?.CompanyName || item?.companyName || 'Licensed professional',
    badge: item?.rating ? `${item.rating} ★` : 'Agent',
    meta: [item?.city, item?.state, item?.zipCode].filter(Boolean).join(' • ') || 'View full profile',
    image: firstImageFromEntity(item),
    raw: item,
  };
}

function normalizeListing(item) {
  const price = toPrice(item?.price, item?.priceCents);
  const beds = item?.beds || item?.bedrooms || 0;
  const baths = item?.baths || item?.bathrooms || 0;
  return {
    id: item?._id || item?.id,
    title: item?.address || item?.streetAddress || item?.title || 'Listing',
    subtitle: [price ? `$${Number(price).toLocaleString()}` : null, beds ? `${beds} Beds` : null, baths ? `${baths} Baths` : null].filter(Boolean).join(' • '),
    badge: item?.status || (item?.dualAgencyAllowed ? 'Dual Agency Allowed' : 'Listing'),
    meta: [item?.city, item?.state, item?.zipCode].filter(Boolean).join(' • '),
    image: firstImageFromEntity(item),
    raw: item,
  };
}

function normalizeOpenHouse(listing, openHouse, index) {
  const start = openHouse?.startTime || openHouse?.startDateTime || openHouse?.date;
  const end = openHouse?.endTime || openHouse?.toTime;
  const dateLabel = start ? new Date(start).toLocaleDateString() : 'Open House';
  const timeLabel = (start || end)
    ? `${start ? new Date(start).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}${end ? ` - ${new Date(end).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : ''}`
    : 'Time to be announced';

  return {
    id: openHouse?._id || openHouse?.id || `${listing?._id || listing?.id || 'listing'}-${index}`,
    title: listing?.address || listing?.streetAddress || 'Open House Property',
    subtitle: `${dateLabel} • ${timeLabel}`,
    badge: 'Open House',
    meta: openHouse?.notes || [listing?.city, listing?.state, listing?.zipCode].filter(Boolean).join(' • ') || 'Tap for full details',
    image: firstImageFromEntity(listing),
    raw: { listing, openHouse },
  };
}

function normalizeLoanOfficer(item) {
  return {
    id: item?._id || item?.id,
    title: item?.fullname || item?.name || 'Loan Officer',
    subtitle: item?.CompanyName || item?.companyName || 'Mortgage professional',
    badge: item?.licenseNumber || item?.liscenceNumber || 'Loan Officer',
    meta: [item?.city, item?.state, item?.zipCode].filter(Boolean).join(' • ') || 'View profile',
    image: firstImageFromEntity(item),
    raw: item,
  };
}

function filterByZip(rows, zip) {
  if (!zip) return rows;
  const z = String(zip).trim();
  return rows.filter((row) => {
    const source = row?.raw?.listing || row?.raw;
    const value = source?.zipCode || source?.zipcode || source?.postalCode;
    return value ? String(value).startsWith(z) : false;
  });
}

export function BuyerHomePage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [zipCode, setZipCode] = useState('');
  const [activeTab, setActiveTab] = useState('agents');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [agents, setAgents] = useState([]);
  const [listings, setListings] = useState([]);
  const [openHouses, setOpenHouses] = useState([]);
  const [loanOfficers, setLoanOfficers] = useState([]);

  const userId = resolveUserId(user);

  const load = async (zip = '') => {
    setLoading(true);
    setError('');
    try {
      const [agentRes, listingRes, loanRes] = await Promise.all([
        zip ? marketplaceApi.getAgentsByZipCode(zip) : marketplaceApi.getAllAgents(1),
        marketplaceApi.getListings(),
        marketplaceApi.getLoanOfficers(),
      ]);

      const rawAgents = unwrapList(agentRes, ['agents', 'data']);
      const rawListings = unwrapList(listingRes, ['listings', 'data']);
      const rawLoanOfficers = unwrapList(loanRes, ['loanOfficers', 'data']);

      const normalizedListings = rawListings.map(normalizeListing);
      const normalizedOpenHouses = [];
      rawListings.forEach((listing) => {
        const ohs = Array.isArray(listing?.openHouses) ? listing.openHouses : [];
        ohs.forEach((oh, idx) => normalizedOpenHouses.push(normalizeOpenHouse(listing, oh, idx)));
      });

      setAgents(rawAgents.map(normalizeAgent));
      setListings(normalizedListings);
      setOpenHouses(normalizedOpenHouses);
      setLoanOfficers(rawLoanOfficers.map(normalizeLoanOfficer));

      if (zip) await marketplaceApi.addAgentSearch(zip);
    } catch (err) {
      setError(err.message || 'Unable to load home feed.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const openRow = async (row) => {
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
      if (listingId) await marketplaceApi.addListingView(listingId).catch(() => {});
      navigate('/listing-detail', { state: { listing: row.raw.listing, openHouse: row.raw.openHouse } });
      return;
    }

    navigate('/buyer-lead-form', { state: { loanOfficer: row.raw } });
  };

  const favoriteRow = async (row) => {
    if (!row?.id || !userId) return;
    if (activeTab === 'agents') {
      await marketplaceApi.likeAgent(row.id);
      return;
    }
    if (activeTab === 'homes' || activeTab === 'openHouses') {
      const listing = row?.raw?.listing || row?.raw;
      const listingId = listing?._id || listing?.id;
      if (!listingId) return;
      await marketplaceApi.likeListing({ userId, listingId, listing });
      return;
    }
    await marketplaceApi.likeLoanOfficer(row.id);
  };

  const tabData = useMemo(() => ({
    agents: filterByZip(agents, zipCode),
    homes: filterByZip(listings, zipCode),
    openHouses: filterByZip(openHouses, zipCode),
    loanOfficers: filterByZip(loanOfficers, zipCode),
  }), [agents, listings, openHouses, loanOfficers, zipCode]);

  const tabs = [
    { key: 'agents', label: 'Agents' },
    { key: 'homes', label: 'Homes for Sale' },
    { key: 'openHouses', label: 'Open Houses' },
    { key: 'loanOfficers', label: 'Loan Officers' },
  ];

  const kpis = [
    { label: 'Agents Found', value: String(tabData.agents.length) },
    { label: 'Listings Found', value: String(tabData.homes.length) },
    { label: 'Open Houses', value: String(tabData.openHouses.length) },
    { label: 'Loan Officers', value: String(tabData.loanOfficers.length) },
  ];

  return (
    <div className="page-body">
      <PageHeader title="Home" subtitle="Find agents, homes, open houses, and rebate-friendly lenders." icon="home" />

      <section className="glass-card buyer-search-panel">
        <div className="buyer-search-copy">
          <h3>Search by ZIP Code</h3>
          <p>Enter your location and discover local rebate-ready professionals and properties.</p>
        </div>
        <div className="buyer-search-controls">
          <input value={zipCode} onChange={(e) => setZipCode(e.target.value)} placeholder="Enter ZIP code (e.g. 10001)" />
          <button className="btn primary" type="button" onClick={() => load(zipCode.trim())}>Search</button>
        </div>
      </section>

      <KpiGrid items={kpis} />

      <ActionTiles
        items={[
          { label: 'Rebate Calculators', caption: 'Estimate your closing credit', onClick: () => navigate('/rebate-calculator') },
          { label: 'Full Survey', caption: 'Track proposals and outcomes', onClick: () => navigate('/proposals') },
          { label: 'Buying Checklist', caption: 'Stay compliant end-to-end', onClick: () => navigate('/checklist') },
          { label: 'Selling Checklist', caption: 'Track every milestone', onClick: () => navigate('/rebate-checklist') },
        ]}
      />

      <section className="glass-card buyer-market">
        <div className="buyer-tabbar">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              type="button"
              className={`buyer-tab ${activeTab === tab.key ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.key)}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {loading ? <p>Loading data...</p> : null}
        {error ? <p className="error-text">{error}</p> : null}

        <div className="market-grid">
          {tabData[activeTab].map((item) => (
            <article key={item.id} className="market-card">
              <div className="market-card-media-wrap">
                {item.image ? (
                  <img src={item.image} alt={item.title} className="market-card-media" />
                ) : (
                  <div className="market-card-media-fallback">No Image</div>
                )}
              </div>
              <div className="market-card-top">
                <div>
                  <h4>{item.title}</h4>
                  <p>{item.subtitle}</p>
                </div>
                <span>{item.badge}</span>
              </div>
              <small>{item.meta || 'No additional details'}</small>
              <div className="market-card-actions">
                <button className="btn tiny" type="button" onClick={() => openRow(item)}>View Details</button>
                <button className="btn tiny ghost" type="button" onClick={() => favoriteRow(item)}>Save</button>
              </div>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}
