import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { AnimatedLoader } from '../components/ui/AnimatedLoader';
import { USER_ROLES } from '../lib/constants';

function homeForRole(role) {
  if (role === USER_ROLES.AGENT) return '/agent';
  if (role === USER_ROLES.LOAN_OFFICER) return '/loan-officer';
  return '/app';
}

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
    return <Navigate to={homeForRole(currentRole)} replace />;
  }
  return children;
}
