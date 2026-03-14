import { PageHeader } from '../../components/layout/PageHeader';

function LegalLayout({ title, points }) {
  return (
    <div className="page-body">
      <PageHeader title={title} subtitle="Structured policy content for professional transparency." icon="shield" />
      <section className="glass-card panel">
        <ul className="clean-list">
          {points.map((p) => <li key={p}>{p}</li>)}
        </ul>
      </section>
    </div>
  );
}

export function PrivacyPolicyPage() {
  return <LegalLayout title="Privacy Policy" points={['We store only required account data.', 'Messages and notifications are secured.', 'You can request data deletion support.']} />;
}

export function TermsOfServicePage() {
  return <LegalLayout title="Terms of Service" points={['Only verified professionals may claim ZIP markets.', 'Rebate disclosure must comply with local laws.', 'Platform misuse can trigger account suspension.']} />;
}

export function AboutLegalPage() {
  return <LegalLayout title="About & Legal" points={['GetaRebate connects buyers/sellers with rebate-friendly professionals.', 'All mortgage and legal outcomes depend on licensed provider review.', 'Contact support for policy clarifications.']} />;
}

export function HelpSupportPage() {
  return <LegalLayout title="Help & Support" points={['Email support@getarebate.com', 'In-app chat support during business hours', 'Priority support for active subscribers']} />;
}
