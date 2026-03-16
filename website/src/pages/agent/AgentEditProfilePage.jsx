import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, extractUserFromGetUserById } from '../../lib/api';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
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

export function AgentEditProfilePage() {
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
    isDualAgencyAllowedInState: false,
    isDualAgencyAllowedAtBrokerage: false,
  });

  useEffect(() => {
    let live = true;
    const load = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        const data = extractUserFromGetUserById(res);
        if (!live) return;
        const states = parseLicensedStates(data);
        setForm({
          fullname: data?.fullname || data?.name || user?.fullname || user?.name || '',
          email: data?.email || user?.email || '',
          phone: data?.phone || user?.phone || '',
          liscenceNumber: data?.liscenceNumber || data?.licenseNumber || data?.additionalData?.liscenceNumber || '',
          CompanyName: data?.CompanyName || data?.additionalData?.CompanyName || '',
          zipCode: data?.zipCode || data?.additionalData?.zipCode || data?.serviceAreas?.[0] || '',
          licensedStates: states,
          isDualAgencyAllowedInState: data?.dualAgencyState ?? data?.isDualAgencyAllowedInState ?? data?.additionalData?.dualAgencyState ?? false,
          isDualAgencyAllowedAtBrokerage: data?.dualAgencySBrokerage ?? data?.isDualAgencyAllowedAtBrokerage ?? data?.additionalData?.dualAgencySBrokerage ?? false,
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
    const { name, value, type, checked } = e.target;
    setForm((p) => ({ ...p, [name]: type === 'checkbox' ? checked : value }));
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
        dualAgencyState: form.isDualAgencyAllowedInState,
        dualAgencySBrokerage: form.isDualAgencyAllowedAtBrokerage,
      };
      await userApi.updateUser(userId, payload);
      await refreshUser();
      showToast({ type: 'success', message: 'Profile updated' });
      navigate('/agent');
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Failed to save profile' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="page-body">
        <PageHeader title="Edit Profile" subtitle="Update your profile and licensed states." icon="profile" />
        <AnimatedLoader variant="full" label="Loading profile..." />
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
        <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder="Company / Brokerage" />
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

        <h3>Dual Agency</h3>
        <label className="checkbox-row"><input type="checkbox" name="isDualAgencyAllowedInState" checked={form.isDualAgencyAllowedInState} onChange={onChange} /> <span>Dual agency allowed in state</span></label>
        <label className="checkbox-row"><input type="checkbox" name="isDualAgencyAllowedAtBrokerage" checked={form.isDualAgencyAllowedAtBrokerage} onChange={onChange} /> <span>Dual agency allowed at brokerage</span></label>

        <button type="submit" className="btn primary btn-with-loader" disabled={saving}>
          {saving ? (
            <span className="btn-loading-content"><AnimatedLoader variant="button" label="" />Saving...</span>
          ) : (
            'Save Changes'
          )}
        </button>
      </form>
    </div>
  );
}
