import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, extractUserFromGetUserById } from '../../lib/api';
import { US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { MediaUploadField } from '../../components/ui/MediaUploadField';
import { ProfileUploadGuidelines } from '../../components/ui/ProfileUploadGuidelines';
import { networkUploadErrorMessage } from '../../lib/mediaUpload';
import { LOAN_SPECIALTY_OPTIONS } from '../../lib/profileOptions';
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

function normalizeMortgageUrl(raw) {
  const u = String(raw || '').trim();
  if (!u) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  return `https://${u}`;
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
    bio: '',
    liscenceNumber: '',
    CompanyName: '',
    zipCode: '',
    website_link: '',
    mortgageApplicationUrl: '',
    thirdPartReviewLink: '',
    licensedStates: [],
    specialtyProducts: [],
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
        const root = extractUserFromGetUserById(res);
        const lo = root?.loanOfficer && typeof root.loanOfficer === 'object' ? root.loanOfficer : root;
        const add = additionalBlock(root);
        if (!live) return;

        let states = parseLicensedStates(lo);
        if (!states.length) states = parseLicensedStates(root);
        const specialty = parseJsonStringArray(
          lo?.specialtyProducts ?? add?.specialtyProducts ?? add?.areasOfExpertise,
        );

        const zipFromLo = lo?.claimedZipCodes;
        let zipFallback = '';
        if (Array.isArray(zipFromLo) && zipFromLo.length > 0) {
          zipFallback = String(zipFromLo[0]);
        }

        setForm({
          fullname: lo?.fullname || lo?.name || user?.fullname || user?.name || '',
          email: lo?.email || user?.email || '',
          phone: lo?.phone || user?.phone || '',
          bio: lo?.bio ?? add?.bio ?? '',
          liscenceNumber: lo?.liscenceNumber || lo?.licenseNumber || add?.liscenceNumber || '',
          CompanyName: lo?.CompanyName || lo?.company || add?.CompanyName || '',
          zipCode: lo?.zipCode || add?.zipCode || (Array.isArray(add?.serviceAreas) && add.serviceAreas[0]) || (typeof add?.serviceAreas === 'string' ? add.serviceAreas : '') || zipFallback || '',
          website_link: add?.website_link || add?.websiteUrl || lo?.website_link || '',
          mortgageApplicationUrl: lo?.mortgageApplicationUrl || lo?.mortagelink || add?.mortgageApplicationUrl || add?.mortagelink || '',
          thirdPartReviewLink: lo?.externalReviewsUrl || add?.thirdPartReviewLink || '',
          licensedStates: states,
          specialtyProducts: specialty,
        });

        setExistingMedia({
          profile: resolveMediaUrl(lo?.profilePic || lo?.profileImage || root?.profilePic || root?.profileImage),
          companyLogo: resolveMediaUrl(lo?.companyLogo || lo?.companyLogoUrl || add?.companyLogo),
          video: resolveMediaUrl(add?.video || add?.videoUrl || lo?.video),
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

  const toggleProduct = (label) => {
    setForm((p) => ({
      ...p,
      specialtyProducts: p.specialtyProducts.includes(label)
        ? p.specialtyProducts.filter((x) => x !== label)
        : [...p.specialtyProducts, label],
    }));
  };

  const openMortgageLink = () => {
    const raw = form.mortgageApplicationUrl?.trim();
    if (!raw) {
      showToast({ type: 'error', message: 'Enter a mortgage application URL first.' });
      return;
    }
    const url = normalizeMortgageUrl(raw);
    try {
      const u = new URL(url);
      if (!u.protocol.startsWith('http')) throw new Error();
    } catch {
      showToast({ type: 'error', message: 'Please enter a valid URL.' });
      return;
    }
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  const save = async (e) => {
    e.preventDefault();
    if (!userId) return;
    if (!form.CompanyName?.trim()) {
      showToast({ type: 'error', message: 'Please enter your company name' });
      return;
    }
    if (!form.liscenceNumber?.trim()) {
      showToast({ type: 'error', message: 'Please enter your license number' });
      return;
    }
    if (!/^\d{5}$/.test(String(form.zipCode || '').trim())) {
      showToast({ type: 'error', message: 'Please enter a valid 5-digit office ZIP code' });
      return;
    }

    setSaving(true);
    try {
      const fd = buildUpdateUserProfileFormData('loanOfficer', { ...form }, files);
      await userApi.updateUser(userId, fd);
      await refreshUser();
      showToast({ type: 'success', message: 'Profile updated' });
      navigate('/loan-officer');
    } catch (err) {
      showToast({ type: 'error', message: networkUploadErrorMessage(err) || 'Failed to save profile' });
    } finally {
      setSaving(false);
    }
  };

  const profileImgSrc = profileObjectUrl || existingMedia.profile;
  const logoImgSrc = logoObjectUrl || existingMedia.companyLogo;

  if (loading) {
    return (
      <div className="page-body page-body--loan-officer">
        <PageHeader title="Edit Profile" subtitle="Update your profile and licensed states." icon="profile" />
        <AnimatedLoader variant="full" label="Loading profile..." />
      </div>
    );
  }

  return (
    <div className="page-body page-body--loan-officer">
      <PageHeader title="Edit Profile" subtitle="Update your public profile and licensing." icon="profile" />
      <form className="glass-card panel form-stack edit-profile-shell" onSubmit={save}>
        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Photos & branding</h3>
          <ProfileUploadGuidelines />
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
                variant="profile"
                file={files.profilePic}
                onFileChange={(f) => setFiles((p) => ({ ...p, profilePic: f }))}
                onValidationError={(msg) => showToast({ type: 'error', message: msg })}
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
                variant="logo"
                file={files.companyLogo}
                onFileChange={(f) => setFiles((p) => ({ ...p, companyLogo: f }))}
                onValidationError={(msg) => showToast({ type: 'error', message: msg })}
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
            <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder="Lender / company" required />
            <input className="full-span" name="email" type="email" value={form.email} onChange={onChange} placeholder="Email" required readOnly />
            <p className="form-hint full-span">Email cannot be changed.</p>
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">About</h3>
          <textarea name="bio" value={form.bio} onChange={onChange} placeholder="Bio" rows={3} />
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Office ZIP</h3>
          <p className="form-hint">5-digit office ZIP from signup.</p>
          <ZipInputWithLocation value={form.zipCode} onChange={onChange} placeholder="Office ZIP" onLocationError={(msg) => showToast({ type: 'error', message: msg })} />
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Loan programs & specialties</h3>
          <p className="form-hint">Select all that apply (scroll if needed).</p>
          <div className="edit-profile-chip-scroll">
            <div className="states-chip-grid auth-profile-chip-grid auth-specialty-grid">
              {LOAN_SPECIALTY_OPTIONS.map((label) => (
                <button
                  key={label}
                  type="button"
                  className={`state-chip-btn auth-profile-chip ${form.specialtyProducts.includes(label) ? 'selected' : ''}`}
                  onClick={() => toggleProduct(label)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
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
            variant="video"
            file={files.video}
            onFileChange={(f) => setFiles((p) => ({ ...p, video: f }))}
            onValidationError={(msg) => showToast({ type: 'error', message: msg })}
          />
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Professional links</h3>
          <div className="edit-profile-form-grid">
            <input name="website_link" value={form.website_link} onChange={onChange} placeholder="Website URL" />
            <div className="edit-profile-inline-field full-span">
              <input name="mortgageApplicationUrl" value={form.mortgageApplicationUrl} onChange={onChange} placeholder="Mortgage application URL" />
              <button type="button" className="btn secondary" onClick={openMortgageLink}>
                Open link
              </button>
            </div>
            <input className="full-span" name="thirdPartReviewLink" value={form.thirdPartReviewLink} onChange={onChange} placeholder="Reviews URL (Google, Zillow, …)" />
          </div>
        </section>

        <section className="edit-profile-section">
          <h3 className="edit-profile-section__title">Licensed states</h3>
          <p className="form-hint">Hover a code for the full state name.</p>
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
