export const APP_NAME = 'GetaRebate';

export const COLORS = {
  primaryBlue: '#2563EB',
  lightBlue: '#3B82F6',
  darkBlue: '#1D4ED8',
  lightGreen: '#10B981',
  white: '#FFFFFF',
  lightGray: '#F1F5F9',
  mediumGray: '#64748B',
  darkGray: '#334155',
  black: '#0F172A',
  skyBlue: '#0EA5E9',
  cyanBlue: '#06B6D4',
};

export const GRADIENTS = {
  primary: 'linear-gradient(135deg, #2563EB 0%, #3B82F6 45%, #0EA5E9 100%)',
  success: 'linear-gradient(135deg, #10B981 0%, #34D399 45%, #6EE7B7 100%)',
  surface: 'linear-gradient(135deg, #FFFFFF 0%, #F8FAFC 100%)',
  appBg: 'radial-gradient(circle at 0% 0%, rgba(59,130,246,.16) 0%, rgba(241,245,249,.3) 38%, #F8FAFC 100%)',
};

export const API_BASE_URL = 'https://api.getarebate.com/api/v1';

export const USER_ROLES = {
  BUYER_SELLER: 'buyerSeller',
  AGENT: 'agent',
  LOAN_OFFICER: 'loanOfficer',
} as const;

/** US states (rebate-allowed) for dropdowns - code and display name */
export const US_STATES = [
  { code: 'AZ', name: 'Arizona' },
  { code: 'AR', name: 'Arkansas' },
  { code: 'CA', name: 'California' },
  { code: 'CO', name: 'Colorado' },
  { code: 'CT', name: 'Connecticut' },
  { code: 'DC', name: 'District of Columbia' },
  { code: 'DE', name: 'Delaware' },
  { code: 'FL', name: 'Florida' },
  { code: 'GA', name: 'Georgia' },
  { code: 'HI', name: 'Hawaii' },
  { code: 'ID', name: 'Idaho' },
  { code: 'IL', name: 'Illinois' },
  { code: 'IN', name: 'Indiana' },
  { code: 'KY', name: 'Kentucky' },
  { code: 'ME', name: 'Maine' },
  { code: 'MD', name: 'Maryland' },
  { code: 'MA', name: 'Massachusetts' },
  { code: 'MI', name: 'Michigan' },
  { code: 'MN', name: 'Minnesota' },
  { code: 'MT', name: 'Montana' },
  { code: 'NE', name: 'Nebraska' },
  { code: 'NV', name: 'Nevada' },
  { code: 'NH', name: 'New Hampshire' },
  { code: 'NJ', name: 'New Jersey' },
  { code: 'NM', name: 'New Mexico' },
  { code: 'NY', name: 'New York' },
  { code: 'NC', name: 'North Carolina' },
  { code: 'ND', name: 'North Dakota' },
  { code: 'OH', name: 'Ohio' },
  { code: 'PA', name: 'Pennsylvania' },
  { code: 'RI', name: 'Rhode Island' },
  { code: 'SC', name: 'South Carolina' },
  { code: 'SD', name: 'South Dakota' },
  { code: 'TX', name: 'Texas' },
  { code: 'UT', name: 'Utah' },
  { code: 'VT', name: 'Vermont' },
  { code: 'VA', name: 'Virginia' },
  { code: 'WA', name: 'Washington' },
  { code: 'WV', name: 'West Virginia' },
  { code: 'WI', name: 'Wisconsin' },
  { code: 'WY', name: 'Wyoming' },
] as const;

export const ROUTES = {
  splash: '/splash',
  onboarding: '/onboarding',
  auth: '/auth',
  verifyOtp: '/verify-otp',
  forgotPassword: '/forgot-password',
  resetPassword: '/reset-password',

  buyerMain: '/app',
  buyerFavorites: '/app/favorites',
  buyerMessages: '/app/messages',
  buyerProfile: '/app/profile',

  agent: '/agent',
  loanOfficer: '/loan-officer',

  notifications: '/notifications',
  proposals: '/proposals',
  leadDetail: '/lead-detail',

  rebateCalculator: '/rebate-calculator',
  buyerLeadForm: '/buyer-lead-form',
  sellerLeadForm: '/seller-lead-form',
  listingDetail: '/listing-detail',
  addListing: '/add-listing',
  addLoan: '/add-loan',

  checklist: '/checklist',
  rebateChecklist: '/rebate-checklist',
  agentChecklist: '/agent-checklist',
  loanOfficerChecklist: '/loan-officer-checklist',

  privacyPolicy: '/privacy-policy',
  termsOfService: '/terms-of-service',
  aboutLegal: '/about-legal',
  helpSupport: '/help-support',
};
