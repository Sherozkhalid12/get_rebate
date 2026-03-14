import { useEffect, useState } from 'react';
import { PageHeader } from '../../components/layout/PageHeader';
import { ListPanel } from '../shared/FeatureCards';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, unwrapList, unwrapObject } from '../../lib/api';
import * as userApi from '../../api/user';

function normalizeFavoriteRows(profile) {
  const items = [];
  const agents = unwrapList(profile?.favoriteAgents || profile?.likedAgents || [], []);
  const loanOfficers = unwrapList(profile?.favoriteLoanOfficers || profile?.likedLoanOfficers || [], []);
  const listings = unwrapList(profile?.favoriteListings || profile?.likedListings || [], []);

  agents.forEach((a) => {
    items.push({
      id: `agent-${a._id || a.id}`,
      name: a.fullname || a.name || 'Agent',
      preview: a.CompanyName || a.companyName || 'Agent profile',
    });
  });

  loanOfficers.forEach((l) => {
    items.push({
      id: `lo-${l._id || l.id}`,
      name: l.fullname || l.name || 'Loan Officer',
      preview: l.CompanyName || l.companyName || 'Loan officer profile',
    });
  });

  listings.forEach((p) => {
    items.push({
      id: `listing-${p._id || p.id}`,
      name: p.address || p.title || 'Listing',
      preview: p.price ? `$${Number(p.price).toLocaleString()}` : 'Property listing',
    });
  });

  return items;
}

export function FavoritesPage() {
  const { user } = useAuth();
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    let live = true;
    const run = async () => {
      const userId = resolveUserId(user);
      if (!userId) return;
      try {
        const response = await userApi.getUserById(userId);
        if (!live) return;
        const profile = unwrapObject(response, ['user']);
        setRows(normalizeFavoriteRows(profile));
      } catch (err) {
        if (!live) return;
        setError(err.message || 'Unable to load favorites.');
      }
    };
    run();
    return () => {
      live = false;
    };
  }, [user]);

  return (
    <div className="page-body">
      <PageHeader title="Favorites" subtitle="Your saved agents, lenders, and listings." icon="heart" />
      {error ? <p className="error-text">{error}</p> : null}
      <ListPanel title="Saved Connections" rows={rows} renderRight={() => <button className="btn tiny">Open</button>} />
    </div>
  );
}
