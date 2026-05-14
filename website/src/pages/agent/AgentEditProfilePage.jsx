import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, extractUserFromGetUserById } from '../../lib/api';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { MediaUploadField } from '../../components/ui/MediaUploadField';
import { AGENT_EXPERTISE_OPTIONS } from '../../lib/profileOptions';
import { buildUpdateUserProfileFormData } from '../../lib/buildUpdateUserProfileFormData';
import { resolveMediaUrl } from '../../lib/media';
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

function parseJsonStringArray(raw) {
  if (Array.isArray(raw)) return raw.map((x) => String(x));
  if (typeof raw === 'string') {
    try {
      const p = JSON.parse(raw);
      return Array.isArray(p) ? p.map((x) => String(x)) : [];
    } catch {
      return [];
    }
  }
  return [];
}

function additionalBlock(data) {
  const add = data?.additionalData;
  return add && typeof add === 'object' ? add : {};
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
    bio: '',
    description: '',
    liscenceNumber: '',
    CompanyName: '',
    zipCode: '',
    website_link: '',
    google_reviews_link: '',
    thirdPartReviewLink: '',
    licensedStates: [],
    areasOfExpertise: [],
    dualAgencyState: null,
    dualAgencySBrokerage: null,
  });
  const [files, setFiles] = useState({ profilePic: null, companyLogo: null, video: null });
  const [existingMedia, setExistingMedia] = useState({ profile: '', companyLogo: '', video: '' });

  const profileObjectUrl = useMemo(() => {
    if (!(files.profilePic instanceof File)) return '';
    return URL.createObjectURL(files.profilePic);
  }, [files.profilePic]);

  const logoObjectUrl = useMemo(() => {
    if (!(files.companyLogo instanceof File)) return '';
    return URL.createObjectURL(files.companyLogo);
  }, [files.companyLogo]);

  useEffect(() => () => {
    if (profileObjectUrl) URL.revokeObjectURL(profileObjectUrl);
  }, [profileObjectUrl]);

  useEffect(() => () => {
    if (logoObjectUrl) URL.revokeObjectURL(logoObjectUrl);
  }, [logoObjectUrl]);

  useEffect(() => {
    let live = true;
    const load = async () => {
      if (!userId) return;
      try {
        const res = await userApi.getUserById(userId);
        const data = extractUserFromGetUserById(res);
        if (!live) return;
        const add = additionalBlock(data);
        const states = parseLicensedStates(data);
        const expertise = parseJsonStringArray(data?.areasOfExpertise ?? add?.areasOfExpertise);

        const ds = data?.dualAgencyState ?? add?.dualAgencyState ?? data?.isDualAgencyAllowedInState;
        const db = data?.dualAgencySBrokerage ?? add?.dualAgencySBrokerage ?? data?.isDualAgencyAllowedAtBrokerage;

        setForm({
          fullname: data?.fullname || data?.name || user?.fullname || user?.name || '',
          email: data?.email || user?.email || '',
          phone: data?.phone || user?.phone || '',
          bio: data?.bio ?? add?.bio ?? '',
          description: data?.description ?? add?.description ?? '',
          liscenceNumber: data?.liscenceNumber || data?.licenseNumber || add?.liscenceNumber || '',
          CompanyName: data?.CompanyName || add?.CompanyName || '',
          zipCode: data?.zipCode || add?.zipCode || (Array.isArray(add?.serviceAreas) && add.serviceAreas[0]) || (typeof add?.serviceAreas === 'string' ? add.serviceAreas : '') || '',
          website_link: add?.website_link || add?.websiteUrl || data?.website_link || '',
          google_reviews_link: add?.google_reviews_link || data?.google_reviews_link || '',
          thirdPartReviewLink: add?.thirdPartReviewLink || data?.thirdPartReviewLink || '',
          licensedStates: states,
          areasOfExpertise: expertise,
          dualAgencyState: typeof ds === 'boolean' ? ds : null,
          dualAgencySBrokerage: typeof db === 'boolean' ? db : null,
        });

        setExistingMedia({
          profile: resolveMediaUrl(data?.profilePic || data?.profileImage || user?.profilePic || user?.profileImage),
          companyLogo: resolveMediaUrl(add?.companyLogo || add?.company_logo || data?.companyLogo),
          video: resolveMediaUrl(add?.video || add?.videoUrl || data?.video),
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

  const toggleExpertise = (label) => {
    setForm((p) => ({
      ...p,
      areasOfExpertise: p.areasOfExpertise.includes(label)
        ? p.areasOfExpertise.filter((x) => x !== label)
        : [...p.areasOfExpertise, label],
    }));
  };

  const save = async (e) => {
    e.preventDefault();
    if (!userId) return;
    if (form.dualAgencyState !== true && form.dualAgencyState !== false) {
      showToast({ type: 'error', message: 'Please answer whether dual agency is allowed in your state' });
      return;
    }
    if (form.dualAgencySBrokerage !== true && form.dualAgencySBrokerage !== false) {
      showToast({ type: 'error', message: 'Please answer whether dual agency is allowed at your brokerage' });
      return;
    }
    if (!form.liscenceNumber?.trim()) {
      showToast({ type: 'error', message: 'Please enter your license number' });
      return;
    }
    if (!form.CompanyName?.trim()) {
      showToast({ type: 'error', message: 'Please enter your company name' });
      return;
    }
    if (!/^\d{5}$/.test(String(form.zipCode || '').trim())) {
      showToast({ type: 'error', message: 'Please enter a valid 5-digit office ZIP code' });
      return;
    }
    if (form.licensedStates.length === 0) {
      showToast({ type: 'error', message: 'Please select at least one licensed state' });
      return;
    }

    setSaving(true);
    try {
      const fd = buildUpdateUserProfileFormData(
        'agent',
        {
          ...form,
          dualAgencyState: form.dualAgencyState,
          dualAgencySBrokerage: form.dualAgencySBrokerage,
        },
        files,
      );
      await userApi.updateUser(userId, fd);
      await refreshUser();
      showToast({ type: 'success', message: 'Profile updated' });
      navigate('/agent');
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Failed to save profile' });
    } finally {
      setSaving(false);
    }
  };

  const profileImgSrc = profileObjectUrl || existingMedia.profile;
  const logoImgSrc = logoObjectUrl || existingMedia.companyLogo;

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
      <PageHeader title="Edit Profile" subtitle="Update your public profile and licensing." icon="profile" />
      <form className="glass-card panel form-stack edit-profile-shell" onSubmit={save}>
        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Photos & branding</h3>
          <div className="edit-profile-media-row">
            <div className="edit-profile-media-cell">
              <div className="profile-edit-media-preview">
                {profileImgSrc ? (
                  <img className="profile-edit-avatar" src={profileImgSrc} alt="" />
                ) : (
                  <div className="profile-edit-avatar" aria-hidden />
                )}
              </div>
              <MediaUploadField
                label="Headshot"
                hint="Optional"
                accept="image/*"
                variant="profile"
                file={files.profilePic}
                onFileChange={(f) => setFiles((p) => ({ ...p, profilePic: f }))}
              />
            </div>
            <div className="edit-profile-media-cell">
              <div className="profile-edit-media-preview">
                {logoImgSrc ? (
                  <img className="profile-edit-logo" src={logoImgSrc} alt="" />
                ) : (
                  <div className="profile-edit-logo" aria-hidden />
                )}
              </div>
              <MediaUploadField
                label="Company logo"
                hint="Optional"
                accept="image/*"
                variant="logo"
                file={files.companyLogo}
                onFileChange={(f) => setFiles((p) => ({ ...p, companyLogo: f }))}
              />
            </div>
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Basic information</h3>
          <div className="edit-profile-form-grid edit-profile-form-grid--2">
            <input name="fullname" value={form.fullname} onChange={onChange} placeholder="Full name" required />
            <input name="phone" value={form.phone} onChange={onChange} placeholder="Phone" />
            <input name="liscenceNumber" value={form.liscenceNumber} onChange={onChange} placeholder="License number" required />
            <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder="Company name" required />
            <input className="full-span" name="email" type="email" value={form.email} onChange={onChange} placeholder="Email" required readOnly />
            <p className="form-hint full-span">Email cannot be changed.</p>
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">About</h3>
          <textarea name="bio" value={form.bio} onChange={onChange} placeholder="Bio" rows={3} />
          <textarea name="description" value={form.description} onChange={onChange} placeholder="Description" rows={3} />
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Video introduction</h3>
          <p className="form-hint">Short intro clip (optional).</p>
          {existingMedia.video && !files.video ? (
            <p className="profile-edit-video-link">
              <a href={existingMedia.video} target="_blank" rel="noopener noreferrer">Current video</a>
            </p>
          ) : null}
          <MediaUploadField
            label="Video file"
            hint="Optional"
            accept="video/*"
            variant="video"
            file={files.video}
            onFileChange={(f) => setFiles((p) => ({ ...p, video: f }))}
          />
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Dual agency</h3>
          <div className="edit-profile-dual">
            <p className="profile-yes-no-help">
              When your brokerage represents both sides of the same transaction.
            </p>
            <p className="profile-yes-no-label">Allowed in your state?</p>
            <div className="yes-no-row">
              <button
                type="button"
                className={`yes-no-btn ${form.dualAgencyState === true ? 'selected' : ''}`}
                onClick={() => setForm((p) => ({ ...p, dualAgencyState: true }))}
              >
                Yes
              </button>
              <button
                type="button"
                className={`yes-no-btn ${form.dualAgencyState === false ? 'selected' : ''}`}
                onClick={() => setForm((p) => ({ ...p, dualAgencyState: false }))}
              >
                No
              </button>
            </div>
            <p className="profile-yes-no-label">Allowed at your brokerage?</p>
            <div className="yes-no-row">
              <button
                type="button"
                className={`yes-no-btn ${form.dualAgencySBrokerage === true ? 'selected' : ''}`}
                onClick={() => setForm((p) => ({ ...p, dualAgencySBrokerage: true }))}
              >
                Yes
              </button>
              <button
                type="button"
                className={`yes-no-btn ${form.dualAgencySBrokerage === false ? 'selected' : ''}`}
                onClick={() => setForm((p) => ({ ...p, dualAgencySBrokerage: false }))}
              >
                No
              </button>
            </div>
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Office ZIP</h3>
          <p className="form-hint">5-digit office ZIP from signup.</p>
          <ZipInputWithLocation value={form.zipCode} onChange={onChange} placeholder="Office ZIP" onLocationError={(msg) => showToast({ type: 'error', message: msg })} />
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Areas of expertise</h3>
          <p className="form-hint">Select all that apply.</p>
          <div className="edit-profile-chip-scroll">
            <div className="states-chip-grid auth-profile-chip-grid">
              {AGENT_EXPERTISE_OPTIONS.map((label) => (
                <button
                  key={label}
                  type="button"
                  className={`state-chip-btn auth-profile-chip ${form.areasOfExpertise.includes(label) ? 'selected' : ''}`}
                  onClick={() => toggleExpertise(label)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Professional links</h3>
          <div className="edit-profile-form-grid edit-profile-form-grid--2">
            <input name="website_link" value={form.website_link} onChange={onChange} placeholder="Website (https://…)" />
            <input name="google_reviews_link" value={form.google_reviews_link} onChange={onChange} placeholder="Google reviews URL" />
            <input className="full-span" name="thirdPartReviewLink" value={form.thirdPartReviewLink} onChange={onChange} placeholder="Other reviews URL" />
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Licensed states</h3>
          <p className="form-hint">Hover a code for full state name. Used for ZIP management.</p>
          <div className="edit-profile-chip-scroll">
            <div className="states-chip-grid">
              {US_STATES.map((s) => (
                <button
                  key={s.code}
                  type="button"
                  title={`${s.name} (${s.code})`}
                  className={`state-chip-btn ${form.licensedStates.includes(s.code) ? 'selected' : ''}`}
                  onClick={() => toggleState(s.code)}
                >
                  {s.code}
                </button>
              ))}
            </div>
          </div>
        </section>

        <section className="edit-profile-section edit-profile-section--actions">
          <button type="submit" className="btn primary btn-with-loader" disabled={saving}>
            {saving ? (
              <span className="btn-loading-content"><AnimatedLoader variant="button" label="" />Saving…</span>
            ) : (
              'Save changes'
            )}
          </button>
        </section>
      </form>
    </div>
  );
}
