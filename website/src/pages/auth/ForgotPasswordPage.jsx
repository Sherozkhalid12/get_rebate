import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import * as authApi from '../../api/auth';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';

export function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await authApi.sendPasswordResetEmail(email);
      navigate('/reset-password', { state: { email: email.trim() } });
    } catch (err) {
      setError(err.message || 'Unable to send reset code right now.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-shell auth-bg">
      <form className="glass-card auth-card" onSubmit={submit}>
        <h2>Forgot password</h2>
        <p className="auth-card__lede">We&apos;ll email you a verification code. You&apos;ll verify it, then set a new password.</p>
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required disabled={loading} />
        {error ? <p className="error-text">{error}</p> : null}
        <button type="submit" className="btn primary btn-with-loader" disabled={loading}>
          {loading ? (
            <span className="btn-loading-content">
              <AnimatedLoader variant="button" label="" />
              Sending…
            </span>
          ) : (
            'Send reset code'
          )}
        </button>
      </form>
    </div>
  );
}
