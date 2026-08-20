import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { USER_ROLES } from '../../lib/constants';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { storage } from '../../lib/storage';
import { friendlyApiError } from '../../lib/apiErrors';
import { useToast } from '../../components/ui/ToastProvider';

export function VerifyOtpPage() {
  const [otp, setOtp] = useState('');
  const [error, setError] = useState('');
  const { completeOtpSignup, loading } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const { state } = useLocation();
  const pending = storage.get('pending_signup', null);
  const email = state?.email || pending?.email || '';

  const submit = async (e) => {
    e.preventDefault();
    setError('');

    try {
      if (!email) throw new Error('Signup email is missing. Please start sign up again.');
      const user = await completeOtpSignup({ email, otp });
      const mediaWarn = storage.get('signup_media_warning', '');
      if (mediaWarn) {
        storage.remove('signup_media_warning');
        showToast({ type: 'info', message: mediaWarn });
      }
      if (user.role === USER_ROLES.AGENT) navigate('/agent');
      else if (user.role === USER_ROLES.LOAN_OFFICER) navigate('/loan-officer');
      else navigate('/app');
    } catch (err) {
      setError(friendlyApiError(err, err.message || 'OTP verification failed.'));
    }
  };

  return (
    <div className="auth-shell auth-bg">
      <form className="glass-card auth-card" onSubmit={submit}>
        <h2>Email Verification</h2>
        <p>Enter the code sent to {email || 'your email'}.</p>
        <p className="form-hint">
          Headshot and logo are resized automatically (max 1 MB after processing). Intro video max 25 MB.
          If a file is rejected, your account is still created and you can add media later from Edit Profile.
        </p>
        <input value={otp} onChange={(e) => setOtp(e.target.value)} placeholder="6-digit OTP" required />
        {error ? <p className="error-text">{error}</p> : null}
        <button type="submit" className="btn primary btn-with-loader" disabled={loading}>
          {loading ? (
            <span className="btn-loading-content"><AnimatedLoader variant="button" label="" />Verifying...</span>
          ) : (
            'Verify & Finish'
          )}
        </button>
        <button
          type="button"
          className="btn link"
          onClick={() => navigate('/auth?mode=signup')}
        >
          Back to signup (your details are saved)
        </button>
      </form>
    </div>
  );
}
