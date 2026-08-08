#!/usr/bin/env bash
# Resolve smart_assistant_api checkout path (sibling repo or $HOME fallback).
set -euo pipefail

resolve_api_dir() {
  local workspace_root
  workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local sibling
  sibling="$(dirname "$workspace_root")/smart_assistant_api"
  if [ -d "$sibling/.git" ]; then
    printf '%s\n' "$sibling"
    return 0
  fi
  if [ -d "$HOME/smart_assistant_api/.git" ]; then
    printf '%s\n' "$HOME/smart_assistant_api"
    return 0
  fi
  return 1
}

ensure_api_repo() {
  local api_dir
  if api_dir="$(resolve_api_dir)"; then
    printf '%s\n' "$api_dir"
    return 0
  fi

  local workspace_root
  workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local sibling
  sibling="$(dirname "$workspace_root")/smart_assistant_api"
  if git clone --depth 1 https://github.com/cymonevo-luna/smart_assistant_api.git "$sibling" 2>/dev/null; then
    printf '%s\n' "$sibling"
    return 0
  fi

  git clone --depth 1 https://github.com/cymonevo-luna/smart_assistant_api.git "$HOME/smart_assistant_api"
  printf '%s\n' "$HOME/smart_assistant_api"
}

if [ "${1:-}" = "ensure_api_repo" ]; then
  ensure_api_repo
fi
