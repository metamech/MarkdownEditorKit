#!/usr/bin/env bash
# Claude Code PreToolUse hook — blocks destructive Bash patterns.
#
# Enforces CLAUDE.md §"AI Agent Guidelines":
#   • Never clear caches on your own initiative — DerivedData, ~/.swiftpm, …
#   • Never `git clone` external repositories for tangential investigation.
#
# Protocol:
#   stdin  — PreToolUse JSON from Claude Code
#   exit 0 — allow
#   exit 2 — block, with reason on stderr

set -euo pipefail

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // ""')"

if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command_str="$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')"
if [ -z "$command_str" ]; then
  exit 0
fi

# --- Normalize a copy for matching only --------------------------------------
home_literal="$HOME"
normalized="$command_str"

normalized="${normalized//\"/}"
normalized="${normalized//\'/}"
normalized="${normalized//\$\{HOME\}/$home_literal}"
normalized="${normalized//\$HOME/$home_literal}"
if [[ "$normalized" == "~/"* ]]; then
  normalized="$home_literal/${normalized:2}"
fi
if [[ "$normalized" == "~" || "$normalized" == "~ "* ]]; then
  normalized="$home_literal${normalized:1}"
fi
normalized="${normalized// ~\// $home_literal/}"
normalized="${normalized// ~ / $home_literal }"

matched_rule=""

# Rule 1: whole-tree DerivedData wipe.
derived_root="$home_literal/Library/Developer/Xcode/DerivedData"
derived_root_re="${derived_root//\//\\/}"
derived_root_re="${derived_root_re//./\\.}"
if printf '%s' "$normalized" | grep -Eq "rm[[:space:]]+-[rRf]+[[:space:]]+${derived_root_re}(/?\*?)?([[:space:]]|;|&|\||$)"; then
  matched_rule="rm -rf of ~/Library/Developer/Xcode/DerivedData (whole-tree cache wipe)"
fi

# Rule 2: rm -rf ~/.swiftpm.
if [ -z "$matched_rule" ]; then
  swiftpm_root="$home_literal/.swiftpm"
  swiftpm_root_re="${swiftpm_root//\//\\/}"
  swiftpm_root_re="${swiftpm_root_re//./\\.}"
  if printf '%s' "$normalized" | grep -Eq "rm[[:space:]]+-[rRf]+[[:space:]]+${swiftpm_root_re}(/[^[:space:]]*)?([[:space:]]|;|&|\||$)"; then
    matched_rule="rm -rf of ~/.swiftpm (SPM cache wipe)"
  fi
fi

# Rule 3: rm -rf ~/Library/Caches/org.swift.swiftpm.
if [ -z "$matched_rule" ]; then
  spm_cache="$home_literal/Library/Caches/org.swift.swiftpm"
  spm_cache_re="${spm_cache//\//\\/}"
  spm_cache_re="${spm_cache_re//./\\.}"
  if printf '%s' "$normalized" | grep -Eq "rm[[:space:]]+-[rRf]+[[:space:]]+${spm_cache_re}(/[^[:space:]]*)?([[:space:]]|;|&|\||$)"; then
    matched_rule="rm -rf of ~/Library/Caches/org.swift.swiftpm (SPM cache wipe)"
  fi
fi

# Rule 4: git clone with destination under /tmp/.
if [ -z "$matched_rule" ]; then
  if printf '%s' "$normalized" | grep -Eq "git[[:space:]]+clone([[:space:]]|$)"; then
    after_clone="${normalized#*git clone}"
    if printf '%s' "$after_clone" | grep -Eq "(^|[[:space:]=])/tmp/"; then
      matched_rule="git clone into /tmp/ (external repo clone for tangential investigation)"
    fi
  fi
fi

if [ -n "$matched_rule" ]; then
  cat >&2 <<EOF
[block-destructive-bash] Command blocked by project hook.

Matched rule: ${matched_rule}

This violates CLAUDE.md §"AI Agent Guidelines":
  • Never clear caches on your own initiative — DerivedData, ~/.swiftpm, …
  • Never \`git clone\` external repositories for tangential investigation.

If this is intentional, ask the user for explicit authorization.
EOF
  exit 2
fi

exit 0
