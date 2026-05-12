import { useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { FaqAccordion, PremiumLandingFooter, PremiumLandingFrame, PremiumLandingHeader } from '../../components/landing/PremiumLandingKit';
import { useAuth } from '../../context/AuthContext';
import { useScrollToTop, useLandingScrollAnimations } from '../../hooks/useLandingPage';

const faqs = [
  { q: 'How do I claim ZIP coverage?', a: 'Create an account, Select your desired ZIP codes and complete your subscription through secure Stripe checkout. Once payment is confirmed, your ZIP coverage activates instantly and you’re live in the platform', icon: 'location' },
  {
    q: 'Do I work with agents on the platform?',
    a: 'Yes. You’ll connect with local real estate agents working with active buyers in your ZIP codes, creating opportunities for stronger partnerships and more closed deals. Some buyers will already have a loan officer, but with you confirming that your lender allows real estate rebates and your goal is to get the rebate on the settlement statement as a credit, buyers will reach out to you.',
    icon: 'billing',
  },
  {
    q: 'What kind of leads will I receive?',
    a: 'You’ll receive inquiries from motivated buyers actively searching for homes in your selected ZIP codes—giving you access to high-intent, purchase-ready clients.',
    icon: 'leads',
  },
  {
    q: 'How does the rebate process work for lenders?',
    a: 'The platform includes built-in checklists for both buyers and agents to help ensure rebate compliance throughout the mortgage process, making it easy to stay aligned while offering added value to buyers. As the lender, staying in compliance is top priority and agents and buyers will need your assistance to ensure lender guidelines are met and max contributions are not exceeded, etc.',
    icon: 'checklist',
  },
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
              Claim Your ZIP Codes.
              <span className="lp2-title-accent"> Connect with Buyers.</span>
              <span className="lp2-title-accent"> Close More Loans.</span>
            </h1>
            <p className="lp2-lead">
              Claim ZIP coverage, work with local agents, and keep buyers loyal with your rebate-friendly
              mortgage process—all within a seamless, synchronized platform.
            </p>
            <div className="lp2-cta">
              <Link className="btn primary" to="/auth?role=loanOfficer">Continue to Login</Link>
              <Link className="btn ghost" to="/onboarding">Platform Tour</Link>
            </div>
            <div className="lp2-trust">
              <span className="lp2-trust-pill"><IconGlyph name="location" filled /> ZIP coverage</span>
              <span className="lp2-trust-pill"><IconGlyph name="billing" filled /> Get Buyer Leads</span>
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
                <strong>Grow your business.</strong>
                <span>In the ZIP codes you choose.</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--bot">
              <div className="lp2-media-card-icon"><IconGlyph name="checklist" filled /></div>
              <div>
                <strong>Borrower checklists</strong>
                <span>Helps buyers stay compliant</span>
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
                <h3>Exclusive ZIP Coverage</h3>
              </div>
              <p>Claim 1 to 6 ZIP codes and position yourself as the go-to loan officer in your market.</p>
            </article>

            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="billing" filled /></span>
                <h3>Real-Time Performance Insights</h3>
              </div>
              <p>Track how often you appear in searches and how many buyers view your profile.</p>
            </article>

            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="checklist" filled /></span>
                <h3>Built-In Compliance Tools</h3>
              </div>
              <p>Stay aligned with rebate guidelines using integrated checklists for both buyers and agents.</p>
            </article>

            <article className="lp2-feature-card">
              <div className="lp2-feature-card-top">
                <span className="lp2-feature-icon"><IconGlyph name="leads" filled /></span>
                <h3>Flexible, No-Contract Model</h3>
              </div>
              <p>No long-term commitments—cancel anytime with 30 days&apos; notice.</p>
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
            <p>Log in to claim ZIPs, create your profile, and connect with rebate-ready buyers looking to buy or build.</p>
          </div>
          <Link className="btn primary" to="/auth?role=loanOfficer">Login to Loan Officer Portal</Link>
        </section>

        <PremiumLandingFooter />
      </main>
    </PremiumLandingFrame>
  );
}
