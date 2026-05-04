#!/usr/bin/env bash
# agent-core PreToolUse safety hook
#
# Last line of defense against catastrophic, irreversible operations.
# The model is supposed to confirm destructive ops (CLAUDE.md §10);
# this hook catches the cases where it forgets, gets jailbroken, or
# misjudges blast radius.
#
# Wire up in ~/.claude/settings.json:
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Bash",
#       "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/pre-tool-use.sh"}]
#     }]
#   }
#
# Install: symlink this file into ~/.claude/hooks/ — see README install section.
#
# Exit codes:
#   0 = allow
#   2 = block (stderr message surfaced to model)

set -euo pipefail

input="$(cat)"
tool_name="$(echo "$input" | jq -r '.tool_name // ""')"

# Only inspect Bash. Edit/Write are handled by Claude Code's own protections.
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

cmd="$(echo "$input" | jq -r '.tool_input.command // ""')"

block() {
  local reason="$1"
  echo "BLOCKED by agent-core safety hook: ${reason}" >&2
  echo "If this is genuinely needed, ask the user to run it manually." >&2
  exit 2
}

# --- rm targeting catastrophic paths ---------------------------------------
# rm -rf /, /*, ~, $HOME, ./, .
if [[ "$cmd" =~ (^|[[:space:];|&])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*|-[a-zA-Z]*[fF][a-zA-Z]*[rR][a-zA-Z]*)[[:space:]]+(/|/\*|~|\$HOME|\.|\./)([[:space:]]|$|\;|\||\&) ]]; then
  block "rm -rf targeting root, home, or current dir"
fi

# rm -rf inside $HOME / ~  (e.g. rm -rf ~/Projects)
if [[ "$cmd" =~ (^|[[:space:];|&])rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*[[:space:]]+(\$HOME|~)/ ]]; then
  block "rm -rf inside \$HOME / ~"
fi

# --- git: force push to protected branches --------------------------------
# Allow --force-with-lease (safer: refuses if upstream moved).
if [[ "$cmd" =~ git[[:space:]]+push.*(--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$)) ]]; then
  if [[ ! "$cmd" =~ --force-with-lease ]]; then
    if [[ "$cmd" =~ (main|master|production|prod|release|develop) ]]; then
      block "git push --force to protected branch (use --force-with-lease, or push to a feature branch)"
    fi
  fi
fi

# --- git: bypassing hooks / signing ---------------------------------------
if [[ "$cmd" =~ git[[:space:]]+commit.*--no-verify ]]; then
  block "git commit --no-verify (skipping pre-commit hooks). Fix the underlying check instead."
fi

if [[ "$cmd" =~ git[[:space:]]+commit.*--no-gpg-sign ]]; then
  block "git commit --no-gpg-sign (bypassing signing)"
fi

# --- git: hard reset on protected branches --------------------------------
if [[ "$cmd" =~ git[[:space:]]+reset[[:space:]]+--hard.*(main|master|production|prod|release) ]]; then
  block "git reset --hard on protected branch"
fi

# --- git: branch deletion of protected branches ---------------------------
if [[ "$cmd" =~ git[[:space:]]+branch[[:space:]]+-D[[:space:]]+(main|master|production|prod|release) ]]; then
  block "git branch -D on protected branch"
fi

# --- chmod 777 / chown -R / on broad targets ------------------------------
if [[ "$cmd" =~ chmod[[:space:]]+(-R[[:space:]]+)?777[[:space:]]+(/|~|\$HOME) ]]; then
  block "chmod 777 on root/home (creates world-writable)"
fi

# --- wrapper bypass: bash -c / sh -c / eval containing rm -rf -------------
# Catches: bash -c "rm -rf /", eval 'rm -rf ~', sh -c "rm -rf \$HOME"
WRAPPER=0
if [[ "$cmd" =~ (^|[[:space:];|&])(bash|sh|zsh|fish|ksh|dash)[[:space:]]+-c ]] || \
   [[ "$cmd" =~ (^|[[:space:];|&])eval([[:space:]]|$) ]]; then
  WRAPPER=1
fi
if [[ $WRAPPER -eq 1 ]] && [[ "$cmd" =~ rm[[:space:]]+-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+(/|~|\$HOME|/\*|\./?) ]]; then
  block "rm -rf catastrophic target inside bash -c / sh -c / eval wrapper"
fi

# --- escaped \rm (bypasses shell aliases) ---------------------------------
if [[ "$cmd" =~ \\rm[[:space:]]+-[a-zA-Z]*[rRfF] ]]; then
  block "escaped \\rm with -rf flags"
fi

# --- absolute-path rm targeting catastrophic paths ------------------------
if [[ "$cmd" =~ /(bin|usr/bin|sbin|usr/sbin)/rm[[:space:]]+-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+(/|~|\$HOME) ]]; then
  block "absolute-path rm targeting root/home"
fi

# --- find -delete / find -exec rm rooted at / or $HOME --------------------
# Allow find on cwd, /tmp, project subdirs. Block only when rooted at / or ~.
if [[ "$cmd" =~ find[[:space:]]+(/|~|\$HOME)([[:space:]]|$) ]] && \
   [[ "$cmd" =~ (-delete|-exec[[:space:]]+(/[a-z]+/)?rm) ]]; then
  block "find rooted at / or \$HOME with -delete / -exec rm"
fi

# --- xargs rm with destructive flags --------------------------------------
if [[ "$cmd" =~ xargs[[:space:]]+(-[a-zA-Z0-9]+[[:space:]]+)*(/[a-z]+/)?rm[[:space:]]+-[a-zA-Z]*[rRfF] ]]; then
  block "xargs rm -rf (dangerous in pipe contexts)"
fi

# --- sensitive file reads (credential exfiltration) -----------------------
# Match common credential / key files. Adjust if you have legit reasons to read these.
SENSITIVE='(\.ssh/(id_|.*_key$|.*_key[[:space:]])|\.aws/credentials|\.aws/config|\.config/gh/hosts\.yml|\.netrc|\.kube/config|\.npmrc|\.pypirc|\.docker/config\.json|/etc/(passwd|shadow|sudoers))'
if [[ "$cmd" =~ (^|[[:space:];|&|])(cat|less|more|head|tail|bat|xxd|od)[[:space:]].*$SENSITIVE ]]; then
  block "reading sensitive credential file. Ask the user to share specific values instead."
fi

# --- .env file reads (excluding committed templates) ----------------------
# Block .env, .env.local, .env.production, .env.development, .env.staging, .env.test
# Allow .env.example, .env.sample, .env.template, .env.dist
if [[ "$cmd" =~ (^|[[:space:];|&|])(cat|less|more|head|tail|bat)[[:space:]].*\.env(\.[a-zA-Z]+)?([[:space:]\"\';|&]|$) ]]; then
  if [[ ! "$cmd" =~ \.env\.(example|sample|template|tpl|tmpl|dist|defaults?) ]]; then
    block "reading .env file (likely contains secrets). If genuinely needed, ask the user to share the specific value."
  fi
fi

exit 0
