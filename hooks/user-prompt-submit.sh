#!/usr/bin/env bash
# agent-core UserPromptSubmit hook
#
# Injects fresh git context (branch, dirty status, ahead/behind) into the
# model's context on every user prompt. Saves the model from running
# `git status` / `git branch --show-current` over and over for grounding.
#
# Wire up in ~/.claude/settings.json:
#   "hooks": {
#     "UserPromptSubmit": [{
#       "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/user-prompt-submit.sh"}]
#     }]
#   }
#
# Install: symlink this file into ~/.claude/hooks/ — see README install section.
#
# Anything written to stdout is surfaced to the model as additional context.
# Exit 0 always (this hook is informational, never blocks).

set -uo pipefail

# Drain stdin (we don't need the prompt content, but Claude Code will pipe it)
cat >/dev/null

# Bail silently if not in a git repo
git_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

cd "$git_root"

branch="$(git branch --show-current 2>/dev/null)"
[[ -z "$branch" ]] && branch="(detached HEAD)"

dirty_count="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
dirty_str=""
[[ "$dirty_count" -gt 0 ]] && dirty_str=" · ${dirty_count} uncommitted"

ahead_behind=""
if upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
  if counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null)"; then
    behind="$(echo "$counts" | cut -f1)"
    ahead="$(echo "$counts" | cut -f2)"
    if [[ "$ahead" -gt 0 || "$behind" -gt 0 ]]; then
      ahead_behind=" · ↑${ahead} ↓${behind} vs ${upstream}"
    fi
  fi
fi

cat <<EOF
<git-context>
branch: ${branch}${dirty_str}${ahead_behind}
root:   ${git_root}
</git-context>
EOF
