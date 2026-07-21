[English](README.md) | [中文](README.zh-CN.md)

# MuseFlow

Product, part, and process document control for manufacturing engineering
teams. MuseFlow is a self-hosted, single-tenant PLM: it manages CAD drawing
versions, parts, process documents, and BOM releases behind an engineering
approval workflow — one company's data, on infrastructure you control.

It is not a multi-tenant SaaS. Every logged-in user sees the same company's
drawings; there is no tenant-level data isolation, by design (see
[Terminology & scope](#terminology--scope) below).

> 📷 Screenshot placeholder — see below

<!-- Replace this block with: ![MuseFlow products list](docs/screenshots/products.png).
     Capture it by logging in as admin/password123 and opening the products list. -->

## Quick start

Prerequisites: Ruby 4.0.1, PostgreSQL, and Redis, all running locally.

```bash
bundle install
bin/rails db:setup   # creates the database, loads the schema, and seeds demo data
bin/rails server
```

Then open **http://localhost:3000** — you'll land on the marketing page; sign
in with one of the [demo accounts](#registration--demo-accounts) below to
reach the app.

If your local PostgreSQL needs credentials other than `postgres`/no password,
copy `.env.example` to `.env` and fill in `DB_USERNAME` / `DB_PASSWORD` /
`DB_HOST` before running `db:setup`.

## What it manages

MuseFlow is organized around four business lines. The demo seed data
(`bin/rails db:setup`) gives you one working sample of each:

| Business line | What it is |
|---|---|
| **Product** | A top-level manufactured assembly. |
| **Part** | A component or sub-assembly, nested under a product or another part. |
| **Process Document** | The manufacturing process spec attached to a product or part. |
| **BOM Release** | A released bill of materials for an assembly. |

A drawing uploaded against any of these moves through a single approval
workflow: **Draft → Submitted → Engineering Approved → Process Approved →
Released**, and can be **Rejected** back to the submitter at any
intermediate step.

## Tech stack

Rails 7.1 (Ruby 4.0.1) · PostgreSQL · Redis + Sidekiq (background jobs) ·
Devise (auth) · CanCanCan (authorization) · RailsAdmin (`/admin` backend) ·
Bootstrap 5 · ActiveStorage (local disk by default, Cloudflare R2 in
production).

**Dependency security:** `bundle audit` High/Critical findings were brought
down from 12 to 2 during the pre-release pass. The 2 remaining are both
`puma` and require a jump to puma 7/8, which in turn wants newer Rails —
left for a follow-up rather than bundled into this release. Run
`bundle audit check` yourself to see the current state.

## Deployment

MuseFlow ships without a bundled Dockerfile or `docker-compose.yml` yet —
that's a known gap, tracked as a follow-up, not shipped in this release
because it hasn't been verified against a real Docker environment. For now,
deploy it the way you'd deploy any Rails 7 app.

**Render (or any similar PaaS):**

- Build command: `bundle install && bin/rails assets:precompile`
- Start command: `bin/rails server`
- Provision a PostgreSQL and a Redis instance, and set `DB_USERNAME`,
  `DB_PASSWORD`, `DB_HOST`, `REDIS_URL`, `SECRET_KEY_BASE`.
- Run `bin/rails db:migrate` (and `db:seed` if you want the demo accounts)
  on first deploy.

**File storage on Render (or any PaaS with an ephemeral filesystem):** the
default `local` disk storage will silently lose every uploaded file on the
next deploy or restart — no error, just gone. Set `STORAGE_SERVICE=r2` and
the four `R2_*` variables (see `.env.example`) to store uploads in
Cloudflare R2 (S3-compatible) instead.

⚠️ **The R2 bucket must have a CORS policy configured**, or the browser's
direct upload to R2 will be blocked as cross-origin and every upload will
hang at "uploading" with a CORS/preflight error in the console. See
`.env.example` for the exact policy JSON to add in the Cloudflare dashboard
under *R2 → your bucket → Settings → CORS policy*.

## Registration & demo accounts

Self-registration is **off by default** — MuseFlow is single-tenant, so
opening `/users/sign_up` to the world means anyone who finds it can log in
and see this company's drawings. Set `ALLOW_REGISTRATION=true` to turn it on
(e.g. for a public demo/evaluation instance); leave it unset for a real
deployment and create accounts from the `/admin` backend instead.

The seed data creates four demo accounts, all with password `password123`.
Sign in with the **login**, not the email address:

| Login | Role | What they see |
|---|---|---|
| `admin` | Super Admin | Everything, plus the `/admin` backend |
| `devmgr` | Engineering Manager | Engineering approval step |
| `dev` | Engineer | Drafts, submissions |
| `proc` | Process Manager | Process approval step |

## Terminology & scope

The UI uses manufacturing-domain terms that don't always match the
underlying Rails model names — this is intentional and documented, not a
bug. It's the result of a deliberate decision *not* to rename models mid-way
through a stabilization effort, to avoid churning migrations and code
references for a cosmetic win.

| Model name (code) | UI / business term |
|---|---|
| `Product` | Product |
| `Instance` | **Part** |
| `Technology` | **Process Document** |
| `Matter` | **BOM Release** |

If you're reading the code and see `Instance`, that's a Part everywhere a
user sees it. Same for `Technology` (Process Document) and `Matter` (BOM
Release).

## The `/admin` backend

`/admin` is a separate data-administration backend for system
administrators, built on [RailsAdmin](https://github.com/railsadminteam/rails_admin).
It's where you create users, assign roles and permissions, and maintain
reference data like product types, material types, and the organization
tree. It requires the `super_admin` role.

Its look and feel is deliberately different from the main app — it's a
generic data-grid admin tool, not a redesigned surface, because engineers
use the main app day to day and only administrators go into `/admin`. That
visual split is intentional, not an unfinished skin.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — running the test suite, what CI
checks, and the i18n rule (any user-facing text change needs both
`config/locales/en/` and `config/locales/zh-CN/`).

## License

[MIT](LICENSE) — see the LICENSE file.
