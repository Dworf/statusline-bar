#!/usr/bin/env bash
# statusline-bar — customizable Claude Code statusline
# Single file. bash 3.2+ and jq required.
# https://github.com/Dworf/statusline-bar

set -u

VERSION="0.1.0"

# ============================================================
# SECTION: Embedded data — themes
# ============================================================

read -r -d '' THEMES_JSON <<'JSON' || true
{
  "default":     { "good":"#3fb950","warn":"#d29922","crit":"#f85149","dim":"#8b949e","accent":"#79c0ff","bar_style":"blocks" },
  "dark":        { "good":"#00ff87","warn":"#ffaf00","crit":"#ff5f5f","dim":"#6a737d","accent":"#5fafff","bar_style":"blocks" },
  "light":       { "good":"#1a7f37","warn":"#bf8700","crit":"#cf222e","dim":"#57606a","accent":"#0969da","bar_style":"blocks" },
  "graphite":    { "good":"bold",   "warn":"normal","crit":"normal","dim":"dim",    "accent":"bold",    "bar_style":"ascii"  },
  "solarized":   { "good":"#859900","warn":"#b58900","crit":"#dc322f","dim":"#586e75","accent":"#268bd2","bar_style":"heavy"  },
  "dracula":     { "good":"#50fa7b","warn":"#f1fa8c","crit":"#ff5555","dim":"#6272a4","accent":"#bd93f9","bar_style":"blocks" },
  "nord":        { "good":"#a3be8c","warn":"#ebcb8b","crit":"#bf616a","dim":"#4c566a","accent":"#88c0d0","bar_style":"heavy"  },
  "gruvbox":     { "good":"#98971a","warn":"#d79921","crit":"#cc241d","dim":"#7c6f64","accent":"#458588","bar_style":"heavy"  },
  "tokyo-night": { "good":"#9ece6a","warn":"#e0af68","crit":"#f7768e","dim":"#565f89","accent":"#7aa2f7","bar_style":"blocks" },
  "catppuccin":  { "good":"#a6e3a1","warn":"#f9e2af","crit":"#f38ba8","dim":"#6c7086","accent":"#89b4fa","bar_style":"blocks" }
}
JSON

# ============================================================
# SECTION: Embedded data — separators
# ============================================================
# chevron/slant/chevron_thin use Powerline Nerd Font codepoints
# (E0B0 / E0BC / E0B1) via \u escapes. The other 16 are plain unicode/ASCII.

read -r -d '' SEPARATORS_JSON <<'JSON' || true
{
  "space":        { "chars":"  ",                  "kind":"ascii" },
  "pipe":         { "chars":" | ",                 "kind":"ascii" },
  "slash":        { "chars":" / ",                 "kind":"ascii" },
  "dot":          { "chars":" · ",            "kind":"unicode" },
  "vbar":         { "chars":" │ ",            "kind":"unicode" },
  "dash":         { "chars":" ─ ",            "kind":"unicode" },
  "bullet":       { "chars":" • ",            "kind":"unicode" },
  "diamond":      { "chars":" ◆ ",            "kind":"unicode" },
  "arrow":        { "chars":" ▸ ",            "kind":"unicode" },
  "tri":          { "chars":" ▶ ",            "kind":"unicode" },
  "star":         { "chars":" ★ ",            "kind":"unicode" },
  "sparkle":      { "chars":" ✦ ",            "kind":"unicode" },
  "gear":         { "chars":" ⚙ ",            "kind":"unicode" },
  "check":        { "chars":" ✓ ",            "kind":"decorative" },
  "heart":        { "chars":" ♥ ",            "kind":"decorative" },
  "music":        { "chars":" ♪ ",            "kind":"decorative" },
  "chevron":      { "chars":"  ",            "kind":"nerd" },
  "slant":        { "chars":"  ",            "kind":"nerd" },
  "chevron_thin": { "chars":"  ",            "kind":"nerd" }
}
JSON

# ============================================================
# SECTION: Embedded data — bar styles
# ============================================================

read -r -d '' BAR_STYLES_JSON <<'JSON' || true
{
  "blocks":   { "fill":"█",   "empty":"░",   "gradient":false },
  "heavy":    { "fill":"▰",   "empty":"▱",   "gradient":false },
  "line":     { "fill":"━",   "empty":"─",   "gradient":false },
  "braille":  { "fill":"⣿",   "empty":"⡀",   "gradient":false },
  "dots":     { "fill":"●",   "empty":"○",   "gradient":false },
  "arrows":   { "fill":"▶",   "empty":"▷",   "gradient":false },
  "ascii":    { "fill":"#",        "empty":".",        "gradient":false },
  "gradient": { "fill":"█",   "empty":" ",        "gradient":true,
                "eighths":["", "▏","▎","▍","▌","▋","▊","▉"] }
}
JSON

# ============================================================
# SECTION: Embedded data — presets
# ============================================================

read -r -d '' PRESETS_JSON <<'JSON' || true
{
  "minimum": {
    "lines": [ ["model","context_pct","cost"] ],
    "token_formats": {}
  },
  "compact": {
    "lines": [ ["model","context_pct","cost","git_branch","duration","rl_5h"] ],
    "token_formats": { "rl_5h": "percent" }
  },
  "default": {
    "lines": [
      ["model","context_pct","cost","rl_5h","rl_7d"],
      ["thinking","effort","dir","worktree","git_branch","lines_added","lines_removed","duration"]
    ],
    "token_formats": {
      "rl_5h": "progressbar+percent+countdown",
      "rl_7d": "progressbar+percent+countdown"
    }
  },
  "modern": {
    "lines": [
      ["model","context_pct","git_branch","git_staged","git_modified","cost"],
      ["rl_5h","rl_7d","duration"]
    ],
    "token_formats": {
      "rl_5h": "progressbar+percent",
      "rl_7d": "progressbar+percent"
    }
  },
  "fancy": {
    "lines": [
      ["model","context_bar","cost","duration"],
      ["rl_5h","rl_7d"],
      ["dir","git_branch","git_status","thinking","effort","battery","clock"]
    ],
    "token_formats": {
      "rl_5h": "progressbar+percent+countdown",
      "rl_7d": "progressbar+percent+countdown",
      "battery": "progressbar+percent"
    }
  },
  "everything": {
    "lines": [
      ["model","session_name","context_pct","cache_hit","cost","duration","api_duration"],
      ["rl_5h","rl_7d","thinking","effort","output_style","version"],
      ["dir","worktree","git_branch","git_status","git_ahead_behind","lines_added","lines_removed"],
      ["clock","date","hostname","user","battery","memory","load","fast_mode","exceeds_200k"]
    ],
    "token_formats": {}
  },
  "maximum": {
    "lines": [
      ["model","session_name","context_pct","cache_hit","cost","duration","api_duration"],
      ["rl_5h","rl_7d","thinking","effort","output_style","version"],
      ["dir","worktree","git_branch","git_status","git_ahead_behind","lines_added","lines_removed"],
      ["clock","date","hostname","user","battery","memory","load","fast_mode","exceeds_200k"]
    ],
    "token_formats": {
      "context_pct": "progressbar+percent",
      "cache_hit": "progressbar+percent",
      "rl_5h": "progressbar+percent+countdown",
      "rl_7d": "progressbar+percent+countdown",
      "battery": "progressbar+percent",
      "memory": "progressbar+percent",
      "git_status": "combined"
    }
  }
}
JSON

# ============================================================
# SECTION: Embedded data — tokens (39)
# ============================================================
# `nerd` fields are intentionally empty in v0.1.0; nerd prefix style
# renders as empty prefix until follow-up release adds glyph mapping.

read -r -d '' TOKENS_JSON <<'JSON' || true
{
  "model": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Model:", "emoji":"🤖", "nerd":"", "ascii":"[M]" } },
  "session_name": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Session:", "emoji":"📝", "nerd":"", "ascii":"[S]" } },
  "context_pct": { "source":"claude", "default_prefix":"emoji", "default_format":"percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"],
             "prefix": { "none":"", "label":"Ctx:", "emoji":"🧠", "nerd":"", "ascii":"[C]" } },
  "context_bar": { "source":"claude", "default_prefix":"emoji", "default_format":"progressbar+percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"],
             "prefix": { "none":"", "label":"Ctx:", "emoji":"🧠", "nerd":"", "ascii":"[C]" } },
  "cache_hit": { "source":"claude", "default_prefix":"emoji", "default_format":"percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"],
             "prefix": { "none":"", "label":"Cache:", "emoji":"💾", "nerd":"", "ascii":"[H]" } },
  "cost": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Cost:", "emoji":"💰", "nerd":"", "ascii":"[$]" } },
  "duration": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Time:", "emoji":"⏳", "nerd":"", "ascii":"[T]" } },
  "api_duration": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"API:", "emoji":"📡", "nerd":"", "ascii":"[A]" } },
  "lines_added": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"+:", "emoji":"➕", "nerd":"", "ascii":"+" } },
  "lines_removed": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"-:", "emoji":"➖", "nerd":"", "ascii":"-" } },
  "rl_5h": { "source":"claude", "default_prefix":"label", "default_format":"progressbar+percent+countdown",
             "applicable_formats":["value","percent","progressbar","progressbar+percent","countdown","remaining","progressbar+percent+countdown"],
             "prefix": { "none":"", "label":"5h", "emoji":"⏱️ 5h", "nerd":"", "ascii":"[5h]" } },
  "rl_7d": { "source":"claude", "default_prefix":"label", "default_format":"progressbar+percent+countdown",
             "applicable_formats":["value","percent","progressbar","progressbar+percent","countdown","remaining","progressbar+percent+countdown"],
             "prefix": { "none":"", "label":"7d", "emoji":"⏱️ 7d", "nerd":"", "ascii":"[7d]" } },
  "thinking": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","flag"],
             "prefix": { "none":"", "label":"Think:", "emoji":"💭", "nerd":"", "ascii":"[?]" } },
  "effort": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Effort:", "emoji":"💪", "nerd":"", "ascii":"[E]" } },
  "output_style": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Style:", "emoji":"🎨", "nerd":"", "ascii":"[Y]" } },
  "version": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"v", "emoji":"🏷", "nerd":"", "ascii":"[V]" } },
  "fast_mode": { "source":"claude", "default_prefix":"emoji", "default_format":"flag", "applicable_formats":["flag","value"],
             "prefix": { "none":"", "label":"Fast", "emoji":"⚡", "nerd":"", "ascii":"[F]" } },
  "exceeds_200k": { "source":"claude", "default_prefix":"emoji", "default_format":"flag", "applicable_formats":["flag","value"],
             "prefix": { "none":"", "label":">200k", "emoji":"📈", "nerd":"", "ascii":"[>]" } },
  "dir": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Dir:", "emoji":"📁", "nerd":"", "ascii":"[D]" } },
  "worktree": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Tree:", "emoji":"🌳", "nerd":"", "ascii":"[W]" } },
  "vim_mode": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Vim:", "emoji":"⌨", "nerd":"", "ascii":"[Vm]" } },
  "agent_name": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Agent:", "emoji":"🤝", "nerd":"", "ascii":"[Ag]" } },
  "session_id": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"ID:", "emoji":"🔖", "nerd":"", "ascii":"[ID]" } },
  "added_dirs": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","flag"],
             "prefix": { "none":"", "label":"+dirs:", "emoji":"📂", "nerd":"", "ascii":"[+D]" } },
  "git_worktree": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"WT:", "emoji":"🌲", "nerd":"", "ascii":"[WT]" } },
  "transcript": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Log:", "emoji":"📜", "nerd":"", "ascii":"[L]" } },
  "git_branch": { "source":"git", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Branch:", "emoji":"🌿", "nerd":"", "ascii":"[B]" } },
  "git_status": { "source":"git", "default_prefix":"none", "default_format":"combined", "applicable_formats":["combined","value"],
             "prefix": { "none":"", "label":"Status:", "emoji":"📊", "nerd":"", "ascii":"" } },
  "git_staged": { "source":"git", "default_prefix":"ascii", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Staged:", "emoji":"➕", "nerd":"", "ascii":"+" } },
  "git_modified": { "source":"git", "default_prefix":"ascii", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Mod:", "emoji":"✏️", "nerd":"", "ascii":"~" } },
  "git_untracked": { "source":"git", "default_prefix":"ascii", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Untracked:", "emoji":"❓", "nerd":"", "ascii":"?" } },
  "git_ahead_behind": { "source":"git", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"AB:", "emoji":"⇅", "nerd":"", "ascii":"[AB]" } },
  "clock": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Time:", "emoji":"🕒", "nerd":"", "ascii":"[t]" } },
  "date": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Date:", "emoji":"📅", "nerd":"", "ascii":"[d]" } },
  "hostname": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Host:", "emoji":"🖥", "nerd":"", "ascii":"[h]" } },
  "user": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"User:", "emoji":"👤", "nerd":"", "ascii":"[u]" } },
  "battery": { "source":"os", "default_prefix":"emoji", "default_format":"percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"], "threshold_inverted":true,
             "prefix": { "none":"", "label":"Bat:", "emoji":"🔋", "nerd":"", "ascii":"[b]" } },
  "memory": { "source":"os", "default_prefix":"emoji", "default_format":"percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"],
             "prefix": { "none":"", "label":"Mem:", "emoji":"🧬", "nerd":"", "ascii":"[m]" } },
  "load": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Load:", "emoji":"📊", "nerd":"", "ascii":"[l]" } }
}
JSON

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
  # --dump-data is a test hook surfacing the embedded data tables.
  if [[ "${1:-}" == "--dump-data" ]]; then
    case "${2:-}" in
      themes)     jq -r 'keys_unsorted | join(" ")' <<<"$THEMES_JSON"; exit 0 ;;
      separators) jq -r 'keys_unsorted | join(" ")' <<<"$SEPARATORS_JSON"; exit 0 ;;
      bar_styles) jq -r 'keys_unsorted | join(" ")' <<<"$BAR_STYLES_JSON"; exit 0 ;;
      presets)    jq -r 'keys_unsorted | join(" ")' <<<"$PRESETS_JSON"; exit 0 ;;
      tokens)     jq -r 'keys_unsorted | join(" ")' <<<"$TOKENS_JSON"; exit 0 ;;
      token:*)
        local id="${2#token:}"
        jq -r --arg id "$id" '
          .[$id] | (
            "source=" + .source,
            "default_prefix=" + .default_prefix,
            "default_format=" + .default_format,
            "prefix.none=" + .prefix.none,
            "prefix.label=" + .prefix.label,
            "prefix.emoji=" + .prefix.emoji,
            "prefix.nerd=" + .prefix.nerd,
            "prefix.ascii=" + .prefix.ascii,
            "applicable=" + (.applicable_formats | join(","))
          )' <<<"$TOKENS_JSON"
        exit 0 ;;
      *) echo "unknown --dump-data kind: ${2:-}" >&2; exit 2 ;;
    esac
  fi
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
