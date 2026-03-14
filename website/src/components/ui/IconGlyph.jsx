const glyphs = {
  search: 'search',
  shield: 'verified_user',
  calculator: 'calculate',
  home: 'home',
  heart: 'favorite',
  messages: 'chat_bubble',
  profile: 'account_circle',
  dashboard: 'space_dashboard',
  location: 'pin_drop',
  myLocation: 'my_location',
  listings: 'real_estate_agent',
  stats: 'query_stats',
  billing: 'payments',
  leads: 'person_search',
  checklist: 'checklist',
  bell: 'notifications',
  lightbulb: 'lightbulb',
  assignment: 'assignment',
  star: 'star',
  info: 'info',
  checkCircle: 'check_circle',
};

export function IconGlyph({ name, filled = false }) {
  return (
    <span
      aria-hidden="true"
      className={`icon-glyph material-symbols-rounded ${filled ? 'filled' : ''}`}
    >
      {glyphs[name] || 'radio_button_unchecked'}
    </span>
  );
}
