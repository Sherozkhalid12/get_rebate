import { useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { ReviewsCarousel } from '../../components/landing/ReviewsCarousel';
import { FaqAccordion, PremiumLandingFooter, PremiumLandingFrame, PremiumLandingHeader } from '../../components/landing/PremiumLandingKit';
import { useAuth } from '../../context/AuthContext';
import { useScrollToTop, useLandingScrollAnimations } from '../../hooks/useLandingPage';

const reviews = [
  { quote: 'ZIP claims are seamless with Stripe. Coverage updates instantly.', author: 'James K.', rating: 5 },
  { quote: 'Leads flow in from day one. Best platform for rebate-focused agents.', author: 'Rachel T.', rating: 5 },
  { quote: 'Listing studio is intuitive. Buyers love the rebate transparency.', author: 'Michael P.', rating: 5 },
];

const faqs = [
  { q: 'How do ZIP claims work?', a: 'Agents use Stripe to subscribe to ZIP coverage. Once payment is verified, claimed ZIPs update instantly and you can publish listings and receive leads.', icon: 'location' },
  { q: 'What can I add to listings?', a: 'Photos, BAC %, property details, and open houses – all using the same API as the mobile app. Listings appear in the buyer marketplace for your claimed ZIPs.', icon: 'listings' },
  { q: 'How do I manage leads?', a: 'Buyers submit lead forms from your listings. Manage leads, send proposals, and close deals in your dashboard with messages and proposals.', icon: 'leads' },
];

export function AgentLandingPage() {
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
    <PremiumLandingFrame containerRef={containerRef}>
      <PremiumLandingHeader
        links={[
          { href: '#features', label: 'Features' },
          { href: '#flow', label: 'Flow' },
          { href: '#reviews', label: 'Reviews' },
          { href: '#faqs', label: 'FAQs' },
        ]}
        actions={(
          <>
            <Link className="btn ghost tiny" to="/">Change Role</Link>
            <Link className="btn primary tiny" to="/auth?role=agent">Login</Link>
          </>
        )}
      />

      <main className="lp2-main">
        <section className="lp2-hero lp2-surface">
          <div className="lp2-hero-copy">
            <p className="lp2-kicker">For Real Estate Agents</p>
            <h1 className="lp2-title">
              Claim ZIPs.
              <span className="lp2-title-accent"> Capture leads.</span>
              <span className="lp2-title-accent"> Close faster.</span>
            </h1>
            <p className="lp2-lead">
              Stripe-powered ZIP coverage, listing + media uploads, and a lead workspace that feels
              like a modern revenue dashboard.
            </p>
            <div className="lp2-cta">
              <Link className="btn primary" to="/auth?role=agent">Continue to Login</Link>
              <Link className="btn ghost" to="/onboarding">Platform Tour</Link>
            </div>
            <div className="lp2-trust">
              <span className="lp2-trust-pill"><IconGlyph name="location" filled /> Instant ZIP refresh</span>
              <span className="lp2-trust-pill"><IconGlyph name="listings" filled /> Media-ready listings</span>
              <span className="lp2-trust-pill"><IconGlyph name="leads" filled /> Lead routing included</span>
            </div>
          </div>

          <div className="lp2-hero-media" aria-hidden="true">
            <div
              className="lp2-media-visual lp2-media-visual--photo"
              style={{ backgroundImage: 'url("https://images.pexels.com/photos/7578859/pexels-photo-7578859.jpeg")' }}
            />
            <div className="lp2-media-card lp2-media-card--top">
              <div className="lp2-media-card-icon"><IconGlyph name="verified" filled /></div>
              <div>
                <strong>Stripe-backed claims</strong>
                <span>Coverage updates instantly</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--mid">
              <div className="lp2-media-card-icon"><IconGlyph name="trendingUp" filled /></div>
              <div>
                <strong>Lead-ready funnel</strong>
                <span>Proposals + messaging built-in</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--bot">
              <div className="lp2-media-card-icon"><IconGlyph name="listings" filled /></div>
              <div>
                <strong>Listing studio</strong>
                <span>Photos, open houses, BAC%</span>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Agent Platform Features</h2>
            <p>Everything you need to build coverage and convert rebate-minded buyers.</p>
          </div>
          <div className="lp2-grid lp2-grid--2wide">
            <article className="lp2-media-feature">
              <div
                className="lp2-media-feature-art"
                style={{
                  backgroundImage: 'url("https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80")',
                }}
              />
              <div className="lp2-media-feature-body">
                <span className="lp2-feature-icon"><IconGlyph name="location" filled /></span>
                <h3>ZIP Console</h3>
                <p>State-wide ZIP inventory, Stripe checkout, and dashboards that update instantly after payment verification.</p>
              </div>
            </article>

            <article className="lp2-media-feature">
              <div
                className="lp2-media-feature-art"
                style={{
                  backgroundImage: 'url("https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80")',
                }}
              />
              <div className="lp2-media-feature-body">
                <span className="lp2-feature-icon"><IconGlyph name="listings" filled /></span>
                <h3>Listing & Media Studio</h3>
                <p>Upload listings with photos, BAC %, property details, and open houses—using the same backend flows as the mobile app.</p>
              </div>
            </article>

            <article className="lp2-media-feature">
              <div
                className="lp2-media-feature-art"
                style={{
                  backgroundImage: 'url("https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=1200&q=80")',
                }}
              />
              <div className="lp2-media-feature-body">
                <span className="lp2-feature-icon"><IconGlyph name="leads" filled /></span>
                <h3>Lead Management</h3>
                <p>Capture leads from listing + profile experiences, then move them through proposals and messages inside your dashboard.</p>
              </div>
            </article>

            <article className="lp2-media-feature">
              <div
                className="lp2-media-feature-art"
                style={{ backgroundImage: 'url("https://images.pexels.com/photos/7415025/pexels-photo-7415025.jpeg")' }}
              />
              <div className="lp2-media-feature-body">
                <span className="lp2-feature-icon"><IconGlyph name="profile" filled /></span>
                <h3>Premium Agent Profile</h3>
                <p>Showcase coverage, listings, and rebate positioning to buyers—designed for trust and conversion.</p>
              </div>
            </article>
          </div>
        </section>

        <section id="flow" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>How the Agent Flow Works</h2>
            <p>A clean, predictable workflow from coverage to conversions.</p>
          </div>
          <div className="lp2-grid lp2-grid--3">
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="location" filled /></span>
              <h3>1. Claim ZIP Coverage</h3>
              <p>Check claim status, complete Stripe checkout, and return to a refreshed ZIP dashboard.</p>
            </article>
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="listings" filled /></span>
              <h3>2. Publish Listings</h3>
              <p>Upload photos, BAC %, and open houses. Listings appear for buyers in your claimed ZIPs.</p>
            </article>
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="leads" filled /></span>
              <h3>3. Work Leads</h3>
              <p>Manage leads, send proposals, and message in one place—built for speed and follow-up.</p>
            </article>
          </div>
        </section>

        <section id="reviews" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>What Agents Say</h2>
            <p>Built to feel modern—without losing the operational essentials.</p>
          </div>
          <ReviewsCarousel reviews={reviews} />
        </section>

        <section id="faqs" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>FAQs</h2>
            <p>Fast answers about ZIP coverage and listings.</p>
          </div>
          <FaqAccordion items={faqs} />
        </section>

        <section id="start" className="lp2-cta-band lp2-surface animate-on-scroll">
          <div>
            <h2>Ready to Grow Your Coverage?</h2>
            <p>Log in to claim ZIPs, publish listings, and start capturing rebate-ready buyer leads.</p>
          </div>
          <Link className="btn primary" to="/auth?role=agent">Login to Agent Portal</Link>
        </section>

        <PremiumLandingFooter />
      </main>
    </PremiumLandingFrame>
  );
}
