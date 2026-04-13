import { useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { FaqAccordion, PremiumLandingFooter, PremiumLandingFrame, PremiumLandingHeader } from '../../components/landing/PremiumLandingKit';
import { useAuth } from '../../context/AuthContext';
import { useScrollToTop, useLandingScrollAnimations } from '../../hooks/useLandingPage';

const faqs = [
  { q: 'How do I claim ZIP coverage?', a: 'Check ZIP claim status, complete Stripe checkout, and return to refreshed coverage dashboards. Your market presence updates instantly.', icon: 'location' },
  { q: 'What are loan programs?', a: 'Publish loan products tied to your coverage. Buyers and agents see your rebate-friendly options when they search in your claimed ZIPs.', icon: 'billing' },
  { q: 'How do borrower checklists work?', a: 'Manage borrower checklists and leads from the web dashboard. Same flows as the mobile app – fully synchronized.', icon: 'checklist' },
];

export function LoanOfficerLandingPage() {
  const { isAuthenticated, role } = useAuth();
  const containerRef = useRef(null);

  useScrollToTop();
  useLandingScrollAnimations(containerRef);

  if (isAuthenticated) {
    if (role === 'agent') return <Navigate to="/agent" replace />;
    if (role === 'loanOfficer') return <Navigate to="/loan-officer" replace />;
    return <Navigate to="/app" replace />;
  }

  return (
    <PremiumLandingFrame containerRef={containerRef} className="lp2-page lp2-page--loan">
      <PremiumLandingHeader
        links={[
          { href: '#features', label: 'Features' },
          { href: '#flow', label: 'Flow' },
          { href: '#faqs', label: 'FAQs' },
        ]}
        actions={(
          <>
            <Link className="btn ghost tiny" to="/">Change Role</Link>
            <Link className="btn primary tiny" to="/auth?role=loanOfficer">Login</Link>
          </>
        )}
      />

      <main className="lp2-main">
        <section className="lp2-hero lp2-surface">
          <div className="lp2-hero-copy">
            <p className="lp2-kicker">For Loan Officers</p>
            <h1 className="lp2-title">
              Be visible in your market.
              <span className="lp2-title-accent"> Publish programs.</span>
              <span className="lp2-title-accent"> Track borrowers.</span>
            </h1>
            <p className="lp2-lead">
              Claim ZIP coverage, publish rebate-friendly loan programs, and manage borrower checklists—
              with the same synchronized flows as the mobile experience.
            </p>
            <div className="lp2-cta">
              <Link className="btn primary" to="/auth?role=loanOfficer">Continue to Login</Link>
              <Link className="btn ghost" to="/onboarding">Platform Tour</Link>
            </div>
            <div className="lp2-trust">
              <span className="lp2-trust-pill"><IconGlyph name="location" filled /> ZIP coverage</span>
              <span className="lp2-trust-pill"><IconGlyph name="billing" filled /> Program publishing</span>
              <span className="lp2-trust-pill"><IconGlyph name="checklist" filled /> Checklist workflows</span>
            </div>
            <div className="lp2-callout">
              <strong>Only One Loan Officer Per Zip Code.</strong> Secure Yours Today Before It’s Taken. <strong>First Come First Served.</strong>
            </div>
          </div>

          <div className="lp2-hero-media" aria-hidden="true">
            <div
              className="lp2-media-visual lp2-media-visual--photo"
              style={{ backgroundImage: 'url("/images/TopPicLoanOfficerLandingPage.webp")' }}
            />
            <div className="lp2-media-card lp2-media-card--top">
              <div className="lp2-media-card-icon"><IconGlyph name="location" filled /></div>
              <div>
                <strong>ZIP presence</strong>
                <span>Stay discoverable</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--mid">
              <div className="lp2-media-card-icon"><IconGlyph name="billing" filled /></div>
              <div>
                <strong>Loan programs</strong>
                <span>Publish rebate-friendly options</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--bot">
              <div className="lp2-media-card-icon"><IconGlyph name="checklist" filled /></div>
              <div>
                <strong>Borrower checklists</strong>
                <span>Track progress to closing</span>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Loan Officer Platform Features</h2>
            <p>Premium visibility and workflows—built for speed and trust.</p>
          </div>
          <div className="lp2-feature-cards">
            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="location" filled /></span>
                <h3>ZIP Coverage</h3>
              </div>
              <p>Claim ZIP codes with Stripe, view status at a glance, and keep market presence consistently up to date.</p>
            </article>

            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="billing" filled /></span>
                <h3>Loan Programs</h3>
              </div>
              <p>Publish loan products tied to your coverage so buyers and agents discover your rebate-friendly options.</p>
            </article>

            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="checklist" filled /></span>
                <h3>Borrower Checklists</h3>
              </div>
              <p>Manage borrower checklists and leads in the web dashboard—synchronized with the mobile flow.</p>
            </article>

            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="leads" filled /></span>
                <h3>Lead Visibility</h3>
              </div>
              <p>Stay visible to buyers and agents in your claimed ZIPs—with rebate transparency built into discovery.</p>
            </article>
          </div>
        </section>

        <section id="flow" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>How the Loan Officer Flow Works</h2>
            <p>Coverage, programs, and checklists—without tool switching.</p>
          </div>
          <div className="lp2-flow-cards">
            <article className="lp2-flow-card">
              <div
                className="lp2-flow-card-art"
                style={{
                  backgroundImage: 'url("/images/ZipCodeSearchAgentAndLoanOfficerLandinPage.webp")',
                }}
                aria-hidden="true"
              />
              <div className="lp2-flow-card-body">
                <h3>Claim ZIP Coverage</h3>
                <p>Complete Stripe checkout and return to refreshed coverage dashboards.</p>
              </div>
            </article>

            <article className="lp2-flow-card">
              <div
                className="lp2-flow-card-art"
                style={{
                  backgroundImage: 'url("/images/loan%20officer%20landing.webp")',
                }}
                aria-hidden="true"
              />
              <div className="lp2-flow-card-body">
                <h3>Connect with Serious Buyers</h3>
                <p>
                  Show up where motivated buyers search and compare loan officers—aligned with your claimed ZIP
                  coverage and programs.
                </p>
              </div>
            </article>

            <article className="lp2-flow-card">
              <div
                className="lp2-flow-card-art"
                style={{
                  backgroundImage: 'url("/images/Work%20Borrower%20Leads.webp")',
                  backgroundPosition: 'right center',
                }}
                aria-hidden="true"
              />
              <div className="lp2-flow-card-body">
                <h3>Work with Local Agents</h3>
                <p>
                  Collaborate with agents in your ZIPs, stay visible on shared buyer journeys, and keep checklists and
                  leads in one workspace.
                </p>
              </div>
            </article>
          </div>
        </section>

        <section id="faqs" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>FAQs</h2>
            <p>Quick details on coverage and programs.</p>
          </div>
          <FaqAccordion items={faqs} />
        </section>

        <section id="start" className="lp2-cta-band lp2-surface animate-on-scroll">
          <div>
            <h2>Ready to Grow Your Market?</h2>
            <p>Log in to claim ZIPs, publish programs, and connect with rebate-ready borrowers.</p>
          </div>
          <Link className="btn primary" to="/auth?role=loanOfficer">Login to Loan Officer Portal</Link>
        </section>

        <PremiumLandingFooter />
      </main>
    </PremiumLandingFrame>
  );
}
