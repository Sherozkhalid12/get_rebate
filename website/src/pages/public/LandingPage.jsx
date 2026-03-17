import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { useAuth } from '../../context/AuthContext';

const featuredHomes = [
  {
    title: 'SoHo Luxury Loft',
    meta: '$1.25M • 3 Beds • 2 Baths • Manhattan',
    rebate: '$7,500 estimated closing rebate',
    image:
      'https://images.unsplash.com/photo-1512914890250-353c97c9e7e2?auto=format&fit=crop&w=900&q=80',
  },
  {
    title: 'Chelsea Smart Condo',
    meta: '$980K • 2 Beds • 2 Baths • Chelsea',
    rebate: '$5,880 estimated closing rebate',
    image:
      'https://images.unsplash.com/photo-1486304873000-235643847519?auto=format&fit=crop&w=900&q=80',
  },
  {
    title: 'Brooklyn Family Home',
    meta: '$1.08M • 4 Beds • 3 Baths • Brooklyn',
    rebate: '$6,480 estimated closing rebate',
    image:
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=900&q=80',
  },
];

const kpis = [
  { label: 'Active Homes', value: '18.9K+', icon: 'apartment' },
  { label: 'Verified Agents', value: '1.4K+', icon: 'verified' },
  { label: 'Loan Officers', value: '680+', icon: 'businessCenter' },
  { label: 'Avg Savings', value: '$9,850', icon: 'savings' },
];

const reviews = [
  {
    quote: 'Finally found a platform that shows real rebate estimates upfront. Saved over $8K on our Manhattan condo.',
    author: 'Sarah M.',
    role: 'Buyer',
    rating: 5,
  },
  {
    quote: 'ZIP claims are seamless with Stripe. My coverage updates instantly and leads flow in from day one.',
    author: 'James K.',
    role: 'Agent',
    rating: 5,
  },
  {
    quote: 'Rebate-friendly programs get real visibility. Our borrower checklist syncs perfectly with the app.',
    author: 'Maria L.',
    role: 'Loan Officer',
    rating: 5,
  },
];

const faqs = [
  {
    q: 'What is a closing rebate?',
    a: 'A closing rebate is money credited back to you at closing, typically from your agent or lender. GetaRebate surfaces estimated rebates so you know potential savings before making an offer.',
    icon: 'info',
  },
  {
    q: 'How do agents claim ZIP codes?',
    a: 'Agents use Stripe to subscribe to ZIP coverage. Once payment is verified, their claimed ZIPs update instantly in the dashboard and they can publish listings and receive leads.',
    icon: 'location',
  },
  {
    q: 'Is GetaRebate available in my area?',
    a: 'Search by ZIP on the platform to see coverage. We expand based on agent and loan officer claims, so new areas come online as professionals join.',
    icon: 'search',
  },
  {
    q: 'How are rebate estimates calculated?',
    a: 'Estimates are based on typical BAC percentages and loan amounts in your area. Actual rebates depend on your specific transaction and the agent or lender you work with.',
    icon: 'calculator',
  },
];

const roleFlows = [
  {
    role: 'Buyer / Seller',
    icon: 'homeWork',
    description: 'Search homes, favorite listings, and request proposals with rebate transparency.',
    cta: 'Enter Buyer Experience',
    to: '/auth',
    image:
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
  },
  {
    role: 'Real Estate Agent',
    icon: 'verified',
    description: 'Claim ZIP codes, publish listings with media, and manage incoming leads.',
    cta: 'Enter Agent Portal',
    to: '/auth?role=agent',
    image:
      'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=900&q=80',
  },
  {
    role: 'Loan Officer',
    icon: 'businessCenter',
    description: 'Show rebate-friendly policies, add loan products, and track borrower leads.',
    cta: 'Enter Loan Officer Portal',
    to: '/auth?role=loanOfficer',
    image:
      'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=800&q=80',
  },
];

export function LandingPage() {
  const { isAuthenticated, role } = useAuth();

  if (isAuthenticated) {
    if (role === 'agent') return <Navigate to="/agent" replace />;
    if (role === 'loanOfficer') return <Navigate to="/loan-officer" replace />;
    return <Navigate to="/app" replace />;
  }

  return (
    <div className="landing-wrap">
      <header className="landing-nav landing-nav-premium glass-card">
        <Link to="/" className="brand landing-brand">
          <img src="/images/mainlogo.png" alt="GetaRebate" className="landing-brand-logo" />
          GetaRebate
        </Link>
        <nav className="landing-nav-links">
          <a href="#flows">Platform Flows</a>
          <a href="#collections">Live Homes</a>
          <a href="#reviews">Reviews</a>
          <a href="#faqs">FAQs</a>
          <a href="#services">Why GetaRebate</a>
          <a href="#start">Get Started</a>
        </nav>
        <div className="landing-nav-actions">
          <Link className="btn ghost tiny" to="/onboarding">Platform Tour</Link>
          <Link className="btn primary tiny" to="/auth">Login</Link>
        </div>
      </header>

      <section className="landing-stats-bar glass-card">
        <div className="landing-stats-inner">
          {kpis.map((s) => (
            <article key={s.label} className="landing-stat-item">
              <span className="landing-stat-icon-wrap">
                <IconGlyph name={s.icon} filled />
              </span>
              <div className="landing-stat-content">
                <strong>{s.value}</strong>
                <span>{s.label}</span>
              </div>
            </article>
          ))}
        </div>
      </section>

      <main className="landing-main">
        <section className="landing-hero landing-hero-premium glass-card">
          <div className="hero-copy premium-copy">
            <p className="site-hero-kicker">Premium Rebate Real Estate Platform</p>
            <h1>One Connected Experience for Buyers, Agents, and Loan Officers</h1>
            <p>
              Search live homes, route leads to elite agents, and keep rebate-friendly lenders in
              the loop – all in a single workflow designed for transparency.
            </p>
            <div className="hero-cta">
              <Link className="btn primary" to="/auth">Continue to Login</Link>
              <Link className="btn ghost" to="/onboarding">See Full Flow</Link>
            </div>
          </div>

          <div className="hero-visual-block">
            <div
              className="hero-visual-art"
              style={{
                backgroundImage:
                  'url("https://images.unsplash.com/photo-1501183638710-841dd1904471?auto=format&fit=crop&w=1200&q=80")',
                backgroundSize: 'cover',
                backgroundPosition: 'center',
              }}
            />
            <div className="hero-badge">
              <IconGlyph name="autoAwesome" filled /> Rebate-Friendly Network Verified
            </div>
            <div className="hero-search">
              <IconGlyph name="search" filled />
              <input placeholder="Search by ZIP to preview local coverage (e.g. 10001)" />
              <button className="btn primary tiny" type="button">Preview</button>
            </div>
            <div className="hero-mini-cards hero-mini-cards-with-icons">
              {kpis.map((s) => (
                <article key={s.label}>
                  <span className="hero-mini-icon-wrap">
                    <IconGlyph name={s.icon} filled />
                  </span>
                  <div>
                    <strong>{s.value}</strong>
                    <p>{s.label}</p>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="flows" className="landing-section glass-card">
          <h2>Three Role-Based Flows, One Platform</h2>
          <p className="landing-subtext">
            GetaRebate keeps buyers, agents, and loan officers aligned from first search to closing
            statement – with ZIP claims, listings, and leads flowing through the same system.
          </p>
          <div className="pillars">
            {roleFlows.map((flow) => (
              <article key={flow.role} className="flow-card">
                <div
                  className="flow-card-media"
                  style={{
                    backgroundImage: `linear-gradient(135deg, rgba(15,23,42,0.18), rgba(15,23,42,0.06)), url("${flow.image}")`,
                  }}
                />
                <div className="flow-card-body">
                  <IconGlyph name={flow.icon} filled />
                  <h3>{flow.role}</h3>
                  <p>{flow.description}</p>
                  <Link className="btn tiny ghost" to={flow.to}>{flow.cta}</Link>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section id="collections" className="landing-section glass-card">
          <h2>Live-Inspired Home Collections</h2>
          <p className="landing-subtext">
            A taste of the kinds of homes buyers explore in the marketplace, with rebate estimates
            surfaced alongside price and location.
          </p>
          <div className="homes-grid">
            {featuredHomes.map((item) => (
              <article key={item.title} className="home-card premium-home-card">
                <div
                  className="home-art"
                  style={{
                    backgroundImage: `url("${item.image}")`,
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                  }}
                />
                <h3>{item.title}</h3>
                <p>{item.meta}</p>
                <span>{item.rebate}</span>
                <button className="btn ghost tiny" type="button">View Buyer Experience</button>
              </article>
            ))}
          </div>
        </section>

        <section className="landing-section glass-card">
          <h2>How the Rebate Flow Works</h2>
          <p className="landing-subtext">
            The same backend powering the mobile app also powers this web experience – from ZIP
            claims and Stripe payments to listing media uploads and lead routing.
          </p>
          <div className="pillars timeline-pillar">
            <article>
              <IconGlyph name="location" filled />
              <h3>1. Claim ZIP Coverage</h3>
              <p>
                Agents and loan officers check ZIP claim status, start Stripe checkout, and return
                to instantly refreshed coverage dashboards.
              </p>
            </article>
            <article>
              <IconGlyph name="listings" filled />
              <h3>2. Add Listings & Programs</h3>
              <p>
                Agents upload listings with photos and open houses; loan officers publish loan
                programs tied to their coverage.
              </p>
            </article>
            <article>
              <IconGlyph name="leads" filled />
              <h3>3. Capture & Work Leads</h3>
              <p>
                Buyers submit lead forms from listing and profile pages; agents and lenders manage
                those leads in their web dashboards.
              </p>
            </article>
          </div>
        </section>

        <section className="landing-section glass-card">
          <h2>Inside the Web App</h2>
          <p className="landing-subtext">
            Every role gets a focused workspace that mirrors the mobile experience – optimized for
            keyboard, large screens, and team collaboration.
          </p>
          <div className="feature-grid">
            <article className="feature-card-with-media">
              <div
                className="feature-card-media"
                style={{
                  backgroundImage:
                    'url("https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=900&q=80")',
                }}
              />
              <div className="feature-card-body">
                <IconGlyph name="dashboard" filled />
                <h3>Buyer Workspace</h3>
                <p>
                  Home feed, ZIP search, favorites, and a unified messages view so buyers can manage
                  agents and loan officers from one place.
                </p>
              </div>
            </article>
            <article className="feature-card-with-media">
              <div
                className="feature-card-media"
                style={{
                  backgroundImage:
                    'url("https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=900&q=80")',
                }}
              />
              <div className="feature-card-body">
                <IconGlyph name="location" filled />
                <h3>Agent ZIP Console</h3>
                <p>
                  State-wide ZIP inventory, Stripe-powered claims, and claimed ZIP lists that update
                  the moment a payment is verified.
                </p>
              </div>
            </article>
            <article className="feature-card-with-media">
              <div
                className="feature-card-media"
                style={{
                  backgroundImage:
                    'url("https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=900&q=80")',
                }}
              />
              <div className="feature-card-body">
                <IconGlyph name="listings" filled />
                <h3>Listing & Media Studio</h3>
                <p>
                  App-like listing creation that accepts photos, BAC %, property details, and open
                  houses – all using the same API contract.
                </p>
              </div>
            </article>
            <article className="feature-card-with-media">
              <div
                className="feature-card-media"
                style={{
                  backgroundImage:
                    'url("https://images.unsplash.com/photo-1556740749-887f6717d7e4?auto=format&fit=crop&w=900&q=80")',
                }}
              />
              <div className="feature-card-body">
                <IconGlyph name="checklist" filled />
                <h3>Loan Officer Coverage</h3>
                <p>
                  ZIP coverage, loan programs, and borrower checklists, with flows synchronized to the
                  mobile Loan Officer dashboard.
                </p>
              </div>
            </article>
          </div>
        </section>

        <section id="reviews" className="landing-section glass-card">
          <h2>What People Say</h2>
          <p className="landing-subtext">
            Buyers, agents, and loan officers share their experience with GetaRebate.
          </p>
          <div className="reviews-grid">
            {reviews.map((r) => (
              <article key={r.author} className="review-card">
                <div className="review-stars">
                  {Array.from({ length: r.rating }).map((_, i) => (
                    <IconGlyph key={i} name="star" filled />
                  ))}
                </div>
                <blockquote>{r.quote}</blockquote>
                <div className="review-author">
                  <IconGlyph name="person" filled />
                  <div>
                    <strong>{r.author}</strong>
                    <span>{r.role}</span>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section id="faqs" className="landing-section glass-card">
          <h2>Frequently Asked Questions</h2>
          <p className="landing-subtext">
            Quick answers about rebates, coverage, and how GetaRebate works.
          </p>
          <div className="faqs-list">
            {faqs.map((faq) => (
              <article key={faq.q} className="faq-item">
                <IconGlyph name={faq.icon} filled />
                <div>
                  <h4>{faq.q}</h4>
                  <p>{faq.a}</p>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section id="services" className="landing-section glass-card">
          <h2>Why Teams Choose GetaRebate</h2>
          <div className="feature-grid">
            <article>
              <span className="feature-icon-wrap"><IconGlyph name="homeWork" filled /></span>
              <h3>Buyer Discovery</h3>
              <p>ZIP-based search, open houses, and listing detail pages that highlight rebate potential.</p>
            </article>
            <article>
              <span className="feature-icon-wrap"><IconGlyph name="verified" filled /></span>
              <h3>Agent ZIP Claims</h3>
              <p>Stripe-powered ZIP subscriptions with live claim status and instant coverage updates.</p>
            </article>
            <article>
              <span className="feature-icon-wrap"><IconGlyph name="businessCenter" filled /></span>
              <h3>Loan Officer Visibility</h3>
              <p>Market coverage, loan programs, and borrower checklists in one consistent view.</p>
            </article>
            <article>
              <span className="feature-icon-wrap"><IconGlyph name="handshake" filled /></span>
              <h3>End-to-End Workflow</h3>
              <p>Messages, proposals, and lead records flow directly into dashboards for each role.</p>
            </article>
          </div>
        </section>

        <section id="start" className="landing-cta glass-card">
          <h2>Continue Into the App</h2>
          <p>
            Log in and pick your role to see live data: claimed ZIPs, listings, leads, and rebate
            journeys – all wired to the same backend the mobile app uses.
          </p>
          <Link className="btn primary" to="/auth">Login to GetaRebate</Link>
        </section>
      </main>

      <footer className="landing-footer glass-card">
        <div className="landing-footer-inner">
          <div className="landing-footer-brand">
            <img src="/images/mainlogo.png" alt="GetaRebate" className="landing-footer-logo" />
            <div>
              <strong>GetaRebate</strong>
              <p>Rebate transparency for buyers, agents, and loan officers.</p>
            </div>
          </div>
          <div className="landing-footer-links">
            <Link to="/privacy-policy">Privacy</Link>
            <Link to="/terms-of-service">Terms</Link>
            <Link to="/about-legal">Legal</Link>
            <Link to="/help-support">Support</Link>
          </div>
        </div>
        <div className="landing-footer-bottom">
          <span>© {new Date().getFullYear()} GetaRebate</span>
          <span className="landing-footer-sep" aria-hidden="true" />
          <span>Built for modern rebate-first transactions</span>
        </div>
      </footer>
    </div>
  );
}
