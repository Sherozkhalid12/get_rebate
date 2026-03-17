import { useState, useRef, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { USER_ROLES, US_STATES } from '../../lib/constants';
import { ZipInputWithLocation } from '../../components/ui/ZipInputWithLocation';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

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

  const [mode, setMode] = useState('login');
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
  });
  const { login, signup, loading } = useAuth();
  const navigate = useNavigate();

  const onChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((prev) => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
  };

  const toRoleHome = (role) => {
    if (role === USER_ROLES.AGENT) navigate('/agent');
    else if (role === USER_ROLES.LOAN_OFFICER) navigate('/loan-officer');
    else navigate('/app');
  };

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

      await signup({
        fullname: form.name,
        name: form.name,
        email: form.email,
        password: form.password,
        phone: form.phone,
        role: form.role,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        ...rolePayload,
      });

      navigate('/verify-otp', { state: { email: form.email } });
    } catch (err) {
      setError(err.message || 'Unable to continue.');
    }
  };

  const isAgent = form.role === USER_ROLES.AGENT;
  const isLoanOfficer = form.role === USER_ROLES.LOAN_OFFICER;

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
        <input name="email" type="email" value={form.email} onChange={onChange} placeholder="Email" required />
        <input name="password" type="password" value={form.password} onChange={onChange} placeholder="Password" required minLength={6} />

        {mode === 'signup' ? (
          <>
            <input name="phone" value={form.phone} onChange={onChange} placeholder="Phone" />
            <select name="role" value={form.role} onChange={onChange} className="dropdown-glass">
              {roleOptions.map((opt) => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
            </select>

            {(isAgent || isLoanOfficer) ? (
              <>
                <input name="CompanyName" value={form.CompanyName} onChange={onChange} placeholder={isAgent ? 'Brokerage / Company' : 'Lender Company'} required />
                <input name="liscenceNumber" value={form.liscenceNumber} onChange={onChange} placeholder="License Number" required />
                <ZipInputWithLocation
                  value={form.zipCode}
                  onChange={onChange}
                  placeholder="Office ZIP (5 digits)"
                  required
                  onLocationError={(msg) => setError(msg)}
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

            <div className="checkbox-group checkbox-group-terms">
              <label className="checkbox-row"><input type="checkbox" name="agreeTos" checked={form.agreeTos} onChange={onChange} required /> <span>I have read and agree to the Terms of Service.</span></label>
            </div>
          </>
        ) : null}

        {error ? <p className="error-text">{error}</p> : null}

        <button type="submit" className="btn primary btn-with-loader" disabled={loading}>
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
