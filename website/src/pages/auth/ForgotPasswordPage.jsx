import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import * as authApi from '../../api/auth';

export function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const submit = async (e) => {
    e.preventDefault();
    setStatus('');
    setError('');
    try {
      await authApi.sendPasswordResetEmail(email);
      setStatus('Reset code sent.');
      navigate('/reset-password', { state: { email } });
    } catch (err) {
      setError(err.message || 'Unable to send reset code right now.');
    }
  };

  return (
    <div className="auth-shell auth-bg">
      <form className="glass-card auth-card" onSubmit={submit}>
        <h2>Forgot Password</h2>
        <p>Enter your account email.</p>
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        {status ? <p>{status}</p> : null}
        {error ? <p className="error-text">{error}</p> : null}
        <button type="submit" className="btn primary">Send Reset Code</button>
      </form>
    </div>
  );
}
