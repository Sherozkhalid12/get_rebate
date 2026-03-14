import { Link } from 'react-router-dom';
import { useState } from 'react';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId } from '../../lib/api';
import * as userApi from '../../api/user';

export function ProfilePage() {
  const { user, setUser } = useAuth();
  const [name, setName] = useState(user?.fullname || user?.name || '');
  const [email, setEmail] = useState(user?.email || '');
  const [status, setStatus] = useState('');

  const save = async () => {
    const userId = resolveUserId(user);
    if (!userId) return;
    setStatus('Saving...');
    try {
      const payload = { fullname: name, email };
      const res = await userApi.updateUser(userId, payload);
      const updated = res?.user || res?.data?.user || { ...user, ...payload };
      setUser(updated);
      setStatus('Profile updated.');
    } catch (err) {
      setStatus(err.message || 'Profile update failed.');
    }
  };

  return (
    <div className="page-body">
      <PageHeader title="Profile" subtitle="Manage account, settings, and legal." icon="profile" />
      <section className="glass-card profile-grid">
        <div>
          <h3>{user?.fullname || user?.name || 'User'}</h3>
          <p>{user?.email}</p>
          <small>Role: {user?.role}</small>
        </div>
        <form className="form-stack" onSubmit={(e) => e.preventDefault()}>
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" />
          <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" />
          <button type="button" className="btn primary" onClick={save}>Save Changes</button>
          {status ? <small>{status}</small> : null}
        </form>
      </section>

      <section className="glass-card panel">
        <h3>Settings</h3>
        <div className="quick-links">
          <Link to="/proposals">My Proposals</Link>
          <Link to="/notifications">Notifications</Link>
          <Link to="/help-support">Help & Support</Link>
          <Link to="/privacy-policy">Privacy Policy</Link>
          <Link to="/terms-of-service">Terms of Service</Link>
          <Link to="/about-legal">About & Legal</Link>
        </div>
      </section>
    </div>
  );
}
