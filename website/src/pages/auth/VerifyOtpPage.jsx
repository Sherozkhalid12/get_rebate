import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { USER_ROLES } from '../../lib/constants';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

export function VerifyOtpPage() {
  const [otp, setOtp] = useState('');
  const [error, setError] = useState('');
  const { completeOtpSignup, loading } = useAuth();
  const navigate = useNavigate();
  const { state } = useLocation();
  const email = state?.email || '';

  const submit = async (e) => {
    e.preventDefault();
    setError('');

    try {
      if (!email) throw new Error('Signup email is missing. Please start sign up again.');
      const user = await completeOtpSignup({ email, otp });
      if (user.role === USER_ROLES.AGENT) navigate('/agent');
      else if (user.role === USER_ROLES.LOAN_OFFICER) navigate('/loan-officer');
      else navigate('/app');
    } catch (err) {
      setError(err.message || 'OTP verification failed.');
    }
  };

  return (
    <div className="auth-shell auth-bg">
      <form className="glass-card auth-card" onSubmit={submit}>
        <h2>Email Verification</h2>
        <p>Enter the code sent to {email || 'your email'}.</p>
        <input value={otp} onChange={(e) => setOtp(e.target.value)} placeholder="6-digit OTP" required />
        {error ? <p className="error-text">{error}</p> : null}
        <button type="submit" className="btn primary btn-with-loader" disabled={loading}>
          {loading ? (
            <span className="btn-loading-content"><AnimatedLoader variant="button" label="" />Verifying...</span>
          ) : (
            'Verify & Finish'
          )}
        </button>
      </form>
    </div>
  );
}
