import { useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
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

const faqs = [
  {
    q: 'What is a real estate rebate?',
    a: 'A real estate rebate is a portion of the agent’s commission that is given back to you at closing. Instead of the full commission going to the agent, part of it is shared with you—putting money back in your pocket when you buy or sell a home.',
    icon: 'info',
  },
  {
    q: 'How do I find homes in my area?',
    a: 'Simply create a free account and enter a ZIP code where you’re looking to buy. You’ll be able to browse homes for sale, view open houses, and connect with local agents (when selling and/or buying/building) and loan officers (when buying or building) who service that area.',
    icon: 'search',
  },
  {
    q: 'Are rebate estimates accurate?',
    a: 'Rebate estimates are based on the purchase or sale price and an assumed commission. Since commission is negotiable, the exact rebate amount may vary. Our calculators provide a close estimate so you know what to expect—no guessing. Once you know the commission your listing agent charges for the listing side commission and/or what the seller or builder is paying your buyer’s agent, you can then determine a more accurate amount.',
    icon: 'calculator',
  },
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
              Local, Full-Service Real Estate, With Cash Back.
            </h1>
            <p className="lp2-lead">
              Connect with local agents, explore homes and open houses, and receive a rebate based on the commission—simple, transparent, and built
              for today’s market.
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
              style={{ backgroundImage: 'url("/images/buyerSeller.PNG")' }}
            />
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
              <p>Find Local Agents to sell your home, get a rebate at closing or a lower listing fee.</p>
            </article>
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="listings" filled /></span>
              <h3>Advertise your Listing</h3>
              <p>Potential Buyers search our site/app for homes for sale and open houses, giving you more exposure.</p>
            </article>
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="handshake" filled /></span>
              <h3>Also Buying?</h3>
              <p>Work with your same agent from this site if buying/building locally, or search for a different agent where you plan to move (if in a state that allows rebates).</p>
            </article>
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="calculator" filled /></span>
              <h3>Calculate your savings</h3>
              <p>Use the rebate calculator to determine your savings. It's easier to just lower the listing fee, but your savings is the same.</p>
            </article>
          </div>
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
