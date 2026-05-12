import { useState, useRef, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { USER_ROLES, US_STATES } from '../../lib/constants';
import { AGENT_EXPERTISE_OPTIONS, LOAN_SPECIALTY_OPTIONS } from '../../lib/profileOptions';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

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

function UploadGlyph({ variant }) {
  const cls = 'auth-upload__svg';
  if (variant === 'profile') {
    return (
      <svg className={cls} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
        <circle cx="12" cy="9" r="3.5" stroke="currentColor" strokeWidth="1.5" />
        <path d="M6 19.5c0-3.5 3-5.5 6-5.5s6 2 6 5.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    );
  }
  if (variant === 'logo') {
    return (
      <svg className={cls} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
        <rect x="4" y="4" width="16" height="16" rx="2.5" stroke="currentColor" strokeWidth="1.5" />
        <path d="M8 16l2.5-3.5 2 2.5L16 11l3 5" stroke="currentColor" strokeWidth="1.35" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="9.5" cy="9.5" r="1.25" fill="currentColor" />
      </svg>
    );
  }
  return (
    <svg className={cls} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
      <rect x="3" y="5" width="14" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M17 9l4-2v10l-4-2" fill="currentColor" opacity="0.25" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
  );
}

/** Premium file row: hidden input + custom actions (matches app polish). */
function AuthFileUploadRow({
  label,
  hint,
  accept,
  field,
  file,
  variant,
  setForm,
}) {
  const inputRef = useRef(null);
  const pick = (f) => setForm((p) => ({ ...p, [field]: f }));
  const clear = () => {
    if (inputRef.current) inputRef.current.value = '';
    setForm((p) => ({ ...p, [field]: null }));
  };

  return (
    <div
      className={`auth-upload auth-upload--${variant}${file ? ' auth-upload--has-file' : ''}`}
    >
      <div className="auth-upload__header">
        <span className="auth-upload__label">{label}</span>
        {hint ? <span className="auth-upload__hint">{hint}</span> : null}
      </div>
      <div className="auth-upload__surface">
        <input
          ref={inputRef}
          type="file"
          accept={accept}
          className="auth-upload__native"
          onChange={(e) => pick(e.target.files?.[0] ?? null)}
        />
        <div className="auth-upload__main">
          <div className="auth-upload__visual">
            <UploadGlyph variant={variant} />
          </div>
          <div className="auth-upload__content">
            {!file ? (
              <>
                <p className="auth-upload__pitch">
                  {variant === 'video'
                    ? 'MP4 or MOV — a short intro helps buyers trust you.'
                    : variant === 'logo'
                      ? 'Square PNG or SVG looks best on your profile.'
                      : 'A clear headshot helps your profile stand out.'}
                </p>
                <button
                  type="button"
                  className="auth-upload__cta"
                  onClick={() => inputRef.current?.click()}
                >
                  Browse files
                </button>
              </>
            ) : (
              <div className="auth-upload__picked">
                <span className="auth-upload__filename" title={file.name}>{file.name}</span>
                <div className="auth-upload__picked-actions">
                  <button type="button" className="auth-upload__mini auth-upload__mini--solid" onClick={() => inputRef.current?.click()}>
                    Replace
                  </button>
                  <button type="button" className="auth-upload__mini auth-upload__mini--ghost" onClick={clear}>
                    Remove
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

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
      setError(err.message || 'Unable to continue.');
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
          <AuthFileUploadRow
            label="Profile photo"
            hint="Optional"
            accept="image/*"
            field="profilePic"
            file={form.profilePic}
            variant="profile"
            setForm={setForm}
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
                <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder={isAgent ? 'Brokerage / Company' : 'Lender Company'} required />
                <input name="liscenceNumber" value={form.liscenceNumber} onChange={onChange} placeholder="License Number" required />
                <AuthFileUploadRow
                  label="Company logo"
                  hint="Optional · branding on your profile"
                  accept="image/*"
                  field="companyLogo"
                  file={form.companyLogo}
                  variant="logo"
                  setForm={setForm}
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
                <AuthFileUploadRow
                  label="Video introduction"
                  hint="Optional"
                  accept="video/*"
                  field="video"
                  file={form.video}
                  variant="video"
                  setForm={setForm}
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
                <AuthFileUploadRow
                  label="Video introduction"
                  hint="Optional"
                  accept="video/*"
                  field="video"
                  file={form.video}
                  variant="video"
                  setForm={setForm}
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
