import { useEffect, useRef, useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { gsap } from 'gsap';
import { useAuth } from '../../context/AuthContext';
import { ThemeToggle } from '../../components/ui/ThemeToggle';

const ROTATING_LINES = [
  'Verified rebates. Better closings.',
  'Buyers, agents, and lenders in one flow.',
  'Transparency from search to closing.',
  'Real savings. Real homes.',
];

const SPLASH_DURATION = 5;

export function LandingPage() {
  const navigate = useNavigate();
  const { isAuthenticated, role } = useAuth();
  const wrapRef = useRef(null);
  const logoImgRef = useRef(null);
  const logoRef = useRef(null);
  const logoGetaRef = useRef(null);
  const logoRebateRef = useRef(null);
  const descRef = useRef(null);
  const loadBarRef = useRef(null);
  const loadTextRef = useRef(null);
  const [lineIndex, setLineIndex] = useState(0);
  const [loadPercent, setLoadPercent] = useState(0);

  useEffect(() => {
    const t = setTimeout(() => navigate('/auth', { replace: true }), SPLASH_DURATION * 1000);
    return () => clearTimeout(t);
  }, [navigate]);

  useEffect(() => {
    const start = Date.now();
    const interval = setInterval(() => {
      const elapsed = (Date.now() - start) / 1000;
      const pct = Math.min(100, Math.round((elapsed / SPLASH_DURATION) * 100));
      setLoadPercent(pct);
    }, 50);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setLineIndex((i) => (i + 1) % ROTATING_LINES.length);
    }, 2200);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (!wrapRef.current) return;
    const ctx = gsap.context(() => {
      gsap.set(logoImgRef.current, { opacity: 0, scale: 0.8 });
      gsap.set(logoRef.current, { opacity: 0, y: 20 });
      gsap.set(logoGetaRef.current, { opacity: 0, x: -20 });
      gsap.set(logoRebateRef.current, { opacity: 0, x: 20 });
      gsap.set(descRef.current, { opacity: 0, y: 12 });
      gsap.set(loadBarRef.current, { scaleX: 0 });
      gsap.set(loadTextRef.current, { opacity: 0 });

      const tl = gsap.timeline({ defaults: { ease: 'power2.out' } });
      tl.to(logoImgRef.current, { opacity: 1, scale: 1, duration: 0.5 })
        .to(logoRef.current, { opacity: 1, y: 0, duration: 0.5 }, '-=0.3')
        .fromTo(logoGetaRef.current, { x: -20, opacity: 0 }, { x: 0, opacity: 1, duration: 0.4 }, '-=0.3')
        .fromTo(logoRebateRef.current, { x: 20, opacity: 0 }, { x: 0, opacity: 1, duration: 0.4 }, '-=0.4')
        .to(descRef.current, { opacity: 1, y: 0, duration: 0.35 }, '-=0.2')
        .to(loadTextRef.current, { opacity: 1, duration: 0.3 }, '-=0.1')
        .to(loadBarRef.current, { scaleX: 1, duration: SPLASH_DURATION - 1.2, ease: 'none' }, '-=0.2');
    }, wrapRef);
    return () => ctx.revert();
  }, []);

  useEffect(() => {
    if (!descRef.current) return;
    gsap.fromTo(descRef.current, { opacity: 0, y: 8 }, { opacity: 1, y: 0, duration: 0.4, ease: 'power2.out' });
  }, [lineIndex]);

  if (isAuthenticated) {
    if (role === 'agent') return <Navigate to="/agent" replace />;
    if (role === 'loanOfficer') return <Navigate to="/loan-officer" replace />;
    return <Navigate to="/app" replace />;
  }

  return (
    <div ref={wrapRef} className="landing-splash">
      <div className="landing-splash-theme">
        <ThemeToggle />
      </div>
      <div className="landing-splash-inner">
        <img
          ref={logoImgRef}
          src="/images/mainlogo.png"
          alt="GetaRebate"
          className="landing-splash-logo-img"
        />
        <h1 ref={logoRef} className="landing-splash-logo">
          <span ref={logoGetaRef} className="logo-geta">Geta</span>
          <span ref={logoRebateRef} className="logo-rebate">Rebate</span>
        </h1>
        <p ref={descRef} key={lineIndex} className="landing-splash-desc">
          {ROTATING_LINES[lineIndex]}
        </p>
      </div>
      <div className="landing-splash-load">
        <p ref={loadTextRef} className="landing-splash-load-label">
          Loading <span className="landing-splash-load-pct">{loadPercent}%</span>
        </p>
        <div className="landing-splash-load-track">
          <div ref={loadBarRef} className="landing-splash-load-bar" />
        </div>
      </div>
    </div>
  );
}
