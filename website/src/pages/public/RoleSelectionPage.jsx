import { useMemo, useRef, useState } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { FaqAccordion, PremiumLandingFooter, PremiumLandingFrame, PremiumLandingHeader } from '../../components/landing/PremiumLandingKit';
import { useAuth } from '../../context/AuthContext';
import { useScrollToTop, useLandingScrollAnimations } from '../../hooks/useLandingPage';
// import { ThemeToggle } from '../../components/ui/ThemeToggle';

function clampNumber(n, min, max) {
  if (!Number.isFinite(n)) return min;
  return Math.min(max, Math.max(min, n));
}

function formatCurrency(amount) {
  if (!Number.isFinite(amount)) return '$0';
  return amount.toLocaleString(undefined, { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
}

function parsePriceInput(raw) {
  const cleaned = String(raw ?? '').replace(/[^\d.]/g, '');
  const num = Number(cleaned);
  if (!Number.isFinite(num)) return 0;
  return num;
}

const REBATE_ALLOWED_STATES = [
  'Arizona',
  'Arkansas',
  'California',
  'Colorado',
  'Connecticut',
  'Delaware',
  'Florida',
  'Georgia',
  'Hawaii',
  'Idaho',
  'Illinois',
  'Indiana',
  'Kentucky',
  'Maine',
  'Maryland',
  'Massachusetts',
  'Michigan',
  'Minnesota',
  'Montana',
  'Nebraska',
  'Nevada',
  'New Hampshire',
  'New Jersey',
  'New Mexico',
  'New York',
  'North Carolina',
  'North Dakota',
  'Ohio',
  'Pennsylvania',
  'Rhode Island',
  'South Carolina',
  'South Dakota',
  'Texas',
  'Utah',
  'Vermont',
  'Virginia',
  'Washington',
  'West Virginia',
  'Wisconsin',
  'Wyoming',
  'District of Columbia',
];

const REBATE_RESTRICTED_STATES = [
  'Alabama',
  'Alaska',
  'Iowa',
  'Kansas',
  'Louisiana',
  'Mississippi',
  'Missouri',
  'Oklahoma',
  'Oregon',
  'Tennessee',
];

// Source: Flutter app tier rules in `lib/app/services/rebate_calculator_service.dart`
const REBATE_TIERS = [
  { tier: 1, minCommissionPct: 0.04, maxCommissionPct: null, commissionRange: '4.0% or more', rebateSharePct: 0.40, rebateShare: '40%' },
  { tier: 2, minCommissionPct: 0.0301, maxCommissionPct: 0.0399, commissionRange: '3.01% – 3.99%', rebateSharePct: 0.35, rebateShare: '35%' },
  { tier: 3, minCommissionPct: 0.025, maxCommissionPct: 0.03, commissionRange: '2.50% – 3.00%', rebateSharePct: 0.30, rebateShare: '30%' },
  { tier: 4, minCommissionPct: 0.02, maxCommissionPct: 0.0249, commissionRange: '2.00% – 2.49%', rebateSharePct: 0.25, rebateShare: '25%' },
  { tier: 5, minCommissionPct: 0.015, maxCommissionPct: 0.0199, commissionRange: '1.50% – 1.99%', rebateSharePct: 0.20, rebateShare: '20%' },
  { tier: 6, minCommissionPct: 0.0025, maxCommissionPct: 0.0149, commissionRange: '0.25% – 1.49%', rebateSharePct: 0.10, rebateShare: '10%' },
  { tier: 7, minCommissionPct: 0.0, maxCommissionPct: 0.0024, commissionRange: '0% – 0.24%', rebateSharePct: 0.00, rebateShare: '0%' },
];

const FAQS = [
  {
    q: 'What states allow real estate rebates?',
    a: `These 40 states allow real estate rebates and are included on our site/app: ${REBATE_ALLOWED_STATES.join(', ')}.`,
    icon: 'search',
  },
  {
    q: 'What states ban or restrict real estate rebates?',
    a: `These 10 states ban or restrict rebates so are not included on our site/app: ${REBATE_RESTRICTED_STATES.join(', ')}.`,
    icon: 'info',
  },
  {
    q: 'How are rebates calculated?',
    a: 'Rebates are based on the purchase price and the agent’s commission. All agents on our site offer the same rebate percentage, and our calculators show the exact amount—no guessing.',
    icon: 'calculator',
  },
  {
    q: 'Do all real estate agents on this site/app offer rebates to buyers and sellers?',
    a: 'Yes. Agents who sign up on our site and app have agreed to pay the same rebate, which is based on the amount of commission. The higher the commission, the higher the rebate.',
    icon: 'verified',
  },
  {
    q: 'Do all loan officers/lenders on this site/app allow real estate rebates as part of the mortgage process?',
    a: 'Yes, all loan officers who have signed up on our site and app have confirmed that their lender allows real estate rebates as part of the mortgage process. If you are not using a loan officer from our site or app, then you would have to confirm that they allow rebates.',
    icon: 'businessCenter',
  },
  {
    q: 'Does Get a Rebate Real Estate represent me?',
    a: 'No. GetaRebate connects you with participating agents, but the agent you choose should represent you when you sign a contract with them.',
    icon: 'handshake',
  },
  {
    q: 'Is Get a Rebate Real Estate a licensed real estate broker?',
    a: 'Yes, Get a Rebate Real Estate is a licensed real estate broker, in the state of Minnesota. We created this site/app to bring rebates to all buyers and sellers in all 40 states that allow rebates.',
    icon: 'verified',
  },
  {
    q: 'Is GetaRebate available in my area?',
    a: 'We are continuously working on getting agents and loan officers to sign up. Once we have a sufficient number signed up to provide service to you, we will begin to advertise that area. For now, create an account to see how many agents and loan officers are signed up in your area.',
    icon: 'location',
  },
  {
    q: 'Are real estate rebates legal?',
    a: 'Yes, rebates are legal in states that allow them, subject to local rules and lender policies.',
    icon: 'shield',
  },
  {
    q: 'Can I get a rebate when I build new construction?',
    a: 'Yes. Most builders have a built in commission to pay the agent that brings in the buyer, the rebate would come from that commission. Restrictions apply and you most likely have to have your agent with you on your first visit with the builder, or at least be able to say who your agent is, so find an agent on our site before visiting the builder. Some builders do ban or restrict rebates, even in states that allow them. But that is rare.',
    icon: 'homeWork',
  },
  {
    q: 'I am a Buyer or Seller, how do I sign up?',
    a: 'Signing up is fast, easy, and free. Create an account as a Buyer/Seller, confirm your email, and log in. Enter a zip code—if you’re selling, use your home’s zip code; if buying or building, use a nearby area. You’ll instantly see agents, loan officers, homes for sale, and open houses in that area.',
    icon: 'person',
  },
  {
    q: 'I am a Real Estate Agent, how do I sign up?',
    a: null,
    icon: 'verified',
  },
  {
    q: 'I am a Mortgage Loan Officer, how do I sign up?',
    a: 'Create an account as a Loan Officer, confirm your email, and log in. Search and select the zip codes you serve. To receive leads, you must subscribe to at least one zip code. There is a small monthly fee per zip code based on population. You may subscribe to up to 6 zip codes. We allow one loan officer per zip code—first come, first served. If a zip code is taken, you can join the waiting list or choose a nearby area. Once subscribed, you’re instantly live. While loan officers do not offer rebates, you can promote discounts and offers directly on your profile.',
    icon: 'businessCenter',
  },
];

function AppStoreBadgeLinks() {
  return (
    <>
      <a className="lp2-store-badge" href="#" aria-disabled="true">
        <img src="/images/badges/app-store.svg" alt="Download on the App Store" />
      </a>
      <a className="lp2-store-badge" href="#" aria-disabled="true">
        <img src="/images/badges/google-play.svg" alt="Get it on Google Play" />
      </a>
    </>
  );
}

export function RoleSelectionPage() {
  const { isAuthenticated, role } = useAuth();
  const containerRef = useRef(null);
  const [purchasePriceRaw, setPurchasePriceRaw] = useState('');
  const [tiersOpen, setTiersOpen] = useState(false);
  const [statesOpen, setStatesOpen] = useState(false);

  useScrollToTop();
  useLandingScrollAnimations(containerRef);

  if (isAuthenticated) {
    if (role === 'agent') return <Navigate to="/agent" replace />;
    if (role === 'loanOfficer') return <Navigate to="/loan-officer" replace />;
    return <Navigate to="/app" replace />;
  }

  const purchasePrice = useMemo(() => {
    const parsed = parsePriceInput(purchasePriceRaw);
    return clampNumber(parsed, 0, 50_000_000);
  }, [purchasePriceRaw]);

  const tierEstimates = useMemo(() => {
    if (!purchasePrice) return [];
    return REBATE_TIERS.map((t) => {
      const min = Math.round(purchasePrice * t.minCommissionPct * t.rebateSharePct);
      const max =
        t.maxCommissionPct == null
          ? null
          : Math.round(purchasePrice * t.maxCommissionPct * t.rebateSharePct);
      return {
        tier: t.tier,
        commissionRange: t.commissionRange,
        rebateShare: t.rebateShare,
        minAmount: min,
        maxAmount: max,
      };
    });
  }, [purchasePrice]);

  const faqsWithAgentSignup = useMemo(() => {
    return FAQS.map((f) => {
      if (f.q !== 'I am a Real Estate Agent, how do I sign up?') return f;
      return {
        ...f,
        a: (
          <div className="lp2-faq-rich">
            <p>
              Create an account as an Agent, confirm your email, and log in. Search and select the zip codes you serve. To receive leads and access
              features like listings and open houses, you must subscribe to a zip code.
            </p>
            <p>
              There is a small monthly fee per zip code based on population (larger areas = more leads). You may subscribe to up to 6 zip codes.
              We allow one agent per zip code—first come, first served. If a zip code is taken, you can join the waiting list or choose a nearby area.
            </p>
            <p>
              Once subscribed, you’re instantly live. All agents agree to offer rebates based on commission using our 7-tier structure.{' '}
              <button type="button" className="btn link" onClick={() => setTiersOpen(true)}>
                View the 7 tiers
              </button>
              .
            </p>
          </div>
        ),
      };
    });
  }, []);

  return (
    <PremiumLandingFrame containerRef={containerRef} className="lp2-role">
      {tiersOpen && (
        <div
          className="lp2-modal-overlay"
          role="dialog"
          aria-modal="true"
          aria-label="7-tier rebate structure"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) setTiersOpen(false);
          }}
        >
          <div className="lp2-modal glass-card">
            <div className="lp2-modal-head">
              <strong>7-tier structure</strong>
              <button type="button" className="btn ghost tiny" onClick={() => setTiersOpen(false)}>
                Close
              </button>
            </div>
            <p className="lp2-modal-sub">
              Tiers are based on the agent commission percentage. Rebate is a share of that commission.
            </p>
            <div className="lp2-tier-grid" role="table" aria-label="Rebate tiers">
              <div className="lp2-tier-row lp2-tier-row--head" role="row">
                <span role="columnheader">Tier</span>
                <span role="columnheader">Commission range</span>
                <span role="columnheader">Rebate share</span>
              </div>
              {REBATE_TIERS.map((t) => (
                <div key={t.tier} className="lp2-tier-row" role="row">
                  <span role="cell">{t.tier}</span>
                  <span role="cell">{t.commissionRange}</span>
                  <span role="cell">{t.rebateShare}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {statesOpen && (
        <div
          className="lp2-modal-overlay"
          role="dialog"
          aria-modal="true"
          aria-label="States that allow rebates"
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) setStatesOpen(false);
          }}
        >
          <div className="lp2-modal glass-card">
            <div className="lp2-modal-head">
              <strong>Rebate availability by state</strong>
              <button type="button" className="btn ghost tiny" onClick={() => setStatesOpen(false)}>
                Close
              </button>
            </div>
            <p className="lp2-modal-sub">
              We include the states that allow real estate rebates on our site/app. Some states ban or restrict rebates. Lender and broker rules may
              also apply.
            </p>

            <div className="lp2-tier-grid" style={{ marginTop: '0.85rem' }}>
              <div className="lp2-tier-row lp2-tier-row--head" role="row">
                <span role="columnheader">Allowed</span>
                <span role="columnheader">States (plus DC)</span>
                <span role="columnheader">Count</span>
              </div>
              <div className="lp2-tier-row" role="row">
                <span role="cell">Yes</span>
                <span role="cell">{REBATE_ALLOWED_STATES.join(', ')}</span>
                <span role="cell">{REBATE_ALLOWED_STATES.filter((s) => s !== 'District of Columbia').length}</span>
              </div>
            </div>

            <div className="lp2-tier-grid" style={{ marginTop: '0.85rem' }}>
              <div className="lp2-tier-row lp2-tier-row--head" role="row">
                <span role="columnheader">Restricted States</span>
                <span role="columnheader"></span>
                <span role="columnheader">Count</span>
                {/* <span role="columnheader">Count</span> */}
              </div>
              <div className="lp2-tier-row" role="row">
                <span role="cell">No</span>
                <span role="cell">{REBATE_RESTRICTED_STATES.join(', ')}</span>
                <span role="cell">{REBATE_RESTRICTED_STATES.length}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      <PremiumLandingHeader
        links={[
          { href: '#roles', label: 'Roles' },
          { href: '#how', label: 'How it works' },
          { href: '#app', label: 'App' },
          { href: '#faqs', label: 'FAQs' },
        ]}
        actions={(
          <>
            <Link className="btn ghost tiny" to="/onboarding">Platform Tour</Link>
            <Link className="btn ghost tiny" to="/auth?mode=signup">Create account</Link>
            <Link className="btn primary tiny" to="/auth">Log in</Link>
          </>
        )}
        // rightSlot={<ThemeToggle />}
      />

      <aside className="lp2-app-teaser lp2-surface" aria-label="GetaRebate mobile app">
        <span className="lp2-app-teaser-icon" aria-hidden="true">
          <IconGlyph name="smartphone" filled />
        </span>
        <p className="lp2-app-teaser-text">
          <strong>Get the free app.</strong> Search by ZIP, browse listings and open houses, and follow your rebate — same login as the website.
        </p>
        <div className="lp2-app-teaser-badges">
          <AppStoreBadgeLinks />
        </div>
        <a className="lp2-app-teaser-more" href="#app">
          App details
        </a>
      </aside>

      <section className="lp2-hero lp2-surface lp2-hero--home">
        <div className="lp2-hero-card">
            <div className="lp2-hero-card-head lp2-hero-card-head--row">
              <div className="lp2-hero-card-head-text">
                <strong>How much rebate could you get?</strong>
                <span>Enter your estimated home price to preview all 7 tiers.</span>
              </div>
              {purchasePrice ? (
                <button
                  type="button"
                  className="lp2-hero-card-close"
                  onClick={() => setPurchasePriceRaw('')}
                  aria-label="Clear price and hide tier breakdown"
                  title="Clear estimate"
                >
                  <IconGlyph name="close" />
                </button>
              ) : null}
            </div>

          <div className="hero-search hero-search--single" role="search" aria-label="Rebate estimator">
            <IconGlyph name="calculator" filled />
            <div className="hero-calc-fields">
              <label className="hero-calc-field">
                <input
                  inputMode="decimal"
                  autoComplete="off"
                  placeholder="e.g. 450,000"
                  value={purchasePriceRaw}
                  onChange={(e) => setPurchasePriceRaw(e.target.value)}
                  aria-label="Purchase price"
                />
              </label>
            </div>
          </div>

          <div className="hero-rebate-results" aria-live="polite">
            {!purchasePrice ? (
              <div className="hero-rebate-empty">
                <strong>Rebates are allowed in 40 states.</strong>{' '}
                <button type="button" className="btn link" onClick={() => setStatesOpen(true)}>
                  See the list
                </button>
              </div>
            ) : (
              <div className="hero-tier-table" role="table" aria-label="Tier estimates">
                <div className="hero-tier-row hero-tier-row--head" role="row">
                  <span role="columnheader">Tier</span>
                  <span role="columnheader">Commission range</span>
                  <span role="columnheader">Rebate share</span>
                  <span role="columnheader">Estimated rebate</span>
                </div>
                {tierEstimates.map((t) => (
                  <div key={t.tier} className="hero-tier-row" role="row">
                    <span role="cell">{t.tier}</span>
                    <span role="cell">{t.commissionRange}</span>
                    <span role="cell">{t.rebateShare}</span>
                    <span role="cell">
                      {t.maxAmount == null
                        ? `${formatCurrency(t.minAmount)} or more`
                        : `${formatCurrency(t.minAmount)} – ${formatCurrency(t.maxAmount)}`}
                    </span>
                  </div>
                ))}
              </div>
            )}
            <div className="hero-rebate-help">
              <IconGlyph name="info" filled />
              <span>
                Want help? Jump to <a href="#faqs">FAQs</a> or <Link to="/help-support">contact support</Link>.
              </span>
            </div>
          </div>
        </div>
      </section>

      <main className="lp2-main">
        <section id="roles" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Choose Your Role</h2>
            <p>Pick the experience that matches you. You can switch roles anytime.</p>
          </div>

          <div className="lp2-role-tiles">
            <article className="lp2-role-tile lp2-role-tile--buyer">
              <div className="lp2-role-tile-head">
                <span className="lp2-role-tile-icon">
                  <img src="/images/buyer-seller.PNG" alt="" />
                </span>
                <div>
                  <h3>Buyer & Seller</h3>
                  <p>If you are looking to Buy, Build or Sell</p>
                </div>
              </div>
              <div className="lp2-role-tile-auth lp2-cta-auth-row">
                <Link className="btn primary" to="/auth">Log in</Link>
                <Link className="btn ghost" to="/auth?mode=signup">Create account</Link>
              </div>
              <p className="lp2-role-tile-sub"><strong>Getting Started is Easy</strong></p>
              <ul className="lp2-bullets">
                <li>Create a free account — it takes less than a minute</li>
                <li>Verify your email, and log in</li>
                <li>Search by zip code to find local agents offering buyer and seller rebates</li>
                <li>View agent profiles instantly and compare your options</li>
                <li>Browse homes for sale with estimated rebates on each listing</li>
                <li>Explore open houses in your area</li>
                <li>Connect with loan officers whose lenders allow rebates</li>
              </ul>
              <div className="lp2-role-tile-more">
                <Link className="btn ghost" to="/landing/buyer">More Buyer/Seller info</Link>
              </div>
            </article>

            <article className="lp2-role-tile lp2-role-tile--agent">
              <div className="lp2-role-tile-head">
                <span className="lp2-role-tile-icon">
                  <img src="/images/agent.PNG" alt="" />
                </span>
                <div>
                  <h3>Real Estate Agent</h3>
                  <p>Get started and grow your business with ZIP code subscriptions.</p>
                </div>
              </div>
              <div className="lp2-role-tile-auth lp2-cta-auth-row">
                <Link className="btn primary" to="/auth?role=agent">Log in</Link>
                <Link className="btn ghost" to="/auth?role=agent&mode=signup">Create account</Link>
              </div>
              <div className="lp2-callout">
                <strong>Only One Agent Per Zip Code.</strong> Secure Yours Today Before It’s Taken. <strong>First Come First Served.</strong>
              </div>
              <ul className="lp2-bullets">
                <li>Create your account in just 3–5 minutes (set up your profile during signup)</li>
                <li>Verify your email, and log in</li>
                <li>Subscribe to up to 6 zip codes you want to serve</li>
                <li>Start connecting with local buyers and sellers in and around those zip codes</li>
              </ul>
              <div className="lp2-role-tile-more">
                <Link className="btn ghost" to="/landing/agent">More Agent info</Link>
              </div>
            </article>

            <article className="lp2-role-tile lp2-role-tile--loan">
              <div className="lp2-role-tile-head">
                <span className="lp2-role-tile-icon">
                  <img src="/images/loan.PNG" alt="" />
                </span>
                <div>
                  <h3>Mortgage Loan Officer</h3>
                  <p>Claim ZIP coverage and stay compliant with rebate-friendly lending requirements.</p>
                </div>
              </div>
              <div className="lp2-role-tile-auth lp2-cta-auth-row">
                <Link className="btn primary" to="/auth?role=loanOfficer">Log in</Link>
                <Link className="btn ghost" to="/auth?role=loanOfficer&mode=signup">Create account</Link>
              </div>
              <div className="lp2-callout">
                <strong>Only One Loan Officer Per Zip Code.</strong> Secure Yours Today Before It’s Taken. <strong>First Come First Served.</strong>
              </div>
              <ul className="lp2-bullets">
                <li>Create your account in just 3–5 minutes (set up your profile during signup)</li>
                <li>Verify your email and log in</li>
                <li>Claim your zip codes by subscribing to up to 6 areas you serve</li>
                <li>Start responding to local buyers looking to buy or build in and around those zip codes</li>
              </ul>
              <div className="lp2-role-tile-more">
                <Link className="btn ghost" to="/landing/loan-officer">More Loan Officer info</Link>
              </div>
            </article>
          </div>
        </section>

        <section id="buyers" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>What Is a Rebate and Why Do I Want One?</h2>
            <p>
              A real estate commission rebate is a portion of the commission that is credited back to the buyer or seller at closing,
              or reflected as a reduced commission on the listing side. In simple terms, it means you keep more of the money that would
              normally go to a real estate commission.
            </p>
          </div>
          <div className="lp2-grid lp2-grid--2wide lp2-rebate-subgrid">
            <article className="lp2-media-feature lp2-subsection-card">
              <div className="lp2-media-feature-body">
                <span className="lp2-feature-icon lp2-subsection-icon" aria-hidden="true"><IconGlyph name="homeWork" filled /></span>
                <h3>If you are looking to Buy, Build or Sell</h3>
                <p><strong>Getting Started is Easy</strong></p>
                <ul className="lp2-bullets">
                  <li>Create a free account — it takes less than a minute</li>
                  <li>Verify your email, and log in</li>
                  <li>Search by zip code to find local agents offering buyer and seller rebates</li>
                  <li>View agent profiles instantly and compare your options</li>
                  <li>Browse homes for sale with estimated rebates on each listing</li>
                  <li>Explore open houses in your area</li>
                  <li>Connect with loan officers whose lenders allow rebates</li>
                </ul>
              </div>
            </article>

            <article className="lp2-media-feature lp2-subsection-card">
              <div className="lp2-media-feature-body">
                <span className="lp2-feature-icon lp2-subsection-icon" aria-hidden="true"><IconGlyph name="savings" filled /></span>
                <h3>Why Use Our Platform</h3>
                <ul className="lp2-bullets">
                  <li>No cost. No obligation.</li>
                  <li>Contact local agents and lenders directly, anytime</li>
                  <li>Work only with professionals who offer you savings</li>
                </ul>
                <div className="lp2-cta lp2-cta-auth-stack">
                  <div className="lp2-cta-auth-row">
                    <Link className="btn primary" to="/auth">Log in</Link>
                    <Link className="btn ghost" to="/auth?mode=signup">Create account</Link>
                  </div>
                  <div className="lp2-cta-more-row">
                    <Link className="btn ghost" to="/landing/buyer">More Buyer/Seller info</Link>
                  </div>
                </div>
              </div>
            </article>
          </div>
        </section>

        <section className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2 id="agents">If you are a Real Estate Agent</h2>
            <p>Get started and grow your business with ZIP code subscriptions.</p>
          </div>
          <div className="lp2-grid lp2-grid--2wide">
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="verified" filled /></span>
              <h3>Get Started</h3>
              <div className="lp2-callout">
                <strong>Only One Agent Per Zip Code.</strong> Secure Yours Today Before It’s Taken. <strong>First Come First Served.</strong>
              </div>
              <ul className="lp2-bullets">
                <li>Create your account in just 3–5 minutes (set up your profile during signup)</li>
                <li>Verify your email, and log in</li>
                <li>Subscribe to up to 6 zip codes you want to serve</li>
                <li>Start connecting with local buyers and sellers in and around those zip codes</li>
              </ul>
              <div className="lp2-cta lp2-cta-auth-stack">
                <div className="lp2-cta-auth-row">
                  <Link className="btn primary" to="/auth?role=agent">Log in</Link>
                  <Link className="btn ghost" to="/auth?role=agent&mode=signup">Create account</Link>
                </div>
                <div className="lp2-cta-more-row">
                  <Link className="btn ghost" to="/landing/agent">More Agent info</Link>
                </div>
              </div>
            </article>

            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="listings" filled /></span>
              <h3>How It Works</h3>
              <ul className="lp2-bullets">
                <li>Monthly subscription is based on zip code population (higher population = more potential leads)</li>
                <li>By subscribing, you agree to offer a rebate based on the commission you receive</li>
                <li>Close unlimited deals with no referral fees, no contracts, and cancel anytime with 30 days’ notice</li>
              </ul>
              <p><strong>Platform Features</strong></p>
              <ul className="lp2-bullets">
                <li>List up to 3 homes per zip code, at no additional cost</li>
                <li>Showcase estimated rebates and open houses</li>
                <li>Display dual agency rebate options (where permitted)</li>
                <li>Get connected directly with active buyers and sellers in your area</li>
              </ul>
            </article>
          </div>
        </section>

        <section id="loan-officers" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>If you are a Mortgage Loan Officer</h2>
            <p>Claim ZIP coverage and stay compliant with rebate-friendly lending requirements.</p>
          </div>
          <div className="lp2-grid lp2-grid--2wide">
            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="businessCenter" filled /></span>
              <h3>Zip Code Subscription</h3>
              <div className="lp2-callout">
                <strong>Only One Loan Officer Per Zip Code.</strong> Secure Yours Today Before It’s Taken. <strong>First Come First Served.</strong>
              </div>
              <ul className="lp2-bullets">
                <li>Monthly fee is based on zip code population (higher population = more potential leads)</li>
                <li>By subscribing, you confirm your lender allows real estate rebates</li>
                <li>Loan officers do not provide rebates but may offer discounted services if permitted</li>
                <li>Close unlimited transactions with no additional costs, no contracts, and no referral fees</li>
                <li>Cancel anytime with 30 days’ notice</li>
              </ul>
              <div className="lp2-cta lp2-cta-auth-stack">
                <div className="lp2-cta-auth-row">
                  <Link className="btn primary" to="/auth?role=loanOfficer">Log in</Link>
                  <Link className="btn ghost" to="/auth?role=loanOfficer&mode=signup">Create account</Link>
                </div>
                <div className="lp2-cta-more-row">
                  <Link className="btn ghost" to="/landing/loan-officer">More Loan Officer info</Link>
                </div>
              </div>
            </article>

            <article className="lp2-feature">
              <span className="lp2-feature-icon"><IconGlyph name="checklist" filled /></span>
              <h3>Compliance & Transparency</h3>
              <ul className="lp2-bullets">
                <li>Access a compliance checklist for rebate rules and regulations</li>
                <li>Agents and buyers agree to follow lender requirements for rebate eligibility</li>
                <li>Rebates are typically applied as a credit on the settlement statement, subject to lender limits</li>
                <li>Staying compliant ensures smooth processing and avoids lender issues</li>
              </ul>
            </article>
          </div>
        </section>

        <section id="how" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>How It Works (Simple & Transparent)</h2>
            <p>Three simple steps from sign-up to rebate credit at closing.</p>
          </div>
          <div className="lp2-grid lp2-grid--3">
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="person" filled /></span>
              <h3>Step 1: Create a Free Account</h3>
              <p>Sign up in minutes and search by zip code to find participating real estate professionals.</p>
            </article>
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="search" filled /></span>
              <h3>Step 2: Connect</h3>
              <p>View profiles, compare options, and contact professionals directly—no obligation or referral fees.</p>
            </article>
            <article className="lp2-step">
              <span className="lp2-step-icon"><IconGlyph name="savings" filled /></span>
              <h3>Step 3: Receive Your Rebate</h3>
              <p>When your transaction closes, your rebate is applied as a credit at closing or reflected in reduced commission savings.</p>
            </article>
          </div>
        </section>

        <section id="faqs" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>FAQs</h2>
            <p>Quick answers about rebates, coverage, and how the platform works.</p>
          </div>
          <FaqAccordion items={faqsWithAgentSignup} />
        </section>

        <section className="lp2-cta-band lp2-surface animate-on-scroll">
          <div>
            <h2>Ready to Get Started?</h2>
            <p>Log in and pick your role to see live data: coverage, listings, leads, and rebate journeys.</p>
          </div>
          <div className="lp2-cta-row lp2-cta-auth-stack">
            <div className="lp2-cta-auth-row">
              <Link className="btn primary" to="/auth">Log in</Link>
              <Link className="btn ghost" to="/auth?mode=signup">Create account</Link>
            </div>
            <div className="lp2-cta-more-row">
              <Link className="btn ghost" to="/onboarding">See full platform tour</Link>
            </div>
          </div>
        </section>

        <section id="app" className="lp2-section lp2-surface animate-on-scroll">
          <div className="lp2-section-head">
            <h2>Get the App</h2>
            <p>Download the GetaRebate app to search by ZIP, compare professionals, and track your rebate journey on the go.</p>
          </div>
          <div className="lp2-app-band">
            <div className="lp2-app-copy">
              <ul className="lp2-bullets">
                <li>Search agents and loan officers by ZIP</li>
                <li>See rebate estimates early</li>
                <li>Favorites, messages, proposals, and checklists</li>
              </ul>
              <div className="lp2-cta">
                <AppStoreBadgeLinks />
              </div>
              {/* <p className="lp2-app-note">We’ll link these buttons to your real store pages when your app listings are ready.</p> */}
            </div>
            <div className="lp2-app-media" aria-hidden="true">
              <img src="/images/appbarlogo.png" alt="" />
              <div className="lp2-app-media-glow" />
            </div>
          </div>
        </section>

        <PremiumLandingFooter />
      </main>
    </PremiumLandingFrame>
  );
}
