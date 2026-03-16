import { AnimatedLoader } from './AnimatedLoader';

/** Shows AnimatedLoader when status indicates loading (ends with ...), else plain text */
export function StatusWithLoader({ status, variant = 'card' }) {
  if (!status) return null;
  const isLoading = typeof status === 'string' && status.trim().endsWith('...');
  if (isLoading) {
    return <AnimatedLoader variant={variant} label={status} />;
  }
  return <p className="status-message">{status}</p>;
}
