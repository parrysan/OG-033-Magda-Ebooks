# OG-033-Magda-Ebooks — Magda Ebooks

> **Bootstrap order — read these in order before doing any work in this project:**
>
> 1. `~/.claude/CLAUDE.md` → `Open-Memory-Vault/system/identity/MASTER-PROMPT.md` — Phil's identity (auto-loaded via symlink in Claude Code; other tools should mirror this).
> 2. `~/AGENT.md` → `agent-config/AGENT.md` — global operating manual (work style, skills routing, secrets policy, layering rules in §2.10).
> 3. `Open-Memory-Vault/AGENTS.md` — vault operating contract (read **only** if you will write to the vault during this session).
> 4. `Open-Memory-Vault/projects/OG-033-Magda-Ebooks/README.md` — durable project page (status, decisions, recent activity, vault-side context).
> 5. **This file (`AGENTS.md`)** — project-specific overrides and live operational references (below). `CLAUDE.md` in this folder is a one-line `@AGENTS.md` shim so Claude Code loads it too.
>
> **The project's `AGENTS.md` is a bootstrap manifest, not a knowledge dump.** It points at everything else. Durable knowledge lives in the vault project page. Do not duplicate.

---

## At a glance

- **Code**: `OG-033`
- **Name**: Magda Ebooks
- **Stakeholder**: Phil (self)
- **Type**: `product`
- **Status**: `active`
- **Priority**: `medium`
- **Revenue lane**: `2-pod`
- **Autonomy mode**: `autopilot` — Lane 2 product work skews autopilot by design (see master prompt); Phil reviews at checkpoints.
- **Purpose** (one sentence): Advise Magda on her "Gruntownie o nieruchomościach" ebook/education business (land real-estate ebooks + checklists, planned "Kanaan" company), assess the opportunity across Poland, and deliver findings via a dedicated client portal.
- **Client dashboard**: _(not deployed yet — paste the Client Area URL here after deploying; the AIOS project card links it automatically)_
- **Last touched**: `2026-07-16`

---

## Where things live

| Resource | Location |
|---|---|
| **Code root** | this folder (`dev/OG-033-Magda-Ebooks/`) |
| **Project docs** | `./docs/` |
| **Vault project page** | `Open-Memory-Vault/projects/OG-033-Magda-Ebooks/README.md` |
| **GitHub repo** | https://github.com/parrysan/OG-033-Magda-Ebooks |
| **Client area** | `docs/client-area/` (Overview + Research + Meetings seeded; Client Area style) |
| **External systems** | none yet |

---

## Live references

> **Operational facts that should never have to be re-discovered.** Deployed URLs, store handles, theme IDs, API endpoints, credentials *location* (never the credentials themselves — those live in the global `.env`, see global AGENT.md §2.5). Update this section whenever a fact changes — it is the canonical source.

- **GitHub**: https://github.com/parrysan/OG-033-Magda-Ebooks
- **Production URL**: https://og-033-magda-ebooks.web.app (client portal — Overview, Research, Meetings)
- **Staging / preview URL**: http://localhost:8081 (`python3 -m http.server 8081` from `docs/client-area/`)
- **Platform handle / project ID**: `og-033-magda-ebooks` (Firebase)
- **Research store**: OG-Research/OG-033-Magda-Ebooks/ (research, assets, deliverables) — https://drive.google.com/drive/folders/1GbDvu_fzsrQwFSUO5jD7lQISCC4A9Mbz
- **Credentials**: stored in global `.env` under `OG033_*`

---

## Tech stack

Inherits OS-000-Design-System defaults (see global AGENT.md §2.7):
- **Framework**: Next.js (App Router)
- **Styling**: Tailwind CSS v4 + OS-000 design tokens
- **Components**: OS-000 shared component library
- **Hosting**: Firebase Hosting
- **Design viewer**: /design-system route

Overrides: none yet — add project-specific overrides here as they emerge.

---

## Project-specific rules

> Domain rules, naming conventions, "do not" lists. Anything an LLM working in this project must know that isn't true globally. If empty, write "None — global rules apply" and stop.

- Source materials from Magda (ebooks, checklists) are in Polish — Phil does not speak Polish. Summarise/translate findings into English for Phil; keep Magda-facing deliverables in Polish where appropriate.
- Related to but distinct from `OG-017-Magdas-Website` (Magda's personal-brand real-estate website, Lane 1 service). This project is the productized ebook/education business — may merge back with OG-017 later if the two converge.
- Brand identity is Magda's own call: logo and dark-green colour are fixed per her instruction — do not propose changing them.

---

## Skills

> List any project-specific skills in `./.claude/skills/`. If none, the project uses the global library at `~/OG/shared-skills/`. Do not duplicate the global skills inventory here — see global AGENT.md §2.2.

- **Project-local skills**: none — uses global library
- **Most relevant global skills for this project**: `deep-research`, `og-plan-roast`, `frontend-design`, `research-notebooklm`

---

## Notes for the next session

> **Optional, ephemeral.** A 2–3 line free-form scratch pad of "where I left off" — not durable knowledge. Durable decisions belong in the vault project page. Wipe and rewrite freely.

Last action (2026-07-16): Fable 5 delivered the market assessment (verdict: RESHAPE) and built a land-value calculator MVP. Findings + calculator demo published to the client portal Research tab; deployed as v1.1 to https://og-033-magda-ebooks.web.app.

Next action: Decide with Phil how to bring the RESHAPE recommendations to Magda (Ebook 2 repricing, funnel redesign, Kanaan copyright fix), then share the portal URL with her.

Open questions: What "client portal" should contain (findings only, or a live dashboard Magda logs into); whether this stays a separate project or folds back into OG-017 once scoped.

---

## Deploy procedure

**Deploys go ONLY through [`scripts/predeploy.sh`](scripts/predeploy.sh).** Calling `firebase deploy --only hosting` directly is forbidden — it bypasses the gates that ensure consistency between source, tag, and live state.

### Steps

```bash
# 1. Make sure you're on main and the tree is clean (the script will refuse otherwise)
git checkout main
git status   # must be clean

# 2. Tag the commit you want to deploy (the tag IS the version label)
git tag v1.X -m "v1.X — <one-line summary>"
git push origin v1.X

# 3. Deploy
./scripts/predeploy.sh
```

### What the script enforces

- **Gate 1**: branch must be `main` (not a worktree, not a feature branch)
- **Gate 2**: working tree must be clean (no uncommitted, no untracked)
- **Gate 3**: `HEAD` must carry a `v*` tag — that tag becomes the version label
- **Stamp (meta)**: every deployed HTML gets `<meta name="x-version">` and `<meta name="x-build">` injected so any live page traces back to a commit
- **Stage isolation**: writes to a temp `docs/client-area.deploy/` copy and swaps `firebase.json` — your source tree is never mutated

Override env vars exist for emergencies (`PREDEPLOY_ALLOW_DIRTY=1`, `PREDEPLOY_ALLOW_UNTAGGED=1`) — use sparingly, document why.

No git-hooks/version-stamping infra (`setup-git-hooks.sh`, `version.json`) — this is a plain client portal with no version badge on the page, so that machinery is a no-op here. Add it if a future page needs a visible version label.

### Verifying what's live

Every deployed page carries provenance metadata. View-source any page and look for:

```html
<meta name="x-version" content="v1.0 — Month YYYY">
<meta name="x-build" content="<sha> · <date>">
```

Or via curl: `curl -s https://og-033-magda-ebooks.web.app/ | grep x-build`. If a live page's meta doesn't match a tag in this repo, something is wrong.
