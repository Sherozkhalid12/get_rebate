import { useState, useEffect, useCallback } from 'react';
import { IconGlyph } from '../ui/IconGlyph';

const AUTO_SLIDE_MS = 4500;

export function ReviewsCarousel({ reviews }) {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);

  const goTo = useCallback((index) => {
    setActiveIndex((i) => (index + reviews.length) % reviews.length);
  }, [reviews.length]);

  const next = useCallback(() => goTo(activeIndex + 1), [activeIndex, goTo]);

  useEffect(() => {
    if (!reviews?.length || isPaused) return;
    const id = setInterval(next, AUTO_SLIDE_MS);
    return () => clearInterval(id);
  }, [activeIndex, isPaused, next, reviews?.length]);

  if (!reviews?.length) return null;

  return (
    <div
      className="reviews-carousel"
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
    >
      <div className="reviews-carousel-track">
        {reviews.map((r, i) => (
          <article
            key={r.author + i}
            className={`review-card review-carousel-card ${i === activeIndex ? 'active' : ''}`}
            aria-hidden={i !== activeIndex}
          >
            <div className="review-stars">
              {Array.from({ length: r.rating }).map((_, j) => (
                <IconGlyph key={j} name="star" filled />
              ))}
            </div>
            <blockquote>{r.quote}</blockquote>
            <div className="review-author">
              <IconGlyph name="person" filled />
              <div>
                <strong>{r.author}</strong>
                {r.role && <span>{r.role}</span>}
              </div>
            </div>
          </article>
        ))}
      </div>
      <div className="reviews-carousel-dots">
        {reviews.map((_, i) => (
          <button
            key={i}
            type="button"
            className={`reviews-carousel-dot ${i === activeIndex ? 'active' : ''}`}
            aria-label={`Go to review ${i + 1}`}
            onClick={() => goTo(i)}
          />
        ))}
      </div>
    </div>
  );
}
