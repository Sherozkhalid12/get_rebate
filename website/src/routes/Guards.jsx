import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { AnimatedLoader } from '../components/ui/AnimatedLoader';

export function RequireAuth({ children }) {
  const { isAuthenticated, userLoaded } = useAuth();
  const location = useLocation();

  if (!userLoaded) return <AnimatedLoader variant="full" label="Loading..." />;
  if (!isAuthenticated) return <Navigate to="/auth" replace state={{ from: location }} />;
  return children;
}

export function RequireRole({ role, children }) {
  const { role: currentRole, userLoaded } = useAuth();

  if (!userLoaded) return <AnimatedLoader variant="full" label="Loading..." />;
  if (currentRole !== role) {
    if (currentRole === 'agent') return <Navigate to="/agent" replace />;
    if (currentRole === 'loanOfficer') return <Navigate to="/loan-officer" replace />;
    return <Navigate to="/app" replace />;
  }
  return children;
}
