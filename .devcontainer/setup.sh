#!/usr/bin/env bash
# Wires this repo's config files into ~/.claude inside the dev container.
# Runs once after the container is created (postCreateCommand).
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "${CLAUDE_DIR}/agents"

# Symlink so edits in the repo are immediately reflected in the running session.
ln -sf "${REPO_DIR}/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"

# Agents are copied so the volume retains them if the repo mount disappears.
cp "${REPO_DIR}/agents/"*.md "${CLAUDE_DIR}/agents/"

# Patch the hardcoded host path before copying settings into the volume.
sed "s|/home/msaraya|${HOME}|g" "${REPO_DIR}/settings.json" > "${CLAUDE_DIR}/settings.json"

cp "${REPO_DIR}/statusline-command.sh" "${CLAUDE_DIR}/statusline-command.sh"
chmod +x "${CLAUDE_DIR}/statusline-command.sh"

echo "Claude Code profile configured in ${CLAUDE_DIR}"
echo "Install skills manually once signed in: claude skill install <name>"
