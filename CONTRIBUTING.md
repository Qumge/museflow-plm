# Contributing to MuseFlow

Thanks for considering a contribution. This project is small and pragmatic —
here's what you need to know before opening a pull request.

## Getting set up

See [README.md](README.md) (or [README.zh-CN.md](README.zh-CN.md)) for the
local setup steps: `bundle install`, `bin/rails db:setup`, `bin/rails server`.

## Running the test suite

```bash
bin/rails test
```

The full suite runs in well under a minute. Please run it locally before
opening a pull request — a green suite is a hard requirement for merge, not
a suggestion.

If you're working on a single area, you can scope a run to one file or
directory, e.g. `bin/rails test test/models/`, but do a full `bin/rails test`
before you push.

## Continuous integration

Every push and pull request runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml):
it spins up Postgres 15 and Redis 7 service containers, runs
`bin/rails db:test:prepare`, then `bin/rails test`. A pull request that
doesn't pass CI won't be merged.

## Internationalization (i18n)

MuseFlow ships in English and Chinese. The two locale trees live at
`config/locales/en/` and `config/locales/zh-CN/`.

**Any change that touches user-facing text must update both trees in the
same pull request.** Adding a key to `config/locales/en/products.yml`
without the matching key in `config/locales/zh-CN/products.yml` (or vice
versa) leaves one locale broken — please don't split that across separate
PRs. If you don't speak Chinese, a best-effort machine translation with a
note in the PR description is fine; a native speaker can refine it later.

## Code style

There's no linter enforced in CI, so match the conventions already present
in the file you're editing (naming, indentation, comment style) rather than
introducing a new style. When in doubt, look at a neighboring file that does
something similar.

## Domain terminology

The UI uses business terms that don't always match the underlying Rails
model names — this is intentional, historical, and documented rather than a
bug. See the terminology table in the README before renaming anything or
being surprised that `Instance` means "Part" on screen.

## Reporting issues

Open a GitHub issue with steps to reproduce.
