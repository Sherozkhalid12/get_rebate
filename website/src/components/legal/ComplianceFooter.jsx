import { COMPANY } from '../../content/legalContent';

export function ComplianceFooter() {
  return (
    <aside className="legal-compliance" aria-label="Regulatory disclosures">
      <div className="legal-compliance__icon" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="40" height="40" fill="none" stroke="currentColor" strokeWidth="1.5">
          <path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1v-9.5z" />
        </svg>
      </div>
      <p>{COMPANY.pledge}</p>
      <p className="legal-compliance__muted">{COMPANY.narDisclaimer}</p>
      <p className="legal-compliance__license">{COMPANY.license}</p>
    </aside>
  );
}
