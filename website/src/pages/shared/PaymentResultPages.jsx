import { useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';

export function PaymentSuccessPage() {
  const navigate = useNavigate();
  const { user } = useAuth();

  useEffect(() => {
    const search = window.location.search || '';
    const role = user?.role;
    const pendingAgent = window.localStorage.getItem('pending_agent_zip_checkout');
    const pendingLoan = window.localStorage.getItem('pending_loan_officer_zip_checkout');

    if (role === 'agent' || pendingAgent) {
      navigate(`/agent/zip-codes${search}`, { replace: true });
      return;
    }

    if (role === 'loanOfficer' || pendingLoan) {
      navigate(`/loan-officer/zip-codes${search}`, { replace: true });
      return;
    }

    navigate(`/agent/zip-codes${search}`, { replace: true });
  }, [navigate, user]);

  return (
    <div className="page-body">
      <PageHeader title="Payment Successful" subtitle="Finalizing your ZIP code claim." icon="location" />
      <section className="glass-card panel">
        <p>Thank you. We are finalizing your ZIP subscription and refreshing your coverage.</p>
        <p>You will be redirected automatically. If not, use the link below.</p>
        <div className="row">
          <Link className="btn primary tiny" to="/agent/zip-codes">Go to ZIP Codes</Link>
        </div>
      </section>
    </div>
  );
}

export function PaymentCancelPage() {
  const { user } = useAuth();

  useEffect(() => {
    window.localStorage.removeItem('pending_agent_zip_checkout');
    window.localStorage.removeItem('pending_loan_officer_zip_checkout');
  }, []);

  const role = user?.role;
  const zipPath = role === 'loanOfficer' ? '/loan-officer/zip-codes' : '/agent/zip-codes';

  return (
    <div className="page-body">
      <PageHeader title="Payment Cancelled" subtitle="Your ZIP claim was not completed." icon="location" />
      <section className="glass-card panel">
        <p>Your Stripe payment was cancelled or did not complete.</p>
        <p>No ZIP codes have been claimed. You can restart checkout at any time from the ZIP Codes page.</p>
        <div className="row">
          <Link className="btn primary tiny" to={zipPath}>Back to ZIP Codes</Link>
        </div>
      </section>
    </div>
  );
}

