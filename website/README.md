# GetaRebate Web (React + Vite)

Modern role-based frontend replicating Flutter app flow:

- Splash -> Onboarding -> Auth -> OTP -> role dashboard
- Buyer/Seller flow: Home, Favorites, Messages, Profile
- Agent flow: Dashboard, ZIP Codes, Listings, Stats, Billing, Leads
- Loan Officer flow: Dashboard, Messages, ZIP Codes, Billing, Checklists
- Shared routes: Notifications, Proposals, Lead Detail, Rebate Calculator, Forms, Checklists, Legal

## Run

```bash
cd website
npm install
npm run dev
```

## Key Files

- `src/App.jsx` route map and role guards
- `src/context/AuthContext.jsx` auth/session state
- `src/api/*` API layer (`auth`, `chat`, `notifications`)
- `src/lib/constants.ts` app palette, roles, route constants
- `src/components/layout/AppShell.jsx` responsive shell and navigation

