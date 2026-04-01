import { useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { ReviewsCarousel } from '../../components/landing/ReviewsCarousel';
import { FaqAccordion, PremiumLandingFooter, PremiumLandingFrame, PremiumLandingHeader } from '../../components/landing/PremiumLandingKit';
import { useAuth } from '../../context/AuthContext';
import { useScrollToTop, useLandingScrollAnimations } from '../../hooks/useLandingPage';

const featuredHomes = [
  {
    title: 'SoHo Luxury Loft',
    meta: '$1.25M • 3 Beds • 2 Baths • Manhattan',
    rebate: '$7,500 estimated closing rebate',
    image: 'https://images.pexels.com/photos/7018253/pexels-photo-7018253.jpeg',
  },
  {
    title: 'Chelsea Smart Condo',
    meta: '$980K • 2 Beds • 2 Baths • Chelsea',
    rebate: '$5,880 estimated closing rebate',
    image: 'https://images.pexels.com/photos/36585406/pexels-photo-36585406.jpeg',
  },
  {
    title: 'Brooklyn Family Home',
    meta: '$1.08M • 4 Beds • 3 Baths • Brooklyn',
    rebate: '$6,480 estimated closing rebate',
    image: 'https://images.pexels.com/photos/280229/pexels-photo-280229.jpeg',
  },
];

const reviews = [
  { quote: 'Saved over $8K on our Manhattan condo. Rebate estimates were spot-on.', author: 'Sarah M.', rating: 5 },
  { quote: 'Finally a platform that shows real savings upfront. Highly recommend.', author: 'David R.', rating: 5 },
  { quote: 'Connected with a great agent and got a $6K rebate at closing.', author: 'Jennifer L.', rating: 5 },
];

const faqs = [
  { q: 'What is a closing rebate?', a: 'A closing rebate is money credited back to you at closing from your agent or lender. GetaRebate shows estimated rebates so you know potential savings before making an offer.', icon: 'info' },
  { q: 'How do I find homes in my area?', a: 'Search by ZIP code to see listings and agents in your area. Favorites and proposals help you compare options with full rebate transparency.', icon: 'search' },
  { q: 'Are rebate estimates accurate?', a: 'Estimates are based on typical BAC percentages. Actual rebates depend on your transaction and the agent or lender you work with.', icon: 'calculator' },
];

export function BuyerLandingPage() {
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
    <PremiumLandingFrame containerRef={containerRef} className="lp2-page lp2-page--buyer">
      <PremiumLandingHeader
        links={[
          { href: '#homes', label: 'Homes' },
          { href: '#features', label: 'Features' },
          { href: '#reviews', label: 'Reviews' },
          { href: '#faqs', label: 'FAQs' },
        ]}
        actions={(
          <>
            <Link className="btn ghost tiny" to="/">Change Role</Link>
            <Link className="btn primary tiny" to="/auth">Login</Link>
          </>
        )}
      />

      <main className="lp2-main">
        <section className="lp2-hero lp2-surface">
          <div className="lp2-hero-copy">
            <p className="lp2-kicker">For Buyers & Sellers</p>
            <h1 className="lp2-title">
              Find homes.
              <span className="lp2-title-accent"> See rebates upfront.</span>
            </h1>
            <p className="lp2-lead">
              Explore listings, favorite homes, and connect with verified professionals—without waiting
              until closing to understand your savings.
            </p>
            <div className="lp2-cta">
              <Link className="btn primary" to="/auth">Continue to Login</Link>
              <Link className="btn ghost" to="/onboarding">Platform Tour</Link>
            </div>
            <div className="lp2-trust">
              <span className="lp2-trust-pill">
                <IconGlyph name="shield" filled /> Verified network
              </span>
              <span className="lp2-trust-pill">
                <IconGlyph name="calculator" filled /> Live estimates
              </span>
              <span className="lp2-trust-pill">
                <IconGlyph name="messages" filled /> One inbox
              </span>
            </div>
          </div>

          <div className="lp2-hero-media" aria-hidden="true">
            <div
              className="lp2-media-visual lp2-media-visual--photo"
              style={{ backgroundImage: 'url("https://images.pexels.com/photos/8470800/pexels-photo-8470800.jpeg")' }}
            />
            <div className="lp2-media-card lp2-media-card--top">
              <div className="lp2-media-card-icon"><IconGlyph name="savings" filled /></div>
              <div>
                <strong>$9,850</strong>
                <span>Avg savings surfaced</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--mid">
              <div className="lp2-media-card-icon"><IconGlyph name="homeWork" filled /></div>
              <div>
                <strong>ZIP-first search</strong>
                <span>Coverage + listings together</span>
              </div>
            </div>
            <div className="lp2-media-card lp2-media-card--bot">
              <div className="lp2-media-card-icon"><IconGlyph name="verified" filled /></div>
              <div>
                <strong>Verified pros</strong>
                <span>Rebate-friendly network</span>
              </div>
            </div>
          </div>
        </section>

        <section id="homes" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Featured Home Collections</h2>
            <p>See price, location, and estimated closing rebates in the same scroll.</p>
          </div>
          <div className="lp2-grid lp2-grid--3">
            {featuredHomes.map((item) => (
              <article key={item.title} className="lp2-home">
                <div
                  className="lp2-home-art"
                  style={{ backgroundImage: `url("${item.image}")` }}
                />
                <div className="lp2-home-body">
                  <h3>{item.title}</h3>
                  <p className="lp2-meta">{item.meta}</p>
                  <div className="lp2-badge">
                    <IconGlyph name="savings" filled /> {item.rebate}
                  </div>
                  <Link className="btn ghost tiny" to="/auth">View Buyer Experience</Link>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section id="features" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Why Buyers Choose GetaRebate</h2>
            <p>Premium tooling built around transparency, speed, and confidence.</p>
          </div>
          <div className="lp2-grid lp2-grid--4">
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="search" filled /></span>
              <h3>ZIP-Based Search</h3>
              <p>Find listings and coverage in seconds—rebates included.</p>
            </article>
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="heart" filled /></span>
              <h3>Favorites & Proposals</h3>
              <p>Compare options with rebate estimates visible from the start.</p>
            </article>
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="messages" filled /></span>
              <h3>Unified Messaging</h3>
              <p>One inbox for agents and loan officers—less chaos, more clarity.</p>
            </article>
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="dashboard" filled /></span>
              <h3>Buyer Workspace</h3>
              <p>Home feed, calculator, and checklists in a clean dashboard.</p>
            </article>
          </div>
        </section>

        <section id="reviews" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>What Buyers Say</h2>
            <p>Real experiences from rebate-first home shopping.</p>
          </div>
          <ReviewsCarousel reviews={reviews} />
        </section>

        <section id="faqs" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>FAQs</h2>
            <p>Quick answers to common rebate questions.</p>
          </div>
          <FaqAccordion items={faqs} />
        </section>

        <section id="start" className="lp2-cta-band lp2-surface animate-on-scroll">
          <div>
            <h2>Ready to Get Started?</h2>
            <p>Log in to search homes, connect with agents, and track savings.</p>
          </div>
          <Link className="btn primary" to="/auth">Login to GetaRebate</Link>
        </section>

        <PremiumLandingFooter />
      </main>
    </PremiumLandingFrame>
  );
}
