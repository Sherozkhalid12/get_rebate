import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { AnimatedLoader } from '../components/ui/AnimatedLoader';
import { friendlyApiError } from '../lib/apiErrors';

export function LoginPage() {
  const { login, loading } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      await login({ email: email.trim(), password });
      navigate('/', { replace: true });
    } catch (err) {
      setError(friendlyApiError(err, err?.message || 'Login failed'));
    }
  };

  return (
    <div className="admin-login">
      <div className="admin-login-card">
        <div className="admin-login-brand">
          <img src="/images/appbarlogo.png" alt="GetaRebate" />
          <div>
            <strong>GetaRebate</strong>
            <span>Admin access only</span>
          </div>
        </div>

        <h1>Sign in</h1>
        <p className="admin-login-sub">Use your administrator credentials to open the command center.</p>

        <form className="admin-login-form" onSubmit={onSubmit}>
          <label>
            Email
            <input
              type="email"
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              placeholder="admin@getarebate.com"
            />
          </label>
          <label>
            Password
            <input
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="••••••••"
            />
          </label>

          {error ? <div className="admin-alert admin-alert--error">{error}</div> : null}

          <button type="submit" className="btn primary admin-login-submit" disabled={loading}>
            {loading ? <AnimatedLoader variant="button" label="Signing in…" /> : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
