import { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

export function useScrollToTop() {
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
  }, []);
}

export function useLandingScrollAnimations(containerRef) {
  const ctxRef = useRef(null);

  useEffect(() => {
    const container = containerRef?.current;
    if (!container) return;

    const els = container.querySelectorAll('.animate-on-scroll');
    if (!els.length) return;

    ctxRef.current = gsap.context(() => {
      els.forEach((el) => {
        gsap.fromTo(
          el,
          { opacity: 0, y: 32 },
          {
            opacity: 1,
            y: 0,
            duration: 0.65,
            ease: 'power3.out',
            scrollTrigger: {
              trigger: el,
              start: 'top 90%',
              once: true,
            },
          }
        );
      });
    }, container);

    return () => {
      ctxRef.current?.revert();
    };
  }, [containerRef]);
}
