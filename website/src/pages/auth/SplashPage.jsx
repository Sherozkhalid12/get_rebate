import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export function SplashPage() {
  const navigate = useNavigate();
  const { isAuthenticated, role } = useAuth();

  useEffect(() => {
    const id = setTimeout(() => {
      if (!isAuthenticated) {
        navigate('/onboarding', { replace: true });
        return;
      }
      if (role === 'agent') navigate('/agent', { replace: true });
      else if (role === 'loanOfficer') navigate('/loan-officer', { replace: true });
      else navigate('/app', { replace: true });
    }, 1200);
    return () => clearTimeout(id);
  }, [isAuthenticated, navigate, role]);

  return (
    <div className="auth-shell splash-bg">
      <div className="glass-card auth-card center">
        <h1>GetaRebate</h1>
        <p>Verified rebates. Better closings.</p>
      </div>
    </div>
  );
}
