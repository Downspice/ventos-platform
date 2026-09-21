# Deploy Ventos to Vercel (test + production)

Three **separate Vercel projects** (one per GitHub repo). Use Vercel’s **Preview** environment for **test/staging** and **Production** for live.

| Vercel project | GitHub repo | Root directory |
|----------------|-------------|----------------|
| `ventos-backend` | `Downspice/ventos-backend` | `/` (repo root) |
| `ventos-web` | `Downspice/ventos-web` | `/` |
| `ventos-admin` | `Downspice/ventos-admin` | `/` |

## Branch → environment

| Branch | Vercel environment | Purpose |
|--------|----------------------|---------|
| `main` | **Production** | Live |
| `staging` (recommended) or any PR branch | **Preview** | Test / QA |

In each project: **Settings → Git → Production Branch** = `main`. Push to `staging` (or open a PR) to get Preview URLs.

## 1. Backend (`ventos-backend`)

### Build settings

- **Framework preset:** Other  
- **Build command:** `npm run build`  
- **Output:** `public` (static placeholder; API is serverless)  
- **Install:** `npm ci`  

`vercel.json` already rewrites all routes to `/api`.

### Environment variables

Set in **Settings → Environment Variables**. Use **different values** for Preview vs Production.

| Variable | Production | Preview (test) |
|----------|------------|----------------|
| `NODE_ENV` | `production` | `production` |
| `MONGODB_URI` | Prod cluster URI | **Separate** test cluster URI |
| `JWT_SECRET` | Strong secret | Different test secret |
| `CLIENT_WEB_URL` | `https://<web-production-domain>` | `https://<web-preview-url>` or enable `CORS_ALLOW_VERCEL` |
| `CLIENT_ADMIN_URL` | `https://<admin-production-domain>` | Preview admin URL |
| `CORS_ALLOW_VERCEL` | `false` (if using fixed prod domains) | `true` |
| `SUPABASE_URL` | Prod project | Test project |
| `SUPABASE_SERVICE_ROLE_KEY` | Prod key | Test key |
| `SUPABASE_STORAGE_BUCKET` | `ventos` | e.g. `ventos-test` |
| `PUBLIC_API_URL` | `https://<backend-production-domain>` | Preview backend URL |
| `OAUTH_GOOGLE_CALLBACK_URL` | `https://<api>/auth/google/callback` | Preview API callback |
| `RESEND_API_KEY` | Prod (optional) | Test (optional) |

**Media on Vercel:** configure Supabase; local `uploads/` is disabled when `VERCEL` is set.

**GraphQL subscriptions (WebSocket):** not supported on this serverless deploy. HTTP GraphQL (queries/mutations) works; the web app already uses HTTP-only Apollo.

### Smoke test

```bash
curl https://<your-api>.vercel.app/health
curl -X POST https://<your-api>.vercel.app/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ __typename }"}'
```

## 2. Web (`ventos-web`)

| Variable | Production | Preview |
|----------|------------|---------|
| `VITE_API_URL` | `https://<backend-production>` (no `/graphql` suffix) | `https://<backend-preview>` |

Deploy; set custom domain on Production if desired.

## 3. Admin (`ventos-admin`)

Same as web:

| Variable | Production | Preview |
|----------|------------|---------|
| `VITE_API_URL` | Production backend URL | Preview backend URL |

## Recommended test vs prod topology

**Option A (simplest):** One Vercel project per app; Preview env vars point at a **preview backend** deployment; Production env vars point at **production backend**.

**Option B (stricter):** Six Vercel projects: `ventos-backend`, `ventos-backend-staging`, `ventos-web`, `ventos-web-staging`, etc., each with a single environment.

Option A is enough for most teams if MongoDB and Supabase are **separate for Preview vs Production**.

## OAuth on Vercel

Register both callback URLs in Google Cloud Console:

- `https://<prod-api>/auth/google/callback`
- `https://<preview-api>/auth/google/callback`

## CLI (optional)

```bash
npm i -g vercel
cd backend && vercel link
vercel env pull .env.local
vercel --prod   # production deploy
vercel          # preview deploy
```

Repeat for `frontend/web` and `frontend/admin`.

## After changing this monorepo

Re-run `./scripts/bootstrap-repos.sh` and push to GitHub so split repos stay in sync, or edit the GitHub repos directly and connect Vercel to them.
