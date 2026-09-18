import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { AnimatedLoader } from '../components/ui/AnimatedLoader';

export function RequireAdmin({ children }) {
  const { role, userLoaded, isAuthenticated } = useAuth();
  const location = useLocation();

  if (!userLoaded) return <AnimatedLoader variant="full" label="Loading..." />;
  if (!isAuthenticated) return <Navigate to="/login" replace state={{ from: location }} />;
  if (role !== 'admin') return <Navigate to="/login" replace />;
  return children;
}

export function RedirectIfAuthed({ children }) {
  const { role, userLoaded, isAuthenticated } = useAuth();
  if (!userLoaded) return <AnimatedLoader variant="full" label="Loading..." />;
  if (isAuthenticated && role === 'admin') return <Navigate to="/" replace />;
  return children;
}
