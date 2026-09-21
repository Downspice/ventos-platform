# Ventos multi-repository layout

Split the current monorepo into **one repo per deployable app**, plus optional **shared** and **platform** repos. This keeps releases, CI, secrets, and access control independent while keeping a clear contract between clients and the API.

## Recommended repositories

| Repository | Source path today | Deployable | Notes |
|------------|-------------------|------------|--------|
| `ventos-backend` | `backend/` | API + GraphQL | Source of truth for schema; publish OpenAPI/GraphQL docs in CI optional |
| `ventos-web` | `frontend/web/` | Ventos Web (Vite) | Points at backend via `VITE_*` / env |
| `ventos-admin` | `frontend/admin/` | Admin hub | Same API contract as web |
| `ventos-pos-desktop` | `clients/pos_desktop/` | Flutter macOS/desktop | `--dart-define=VENTOS_API_URL=...` |
| `ventos-shared` | `shared/` | No (library/assets) | Avatar presets; sync script consumed by other repos |
| `ventos-platform` (optional) | root `docker-compose.yml`, `docs/`, dev scripts | No | Meta-repo for local full-stack dev only |

You do **not** need a monorepo remote after split. Use **ventos-platform** (or a short README in each repo) to document how to run the full stack locally.

## Best practices (all repos)

### Git and security

- **Never commit** `.env`, keys, or `backend/uploads/` / build artifacts.
- Ship **`.env.example`** (no secrets) and document every variable in the repo README.
- Default branch **`main`**, short-lived feature branches, PRs required for `main`.
- Use **Conventional Commits** (`feat:`, `fix:`, `chore:`) for readable history and changelogs.
- Enable **secret scanning** on the host (GitHub Advanced Security or equivalent).

### API contract (backend ↔ clients)

- **GraphQL schema lives only in `ventos-backend`.** Clients do not copy schema files long-term; they codegen from a running server or a published schema artifact in CI.
- Tag backend releases (e.g. `v0.2.0`) when breaking GraphQL changes ship; note minimum version in client READMEs.
- CORS / client URLs: configure `CLIENT_WEB_URL`, `CLIENT_ADMIN_URL` on the API; clients configure API URL in env.

### CI (each repo)

| Repo | Minimum CI |
|------|------------|
| backend | `npm ci` → `npm run lint` → `npm test` |
| web / admin | `npm ci` → `npm run lint` → `npm run build` |
| pos-desktop | `flutter pub get` → `flutter analyze` → `flutter test` |
| shared | Validate manifest / optional sync dry-run |

Store CI templates under `templates/github/workflows/` in this tree; the bootstrap script copies them into each new repo.

### Shared assets (avatars)

Today `scripts/sync-avatar-presets.sh` copies from `shared/avatar-presets/` into web, admin, and desktop.

After split:

1. **`ventos-shared`** holds `avatar-presets/` and `scripts/sync-to-consumers.sh` (paths passed as args or env).
2. Each client repo either runs sync in CI from a **pinned tag** of `ventos-shared`, or vendors copies on release branches.

### Local development (multi-repo)

1. Start MongoDB: from **ventos-platform** (or any clone): `docker compose up -d mongo`.
2. Run **ventos-backend** on `:4000`.
3. Run **ventos-web** / **ventos-admin** with API URL pointing at backend.
4. Run **ventos-pos-desktop** with `VENTOS_API_URL=http://127.0.0.1:4000/graphql`.

## Bootstrap standalone repos from this monorepo

From the monorepo root:

```bash
./scripts/bootstrap-repos.sh --output ../ventos-repos
```

Options:

- `--output DIR` — parent directory for new repo folders (default: `../ventos-repos`).
- `--init-git` — run `git init -b main` in each repo (does **not** create remotes or push).
- `--with-platform` — also create `ventos-platform` meta-repo with `docker-compose.yml` and clone helper.

Then create remotes (pick one host):

**GitHub (team / public-private org)**

```bash
cd ../ventos-repos/ventos-backend
gh repo create your-org/ventos-backend --private --source=. --remote=origin --push
```

Repeat per app, or create empty repos and `git remote add origin … && git push -u origin main`.

**Cursor-hosted**

Follow the [origin skill](https://cursor.com) / `origin repo create <name>` per repository after `--init-git`.

## Keeping monorepo vs split

| Approach | When |
|----------|------|
| Stay monorepo | Single team, single release train, heavy cross-app refactors |
| Multi-repo (this doc) | Separate deploy cadence, different access, clearer ownership |
| Meta + multi-repo | Best local DX: small platform repo + app repos |

This workspace can remain the **integration monorepo** for day-to-day work while you publish app repos from `bootstrap-repos.sh`, or you can move entirely to split clones once remotes exist.

## Checklist before first push

- [ ] `.env` not staged; `.env.example` updated
- [ ] `uploads/`, `node_modules/`, `dist/`, `build/`, `.dart_tool/` ignored
- [ ] README: install, env vars, how to point at API
- [ ] CI workflow present and green on `main`
- [ ] Backend: Supabase vars documented for production media storage
