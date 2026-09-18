# GetaRebate admin API (extensions)

Mounts under `/api/v1/admin` (see `src/bootstrap.js`).

## Auth
All routes require Bearer JWT for a user with role `admin` or `mainadmin`.

## Endpoints
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/stats` | Verification stats |
| GET | `/users?userType=both\|agent\|loanofficer` | Paginated professionals |
| GET | `/account-holders` | All account holders |
| GET | `/recent-users` | Last 15 days |
| POST | `/verify` | Set verified true/false |
| PATCH | `/toggle-verification/:userId` | Toggle verified |
| GET | `/zip-coverage` | Loaded vs ~27k potential by state |
| GET | `/payments` | Subscription / revenue overview |
| GET | `/analytics` | Platform analytics |

Copy these files into the deployed backend (`src/admin/*`, `src/middleware/adminAuth.js`) and restart the API.
