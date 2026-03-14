import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { onboardingSlides } from '../../data/mockData';

export function OnboardingPage() {
  const [index, setIndex] = useState(0);
  const slide = onboardingSlides[index];
  const navigate = useNavigate();

  return (
    <div className="auth-shell onboarding-bg">
      <div className="glass-card auth-card">
        <div className="slide-mark">0{index + 1} / 03</div>
        <h2>{slide.title}</h2>
        <p>{slide.description}</p>
        <div className="step-dots">
          {onboardingSlides.map((_, i) => <span key={i} className={i === index ? 'active' : ''} />)}
        </div>
        <div className="row">
          <button type="button" className="btn ghost" onClick={() => navigate('/auth')}>Skip</button>
          <button
            type="button"
            className="btn primary"
            onClick={() => (index === onboardingSlides.length - 1 ? navigate('/auth') : setIndex(index + 1))}
          >
            {index === onboardingSlides.length - 1 ? 'Get Started' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
}
