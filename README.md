# Claude Code Profile

Personal Claude Code configuration: global engineering standards, custom agents, and terminal statusline.

---

## What's in this repo

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions injected into every Claude Code session — SRE/Go engineering standards, code quality rules, observability requirements |
| `agents/lessonlearned.md` | Custom agent: living catalog of engineering anti-patterns captured from code reviews |
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
