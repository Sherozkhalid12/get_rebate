import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import * as authApi from '../../api/auth';

export function ResetPasswordPage() {
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [status, setStatus] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { state } = useLocation();
  const email = state?.email || '';

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setStatus('');

    try {
      await authApi.verifyPasswordResetOtp(email, otp);
      await authApi.resetPassword({ email, newPassword });
      setStatus('Password reset successful.');
      setTimeout(() => navigate('/auth'), 700);
    } catch (err) {
      setError(err.message || 'Could not reset password.');
    }
  };

  return (
    <div className="auth-shell auth-bg">
      <form className="glass-card auth-card" onSubmit={submit}>
        <h2>Reset Password</h2>
        <p>{email ? `Resetting for ${email}` : 'Enter code and new password.'}</p>
        <input value={otp} onChange={(e) => setOtp(e.target.value)} placeholder="OTP" required />
        <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="New password" required minLength={6} />
        {status ? <p>{status}</p> : null}
        {error ? <p className="error-text">{error}</p> : null}
        <button type="submit" className="btn primary">Reset Password</button>
      </form>
    </div>
  );
}
