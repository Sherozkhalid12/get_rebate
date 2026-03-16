const glyphs = {
  search: 'search',
  shield: 'verified_user',
  calculator: 'calculate',
  home: 'home',
  heart: 'favorite',
  person: 'person',
  event: 'event',
  accountBalance: 'account_balance',
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
  darkMode: 'dark_mode',
  lightMode: 'light_mode',
  close: 'close',
  delete: 'delete',
  phone: 'phone',
  email: 'email',
  link: 'link',
  openInNew: 'open_in_new',
  edit: 'edit',
  logout: 'logout',
  menu: 'menu',
  document: 'description',
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
