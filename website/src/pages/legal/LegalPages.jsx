import { Link } from 'react-router-dom';
import { ComplianceFooter } from '../../components/legal/ComplianceFooter';
import { LegalPageLayout, LegalSection } from '../../components/legal/LegalPageLayout';
import { FaqAccordion } from '../../components/landing/PremiumLandingKit';
import { IconGlyph } from '../../components/ui/IconGlyph';
import {
  ABOUT_LEGAL_SECTIONS,
  PRIVACY_SECTIONS,
  SUPPORT_CONTACTS,
  SUPPORT_FAQS,
  TERMS_SECTIONS,
} from '../../content/legalContent';

export function PrivacyPolicyPage() {
  return (
    <LegalPageLayout
      title="Privacy Policy"
      subtitle="Your privacy matters to us"
      icon="shield"
    >
      {PRIVACY_SECTIONS.map((section) => (
        <LegalSection key={section.title} title={section.title} body={section.body} />
      ))}
      <ComplianceFooter />
    </LegalPageLayout>
  );
}

export function TermsOfServicePage() {
  return (
    <LegalPageLayout
      title="Terms of Service"
      subtitle="Please read these terms carefully"
      icon="document"
    >
      {TERMS_SECTIONS.map((section) => (
        <LegalSection key={section.title} title={section.title} body={section.body} />
      ))}
      <ComplianceFooter />
    </LegalPageLayout>
  );
}

export function AboutLegalPage() {
  return (
    <LegalPageLayout
      title="About & Legal"
      subtitle="Licensing, equal housing, and platform information"
      icon="info"
    >
      {ABOUT_LEGAL_SECTIONS.map((section) => (
        <LegalSection
          key={section.title}
          title={section.title}
          body={section.body}
          links={section.links}
        />
      ))}
      <ComplianceFooter />
    </LegalPageLayout>
  );
}

const CONTACT_ICONS = {
  mail: 'email',
  phone: 'phone',
  shield: 'shield',
  description: 'document',
};

export function HelpSupportPage() {
  return (
    <LegalPageLayout
      title="Help & Support"
      subtitle="Find answers and get in touch with our team"
      icon="info"
    >
      <section className="legal-section glass-card legal-support-intro">
        <h2>We&apos;re here to help</h2>
        <p>
          Browse frequently asked questions below or reach out by email or phone. If you have an
          account, you can also sign in to use in-app messaging with agents and loan officers.
        </p>
        <div className="legal-support-quick">
          <a className="btn primary" href="mailto:support@getrebate.com">
            Email support
          </a>
          <Link className="btn ghost" to="/auth">
            Sign in to the app
          </Link>
        </div>
      </section>

      <section className="legal-section glass-card">
        <h2>Frequently Asked Questions</h2>
        <FaqAccordion items={SUPPORT_FAQS} />
      </section>

      <section className="legal-section glass-card">
        <h2>Contact Support</h2>
        <ul className="legal-contact-list">
          {SUPPORT_CONTACTS.map((item) => (
            <li key={item.href}>
              <a className="legal-contact-card" href={item.href}>
                <span className="legal-contact-card__icon" aria-hidden="true">
                  <IconGlyph name={CONTACT_ICONS[item.icon] || 'email'} />
                </span>
                <span className="legal-contact-card__body">
                  <strong>{item.title}</strong>
                  <span className="legal-contact-card__value">{item.value}</span>
                  <span className="legal-contact-card__desc">{item.description}</span>
                </span>
                <IconGlyph name="arrowRight" />
              </a>
            </li>
          ))}
        </ul>
      </section>

      <section className="legal-section glass-card">
        <h2>Related policies</h2>
        <ul className="legal-section__links">
          <li>
            <Link to="/privacy-policy">Privacy Policy</Link>
          </li>
          <li>
            <Link to="/terms-of-service">Terms of Service</Link>
          </li>
          <li>
            <Link to="/about-legal">About & Legal</Link>
          </li>
        </ul>
      </section>
    </LegalPageLayout>
  );
}
