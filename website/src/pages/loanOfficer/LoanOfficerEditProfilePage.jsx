import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, extractUserFromGetUserById } from '../../lib/api';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import * as userApi from '../../api/user';
import { useToast } from '../../components/ui/ToastProvider';

function parseLicensedStates(data) {
  const raw = data?.licensedStates ?? data?.LisencedStates ?? data?.additionalData?.licensedStates;
  if (Array.isArray(raw)) return raw.map((c) => String(c).toUpperCase());
  if (typeof raw === 'string') {
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed.map((c) => String(c).toUpperCase()) : [];
    } catch {
      return [];
    }
  }
  return [];
}

export function LoanOfficerEditProfilePage() {
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  const { showToast } = useToast();
  const userId = resolveUserId(user);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    fullname: '',
    email: '',
    phone: '',
    liscenceNumber: '',
    CompanyName: '',
    zipCode: '',
    licensedStates: [],
  });

  useEffect(() => {
    let live = true;
    const load = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        const userObj = extractUserFromGetUserById(res);
        const profile = userObj?.loanOfficer || userObj;
        if (!live) return;
        const states = parseLicensedStates(profile);
        setForm({
          fullname: profile?.fullname || profile?.name || user?.fullname || user?.name || '',
          email: profile?.email || user?.email || '',
          phone: profile?.phone || user?.phone || '',
          liscenceNumber: profile?.liscenceNumber || profile?.licenseNumber || profile?.additionalData?.liscenceNumber || '',
          CompanyName: profile?.CompanyName || profile?.additionalData?.CompanyName || '',
          zipCode: profile?.zipCode || profile?.additionalData?.zipCode || profile?.serviceAreas?.[0] || '',
          licensedStates: states,
        });
      } catch {
        if (live) showToast({ type: 'error', message: 'Failed to load profile' });
      } finally {
        if (live) setLoading(false);
      }
    };
    load();
    return () => { live = false; };
  }, [userId]);

  const onChange = (e) => {
    const { name, value } = e.target;
    setForm((p) => ({ ...p, [name]: value }));
  };

  const toggleState = (code) => {
    setForm((p) => ({
      ...p,
      licensedStates: p.licensedStates.includes(code)
        ? p.licensedStates.filter((c) => c !== code)
        : [...p.licensedStates, code],
    }));
  };

  const save = async (e) => {
    e.preventDefault();
    if (!userId) return;
    if (form.licensedStates.length === 0) {
      showToast({ type: 'error', message: 'Please select at least one licensed state' });
      return;
    }
    setSaving(true);
    try {
      const payload = {
        fullname: form.fullname,
        email: form.email,
        phone: form.phone || undefined,
        liscenceNumber: form.liscenceNumber || undefined,
        CompanyName: form.CompanyName || undefined,
        zipCode: form.zipCode || undefined,
        licensedStates: JSON.stringify(form.licensedStates),
      };
      await userApi.updateUser(userId, payload);
      await refreshUser();
      showToast({ type: 'success', message: 'Profile updated' });
      navigate('/loan-officer');
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Failed to save profile' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="page-body">
        <PageHeader title="Edit Profile" subtitle="Loading..." icon="profile" />
      </div>
    );
  }

  return (
    <div className="page-body">
      <PageHeader title="Edit Profile" subtitle="Update your profile and licensed states." icon="profile" />
      <form className="glass-card panel form-stack" onSubmit={save}>
        <h3>Basic Information</h3>
        <input name="fullname" value={form.fullname} onChange={onChange} placeholder="Full name" required />
        <input name="email" type="email" value={form.email} onChange={onChange} placeholder="Email" required readOnly />
        <input name="phone" value={form.phone} onChange={onChange} placeholder="Phone" />

        <h3>Professional Details</h3>
        <input name="liscenceNumber" value={form.liscenceNumber} onChange={onChange} placeholder="License Number" required />
        <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder="Lender Company" />
        <ZipInputWithLocation value={form.zipCode} onChange={onChange} placeholder="Office ZIP (5 digits)" onLocationError={(msg) => showToast({ type: 'error', message: msg })} />

        <h3>Licensed States</h3>
        <p className="form-hint">Select all states where you are licensed. Add more from here to use them in ZIP Code Management.</p>
        <div className="states-chip-grid">
          {US_STATES.map((s) => (
            <button
              key={s.code}
              type="button"
              className={`state-chip-btn ${form.licensedStates.includes(s.code) ? 'selected' : ''}`}
              onClick={() => toggleState(s.code)}
            >
              {s.name} ({s.code})
            </button>
          ))}
        </div>

        <button type="submit" className="btn primary" disabled={saving}>
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </form>
    </div>
  );
}
