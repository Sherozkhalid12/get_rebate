import { useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { ReviewsCarousel } from '../../components/landing/ReviewsCarousel';
import { FaqAccordion, PremiumLandingFooter, PremiumLandingFrame, PremiumLandingHeader } from '../../components/landing/PremiumLandingKit';
import { useAuth } from '../../context/AuthContext';
import { useScrollToTop, useLandingScrollAnimations } from '../../hooks/useLandingPage';
import { ThemeToggle } from '../../components/ui/ThemeToggle';

const ROLES = [
  {
    id: 'buyer',
    label: 'I am a Buyer or Seller',
    description: 'Search homes, explore rebates, and connect with verified agents who offer real closing savings.',
    to: '/landing/buyer',
    icon: 'homeWork',
    image: 'https://images.pexels.com/photos/8470800/pexels-photo-8470800.jpeg',
  },
  {
    id: 'agent',
    label: 'I am a Real Estate Agent',
    description: 'Claim ZIP codes, publish listings with media, and manage incoming buyer leads in one platform.',
    to: '/landing/agent',
    icon: 'verified',
    image: 'https://images.pexels.com/photos/7578859/pexels-photo-7578859.jpeg',
  },
  {
    id: 'loanOfficer',
    label: 'I am a Loan Officer',
    description: 'Show rebate-friendly programs, add loan products, and track borrower leads in your market.',
    to: '/landing/loan-officer',
    icon: 'businessCenter',
    image: 'https://images.pexels.com/photos/8293637/pexels-photo-8293637.jpeg',
  },
];

const KPIS = [
  { label: 'Active Homes', value: '18.9K+', icon: 'apartment' },
  { label: 'Verified Agents', value: '1.4K+', icon: 'verified' },
  { label: 'Loan Officers', value: '680+', icon: 'businessCenter' },
  { label: 'Avg Savings', value: '$9,850', icon: 'savings' },
];

const VALUE_POINTS = [
  {
    icon: 'autoAwesome',
    title: 'Rebate Transparency',
    text: 'Every listing and agent profile shows estimated closing rebates upfront.',
  },
  {
    icon: 'homeWork',
    title: 'One Connected Flow',
    text: 'Buyers, agents, and lenders work in the same system from search to closing.',
  },
  {
    icon: 'handshake',
    title: 'End-to-End Workflow',
    text: 'Messages, proposals, and lead records flow directly into role-specific dashboards.',
  },
];

const REVIEWS = [
  { quote: 'Finally found a platform that shows real rebate estimates upfront. Saved over $8K on our Manhattan condo.', author: 'Sarah M.', role: 'Buyer', rating: 5 },
  { quote: 'ZIP claims are seamless with Stripe. My coverage updates instantly and leads flow in from day one.', author: 'James K.', role: 'Agent', rating: 5 },
  { quote: 'Rebate-friendly programs get real visibility. Our borrower checklist syncs perfectly with the app.', author: 'Maria L.', role: 'Loan Officer', rating: 5 },
];

const FAQS = [
  { q: 'What is a closing rebate?', a: 'A closing rebate is money credited back to you at closing, typically from your agent or lender. GetaRebate surfaces estimated rebates so you know potential savings before making an offer.', icon: 'info' },
  { q: 'How do agents claim ZIP codes?', a: 'Agents use Stripe to subscribe to ZIP coverage. Once payment is verified, their claimed ZIPs update instantly in the dashboard and they can publish listings and receive leads.', icon: 'location' },
  { q: 'Is GetaRebate available in my area?', a: 'Search by ZIP on the platform to see coverage. We expand based on agent and loan officer claims, so new areas come online as professionals join.', icon: 'search' },
  { q: 'How are rebate estimates calculated?', a: 'Estimates are based on typical BAC percentages and loan amounts in your area. Actual rebates depend on your specific transaction and the agent or lender you work with.', icon: 'calculator' },
];

export function RoleSelectionPage() {
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
    <PremiumLandingFrame containerRef={containerRef} className="lp2-role">
      <PremiumLandingHeader
        links={[
          { href: '#roles', label: 'Roles' },
          { href: '#reviews', label: 'Reviews' },
          { href: '#faqs', label: 'FAQs' },
        ]}
        actions={(
          <>
            <Link className="btn ghost tiny" to="/onboarding">Platform Tour</Link>
            <Link className="btn primary tiny" to="/auth">Login</Link>
          </>
        )}
        rightSlot={<ThemeToggle />}
      />

      <section className="lp2-hero lp2-hero--center lp2-surface">
        <div className="lp2-hero-copy">
          <p className="lp2-kicker">Premium Rebate Real Estate Platform</p>
          <h1 className="lp2-title">
            Welcome to <span className="lp2-title-accent">GetaRebate</span>
          </h1>
          <p className="lp2-lead">
            One connected experience for buyers, agents, and loan officers—built for rebate transparency
            from search to closing statement.
          </p>
          <div className="lp2-trust lp2-trust--center">
            <span className="lp2-trust-pill"><IconGlyph name="autoAwesome" filled /> Premium workflows</span>
            <span className="lp2-trust-pill"><IconGlyph name="verified" filled /> Verified professionals</span>
            <span className="lp2-trust-pill"><IconGlyph name="savings" filled /> Savings surfaced early</span>
          </div>
        </div>
      </section>

      <section className="lp2-kpis lp2-surface">
        {KPIS.map((k) => (
          <article key={k.label} className="lp2-kpi">
            <span className="lp2-kpi-icon">
              <IconGlyph name={k.icon} filled />
            </span>
            <div className="lp2-kpi-body">
              <strong>{k.value}</strong>
              <span>{k.label}</span>
            </div>
          </article>
        ))}
      </section>

      <main className="lp2-main">
        <section id="roles" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Choose Your Role</h2>
            <p>Explore tailored features, workflows, and value—built for each role.</p>
          </div>
          <div className="lp2-grid lp2-grid--3">
            {ROLES.map((r) => (
              <Link key={r.id} to={r.to} className="lp2-role-card">
                <div
                  className="lp2-role-card-art"
                  style={{
                    backgroundImage: `url("${r.image}")`,
                  }}
                />
                <div className="lp2-role-card-body">
                  <span className="lp2-role-card-icon">
                    <IconGlyph name={r.icon} filled />
                  </span>
                  <h3>{r.label}</h3>
                  <p>{r.description}</p>
                  <span className="lp2-role-card-cta">Explore →</span>
                </div>
              </Link>
            ))}
          </div>
        </section>

        <section className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Why GetaRebate</h2>
            <p>The same backend powering our mobile app powers this web experience.</p>
          </div>
          <div className="lp2-grid lp2-grid--3">
            {VALUE_POINTS.map((v) => (
              <article key={v.title} className="lp2-feature">
                <span className="lp2-feature-icon"><IconGlyph name={v.icon} filled /></span>
                <h3>{v.title}</h3>
                <p>{v.text}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>How the Platform Works</h2>
            <p>A single connected flow across coverage, listings, and leads.</p>
          </div>
          <div className="lp2-grid lp2-grid--3">
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="location" filled /></span>
              <h3>Claim ZIP Coverage</h3>
              <p>Agents and loan officers complete Stripe checkout and return to refreshed dashboards.</p>
            </article>
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="listings" filled /></span>
              <h3>Add Listings & Programs</h3>
              <p>Agents publish listings with media; loan officers publish programs tied to coverage.</p>
            </article>
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="leads" filled /></span>
              <h3>Capture & Work Leads</h3>
              <p>Buyers submit lead forms; professionals manage leads, proposals, and messages.</p>
            </article>
          </div>
        </section>

        <section id="reviews" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>What People Say</h2>
            <p>Buyers, agents, and loan officers share their experience with GetaRebate.</p>
          </div>
          <ReviewsCarousel reviews={REVIEWS} />
        </section>

        <section id="faqs" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>FAQs</h2>
            <p>Quick answers about rebates, coverage, and how the platform works.</p>
          </div>
          <FaqAccordion items={FAQS} />
        </section>

        <section className="lp2-cta-band lp2-surface animate-on-scroll">
          <div>
            <h2>Ready to Get Started?</h2>
            <p>Log in and pick your role to see live data: coverage, listings, leads, and rebate journeys.</p>
          </div>
          <div className="lp2-cta-row">
            <Link className="btn primary" to="/auth">Login to GetaRebate</Link>
            <Link className="btn ghost" to="/onboarding">See Full Platform Tour</Link>
          </div>
        </section>

        <PremiumLandingFooter />
      </main>
    </PremiumLandingFrame>
  );
}
