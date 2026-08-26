# Claude Code Profile

Personal Claude Code configuration: global engineering standards, custom agents, and terminal statusline.

---

## What's in this repo

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions injected into every Claude Code session — SRE/Go engineering standards, code quality rules, observability requirements |
| `agents/lessonlearned.md` | Custom agent: living catalog of engineering anti-patterns — reasoning-led pre-ship audit and post-review pattern capture |
| `agents/ocr-review.md` | Custom agent: open code review runner |
| `skills/` | Symlinks to marketplace-installed skills (see note below) |
| `settings.json` | Claude Code settings: model, theme, statusline command |
| `statusline-command.sh` | Terminal statusline script — shows model, context %, branch, PR state, vim mode |

---

## Setting up on a new machine

### 1. Prerequisites

Install these before anything else:

```bash
# Claude Code CLI
npm install -g @anthropic-ai/claude-code   # or follow https://claude.ai/code

# Statusline dependencies
sudo apt install jq git      # Debian/Ubuntu
brew install jq git          # macOS
```

### 2. Clone this repo

```bash
git clone git@github.com:msaraya01/claude.git ~/my-repos/claude
```

### 3. Create the ~/.claude directory structure

```bash
mkdir -p ~/.claude/agents
```

### 4. Link or copy CLAUDE.md

```bash
ln -sf ~/my-repos/claude/CLAUDE.md ~/.claude/CLAUDE.md
```

If you prefer a copy instead of a symlink (so local edits don't go straight to git):

```bash
cp ~/my-repos/claude/CLAUDE.md ~/.claude/CLAUDE.md
```

### 5. Install custom agents

```bash
cp ~/my-repos/claude/agents/*.md ~/.claude/agents/
```

Agents are loaded by Claude Code automatically from `~/.claude/agents/`. No restart needed.

### 6. Install settings

```bash
cp ~/my-repos/claude/settings.json ~/.claude/settings.json
```

Then **update the statusline path** in `~/.claude/settings.json` to match your home directory:

```json
"statusLine": {
  "type": "command",
  "command": "bash /YOUR/HOME/.claude/statusline-command.sh"
}
```

### 7. Install the statusline script

```bash
cp ~/my-repos/claude/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 8. Skills (marketplace-managed — not portable via this repo)

The `skills/` directory contains symlinks that only resolve on the original machine. Skills are installed through Claude Code's skill marketplace and cannot be transferred by copying symlinks.

To reinstall skills on a new machine, open Claude Code and install them from the marketplace, or run:

```bash
claude skill install <skill-name>
```

Skills currently in use on the original machine (install these manually):

- `clean-code-guard`
- `codex-delegate`
- `cost-optimization`
- `delegate-setup`
- `devops-engineer`
- `docs-guard`
- `find-skills`
- `github-actions-templates`
- `gitops-workflow`
- `k8s-security-policies`
- `kubernetes-specialist`
- `monitoring-expert`
- `opencode-delegate`
- `sre-engineer`
- `systematic-debugging`
- `test-guard`

---

## lessonlearned agent

`agents/lessonlearned.md` is a custom agent that maintains a language-agnostic catalog of engineering anti-patterns and provides two workflows:

### Pre-ship audit

Before marking any non-trivial feature or refactor as complete, invoke it with:

> "Run lessonlearned on `<file(s)>` — reason about what could go wrong before consulting the catalog."

The agent **reads code with fresh eyes first** — it does not start from the catalog. It identifies failure scenarios (concurrency, boundary conditions, partial failures, silent errors), then uses the catalog to name what it finds. It will also surface violations the catalog hasn't named yet. The order matters: reasoning first, pattern-matching second.

### Post-review capture

After any code review that surfaces a bug, invoke it to extract the pattern:

> "Run lessonlearned post-review — capture any new patterns from the findings."

The agent decides whether each finding generalizes beyond this codebase. If it does, it abstracts the root cause (not the surface symptom), writes a new principle entry with an anti-pattern and correct example, and appends it to the catalog under the appropriate domain. If nothing generalizes, it says so.

### Catalog structure

Principles are grouped by domain and numbered within each domain (`A1`, `B2`, `C4`, …):

| Domain | Covers |
|---|---|
| **A — Async State** | Flag spaghetti, optimistic state, shared keys, lifecycle events, error handling, dedup scope, dedup key mismatch, concurrent state reads, intent-parking eviction, bounds at write layer |
| **B — Web / Browser** | Capture-phase listeners, AJAX form defaultPrevented, SPA DOM snapshot staleness |
| **C — Database / Storage** | Read transactions for composite queries, nil vs empty collections, silent enrichment errors, SQLite LastInsertId after upsert, unbounded queries |
| **D — API Design** | Collection fields that can serialize as null |

New domains are added when findings don't fit any existing group.

### What the agent does NOT do

- It does not run through the catalog as a fixed checklist.
- It does not flag every pattern regardless of context — severity matters.
- It does not add catalog entries for one-off project-specific bugs.

---

## Keeping this repo in sync

After making changes to any file under `~/.claude`:

```bash
cd ~/my-repos/claude

# Copy changed files back to the repo
cp ~/.claude/CLAUDE.md .
cp ~/.claude/agents/*.md agents/
cp ~/.claude/settings.json .
cp ~/.claude/statusline-command.sh .

git add -p   # review each change
git commit -m "chore: update <what changed>"
git push
```

---

## Statusline features

The `statusline-command.sh` script surfaces the following in the Claude Code terminal prompt:

- **user@host:path** — git-aware path with repo name and branch highlighted
- **branch color** — `main`/`master` in red, feature branches in green
- **model** — active Claude model name
- **ctx%** — remaining context window (yellow ≥75%, red ≥90%)
- **effort** — reasoning effort level when set
- **thinking** — shown when extended thinking is enabled
- **vim mode** — INSERT / NORMAL / VISUAL when vim mode is active
- **rate limits** — 5-hour and 7-day usage percentages (Claude.ai subscribers)
- **PR/MR** — open pull/merge request number and review state on the current branch
- **agent** — agent name when launched with `--agent`
- **session name** — when `/rename` has been used

**Dependencies:** `bash`, `jq`, `git`
