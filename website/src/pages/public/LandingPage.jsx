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
  { label: 'Active Homes', value: '18.9K+' },
  { label: 'Verified Agents', value: '1.4K+' },
  { label: 'Loan Officers', value: '680+' },
  { label: 'Avg Savings', value: '$9,850' },
];

const roleFlows = [
  {
    role: 'Buyer / Seller',
    icon: 'home',
    description: 'Search homes, favorite listings, and request proposals with rebate transparency.',
    cta: 'Enter Buyer Experience',
    to: '/auth',
    image:
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
  },
  {
    role: 'Real Estate Agent',
    icon: 'profile',
    description: 'Claim ZIP codes, publish listings with media, and manage incoming leads.',
    cta: 'Enter Agent Portal',
    to: '/auth?role=agent',
    image:
      'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=900&q=80',
  },
  {
    role: 'Loan Officer',
    icon: 'billing',
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
        <Link to="/" className="brand">GetaRebate</Link>
        <nav className="landing-nav-links">
          <a href="#flows">Platform Flows</a>
          <a href="#collections">Live Homes</a>
          <a href="#services">Why GetaRebate</a>
          <a href="#start">Get Started</a>
        </nav>
        <div className="landing-nav-actions">
          <Link className="btn ghost tiny" to="/onboarding">Platform Tour</Link>
          <Link className="btn primary tiny" to="/auth">Login</Link>
        </div>
      </header>

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
              <IconGlyph name="shield" filled /> Rebate-Friendly Network Verified
            </div>
            <div className="hero-search">
              <IconGlyph name="search" filled />
              <input placeholder="Search by ZIP to preview local coverage (e.g. 10001)" />
              <button className="btn primary tiny" type="button">Preview</button>
            </div>
            <div className="hero-mini-cards">
              {kpis.map((s) => (
                <article key={s.label}>
                  <strong>{s.value}</strong>
                  <p>{s.label}</p>
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
                    backgroundImage: `linear-gradient(135deg, rgba(15,23,42,0.3), rgba(15,23,42,0.15)), url("${flow.image}")`,
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
              <h3>1. Claim ZIP Coverage</h3>
              <p>
                Agents and loan officers check ZIP claim status, start Stripe checkout, and return
                to instantly refreshed coverage dashboards.
              </p>
            </article>
            <article>
              <h3>2. Add Listings & Programs</h3>
              <p>
                Agents upload listings with photos and open houses; loan officers publish loan
                programs tied to their coverage.
              </p>
            </article>
            <article>
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

        <section id="services" className="landing-section glass-card">
          <h2>Why Teams Choose GetaRebate</h2>
          <div className="feature-grid">
            <article>
              <IconGlyph name="home" filled />
              <h3>Buyer Discovery</h3>
              <p>ZIP-based search, open houses, and listing detail pages that highlight rebate potential.</p>
            </article>
            <article>
              <IconGlyph name="profile" filled />
              <h3>Agent ZIP Claims</h3>
              <p>Stripe-powered ZIP subscriptions with live claim status and instant coverage updates.</p>
            </article>
            <article>
              <IconGlyph name="billing" filled />
              <h3>Loan Officer Visibility</h3>
              <p>Market coverage, loan programs, and borrower checklists in one consistent view.</p>
            </article>
            <article>
              <IconGlyph name="messages" filled />
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
    </div>
  );
}
