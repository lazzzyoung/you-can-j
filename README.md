# You can J

A simple monthly planner: a month calendar, one-off events, weekly routines, color groups, and a 24-hour dial for each day. Plain HTML, synced with Supabase, hosted on Vercel.

- Live: https://month-do.vercel.app
- Database schema: [`supabase.sql`](supabase.sql)
- History: [`CHANGELOG.md`](CHANGELOG.md)

## Run locally

Open `index.html` in a browser. Sign-in and sync use the Supabase project configured at the top of the script.

## Git conventions

### Branches (git flow)

| Branch | From | Merges into | Purpose |
|---|---|---|---|
| `main` | — | — | Released code only. Every merge is tagged `vX.Y.Z`. |
| `develop` | `main` | — | Integration branch for the next release. |
| `feature/<kebab-name>` | `develop` | `develop` | One feature or fix per branch. |
| `release/X.Y.Z` | `develop` | `main` and `develop` | Version bump and changelog only. |
| `hotfix/X.Y.Z` | `main` | `main` and `develop` | Urgent fix to a released version. |

Merges always use `--no-ff` so each feature stays visible as a unit in history.

### Commit messages ([Conventional Commits](https://www.conventionalcommits.org))

```
<type>(<scope>): <summary in imperative, lowercase, no period>
```

| Type | Use for |
|---|---|
| `feat` | A new user-facing feature |
| `fix` | A bug fix |
| `style` | Visual/CSS changes with no behavior change |
| `refactor` | Code changes that neither fix nor add |
| `docs` | README, CHANGELOG, comments |
| `chore` | Tooling, config, release bookkeeping |

Scopes: `calendar`, `day`, `form`, `routine`, `groups`, `auth`, `sync`, `ui`, `privacy`, `release`.

### Versioning ([SemVer](https://semver.org))

`MAJOR.MINOR.PATCH` — minor for new features, patch for fixes. Each release adds a section to `CHANGELOG.md`.
