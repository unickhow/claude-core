#!/usr/bin/env bash
# agent-core: hook test suite
#
# Runs all PreToolUse and UserPromptSubmit hook test cases against the
# scripts in hooks/. Use after editing any hook to catch regressions.
#
# Usage:
#   bin/test-hooks.sh
#
# Exit code: 0 if all pass, 1 if any fail.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRE_HOOK="$REPO_DIR/hooks/pre-tool-use.sh"
PROMPT_HOOK="$REPO_DIR/hooks/user-prompt-submit.sh"

PASS=0
FAIL=0

run_pre() {
  local label="$1" expected="$2" cmd="$3"
  local json out rc outcome
  json=$(jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')
  out=$(echo "$json" | "$PRE_HOOK" 2>&1); rc=$?
  outcome="ALLOW"; [[ $rc -eq 2 ]] && outcome="BLOCK"
  if [[ "$outcome" == "$expected" ]]; then
    PASS=$((PASS+1))
    printf "  \033[32mPASS\033[0m [%s] %s\n" "$expected" "$label"
  else
    FAIL=$((FAIL+1))
    printf "  \033[31mFAIL\033[0m [exp=%s got=%s] %s\n         %s\n" "$expected" "$outcome" "$label" "$out"
  fi
}

section() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }

# ----------------------------------------------------------------------------
section "pre-tool-use: regression — must allow"
run_pre "ls -la"                      ALLOW 'ls -la'
run_pre "git status"                  ALLOW 'git status'
run_pre "npm test"                    ALLOW 'npm test'
run_pre "rm file.txt"                 ALLOW 'rm file.txt'
run_pre "rm -rf node_modules"         ALLOW 'rm -rf node_modules'
run_pre "rm -rf dist/"                ALLOW 'rm -rf dist/'
run_pre "rm -rf .next"                ALLOW 'rm -rf .next'
run_pre "git push -f feature-x"       ALLOW 'git push -f origin feature-x'
run_pre "force-with-lease to main"    ALLOW 'git push --force-with-lease origin main'
run_pre "chmod 755 file"              ALLOW 'chmod 755 myfile'

section "pre-tool-use: regression — must block"
run_pre "rm -rf /"                    BLOCK 'rm -rf /'
run_pre "rm -rf ~"                    BLOCK 'rm -rf ~'
run_pre 'rm -rf $HOME'                BLOCK 'rm -rf $HOME'
run_pre "rm -rf ./"                   BLOCK 'rm -rf ./'
run_pre "rm -rf ~/Projects"           BLOCK 'rm -rf ~/Projects'
run_pre "rm -fr /"                    BLOCK 'rm -fr /'
run_pre "git push --force main"       BLOCK 'git push --force origin main'
run_pre "git push -f master"          BLOCK 'git push -f origin master'
run_pre "git commit --no-verify"      BLOCK 'git commit --no-verify -m fix'
run_pre "reset --hard origin/main"    BLOCK 'git reset --hard origin/main'
run_pre "git branch -D main"          BLOCK 'git branch -D main'
run_pre "chmod 777 ~"                 BLOCK 'chmod 777 ~'

section "pre-tool-use: wrapper bypass"
run_pre 'bash -c "rm -rf /"'          BLOCK 'bash -c "rm -rf /"'
run_pre 'eval "rm -rf ~"'             BLOCK 'eval "rm -rf ~"'
run_pre "sh -c 'rm -rf \$HOME'"       BLOCK "sh -c 'rm -rf \$HOME'"
run_pre 'bash -c "ls -la"'            ALLOW 'bash -c "ls -la"'

section "pre-tool-use: escape + absolute path"
run_pre '\rm -rf /'                   BLOCK '\rm -rf /'
run_pre "/bin/rm -rf /"               BLOCK '/bin/rm -rf /'
run_pre "/usr/bin/rm -rf ~"           BLOCK '/usr/bin/rm -rf ~'

section "pre-tool-use: find / xargs"
run_pre "find / -delete"              BLOCK 'find / -delete'
run_pre "find ~ -exec rm {} +"        BLOCK 'find ~ -exec rm {} +'
run_pre "ls | xargs rm -rf"           BLOCK 'ls | xargs rm -rf'
run_pre "find /tmp -delete"           ALLOW 'find /tmp -delete'
run_pre "find . -name foo -delete"    ALLOW 'find . -name foo -delete'
run_pre "ls | xargs rm (no -rf)"      ALLOW 'ls | xargs rm'

section "pre-tool-use: sensitive file reads"
run_pre "cat ~/.ssh/id_rsa"           BLOCK 'cat ~/.ssh/id_rsa'
run_pre "cat ~/.aws/credentials"      BLOCK 'cat ~/.aws/credentials'
run_pre "head ~/.ssh/id_ed25519"      BLOCK 'head -1 ~/.ssh/id_ed25519'
run_pre "cat .env"                    BLOCK 'cat .env'
run_pre "cat .env.local"              BLOCK 'cat .env.local'
run_pre "cat .env.production"         BLOCK 'cat .env.production'
run_pre "cat .env.example"            ALLOW 'cat .env.example'
run_pre "cat .env.template"           ALLOW 'cat .env.template'
run_pre "cat README.md"               ALLOW 'cat README.md'

# ----------------------------------------------------------------------------
section "user-prompt-submit: smoke check"
out=$(echo '{"prompt":"hi"}' | "$PROMPT_HOOK" 2>&1)
if [[ "$out" =~ "<git-context>" ]]; then
  PASS=$((PASS+1))
  printf "  \033[32mPASS\033[0m emits <git-context> in git repo\n"
else
  FAIL=$((FAIL+1))
  printf "  \033[31mFAIL\033[0m no <git-context> emitted\n"
fi

# Non-Bash tool special case (PreToolUse must allow)
out=$(echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"}}' | "$PRE_HOOK" 2>&1)
rc=$?
if [[ $rc -eq 0 ]]; then
  PASS=$((PASS+1))
  printf "  \033[32mPASS\033[0m pre-tool-use ignores non-Bash tools\n"
else
  FAIL=$((FAIL+1))
  printf "  \033[31mFAIL\033[0m pre-tool-use should ignore non-Bash, got rc=%d\n" "$rc"
fi

# ----------------------------------------------------------------------------
TOTAL=$((PASS + FAIL))
printf "\n\033[1mResult:\033[0m %d/%d passed" "$PASS" "$TOTAL"
if [[ $FAIL -eq 0 ]]; then
  printf " \033[32m✓\033[0m\n"
  exit 0
else
  printf " \033[31m✗\033[0m\n"
  exit 1
fi
