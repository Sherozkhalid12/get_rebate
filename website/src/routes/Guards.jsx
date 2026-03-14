import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export function RequireAuth({ children }) {
  const { isAuthenticated } = useAuth();
  const location = useLocation();
  if (!isAuthenticated) return <Navigate to="/auth" replace state={{ from: location }} />;
  return children;
}

export function RequireRole({ role, children }) {
  const { role: currentRole } = useAuth();
  if (currentRole !== role) {
    if (currentRole === 'agent') return <Navigate to="/agent" replace />;
    if (currentRole === 'loanOfficer') return <Navigate to="/loan-officer" replace />;
    return <Navigate to="/app" replace />;
  }
  return children;
}
