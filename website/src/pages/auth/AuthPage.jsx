import { useState, useRef, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { USER_ROLES, US_STATES } from '../../lib/constants';
import { AGENT_EXPERTISE_OPTIONS, LOAN_SPECIALTY_OPTIONS } from '../../lib/profileOptions';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { MediaUploadField } from '../../components/ui/MediaUploadField';
import { ProfileUploadGuidelines } from '../../components/ui/ProfileUploadGuidelines';
import { getPendingSignupFiles } from '../../lib/pendingSignupFiles';
import { storage } from '../../lib/storage';
import { friendlyApiError } from '../../lib/apiErrors';
function normalizePhoneDigits(value) {
  return String(value || '').replace(/\D/g, '');
}

function isValidPhone(value) {
  const d = normalizePhoneDigits(value);
  return d.length >= 10 && d.length <= 15;
}

const roleOptions = [
  { value: USER_ROLES.BUYER_SELLER, label: 'Buyer / Seller' },
  { value: USER_ROLES.AGENT, label: 'Agent' },
  { value: USER_ROLES.LOAN_OFFICER, label: 'Loan Officer' },
];

const roleDefaults = {
  [USER_ROLES.BUYER_SELLER]: {},
  [USER_ROLES.AGENT]: {
    CompanyName: '',
    liscenceNumber: '',
    zipCode: '',
    licensedStates: '[]',
    isDualAgencyAllowedInState: false,
    isDualAgencyAllowedAtBrokerage: false,
    agentVerificationConfirmed: false,
  },
  [USER_ROLES.LOAN_OFFICER]: {
    CompanyName: '',
    liscenceNumber: '',
    zipCode: '',
    licensedStates: '[]',
    loanOfficerVerificationConfirmed: false,
  },
};

export function AuthPage() {
  const [searchParams] = useSearchParams();
  const roleFromUrl = searchParams.get('role');
  const initialRole = [USER_ROLES.AGENT, USER_ROLES.LOAN_OFFICER].includes(roleFromUrl)
    ? roleFromUrl
    : USER_ROLES.BUYER_SELLER;
  const initialMode = searchParams.get('mode') === 'signup' ? 'signup' : 'login';

  const [mode, setMode] = useState(initialMode);
  const [error, setError] = useState('');
  const [form, setForm] = useState({
    name: '',
    email: '',
    password: '',
    role: initialRole,
    phone: '',
    agreeTos: false,
    CompanyName: '',
    liscenceNumber: '',
    zipCode: '',
    licensedStates: [],
    isDualAgencyAllowedInState: false,
    isDualAgencyAllowedAtBrokerage: false,
    agentVerificationConfirmed: false,
    loanOfficerVerificationConfirmed: false,
    bio: '',
    websiteUrl: '',
    googleReviewsUrl: '',
    thirdPartyReviewsUrl: '',
    mortgageApplicationUrl: '',
    externalReviewsUrl: '',
    expertise: [],
    specialtyProducts: [],
    profilePic: null,
    companyLogo: null,
    video: null,
  });
  const { login, signup, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const pending = storage.get('pending_signup', null);
    if (!pending) return;
    const files = getPendingSignupFiles();
    let licensed = pending.licensedStates;
    if (typeof licensed === 'string') {
      try { licensed = JSON.parse(licensed); } catch { licensed = []; }
    }
    if (!Array.isArray(licensed)) licensed = [];
    setMode('signup');
    setForm((prev) => ({
      ...prev,
      name: pending.fullname || pending.name || prev.name,
      email: pending.email || prev.email,
      password: pending.password || prev.password,
      role: pending.role || prev.role,
      phone: pending.phone || prev.phone,
      CompanyName: pending.CompanyName || prev.CompanyName,
      liscenceNumber: pending.liscenceNumber || prev.liscenceNumber,
      zipCode: pending.zipCode || prev.zipCode,
      licensedStates: licensed,
      isDualAgencyAllowedInState: Boolean(pending.isDualAgencyAllowedInState),
      isDualAgencyAllowedAtBrokerage: Boolean(pending.isDualAgencyAllowedAtBrokerage),
      agentVerificationConfirmed: Boolean(pending.agentVerificationConfirmed),
      loanOfficerVerificationConfirmed: Boolean(pending.loanOfficerVerificationConfirmed),
      bio: pending.bio || prev.bio,
      websiteUrl: pending.websiteUrl || prev.websiteUrl,
      googleReviewsUrl: pending.googleReviewsUrl || prev.googleReviewsUrl,
      thirdPartyReviewsUrl: pending.thirdPartyReviewsUrl || prev.thirdPartyReviewsUrl,
      mortgageApplicationUrl: pending.mortgageApplicationUrl || prev.mortgageApplicationUrl,
      externalReviewsUrl: pending.externalReviewsUrl || prev.externalReviewsUrl,
      expertise: Array.isArray(pending.expertise) ? pending.expertise : prev.expertise,
      specialtyProducts: Array.isArray(pending.specialtyProducts) ? pending.specialtyProducts : prev.specialtyProducts,
      profilePic: files.profilePic || prev.profilePic,
      companyLogo: files.companyLogo || prev.companyLogo,
      video: files.video || prev.video,
      agreeTos: true,
    }));
  }, []);

  const onChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((prev) => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
  };

  const toggleExpertise = (label) => {
    setForm((p) => ({
      ...p,
      expertise: p.expertise.includes(label)
        ? p.expertise.filter((x) => x !== label)
        : [...p.expertise, label],
    }));
  };

  const toggleSpecialty = (label) => {
    setForm((p) => ({
      ...p,
      specialtyProducts: p.specialtyProducts.includes(label)
        ? p.specialtyProducts.filter((x) => x !== label)
        : [...p.specialtyProducts, label],
    }));
  };

  const toRoleHome = (role) => {
    if (role === USER_ROLES.AGENT) navigate('/agent');
    else if (role === USER_ROLES.LOAN_OFFICER) navigate('/loan-officer');
    else navigate('/app');
  };

  const isAgent = form.role === USER_ROLES.AGENT;
  const isLoanOfficer = form.role === USER_ROLES.LOAN_OFFICER;

  const submit = async (e) => {
    e.preventDefault();
    setError('');

    try {
      if (mode === 'login') {
        const user = await login({ email: form.email, password: form.password });
        toRoleHome(user.role);
        return;
      }

      if (!form.agreeTos) throw new Error('Please agree to the Terms of Service.');

      if ((isAgent || isLoanOfficer) && (!form.licensedStates || form.licensedStates.length === 0)) {
        throw new Error('Please select at least one licensed state.');
      }

      if ((isAgent || isLoanOfficer) && !normalizePhoneDigits(form.phone)) {
        throw new Error('Please enter your phone number.');
      }

      if ((isAgent || isLoanOfficer) && form.phone && !isValidPhone(form.phone)) {
        throw new Error('Phone number must be 10 to 15 digits.');
      }

      const rolePayload = {
        ...roleDefaults[form.role],
        CompanyName: form.CompanyName || undefined,
        liscenceNumber: form.liscenceNumber || undefined,
        zipCode: form.zipCode || undefined,
        licensedStates: JSON.stringify(form.licensedStates || []),
        isDualAgencyAllowedInState: form.isDualAgencyAllowedInState,
        isDualAgencyAllowedAtBrokerage: form.isDualAgencyAllowedAtBrokerage,
        agentVerificationConfirmed: form.agentVerificationConfirmed,
        loanOfficerVerificationConfirmed: form.loanOfficerVerificationConfirmed,
      };

      if (isAgent) {
        if (form.bio.trim()) rolePayload.bio = form.bio.trim();
        if (form.websiteUrl.trim()) rolePayload.websiteUrl = form.websiteUrl.trim();
        if (form.googleReviewsUrl.trim()) rolePayload.googleReviewsUrl = form.googleReviewsUrl.trim();
        if (form.thirdPartyReviewsUrl.trim()) rolePayload.thirdPartyReviewsUrl = form.thirdPartyReviewsUrl.trim();
        if (form.expertise.length > 0) rolePayload.expertise = form.expertise;
      }

      if (isLoanOfficer) {
        if (form.bio.trim()) rolePayload.bio = form.bio.trim();
        if (form.websiteUrl.trim()) rolePayload.websiteUrl = form.websiteUrl.trim();
        if (form.mortgageApplicationUrl.trim()) rolePayload.mortgageApplicationUrl = form.mortgageApplicationUrl.trim();
        if (form.externalReviewsUrl.trim()) rolePayload.externalReviewsUrl = form.externalReviewsUrl.trim();
        if (form.specialtyProducts.length > 0) rolePayload.specialtyProducts = form.specialtyProducts;
      }

      await signup(
        {
          fullname: form.name,
          name: form.name,
          email: form.email,
          password: form.password,
          phone: form.phone,
          role: form.role,
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          ...rolePayload,
        },
        {
          profilePic: form.profilePic,
          companyLogo: isAgent || isLoanOfficer ? form.companyLogo : null,
          video: isAgent || isLoanOfficer ? form.video : null,
        },
      );

      navigate('/verify-otp', { state: { email: form.email } });
    } catch (err) {
      setError(friendlyApiError(err, err.message || 'Unable to continue.'));
    }
  };

  const [statesOpen, setStatesOpen] = useState(false);
  const statesRef = useRef(null);

  useEffect(() => {
    const close = (e) => {
      if (statesRef.current && !statesRef.current.contains(e.target)) setStatesOpen(false);
    };
    if (statesOpen) {
      document.addEventListener('click', close);
      return () => document.removeEventListener('click', close);
    }
  }, [statesOpen]);

  return (
    <div className="auth-shell auth-bg">
      <form className="glass-card auth-card" onSubmit={submit}>
        <h2>{mode === 'login' ? 'Welcome Back' : 'Create Account'}</h2>
        <p>{mode === 'login' ? 'Sign in to continue' : 'Register and verify your account'}</p>

        {mode === 'signup' ? <input name="name" value={form.name} onChange={onChange} placeholder="Full name" required /> : null}
        {mode === 'signup' ? (
          <MediaUploadField
            label="Profile photo"
            variant="profile"
            file={form.profilePic}
            onFileChange={(f) => setForm((p) => ({ ...p, profilePic: f }))}
            onValidationError={(msg) => setError(msg)}
          />
        ) : null}
        <input name="email" type="email" value={form.email} onChange={onChange} placeholder="Email" required />
        <input name="password" type="password" value={form.password} onChange={onChange} placeholder="Password" required minLength={6} />

        {mode === 'signup' ? (
          <>
            <input
              name="phone"
              value={form.phone}
              onChange={onChange}
              placeholder={isAgent || isLoanOfficer ? 'Phone (required)' : 'Phone (optional)'}
              required={isAgent || isLoanOfficer}
            />
            <select name="role" value={form.role} onChange={onChange} className="dropdown-glass">
              {roleOptions.map((opt) => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
            </select>

            {(isAgent || isLoanOfficer) ? (
              <>
                <ProfileUploadGuidelines />
                <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder={isAgent ? 'Brokerage / Company' : 'Lender Company'} required />
                <input name="liscenceNumber" value={form.liscenceNumber} onChange={onChange} placeholder="License Number" required />
                <MediaUploadField
                  label="Company logo"
                  variant="logo"
                  file={form.companyLogo}
                  onFileChange={(f) => setForm((p) => ({ ...p, companyLogo: f }))}
                  onValidationError={(msg) => setError(msg)}
                />
                <div className="states-dropdown-wrap" ref={statesRef}>
                  <label className="states-label">Licensed states</label>
                  <button
                    type="button"
                    className="states-trigger dropdown-glass"
                    onClick={() => setStatesOpen((o) => !o)}
                  >
                    {form.licensedStates.length > 0
                      ? `${form.licensedStates.length} state(s) selected`
                      : 'Select states...'}
                  </button>
                  {statesOpen ? (
                    <div className="states-panel glass-card">
                      {US_STATES.map((s) => (
                        <label key={s.code} className="states-option">
                          <input
                            type="checkbox"
                            checked={form.licensedStates.includes(s.code)}
                            onChange={(e) => {
                              const add = e.target.checked;
                              setForm((p) => ({
                                ...p,
                                licensedStates: add ? [...p.licensedStates, s.code] : p.licensedStates.filter((c) => c !== s.code),
                              }));
                            }}
                          />
                          <span>{s.name} ({s.code})</span>
                        </label>
                      ))}
                    </div>
                  ) : null}
                  {form.licensedStates.length > 0 ? (
                    <div className="states-chips">
                      {form.licensedStates.map((code) => {
                        const st = US_STATES.find((s) => s.code === code);
                        return (
                          <span key={code} className="state-chip">
                            {st?.name || code}
                            <button type="button" aria-label={`Remove ${code}`} onClick={() => setForm((p) => ({ ...p, licensedStates: p.licensedStates.filter((c) => c !== code) }))}>×</button>
                          </span>
                        );
                      })}
                    </div>
                  ) : null}
                </div>
                <ZipInputWithLocation
                  value={form.zipCode}
                  onChange={onChange}
                  placeholder="Office ZIP (5 digits)"
                  required
                  onLocationError={(msg) => setError(msg)}
                />
              </>
            ) : null}

            {isAgent ? (
              <div className="checkbox-group">
                <label className="checkbox-row"><input type="checkbox" name="isDualAgencyAllowedInState" checked={form.isDualAgencyAllowedInState} onChange={onChange} /> <span>Dual agency allowed in state</span></label>
                <label className="checkbox-row"><input type="checkbox" name="isDualAgencyAllowedAtBrokerage" checked={form.isDualAgencyAllowedAtBrokerage} onChange={onChange} /> <span>Dual agency allowed at brokerage</span></label>
                <label className="checkbox-row"><input type="checkbox" name="agentVerificationConfirmed" checked={form.agentVerificationConfirmed} onChange={onChange} required /> <span>I confirm agent verification details</span></label>
              </div>
            ) : null}

            {isLoanOfficer ? (
              <div className="checkbox-group">
                <label className="checkbox-row"><input type="checkbox" name="loanOfficerVerificationConfirmed" checked={form.loanOfficerVerificationConfirmed} onChange={onChange} required /> <span>I confirm loan officer verification details</span></label>
              </div>
            ) : null}

            {isAgent ? (
              <div className="auth-profile-extra glass-card auth-profile-extra--agent">
                <h3 className="auth-profile-extra-title">Agent profile (optional)</h3>
                <p className="form-hint auth-profile-extra__lede">Video intro, bio, home types you focus on, and links—same data as the mobile app.</p>
                <MediaUploadField
                  label="Video introduction"
                  variant="video"
                  file={form.video}
                  onFileChange={(f) => setForm((p) => ({ ...p, video: f }))}
                  onValidationError={(msg) => setError(msg)}
                />
                <textarea name="bio" value={form.bio} onChange={onChange} placeholder="Bio / introduction" rows={3} />
                <p className="auth-profile-extra__section-label">Areas of expertise</p>
                <p className="form-hint auth-profile-extra__micro">Select all that apply</p>
                <div className="states-chip-grid auth-profile-chip-grid">
                  {AGENT_EXPERTISE_OPTIONS.map((label) => (
                    <button
                      key={label}
                      type="button"
                      className={`state-chip-btn auth-profile-chip ${form.expertise.includes(label) ? 'selected' : ''}`}
                      onClick={() => toggleExpertise(label)}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                <input name="websiteUrl" value={form.websiteUrl} onChange={onChange} placeholder="Website URL (optional)" />
                <input name="googleReviewsUrl" value={form.googleReviewsUrl} onChange={onChange} placeholder="Google Reviews page (optional)" />
                <input name="thirdPartyReviewsUrl" value={form.thirdPartyReviewsUrl} onChange={onChange} placeholder="Other reviews (Zillow, etc.) (optional)" />
              </div>
            ) : null}

            {isLoanOfficer ? (
              <div className="auth-profile-extra glass-card auth-profile-extra--lo">
                <h3 className="auth-profile-extra-title">Loan officer profile (optional)</h3>
                <p className="form-hint auth-profile-extra__lede">Video intro, bio, loan programs you specialize in, and links—same data as the mobile app.</p>
                <MediaUploadField
                  label="Video introduction"
                  variant="video"
                  file={form.video}
                  onFileChange={(f) => setForm((p) => ({ ...p, video: f }))}
                  onValidationError={(msg) => setError(msg)}
                />
                <textarea name="bio" value={form.bio} onChange={onChange} placeholder="Bio / introduction" rows={3} />
                <p className="auth-profile-extra__section-label">Loan programs & specialties</p>
                <p className="form-hint auth-profile-extra__micro">Select all that apply</p>
                <div className="states-chip-grid auth-profile-chip-grid auth-specialty-grid">
                  {LOAN_SPECIALTY_OPTIONS.map((label) => (
                    <button
                      key={label}
                      type="button"
                      className={`state-chip-btn auth-profile-chip ${form.specialtyProducts.includes(label) ? 'selected' : ''}`}
                      onClick={() => toggleSpecialty(label)}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                <input name="websiteUrl" value={form.websiteUrl} onChange={onChange} placeholder="Website URL (optional)" />
                <input name="mortgageApplicationUrl" value={form.mortgageApplicationUrl} onChange={onChange} placeholder="Mortgage application link (optional)" />
                <input name="externalReviewsUrl" value={form.externalReviewsUrl} onChange={onChange} placeholder="Reviews page (optional)" />
              </div>
            ) : null}

            <div className="checkbox-group checkbox-group-terms">
              <label className="checkbox-row"><input type="checkbox" name="agreeTos" checked={form.agreeTos} onChange={onChange} required /> <span>I have read and agree to the Terms of Service.</span></label>
            </div>
          </>
        ) : null}

        {error ? <p className="error-text">{error}</p> : null}

        <button type="submit" className="btn primary btn-with-loader auth-submit-cta" disabled={loading}>
          {loading ? (
            <span className="btn-loading-content"><AnimatedLoader variant="button" label="" />Please wait...</span>
          ) : (
            mode === 'login' ? 'Sign In' : 'Continue to OTP'
          )}
        </button>

        <div className="row small-gap">
          <button type="button" className="btn link" onClick={() => setMode(mode === 'login' ? 'signup' : 'login')}>
            {mode === 'login' ? 'Need an account?' : 'Already have an account?'}
          </button>
          {mode === 'login' ? <button type="button" className="btn link" onClick={() => navigate('/forgot-password')}>Forgot password?</button> : null}
        </div>
      </form>
    </div>
  );
}
