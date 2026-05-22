import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import * as authApi from '../../api/auth';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

const VERIFIED_KEY = 'password_reset_otp_verified';

function readVerifiedEmail() {
  try {
    return sessionStorage.getItem(VERIFIED_KEY) || '';
  } catch {
    return '';
  }
}

function setVerifiedEmail(email) {
  try {
    sessionStorage.setItem(VERIFIED_KEY, email.trim().toLowerCase());
  } catch {
    /* ignore */
  }
}

function clearVerifiedEmail() {
  try {
    sessionStorage.removeItem(VERIFIED_KEY);
  } catch {
    /* ignore */
  }
}

export function ResetPasswordPage() {
  const navigate = useNavigate();
  const { state } = useLocation();
  const email = (state?.email || '').trim();

  const [step, setStep] = useState('otp');
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(60);
  const [error, setError] = useState('');
  const [status, setStatus] = useState('');

  useEffect(() => {
    if (!email) {
      navigate('/forgot-password', { replace: true });
      return;
    }
    const verified = readVerifiedEmail();
    if (verified && verified === email.toLowerCase()) {
      setStep('password');
    }
  }, [email, navigate]);

  useEffect(() => {
    if (resendCooldown <= 0 || step !== 'otp') return undefined;
    const t = setInterval(() => {
      setResendCooldown((c) => (c > 0 ? c - 1 : 0));
    }, 1000);
    return () => clearInterval(t);
  }, [resendCooldown, step]);

  const verifyOtp = async (e) => {
    e.preventDefault();
    setError('');
    setStatus('');

    const code = otp.replace(/\D/g, '');
    if (code.length < 4) {
      setError('Please enter the verification code from your email.');
      return;
    }

    setLoading(true);
    try {
      await authApi.verifyPasswordResetOtp(email, code);
      setVerifiedEmail(email);
      setOtp(code);
      setStep('password');
      setStatus('Code verified. Choose a new password.');
    } catch (err) {
      setError(err.message || 'Invalid or expired code. Try again or resend.');
    } finally {
      setLoading(false);
    }
  };

  const resendCode = async () => {
    if (resendCooldown > 0 || resending) return;
    setError('');
    setResending(true);
    try {
      await authApi.sendPasswordResetEmail(email);
      setResendCooldown(60);
      setStatus('A new code was sent to your email.');
    } catch (err) {
      setError(err.message || 'Could not resend code.');
    } finally {
      setResending(false);
    }
  };

  const resetPassword = async (e) => {
    e.preventDefault();
    setError('');
    setStatus('');

    const verified = readVerifiedEmail();
    if (verified !== email.toLowerCase()) {
      setStep('otp');
      setError('Please verify your code first.');
      return;
    }

    if (newPassword.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setLoading(true);
    try {
      await authApi.resetPassword({ email, newPassword });
      clearVerifiedEmail();
      setStatus('Password updated. Redirecting to sign in…');
      setTimeout(() => navigate('/auth', { replace: true }), 800);
    } catch (err) {
      setError(err.message || 'Could not reset password.');
    } finally {
      setLoading(false);
    }
  };

  const backToOtp = () => {
    clearVerifiedEmail();
    setStep('otp');
    setNewPassword('');
    setConfirmPassword('');
    setStatus('');
    setError('');
  };

  if (!email) return null;

  return (
    <div className="auth-shell auth-bg">
      <div className="glass-card auth-card">
        <h2>Reset password</h2>
        <p className="auth-card__lede">
          {step === 'otp'
            ? `Enter the 6-digit code sent to ${email}`
            : `Create a new password for ${email}`}
        </p>

        <div className="reset-password-steps" aria-hidden>
          <span className={step === 'otp' ? 'active' : 'done'}>1. Verify code</span>
          <span className={step === 'password' ? 'active' : ''}>2. New password</span>
        </div>

        {step === 'otp' ? (
          <form onSubmit={verifyOtp}>
            <label className="form-field-label" htmlFor="reset-otp">Verification code</label>
            <input
              id="reset-otp"
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
              placeholder="000000"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              className="otp-input-center"
              required
            />

            {status ? <p className="form-hint">{status}</p> : null}
            {error ? <p className="error-text">{error}</p> : null}

            <div className="auth-form-actions">
              <button type="submit" className="btn primary btn-with-loader" disabled={loading}>
                {loading ? (
                  <span className="btn-loading-content">
                    <AnimatedLoader variant="button" label="" />
                    Verifying…
                  </span>
                ) : (
                  'Verify code'
                )}
              </button>

              <p className="form-hint reset-password-resend">
                {resendCooldown > 0 ? (
                  <>Resend code in {resendCooldown}s</>
                ) : (
                  <button
                    type="button"
                    className="btn link"
                    disabled={resending}
                    onClick={resendCode}
                  >
                    {resending ? 'Sending…' : 'Resend code'}
                  </button>
                )}
              </p>

              <button type="button" className="btn ghost" onClick={() => navigate('/forgot-password')}>
                Use a different email
              </button>
            </div>
          </form>
        ) : (
          <form onSubmit={resetPassword}>
            <label className="form-field-label" htmlFor="reset-password">New password</label>
            <input
              id="reset-password"
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="At least 6 characters"
              autoComplete="new-password"
              minLength={6}
              required
            />

            <label className="form-field-label" htmlFor="reset-password-confirm">Confirm password</label>
            <input
              id="reset-password-confirm"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Re-enter password"
              autoComplete="new-password"
              minLength={6}
              required
            />

            {status ? <p className="form-hint">{status}</p> : null}
            {error ? <p className="error-text">{error}</p> : null}

            <div className="auth-form-actions">
              <button type="submit" className="btn primary btn-with-loader" disabled={loading}>
                {loading ? (
                  <span className="btn-loading-content">
                    <AnimatedLoader variant="button" label="" />
                    Saving…
                  </span>
                ) : (
                  'Set new password'
                )}
              </button>

              <button type="button" className="btn ghost" onClick={backToOtp}>
                Back to verification code
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
