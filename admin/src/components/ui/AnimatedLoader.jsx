import { useEffect, useRef } from 'react';
import { gsap } from 'gsap';

/**
 * Animated loader with GSAP. Use throughout the app where loading occurs.
 * @param {string} variant - 'inline' | 'card' | 'full' | 'button'
 * @param {string} label - Optional text below loader
 */
export function AnimatedLoader({ variant = 'card', label = 'Loading...' }) {
  const containerRef = useRef(null);
  const dot1Ref = useRef(null);
  const dot2Ref = useRef(null);
  const dot3Ref = useRef(null);
  const ringRef = useRef(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      const dots = [dot1Ref.current, dot2Ref.current, dot3Ref.current].filter(Boolean);
      if (dots.length === 0) return;

      // Bouncing dots - stagger Y movement
      gsap.to(dot1Ref.current, {
        y: -12,
        duration: 0.4,
        ease: 'power2.out',
        repeat: -1,
        yoyo: true,
      });
      gsap.to(dot2Ref.current, {
        y: -12,
        duration: 0.4,
        ease: 'power2.out',
        repeat: -1,
        yoyo: true,
        delay: 0.1,
      });
      gsap.to(dot3Ref.current, {
        y: -12,
        duration: 0.4,
        ease: 'power2.out',
        repeat: -1,
        yoyo: true,
        delay: 0.2,
      });

      // Scale pulse on dots
      gsap.to(dots, {
        scale: 1.3,
        duration: 0.35,
        stagger: 0.1,
        ease: 'power2.inOut',
        repeat: -1,
        yoyo: true,
      });

      // Rotating ring
      if (ringRef.current) {
        gsap.to(ringRef.current, {
          rotation: 360,
          duration: 1.8,
          ease: 'none',
          repeat: -1,
        });
      }

    }, containerRef);

    return () => ctx.revert();
  }, []);

  const sizeClasses = {
    inline: 'loader-inline',
    card: 'loader-card',
    full: 'loader-full',
    button: 'loader-button',
  };

  return (
    <div className={`animated-loader ${sizeClasses[variant]}`} ref={containerRef} role="status" aria-label={label}>
      <div className="loader-visual">
        <svg className="loader-ring" viewBox="0 0 100 100" ref={ringRef}>
          <circle className="loader-ring-track" cx="50" cy="50" r="42" fill="none" strokeWidth="4" />
          <circle
            className="loader-ring-arc"
            cx="50"
            cy="50"
            r="42"
            fill="none"
            strokeWidth="4"
            strokeDasharray="66 198"
            strokeLinecap="round"
          />
        </svg>
        <div className="loader-dots">
          <div className="loader-dot" ref={dot1Ref} />
          <div className="loader-dot" ref={dot2Ref} />
          <div className="loader-dot" ref={dot3Ref} />
        </div>
      </div>
      {label ? <span className="loader-label">{label}</span> : null}
    </div>
  );
}
