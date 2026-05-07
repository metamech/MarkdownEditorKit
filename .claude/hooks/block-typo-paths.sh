#!/usr/bin/env bash
# Claude Code PreToolUse hook — blocks `.claude` typo path variants.
#
# Agent sessions have repeatedly produced `.claire/...` (and rarer `.cluade/`,
# `.calude/`, `.cladue/`) directory trees that mirror real `.claude/...` paths.
# Write/Edit/NotebookEdit silently create parent directories, so a typo
# materializes a hidden tree instead of erroring. This hook fails loudly.
#
# Protocol:
#   stdin  — PreToolUse JSON from Claude Code
#   exit 0 — allow
#   exit 2 — block, with reason on stderr

set -euo pipefail

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // ""')"

typo_path_re='(^|/)\.(claire|cluade|calude|cladue)(/|$)'
typo_bash_re='(^|[[:space:]/=>])\.(claire|cluade|calude|cladue)(/|$|[[:space:]])'

target_path=""
matched_segment=""
source_kind=""

case "$tool_name" in
  Write|Edit)
    target_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')"
    source_kind="file_path"
    if [ -n "$target_path" ] && printf '%s' "$target_path" | grep -Eq "$typo_path_re"; then
      matched_segment="$(printf '%s' "$target_path" | grep -Eo '\.(claire|cluade|calude|cladue)' | head -n1)"
    fi
    ;;
  NotebookEdit)
    target_path="$(printf '%s' "$payload" | jq -r '.tool_input.notebook_path // .tool_input.file_path // ""')"
    source_kind="notebook_path"
    if [ -n "$target_path" ] && printf '%s' "$target_path" | grep -Eq "$typo_path_re"; then
      matched_segment="$(printf '%s' "$target_path" | grep -Eo '\.(claire|cluade|calude|cladue)' | head -n1)"
    fi
    ;;
  Bash)
    target_path="$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')"
    source_kind="command"
    if [ -n "$target_path" ] && printf '%s' "$target_path" | grep -Eq "$typo_bash_re"; then
      matched_segment="$(printf '%s' "$target_path" | grep -Eo '\.(claire|cluade|calude|cladue)' | head -n1)"
    fi
    ;;
  *)
    exit 0
    ;;
esac

if [ -n "$matched_segment" ]; then
  cat >&2 <<EOF
[block-typo-paths] Tool call blocked by project hook.

Matched typo segment: ${matched_segment}
Source field: ${source_kind}
Offending value: ${target_path}

This looks like a typo for \`.claude/\`. Rewrite the path using \`.claude/...\`
and retry. The agent harness silently creates parent directories, so a typo
would otherwise materialize a hidden tree.
EOF
  exit 2
fi

exit 0
