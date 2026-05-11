#!/usr/bin/env bash
# statusline-bar — customizable Claude Code statusline
# Single file. bash 3.2+ and jq required.
# https://github.com/Dworf/statusline-bar

set -u

VERSION="0.1.0"

# ============================================================
# SECTION: CLI helpers
# ============================================================

print_help() {
  cat <<EOF
statusline-bar $VERSION — Claude Code statusline (bash + jq)

Usage:
  statusline-bar.sh [FLAGS]               render from stdin (Claude Code mode)
  statusline-bar.sh -c | --wizard         interactive setup
  statusline-bar.sh --examples [MODE]     browse presets/themes/etc
  statusline-bar.sh --check               validate config; exit 0/1

Flags:
  -h, --help                show this help
  -V, --version             print version
  -c, --wizard              enter setup wizard
      --examples [MODE]     MODE is catalog|interactive|all; default asks
      --check               validate config and exit
      --config PATH         use this config file instead of default
      --preset NAME         one-shot render with this preset
      --theme NAME          one-shot render with this theme
      --no-color            disable ANSI color output

Config: ~/.config/statusline-bar/config.json (or \$STATUSLINE_BAR_CONFIG).
Docs:   https://github.com/Dworf/statusline-bar
EOF
}

print_version() {
  echo "statusline-bar $VERSION"
}

# ============================================================
# SECTION: main dispatch
# ============================================================

main() {
  # Minimal dispatcher; expanded in Phase 8.
  case "${1:-}" in
    -h|--help) print_help; exit 0 ;;
    -V|--version) print_version; exit 0 ;;
    *)
      # No render yet; later tasks add stdin handling.
      print_help >&2
      exit 1
      ;;
  esac
}

main "$@"
