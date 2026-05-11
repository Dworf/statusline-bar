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
  "braille":  { "fill":"⣿",   "empty":"⣀",   "gradient":false },
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
# SECTION: Embedded data — synthetic input for --examples
# ============================================================

read -r -d '' EXAMPLES_INPUT_JSON <<'JSON' || true
{
  "session_id": "browse001",
  "transcript_path": "/dev/null",
  "session_name": "Browse",
  "model": { "display_name": "Opus 4.7 (1M)" },
  "workspace": { "current_dir": "/tmp/x", "added_dirs": [] },
  "effort": { "level": "xhigh" },
  "thinking": { "enabled": true },
  "output_style": { "name": "default" },
  "version": "2.1.137",
  "fast_mode": false,
  "exceeds_200k_tokens": false,
  "worktree": { "name": "main" },
  "cost": {
    "total_cost_usd": 0.40,
    "total_duration_ms": 230000,
    "total_api_duration_ms": 39000,
    "total_lines_added": 128,
    "total_lines_removed": 42
  },
  "context_window": {
    "used_percentage": 50,
    "remaining_percentage": 50,
    "current_usage": {
      "input_tokens": 100,
      "output_tokens": 50,
      "cache_creation_input_tokens": 100,
      "cache_read_input_tokens": 9750
    }
  },
  "rate_limits": {
    "five_hour": { "used_percentage": 50, "resets_at": 9999999999 },
    "seven_day": { "used_percentage": 50, "resets_at": 9999999999 }
  }
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

# ============================================================
# SECTION: Capability detection
# ============================================================

detect_color_depth() {
  if [[ -n "${NO_COLOR:-}" ]]; then
    echo "none"; return
  fi
  case "${COLORTERM:-}" in
    truecolor|24bit) echo "truecolor"; return ;;
  esac
  local n
  n="$(tput colors 2>/dev/null || echo 0)"
  if   (( n >= 256 )); then echo "256"
  elif (( n >= 8 ));   then echo "16"
  else                       echo "none"
  fi
}

detect_nerd_font() {
  # Override hook for tests.
  if [[ -n "${STATUSLINE_BAR_FORCE_NERD:-}" ]]; then
    echo "$STATUSLINE_BAR_FORCE_NERD"; return
  fi
  if command -v fc-list >/dev/null 2>&1; then
    if fc-list 2>/dev/null | grep -qi 'nerd font'; then
      echo "yes"; return
    fi
    echo "no"; return
  fi
  case "$(uname -s)" in
    Darwin)
      if find ~/Library/Fonts /Library/Fonts /System/Library/Fonts \
           -maxdepth 3 \( -name '*Nerd*.ttf' -o -name '*Nerd*.otf' \) 2>/dev/null \
           | grep -q .; then
        echo "yes"; return
      fi
      echo "no"; return ;;
    Linux)
      if find ~/.local/share/fonts /usr/share/fonts /usr/local/share/fonts \
           -maxdepth 4 \( -name '*Nerd*.ttf' -o -name '*Nerd*.otf' \) 2>/dev/null \
           | grep -q .; then
        echo "yes"; return
      fi
      echo "no"; return ;;
    *) echo "unknown"; return ;;
  esac
}

# Hex "#rrggbb" → "r;g;b" decimal triple.
_hex_to_rgb() {
  local hex="${1#'#'}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf '%d;%d;%d' "$r" "$g" "$b"
}

# Hex → approximate xterm-256 cube index.
_hex_to_256() {
  local hex="${1#'#'}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf '%d' $(( 16 + 36 * (r * 5 / 255) + 6 * (g * 5 / 255) + (b * 5 / 255) ))
}

# Emit foreground SGR for COLOR at DEPTH. Empty if depth=none.
color_fg() {
  local color="$1" depth="$2"
  case "$depth" in
    none) return ;;
  esac
  case "$color" in
    bold)   printf '\033[1m'; return ;;
    dim)    printf '\033[2m'; return ;;
    normal) printf '\033[22m'; return ;;
  esac
  case "$depth" in
    truecolor) printf '\033[38;2;%sm' "$(_hex_to_rgb "$color")" ;;
    256)       printf '\033[38;5;%sm' "$(_hex_to_256 "$color")" ;;
    16)        printf '\033[37m' ;;
  esac
}

color_reset() {
  local depth="$1"
  case "$depth" in
    none) return ;;
    *) printf '\033[0m' ;;
  esac
}

# ============================================================
# SECTION: Startup theme cache
# ============================================================
# Prime THEME_<theme>_<field> shell vars in one jq pass. Bash 3.2: no
# associative arrays, so we use dynamic var names via eval.
_prime_caches() {
  local line
  while IFS= read -r line; do
    eval "$line"
  done < <(
    jq -r '
      to_entries[] as $t |
      ($t.value | to_entries[]) as $f |
      "THEME_" + ($t.key | gsub("-"; "_")) + "_" + $f.key + "=" + ($f.value | @sh)
    ' <<<"$THEMES_JSON"
  )
}
_prime_caches

# ============================================================
# SECTION: Format primitives
# ============================================================

# fmt_duration_ms <ms> → "<d>d <h>h <m>m <s>s" with leading-zero units dropped.
fmt_duration_ms() {
  local ms="$1"
  if [[ -z "$ms" || "$ms" -le 0 ]]; then echo "0s"; return; fi
  local total=$(( ms / 1000 ))
  local d=$(( total / 86400 ))
  local h=$(( (total % 86400) / 3600 ))
  local m=$(( (total % 3600) / 60 ))
  local s=$(( total % 60 ))
  if   (( d > 0 )); then echo "${d}d ${h}h ${m}m ${s}s"
  elif (( h > 0 )); then echo "${h}h ${m}m ${s}s"
  elif (( m > 0 )); then echo "${m}m ${s}s"
  else                    echo "${s}s"
  fi
}

# fmt_percent <num> → "N%" (rounded to integer).
fmt_percent() {
  local n="$1"
  awk -v v="$n" 'BEGIN { printf "%d%%", int((v+0) + 0.5) }'
}

# ============================================================
# SECTION: Progressbar
# ============================================================

_bar_fill_char()   { jq -r --arg s "$1" '.[$s].fill' <<<"$BAR_STYLES_JSON"; }
_bar_empty_char()  { jq -r --arg s "$1" '.[$s].empty' <<<"$BAR_STYLES_JSON"; }
_bar_is_gradient() { [[ "$(jq -r --arg s "$1" '.[$s].gradient' <<<"$BAR_STYLES_JSON")" == "true" ]]; }
_bar_eighth()      { jq -r --arg s "$1" --argjson i "$2" '.[$s].eighths[$i]' <<<"$BAR_STYLES_JSON"; }

# render_bar <pct> <style> <width> → bar string (no newline).
render_bar() {
  local pct="$1" style="${2:-blocks}" width="${3:-10}"
  if _bar_is_gradient "$style"; then
    local eighths
    eighths="$(awk -v p="$pct" -v w="$width" 'BEGIN { printf "%d", int((p*w*8/100) + 0.5) }')"
    if (( eighths < 0 )); then eighths=0; fi
    local max=$(( width * 8 ))
    if (( eighths > max )); then eighths="$max"; fi
    local full=$(( eighths / 8 ))
    local rem=$(( eighths % 8 ))
    local partial_count=$(( rem > 0 ? 1 : 0 ))
    local empty=$(( width - full - partial_count ))
    local i out=""
    for ((i=0; i<full; i++)); do out+="█"; done
    if (( rem > 0 )); then out+="$(_bar_eighth "$style" "$rem")"; fi
    for ((i=0; i<empty; i++)); do out+=" "; done
    printf '%s' "$out"
    return
  fi
  local filled
  filled="$(awk -v p="$pct" -v w="$width" 'BEGIN { printf "%d", int((p*w/100) + 0.5) }')"
  if (( filled < 0 )); then filled=0; fi
  if (( filled > width )); then filled="$width"; fi
  local empty=$(( width - filled ))
  local fchar echar i out=""
  fchar="$(_bar_fill_char "$style")"
  echar="$(_bar_empty_char "$style")"
  for ((i=0; i<filled; i++)); do out+="$fchar"; done
  for ((i=0; i<empty; i++)); do out+="$echar"; done
  printf '%s' "$out"
}

# ============================================================
# SECTION: Token renderers — Claude stdin
# ============================================================
# Each tok_<id> reads from global $INPUT_JSON and emits the raw value
# (no prefix, no format — those are applied by the composition layer).
# Empty/missing data → empty stdout.

tok_model()        { jq -r '.model.display_name // ""' <<<"$INPUT_JSON"; }
tok_session_name() { jq -r '.session_name // ""' <<<"$INPUT_JSON"; }
tok_effort()       { jq -r '.effort.level // ""' <<<"$INPUT_JSON"; }
tok_output_style() { jq -r '.output_style.name // ""' <<<"$INPUT_JSON"; }
tok_version()      { jq -r '.version // ""' <<<"$INPUT_JSON"; }
tok_dir() {
  local d
  d="$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$INPUT_JSON")"
  [[ -z "$d" ]] && return
  local root
  if root="$(cd "$d" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"; then
    basename "$root"
  else
    basename "$d"
  fi
}
tok_worktree() { jq -r '.worktree.name // ""' <<<"$INPUT_JSON"; }

# New in v0.1.0 — gap-analysis additions
tok_vim_mode()   { jq -r '.vim.mode // ""' <<<"$INPUT_JSON"; }
tok_agent_name() { jq -r '.agent.name // ""' <<<"$INPUT_JSON"; }
tok_session_id() {
  local s; s="$(jq -r '.session_id // ""' <<<"$INPUT_JSON")"
  [[ -z "$s" ]] && return
  printf '%s' "${s:0:8}"
}
tok_added_dirs() {
  jq -r '(.workspace.added_dirs // []) | length' <<<"$INPUT_JSON"
}
tok_git_worktree() { jq -r '.workspace.git_worktree // ""' <<<"$INPUT_JSON"; }
tok_transcript() {
  local p; p="$(jq -r '.transcript_path // ""' <<<"$INPUT_JSON")"
  [[ -z "$p" ]] && return
  basename "$p"
}

# Numeric / duration
tok_cost() {
  local c
  c="$(jq -r '.cost.total_cost_usd // empty' <<<"$INPUT_JSON")"
  [[ -z "$c" ]] && return
  awk -v v="$c" 'BEGIN { printf "$%.2f", v }'
}
tok_lines_added() {
  local n; n="$(jq -r '.cost.total_lines_added // empty' <<<"$INPUT_JSON")"
  [[ -z "$n" ]] && return
  printf '+%s' "$n"
}
tok_lines_removed() {
  local n; n="$(jq -r '.cost.total_lines_removed // empty' <<<"$INPUT_JSON")"
  [[ -z "$n" ]] && return
  printf -- '-%s' "$n"
}
tok_duration() {
  local ms; ms="$(jq -r '.cost.total_duration_ms // empty' <<<"$INPUT_JSON")"
  [[ -z "$ms" ]] && return
  fmt_duration_ms "$ms"
}
tok_api_duration() {
  local ms; ms="$(jq -r '.cost.total_api_duration_ms // empty' <<<"$INPUT_JSON")"
  [[ -z "$ms" ]] && return
  fmt_duration_ms "$ms"
}

# Percent tokens — emit raw integer (0-100); format applied by composition.
tok_context_pct() { jq -r '.context_window.used_percentage // empty' <<<"$INPUT_JSON"; }
tok_context_bar() { tok_context_pct; }
tok_cache_hit() {
  local r c i
  r="$(jq -r '.context_window.current_usage.cache_read_input_tokens // 0' <<<"$INPUT_JSON")"
  c="$(jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' <<<"$INPUT_JSON")"
  i="$(jq -r '.context_window.current_usage.input_tokens // 0' <<<"$INPUT_JSON")"
  local total=$(( r + c + i ))
  (( total <= 0 )) && return
  awk -v r="$r" -v t="$total" 'BEGIN { printf "%d", (r*100/t) }'
}

# Rate-limit tokens emit "pct|epoch"; composition parses.
tok_rl_5h() {
  local p e
  p="$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$INPUT_JSON")"
  e="$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$INPUT_JSON")"
  [[ -z "$p" || -z "$e" ]] && return
  printf '%s|%s' "$p" "$e"
}
tok_rl_7d() {
  local p e
  p="$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$INPUT_JSON")"
  e="$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$INPUT_JSON")"
  [[ -z "$p" || -z "$e" ]] && return
  printf '%s|%s' "$p" "$e"
}

# Flag tokens emit raw boolean string; composition translates to flag sentinel.
# Cannot use `// empty` because jq's // treats `false` as a fallback trigger,
# so we explicitly skip nulls and stringify the boolean.
tok_thinking()     { jq -r '.thinking.enabled     | if . == null then empty else tostring end' <<<"$INPUT_JSON"; }
tok_fast_mode()    { jq -r '.fast_mode            | if . == null then empty else tostring end' <<<"$INPUT_JSON"; }
tok_exceeds_200k() { jq -r '.exceeds_200k_tokens  | if . == null then empty else tostring end' <<<"$INPUT_JSON"; }

# ============================================================
# SECTION: Token renderers — git
# ============================================================

_git_workspace() {
  jq -r '.workspace.current_dir // .cwd // empty' <<<"$INPUT_JSON"
}
_git_check() {
  local d; d="$(_git_workspace)"
  [[ -z "$d" ]] && return 1
  ( cd "$d" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1 )
}

tok_git_branch() {
  _git_check || return
  local d; d="$(_git_workspace)"
  ( cd "$d" && git branch --show-current 2>/dev/null )
}
tok_git_staged() {
  _git_check || return
  local d; d="$(_git_workspace)"
  ( cd "$d" && git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ' )
}
tok_git_modified() {
  _git_check || return
  local d; d="$(_git_workspace)"
  ( cd "$d" && git diff --numstat 2>/dev/null | wc -l | tr -d ' ' )
}
tok_git_untracked() {
  _git_check || return
  local d; d="$(_git_workspace)"
  ( cd "$d" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ' )
}
tok_git_status() {
  _git_check || return
  printf '+%s|~%s|?%s' "$(tok_git_staged)" "$(tok_git_modified)" "$(tok_git_untracked)"
}
tok_git_ahead_behind() {
  _git_check || return
  local d; d="$(_git_workspace)"
  local raw a b
  raw="$( cd "$d" && git rev-list --left-right --count @{u}...HEAD 2>/dev/null )"
  [[ -z "$raw" ]] && return
  a="$(echo "$raw" | awk '{print $1}')"
  b="$(echo "$raw" | awk '{print $2}')"
  printf '↑%s ↓%s' "$b" "$a"
}

# ============================================================
# SECTION: Token renderers — OS
# ============================================================

tok_clock() {
  local now="${STATUSLINE_BAR_FAKE_NOW:-$(date +%s)}"
  TZ=UTC date -r "$now" '+%H:%M' 2>/dev/null || TZ=UTC date -d "@$now" '+%H:%M' 2>/dev/null
}
tok_date() {
  local now="${STATUSLINE_BAR_FAKE_NOW:-$(date +%s)}"
  TZ=UTC date -r "$now" '+%Y-%m-%d' 2>/dev/null || TZ=UTC date -d "@$now" '+%Y-%m-%d' 2>/dev/null
}
tok_hostname() {
  if [[ -n "${HOSTNAME_OVERRIDE:-}" ]]; then echo "$HOSTNAME_OVERRIDE"; return; fi
  hostname -s 2>/dev/null || hostname 2>/dev/null
}
tok_user() {
  echo "${USER:-$(id -un 2>/dev/null)}"
}
tok_battery() {
  [[ -n "${STATUSLINE_BAR_FORCE_NO_BATTERY:-}" ]] && return
  [[ -n "${STATUSLINE_BAR_FAKE_BATTERY:-}" ]] && { echo "$STATUSLINE_BAR_FAKE_BATTERY"; return; }
  case "$(uname -s)" in
    Darwin)
      pmset -g batt 2>/dev/null | awk '/[0-9]+%/ { gsub(/[%;]/,"",$3); print $3; exit }' ;;
    Linux)
      local f
      for f in /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT1/capacity; do
        if [[ -r "$f" ]]; then cat "$f"; return; fi
      done ;;
  esac
}
tok_memory() {
  [[ -n "${STATUSLINE_BAR_FORCE_NO_MEMORY:-}" ]] && return
  [[ -n "${STATUSLINE_BAR_FAKE_MEMORY:-}" ]] && { echo "$STATUSLINE_BAR_FAKE_MEMORY"; return; }
  case "$(uname -s)" in
    Darwin)
      vm_stat 2>/dev/null | awk '
        /Pages free/         { f=$3 }
        /Pages inactive/     { i=$3 }
        /Pages active/       { a=$3 }
        /Pages speculative/  { s=$3 }
        /Pages wired down/   { w=$4 }
        END {
          gsub(/\./,"",f); gsub(/\./,"",i); gsub(/\./,"",a); gsub(/\./,"",s); gsub(/\./,"",w)
          total=f+i+a+s+w
          if (total==0) exit
          used=a+w+s
          printf "%d", used*100/total
        }' ;;
    Linux)
      awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END { if (t>0) printf "%d", (t-a)*100/t }' /proc/meminfo 2>/dev/null ;;
  esac
}
tok_load() {
  [[ -n "${STATUSLINE_BAR_FORCE_NO_LOAD:-}" ]] && return
  [[ -n "${STATUSLINE_BAR_FAKE_LOAD:-}" ]] && { echo "$STATUSLINE_BAR_FAKE_LOAD"; return; }
  case "$(uname -s)" in
    Darwin) sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}' ;;
    Linux)  awk '{print $1}' /proc/loadavg 2>/dev/null ;;
  esac
}

# ============================================================
# SECTION: Format dispatcher
# ============================================================

# apply_format <id> <fmt> <raw> <bar_style> <bar_width> <now_epoch>
apply_format() {
  local id="$1" fmt="$2" raw="$3" bar_style="$4" bar_width="$5" now="$6"
  case "$fmt" in
    value) printf '%s' "$raw" ;;
    percent)
      [[ -z "$raw" ]] && return
      local p="${raw%%|*}"
      fmt_percent "$p" ;;
    progressbar)
      [[ -z "$raw" ]] && return
      local p="${raw%%|*}"
      render_bar "$p" "$bar_style" "$bar_width" ;;
    "progressbar+percent")
      [[ -z "$raw" ]] && return
      local p="${raw%%|*}"
      printf '%s %s' "$(render_bar "$p" "$bar_style" "$bar_width")" "$(fmt_percent "$p")" ;;
    countdown)
      [[ -z "$raw" ]] && return
      local r="${raw##*|}"
      local diff=$(( r - now ))
      (( diff < 0 )) && diff=0
      fmt_duration_ms $(( diff * 1000 )) ;;
    remaining)
      [[ -z "$raw" ]] && return
      local r="${raw##*|}"
      local diff=$(( r - now ))
      (( diff < 0 )) && diff=0
      printf 'in %s' "$(fmt_duration_ms $(( diff * 1000 )))" ;;
    "progressbar+percent+countdown")
      [[ -z "$raw" ]] && return
      local p="${raw%%|*}" r="${raw##*|}"
      local diff=$(( r - now ))
      (( diff < 0 )) && diff=0
      printf '%s %s 🔄 %s' \
        "$(render_bar "$p" "$bar_style" "$bar_width")" \
        "$(fmt_percent "$p")" \
        "$(fmt_duration_ms $(( diff * 1000 )))" ;;
    combined)
      # git_status: "+s|~m|?u" → "+s ~m ?u"
      [[ -z "$raw" ]] && return
      printf '%s' "$raw" | tr '|' ' ' ;;
    flag)
      if [[ "$raw" == "true" ]]; then printf '__FLAG_ON__'; fi ;;
    *) printf '%s' "$raw" ;;
  esac
}

# ============================================================
# SECTION: Prefix dispatcher
# ============================================================

apply_prefix() {
  local id="$1" style="$2" value="$3"
  case "$style" in
    none) printf '%s' "$value" ;;
    label|emoji|nerd|ascii)
      local p
      p="$(jq -r --arg id "$id" --arg s "$style" '.[$id].prefix[$s]' <<<"$TOKENS_JSON")"
      if [[ -z "$p" ]]; then printf '%s' "$value"
      else printf '%s %s' "$p" "$value"
      fi ;;
    emoji+label)
      local pe pl
      pe="$(jq -r --arg id "$id" '.[$id].prefix.emoji' <<<"$TOKENS_JSON")"
      pl="$(jq -r --arg id "$id" '.[$id].prefix.label' <<<"$TOKENS_JSON")"
      printf '%s %s %s' "$pe" "$pl" "$value" ;;
    label+emoji)
      local pe pl
      pe="$(jq -r --arg id "$id" '.[$id].prefix.emoji' <<<"$TOKENS_JSON")"
      pl="$(jq -r --arg id "$id" '.[$id].prefix.label' <<<"$TOKENS_JSON")"
      pl="${pl%:}"
      printf '%s %s %s' "$pl" "$pe" "$value" ;;
    nerd+label)
      local pn pl
      pn="$(jq -r --arg id "$id" '.[$id].prefix.nerd' <<<"$TOKENS_JSON")"
      pl="$(jq -r --arg id "$id" '.[$id].prefix.label' <<<"$TOKENS_JSON")"
      printf '%s %s %s' "$pn" "$pl" "$value" ;;
    *) printf '%s' "$value" ;;
  esac
}

# ============================================================
# SECTION: Config loader / writer / validator
# ============================================================

# Build the default config JSON from PRESETS_JSON (default preset's lines).
build_default_config() {
  local lines_json
  lines_json="$(jq -c '.default.lines' <<<"$PRESETS_JSON")"
  jq -n --argjson lines "$lines_json" '{
    "$schema": "https://raw.githubusercontent.com/Dworf/statusline-bar/main/schema.json",
    version: 1,
    preset: "default",
    theme: "default",
    global: {
      prefix_style: "emoji",
      separator: "pipe",
      bar_style: null,
      color_depth: "auto",
      empty_behavior: "hide",
      placeholder: "—",
      bar_width: 10
    },
    lines: $lines,
    tokens: {}
  }'
}

# Resolve the default-write path: $XDG_CONFIG_HOME/... if set, else ~/.config/...
_default_config_path() {
  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    echo "$XDG_CONFIG_HOME/statusline-bar/config.json"
  else
    echo "$HOME/.config/statusline-bar/config.json"
  fi
}

# Resolve & load config into $CONFIG_JSON; set $CONFIG_PATH if file-backed.
load_config() {
  local p
  # Precedence: --config → env → project-local → XDG → HOME → defaults.
  if [[ -n "${CONFIG_PATH:-}" && -f "$CONFIG_PATH" ]]; then
    p="$CONFIG_PATH"
  elif [[ -n "${STATUSLINE_BAR_CONFIG:-}" && -f "$STATUSLINE_BAR_CONFIG" ]]; then
    p="$STATUSLINE_BAR_CONFIG"
  else
    local ws=""
    if [[ -n "${INPUT_JSON:-}" ]]; then
      ws="$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$INPUT_JSON" 2>/dev/null)"
    fi
    [[ -z "$ws" ]] && ws="$PWD"
    if [[ -f "$ws/.statusline-bar.json" ]]; then
      p="$ws/.statusline-bar.json"
    elif [[ -n "${XDG_CONFIG_HOME:-}" && -f "$XDG_CONFIG_HOME/statusline-bar/config.json" ]]; then
      p="$XDG_CONFIG_HOME/statusline-bar/config.json"
    elif [[ -f "$HOME/.config/statusline-bar/config.json" ]]; then
      p="$HOME/.config/statusline-bar/config.json"
    fi
  fi
  if [[ -n "${p:-}" ]]; then
    CONFIG_PATH="$p"
    if ! CONFIG_JSON="$(jq '.' "$p" 2>/dev/null)"; then
      echo "statusline-bar: config parse error at $p — using defaults" >&2
      CONFIG_JSON="$(build_default_config)"
      CONFIG_PATH=""
    fi
  else
    CONFIG_JSON="$(build_default_config)"
    CONFIG_PATH=""
  fi
}

# Persist JSON to disk, creating parent dirs.
save_config() {
  local path="$1" json="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$json" > "$path"
}

# Validate config. Returns 0 if valid, 1 if invalid (with stderr message).
check_config() {
  local p="${CONFIG_PATH:-}"
  if [[ -n "$p" ]]; then
    if ! jq '.' "$p" >/dev/null 2>&1; then
      echo "check: config parse error in $p"
      return 1
    fi
  fi
  load_config
  local theme; theme="$(jq -r '.theme // ""' <<<"$CONFIG_JSON")"
  local valid_themes="default dark light graphite solarized dracula nord gruvbox tokyo-night catppuccin"
  if ! grep -qw "$theme" <<<"$valid_themes"; then
    echo "check: unknown theme \"$theme\""
    return 1
  fi
  local preset; preset="$(jq -r '.preset // ""' <<<"$CONFIG_JSON")"
  local valid_presets="minimum compact default modern fancy everything maximum"
  if [[ -n "$preset" && "$preset" != "null" ]] && ! grep -qw "$preset" <<<"$valid_presets"; then
    echo "check: unknown preset \"$preset\" (expected: $(echo $valid_presets | tr ' ' ', '))"
    return 1
  fi
  local i n id valid_ids
  valid_ids="$(jq -r 'keys_unsorted | join(" ")' <<<"$TOKENS_JSON")"
  n="$(jq -r '.lines | length' <<<"$CONFIG_JSON")"
  for ((i=0; i<n; i++)); do
    while IFS= read -r id; do
      if ! grep -qw "$id" <<<"$valid_ids"; then
        echo "check: unknown token \"$id\" in lines[$i]"
        return 1
      fi
    done < <( jq -r --argjson i "$i" '.lines[$i][]?' <<<"$CONFIG_JSON" )
  done
  return 0
}

# ============================================================
# SECTION: render_token
# ============================================================
# Globals expected:
#   INPUT_JSON, CONFIG_JSON, COLOR_DEPTH, NOW_EPOCH
# render_token <id> → final colored, prefixed, formatted string (or empty).

# _theme_var <theme> <field> → contents of THEME_<sanitized_theme>_<field>.
_theme_var() {
  local t="${1//-/_}" f="$2" v
  eval "v=\${THEME_${t}_${f}:-}"
  printf '%s' "$v"
}

_threshold_color() {
  local id="$1" raw="$2" theme="$3"
  local pct
  case "$id" in
    context_pct|context_bar|cache_hit|rl_5h|rl_7d)
      pct="${raw%%|*}"
      pct="$(awk -v v="$pct" 'BEGIN{printf "%d", v+0}')"
      if   (( pct >= 90 )); then _theme_var "$theme" crit
      elif (( pct >= 70 )); then _theme_var "$theme" warn
      else                       _theme_var "$theme" good
      fi ;;
    battery)
      pct="$(awk -v v="$raw" 'BEGIN{printf "%d", v+0}')"
      if   (( pct < 20 )); then _theme_var "$theme" crit
      elif (( pct < 50 )); then _theme_var "$theme" warn
      else                      _theme_var "$theme" good
      fi ;;
    memory)
      pct="$(awk -v v="$raw" 'BEGIN{printf "%d", v+0}')"
      if   (( pct >= 95 )); then _theme_var "$theme" crit
      elif (( pct >= 80 )); then _theme_var "$theme" warn
      else                       _theme_var "$theme" good
      fi ;;
    *) _theme_var "$theme" accent ;;
  esac
}

render_token() {
  local id="$1"
  local theme prefix_style format bar_style bar_width preset
  theme="$(jq -r '.theme' <<<"$CONFIG_JSON")"
  preset="$(jq -r '.preset // ""' <<<"$CONFIG_JSON")"
  prefix_style="$(jq -r --arg id "$id" '.tokens[$id].prefix // .global.prefix_style' <<<"$CONFIG_JSON")"
  bar_width="$(jq -r '.global.bar_width // 10' <<<"$CONFIG_JSON")"

  # Format precedence: per-token override > preset's token_formats > token default.
  format="$(jq -r --arg id "$id" '.tokens[$id].format // empty' <<<"$CONFIG_JSON")"
  if [[ -z "$format" && -n "$preset" && "$preset" != "null" ]]; then
    format="$(jq -r --arg id "$id" --arg p "$preset" '.[$p].token_formats[$id] // empty' <<<"$PRESETS_JSON")"
  fi
  if [[ -z "$format" ]]; then
    format="$(jq -r --arg id "$id" '.[$id].default_format' <<<"$TOKENS_JSON")"
  fi

  # Bar style precedence: per-token > global > theme suggestion.
  bar_style="$(jq -r --arg id "$id" '.tokens[$id].bar_style // .global.bar_style // ""' <<<"$CONFIG_JSON")"
  if [[ -z "$bar_style" || "$bar_style" == "null" ]]; then
    bar_style="$(_theme_var "$theme" bar_style)"
  fi

  local raw; raw="$("tok_${id}")"

  local empty_behavior placeholder
  empty_behavior="$(jq -r '.global.empty_behavior // "hide"' <<<"$CONFIG_JSON")"
  placeholder="$(jq -r '.global.placeholder // "—"' <<<"$CONFIG_JSON")"
  if [[ -z "$raw" ]]; then
    if [[ "$empty_behavior" == "hide" ]]; then return; fi
    raw="$placeholder"
    format="value"
  fi

  local body
  body="$(apply_format "$id" "$format" "$raw" "$bar_style" "$bar_width" "$NOW_EPOCH")"

  if [[ "$body" == "__FLAG_ON__" ]]; then
    body=""
  elif [[ -z "$body" && "$format" == "flag" ]]; then
    return
  fi

  local color_token color_esc reset with_prefix
  color_token="$(_threshold_color "$id" "$raw" "$theme")"
  color_esc="$(color_fg "$color_token" "$COLOR_DEPTH")"
  reset="$(color_reset "$COLOR_DEPTH")"
  if [[ -z "$body" ]]; then
    with_prefix="$(apply_prefix "$id" "$prefix_style" "")"
    with_prefix="${with_prefix% }"
  else
    with_prefix="$(apply_prefix "$id" "$prefix_style" "$body")"
  fi
  printf '%s%s%s' "$color_esc" "$with_prefix" "$reset"
}

# ============================================================
# SECTION: render_line / render_all
# ============================================================

_sep_chars() {
  jq -r --arg id "$1" '.[$id].chars // " "' <<<"$SEPARATORS_JSON"
}

render_line() {
  local idx="$1"
  local ids tok i count
  ids=()
  while IFS= read -r tok; do ids+=("$tok"); done < <(
    jq -r --argjson i "$idx" '.lines[$i][]?' <<<"$CONFIG_JSON"
  )
  count=${#ids[@]}
  (( count == 0 )) && return
  local global_sep_id global_sep
  global_sep_id="$(jq -r '.global.separator // "pipe"' <<<"$CONFIG_JSON")"
  global_sep="$(_sep_chars "$global_sep_id")"

  local rendered=() out
  for ((i=0; i<count; i++)); do
    out="$(render_token "${ids[$i]}")"
    rendered+=("$out")
  done

  local result="" prev_visible=0
  for ((i=0; i<count; i++)); do
    local body="${rendered[$i]}"
    [[ -z "$body" ]] && continue
    if (( prev_visible )); then
      local prev_id_for_sep="" k
      for ((k=i-1; k>=0; k--)); do
        if [[ -n "${rendered[$k]}" ]]; then prev_id_for_sep="${ids[$k]}"; break; fi
      done
      local sep_id sep
      sep_id="$(jq -r --arg id "$prev_id_for_sep" '.tokens[$id].separator_after // empty' <<<"$CONFIG_JSON")"
      if [[ -n "$sep_id" && "$sep_id" != "null" ]]; then sep="$(_sep_chars "$sep_id")"
      else sep="$global_sep"
      fi
      result+="$sep"
    fi
    result+="$body"
    prev_visible=1
  done
  printf '%s' "$result"
}

render_all() {
  local n; n="$(jq -r '.lines | length' <<<"$CONFIG_JSON")"
  local i first=1
  for ((i=0; i<n; i++)); do
    if (( first )); then first=0; else printf '\n'; fi
    render_line "$i"
  done
}

# ============================================================
# SECTION: TUI primitives
# ============================================================

tui_init() {
  tput smcup        # alternate screen
  tput civis        # hide cursor
  stty -echo 2>/dev/null
  trap tui_cleanup EXIT INT TERM
}
tui_cleanup() {
  tput rmcup 2>/dev/null || true
  tput cnorm 2>/dev/null || true
  stty echo 2>/dev/null || true
}
tui_clear() { tput clear; tput cup 0 0; }

# Read one key. Sets $KEY to a logical name:
#   up, down, left, right, enter, esc, char:<X>, save, reset, quit, backspace
tui_read_key() {
  local ch
  IFS= read -rsn1 ch
  case "$ch" in
    "") KEY=enter; return ;;
    $'\x1b')
      local rest
      if IFS= read -rsn2 -t 0.05 rest; then
        case "$rest" in
          "[A") KEY=up;    return ;;
          "[B") KEY=down;  return ;;
          "[C") KEY=right; return ;;
          "[D") KEY=left;  return ;;
        esac
      fi
      KEY=esc; return ;;
    $'\x7f') KEY=backspace; return ;;
    s|S) KEY=save; return ;;
    r|R) KEY=reset; return ;;
    q|Q) KEY=quit; return ;;
    *) KEY="char:$ch"; return ;;
  esac
}

# ============================================================
# SECTION: Wizard
# ============================================================

WIZARD_STACK=()
WIZARD_CURSOR_STACK=()
WIZARD_CURSOR=0
WIZARD_DIRTY=0
WIZARD_TUI_SCRIPT=""
WIZARD_COLOR_DEPTH="none"

_wiz_next_key() {
  # OPT_TUI_SCRIPT (set once by the parser) signals scripted mode. WIZARD_TUI_SCRIPT
  # is the consumable buffer — checking it here would block on tui_read_key once
  # the script is exhausted, instead of cleanly exiting.
  if [[ -n "${OPT_TUI_SCRIPT:-}" ]]; then
    local c="${WIZARD_TUI_SCRIPT:0:1}"
    WIZARD_TUI_SCRIPT="${WIZARD_TUI_SCRIPT:1}"
    # Single-char protocol for scripted input (tests):
    #   D=down  U=up  L=left  R=right  \n=enter
    #   s=save  r=reset  q=quit  ESC=esc
    case "$c" in
      q) KEY=quit ;;
      s) KEY=save ;;
      r) KEY=reset ;;
      D) KEY=down ;;
      U) KEY=up ;;
      L) KEY=left ;;
      R) KEY=right ;;
      $'\n') KEY=enter ;;
      $'\x1b') KEY=esc ;;
      "") KEY=quit ;;
      *) KEY="char:$c" ;;
    esac
    return
  fi
  tui_read_key
}

_wiz_top() {
  echo "${WIZARD_STACK[$(( ${#WIZARD_STACK[@]} - 1 ))]}"
}
# Push a new screen onto the stack. Saves the current cursor position;
# the new cursor defaults to 0 unless an initial value is provided.
_wiz_push() {
  WIZARD_STACK+=("$1")
  WIZARD_CURSOR_STACK+=("$WIZARD_CURSOR")
  WIZARD_CURSOR="${2:-0}"
}
# Pop back, restoring the cursor position from before the push. We rebuild
# the arrays via slice (rather than `unset arr[i]`) because bash 3.2 leaves
# sparse holes after unset and ${#arr[@]} stops matching the highest index.
_wiz_pop() {
  local n=${#WIZARD_STACK[@]}
  if (( n > 0 )); then
    WIZARD_STACK=("${WIZARD_STACK[@]:0:n-1}")
  fi
  local m=${#WIZARD_CURSOR_STACK[@]}
  if (( m > 0 )); then
    WIZARD_CURSOR="${WIZARD_CURSOR_STACK[$((m-1))]:-0}"
    WIZARD_CURSOR_STACK=("${WIZARD_CURSOR_STACK[@]:0:m-1}")
  else
    WIZARD_CURSOR=0
  fi
}

# Return the index of $2 in array named $1, or 0 if not found.
_index_of() {
  local arr_name="$1" needle="$2"
  local size; eval "size=\${#${arr_name}[@]}"
  local i v
  for ((i=0; i<size; i++)); do
    eval "v=\${${arr_name}[$i]}"
    if [[ "$v" == "$needle" ]]; then echo "$i"; return; fi
  done
  echo 0
}

# Render a one-line preview using the current $CONFIG_JSON (used by main menu).
_wiz_preview_line() {
  INPUT_JSON="$EXAMPLES_INPUT_JSON" \
    COLOR_DEPTH="$WIZARD_COLOR_DEPTH" \
    NOW_EPOCH=9999999999 \
    MOCK_GIT_STATE=out_of_repo \
    render_all
}

# Render a preview with a hypothetical config mutation applied. Used by
# selection screens so the preview reflects the currently-focused option.
# Args:
#   $1 = jq mutation expression (uses $v and optionally $presets)
#   $2 = value to substitute for $v
_wiz_preview_with() {
  local mutation="$1" v="$2"
  local cfg
  if [[ "$v" == "(theme default)" ]]; then
    cfg="$(jq '.global.bar_style=null' <<<"$CONFIG_JSON")"
  else
    cfg="$(jq --arg v "$v" --argjson presets "$PRESETS_JSON" "$mutation" <<<"$CONFIG_JSON")"
  fi
  INPUT_JSON="$EXAMPLES_INPUT_JSON" \
    CONFIG_JSON="$cfg" \
    COLOR_DEPTH="$WIZARD_COLOR_DEPTH" \
    NOW_EPOCH=9999999999 \
    MOCK_GIT_STATE=out_of_repo \
    render_all
}

_wiz_draw_main() {
  tui_clear
  local theme preset prefix sep bar lines
  theme="$(jq -r '.theme' <<<"$CONFIG_JSON")"
  preset="$(jq -r '.preset // "(custom)"' <<<"$CONFIG_JSON")"
  prefix="$(jq -r '.global.prefix_style' <<<"$CONFIG_JSON")"
  sep="$(jq -r '.global.separator' <<<"$CONFIG_JSON")"
  bar="$(jq -r '.global.bar_style // "(theme default)"' <<<"$CONFIG_JSON")"
  lines="$(jq -r '.lines | length' <<<"$CONFIG_JSON")"

  printf '  statusline-bar ▸ Main\n\n'
  local items=("Preset" "Theme" "Prefix style" "Separator" "Bar style" "Lines" "Tokens" "Empty data" "Color depth")
  local vals=("$preset" "$theme" "$prefix" "$sep" "$bar" "$lines lines" "39 tokens" "$(jq -r '.global.empty_behavior // "hide"' <<<"$CONFIG_JSON")" "$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")")
  local i
  for ((i=0; i<${#items[@]}; i++)); do
    if (( i == WIZARD_CURSOR )); then printf '› '; else printf '  '; fi
    printf '%-14s  [%s]\n' "${items[$i]}" "${vals[$i]}"
  done
  printf '\n  Save (s)  Reset (r)  Quit (q)\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  Preview:\n'
  _wiz_preview_line
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  ↑↓ navigate   Enter select   Esc back   s save   r reset   q quit\n'
}

_wiz_handle_main() {
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=8; fi ;;
    down)
      if (( WIZARD_CURSOR < 8 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter|right)
      # Initial cursor in the submenu = index of currently-selected value.
      local cur
      case "$WIZARD_CURSOR" in
        0) cur="$(jq -r '.preset // ""' <<<"$CONFIG_JSON")"
           _wiz_push preset    "$(_index_of _PRESETS    "$cur")" ;;
        1) cur="$(jq -r '.theme' <<<"$CONFIG_JSON")"
           _wiz_push theme     "$(_index_of _THEMES     "$cur")" ;;
        2) cur="$(jq -r '.global.prefix_style' <<<"$CONFIG_JSON")"
           _wiz_push prefix    "$(_index_of _PREFIXES   "$cur")" ;;
        3) cur="$(jq -r '.global.separator' <<<"$CONFIG_JSON")"
           _wiz_push separator "$(_index_of _SEPARATORS "$cur")" ;;
        4) cur="$(jq -r '.global.bar_style // ""' <<<"$CONFIG_JSON")"
           # null/empty bar_style → focus the synthetic "(theme default)" row (index 0)
           if [[ -z "$cur" || "$cur" == "null" ]]; then
             _wiz_push bar 0
           else
             _wiz_push bar "$(_index_of _BARS "$cur")"
           fi ;;
        5) _wiz_push lines ;;
        6) _wiz_push tokens ;;
        7) cur="$(jq -r '.global.empty_behavior // "hide"' <<<"$CONFIG_JSON")"
           _wiz_push empty     "$(_index_of _EMPTY      "$cur")" ;;
        8) cur="$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")"
           _wiz_push depth     "$(_index_of _DEPTH      "$cur")" ;;
      esac ;;
  esac
}

# Generic selection-screen helper used by preset/theme/prefix/sep/bar/empty/depth.
# Args: <title> <items-array-name> <current-getter-jq-expr> <jq-set-fn-name>
# This is too unwieldy to factor cleanly in bash 3.2 — we inline each screen below.

_wiz_draw_select() {  # title, current_value, mutation, examples-array-name, items[]...
  local title="$1" cur="$2" mutation="$3" ex_arr="$4"; shift 4
  local items=("$@")
  tui_clear
  printf '  statusline-bar ▸ %s\n\n' "$title"
  local i name marker is_current ex
  for ((i=0; i<${#items[@]}; i++)); do
    name="${items[$i]}"
    marker="  "
    (( i == WIZARD_CURSOR )) && marker="› "
    is_current=0
    if [[ "$name" == "$cur" ]]; then
      is_current=1
    elif [[ "${name#\(}" != "$name" && ( "$cur" == "null" || -z "$cur" ) ]]; then
      is_current=1
    fi
    if (( is_current )); then marker+="● "; else marker+="  "; fi
    # Right-side per-item example (parallel array, if provided)
    ex=""
    if [[ -n "$ex_arr" ]]; then
      eval "ex=\${${ex_arr}[$i]:-}"
    fi
    if [[ -n "$ex" ]]; then
      printf '%s%-16s  %s\n' "$marker" "$name" "$ex"
    else
      printf '%s%s\n' "$marker" "$name"
    fi
  done
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  Preview (focused: %s):\n' "${items[$WIZARD_CURSOR]}"
  _wiz_preview_with "$mutation" "${items[$WIZARD_CURSOR]}"
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  ↑↓ navigate (wraps)   Enter select   Esc back   q quit\n'
}

# Each selection screen is wrapped as a small draw+handle pair using a shared list.
_PRESETS=(minimum compact default modern fancy everything maximum)
_THEMES=(default dark light graphite solarized dracula nord gruvbox tokyo-night catppuccin)
_PREFIXES=(none label emoji nerd ascii emoji+label label+emoji nerd+label)
_SEPARATORS=(space pipe slash dot vbar dash bullet diamond arrow tri star sparkle gear check heart music chevron slant chevron_thin)
_BARS=("(theme default)" blocks heavy line braille dots arrows ascii gradient)
_EMPTY=(hide placeholder)
_DEPTH=(auto truecolor 256 16 none)

# Per-item examples shown on the right side of each selection screen.
# Parallel to the data arrays above.

_PRESETS_EX=(
  "1 line · 3 tokens"
  "1 line · 6 tokens"
  "2 lines · 13 tokens"
  "2 lines · 9 tokens"
  "3 lines · 11 tokens"
  "4 lines · 29 tokens"
  "4 lines · 29 tokens (detailed)"
)

_PREFIXES_EX=(
  "Opus"
  "Model: Opus"
  "🤖 Opus"
  " Opus"
  "[M] Opus"
  "🤖 Model: Opus"
  "Model 🤖 Opus"
  " Model: Opus"
)

_SEPARATORS_EX=(
  "a  b  c"
  "a | b | c"
  "a / b / c"
  "a · b · c"
  "a │ b │ c"
  "a ─ b ─ c"
  "a • b • c"
  "a ◆ b ◆ c"
  "a ▸ b ▸ c"
  "a ▶ b ▶ c"
  "a ★ b ★ c"
  "a ✦ b ✦ c"
  "a ⚙ b ⚙ c"
  "a ✓ b ✓ c"
  "a ♥ b ♥ c"
  "a ♪ b ♪ c"
  "a  b  c (needs Nerd Font)"
  "a  b  c (needs Nerd Font)"
  "a  b  c (needs Nerd Font)"
)

_BARS_EX=(
  ""
  "█████░░░░░"
  "▰▰▰▰▰▱▱▱▱▱"
  "━━━━━─────"
  "⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀"
  "●●●●●○○○○○"
  "▶▶▶▶▶▷▷▷▷▷"
  "#####....."
  "█████     "
)

_EMPTY_EX=(
  "🤖 Opus | 💰 \$0.40        (empty tokens dropped)"
  "🤖 Opus | — | 💰 \$0.40   (empty tokens become —)"
)

_DEPTH_EX=(
  "auto-detect (recommended)"
  "24-bit RGB"
  "8-bit cube"
  "basic ANSI"
  "no color"
)

# Build inline theme color swatches dynamically (one per _THEMES entry).
# Run once at wizard start so we don't pay color_fg overhead per redraw.
_THEMES_EX=()
_build_theme_examples() {
  _THEMES_EX=()
  local t good warn crit reset
  reset="$(color_reset "$WIZARD_COLOR_DEPTH")"
  for t in "${_THEMES[@]}"; do
    local s="${t//-/_}"
    eval "good=\$THEME_${s}_good"
    eval "warn=\$THEME_${s}_warn"
    eval "crit=\$THEME_${s}_crit"
    _THEMES_EX+=( "$(color_fg "$good" "$WIZARD_COLOR_DEPTH")●${reset} $(color_fg "$warn" "$WIZARD_COLOR_DEPTH")●${reset} $(color_fg "$crit" "$WIZARD_COLOR_DEPTH")●${reset}" )
  done
}

_wiz_select_handle() {  # items_array_name jq_set_expression
  local arr_name="$1" set_expr="$2"
  local size; eval "size=\${#${arr_name}[@]}"
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$((size-1)); fi ;;
    down)
      if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter)
      local v
      eval "v=\${${arr_name}[$WIZARD_CURSOR]}"
      if [[ "$v" == "(theme default)" ]]; then
        CONFIG_JSON="$(jq '.global.bar_style=null' <<<"$CONFIG_JSON")"
      else
        CONFIG_JSON="$(jq --arg v "$v" "$set_expr" <<<"$CONFIG_JSON")"
      fi
      WIZARD_DIRTY=1
      _wiz_pop ;;
    esc|left) _wiz_pop ;;
  esac
}

_wiz_draw_preset() {
  local cur; cur="$(jq -r '.preset // ""' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Preset" "$cur" '.preset=$v | .lines=$presets[$v].lines' _PRESETS_EX "${_PRESETS[@]}"
}
_wiz_handle_preset() {
  local size=${#_PRESETS[@]}
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$((size-1)); fi ;;
    down)
      if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter)
      local v="${_PRESETS[$WIZARD_CURSOR]}"
      CONFIG_JSON="$(jq --arg p "$v" --argjson presets "$PRESETS_JSON" \
        '.preset=$p | .lines=$presets[$p].lines' <<<"$CONFIG_JSON")"
      WIZARD_DIRTY=1; _wiz_pop ;;
    esc|left) _wiz_pop ;;
  esac
}

_wiz_draw_theme() {
  local cur; cur="$(jq -r '.theme' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Theme" "$cur" '.theme=$v' _THEMES_EX "${_THEMES[@]}"
}
_wiz_handle_theme() { _wiz_select_handle _THEMES '.theme=$v'; }

_wiz_draw_prefix() {
  local cur; cur="$(jq -r '.global.prefix_style' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Prefix style" "$cur" '.global.prefix_style=$v' _PREFIXES_EX "${_PREFIXES[@]}"
}
_wiz_handle_prefix() { _wiz_select_handle _PREFIXES '.global.prefix_style=$v'; }

_wiz_draw_separator() {
  local cur; cur="$(jq -r '.global.separator' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Separator" "$cur" '.global.separator=$v' _SEPARATORS_EX "${_SEPARATORS[@]}"
}
_wiz_handle_separator() { _wiz_select_handle _SEPARATORS '.global.separator=$v'; }

_wiz_draw_bar() {
  local cur; cur="$(jq -r '.global.bar_style // ""' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Bar style" "$cur" '.global.bar_style=$v' _BARS_EX "${_BARS[@]}"
}
_wiz_handle_bar() { _wiz_select_handle _BARS '.global.bar_style=$v'; }

_wiz_draw_empty() {
  local cur; cur="$(jq -r '.global.empty_behavior // "hide"' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Empty data" "$cur" '.global.empty_behavior=$v' _EMPTY_EX "${_EMPTY[@]}"
}
_wiz_handle_empty() { _wiz_select_handle _EMPTY '.global.empty_behavior=$v'; }

_wiz_draw_depth() {
  local cur; cur="$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Color depth" "$cur" '.global.color_depth=$v' _DEPTH_EX "${_DEPTH[@]}"
}
_wiz_handle_depth() { _wiz_select_handle _DEPTH '.global.color_depth=$v'; }

_wiz_draw_lines() {
  tui_clear
  printf '  statusline-bar ▸ Lines (advanced)\n\n'
  printf '  Editing the lines array via TUI is coming in v0.1.1.\n'
  printf '  For now, edit your config file directly:\n\n'
  printf '    %s\n\n' "${CONFIG_PATH:-(no config file — run :save first)}"
  printf '  Or pick a preset from the main menu; presets define the lines.\n\n'
  printf '  Press Esc or q to go back.\n'
}
_wiz_handle_lines() { case "$KEY" in esc|left|quit) _wiz_pop ;; esac; }

_wiz_draw_tokens() {
  tui_clear
  printf '  statusline-bar ▸ Tokens (advanced)\n\n'
  printf '  Per-token overrides via TUI are coming in v0.1.1.\n'
  printf '  For now, edit your config file directly:\n\n'
  printf '    %s\n\n' "${CONFIG_PATH:-(no config file — run :save first)}"
  printf '  Set tokens.<id>.prefix / format / bar_style / separator_after.\n\n'
  printf '  Press Esc or q to go back.\n'
}
_wiz_handle_tokens() { case "$KEY" in esc|left|quit) _wiz_pop ;; esac; }

run_wizard() {
  if [[ -z "${CONFIG_JSON:-}" ]]; then load_config; fi
  WIZARD_STACK=(main)
  WIZARD_CURSOR_STACK=()
  WIZARD_CURSOR=0
  WIZARD_DIRTY=0
  WIZARD_TUI_SCRIPT="${OPT_TUI_SCRIPT:-}"
  local scripted=0
  [[ -n "$WIZARD_TUI_SCRIPT" ]] && scripted=1

  # Use the real terminal's color depth in the live preview so themes
  # visibly differ when scrolling. Scripted tests force "none" to keep
  # expected-output files ANSI-free.
  if (( scripted )); then
    WIZARD_COLOR_DEPTH="none"
  else
    WIZARD_COLOR_DEPTH="$(detect_color_depth)"
  fi
  _build_theme_examples

  if (( ! scripted )); then
    tui_init
  fi

  while (( ${#WIZARD_STACK[@]} > 0 )); do
    local screen; screen="$(_wiz_top)"
    case "$screen" in
      main)      _wiz_draw_main ;;
      preset)    _wiz_draw_preset ;;
      theme)     _wiz_draw_theme ;;
      prefix)    _wiz_draw_prefix ;;
      separator) _wiz_draw_separator ;;
      bar)       _wiz_draw_bar ;;
      empty)     _wiz_draw_empty ;;
      depth)     _wiz_draw_depth ;;
      lines)     _wiz_draw_lines ;;
      tokens)    _wiz_draw_tokens ;;
    esac
    _wiz_next_key
    # Global shortcuts (apply on any screen)
    case "$KEY" in
      save)
        save_config "${CONFIG_PATH:-$(_default_config_path)}" "$CONFIG_JSON"
        WIZARD_DIRTY=0
        break ;;
      reset)
        CONFIG_JSON="$(build_default_config)"
        WIZARD_DIRTY=1
        continue ;;
      quit)
        # On main: quit immediately. On submenu: pop back to main.
        if [[ "$screen" == "main" ]]; then break
        else _wiz_pop; fi
        continue ;;
    esac
    case "$screen" in
      main)      _wiz_handle_main ;;
      preset)    _wiz_handle_preset ;;
      theme)     _wiz_handle_theme ;;
      prefix)    _wiz_handle_prefix ;;
      separator) _wiz_handle_separator ;;
      bar)       _wiz_handle_bar ;;
      empty)     _wiz_handle_empty ;;
      depth)     _wiz_handle_depth ;;
      lines)     _wiz_handle_lines ;;
      tokens)    _wiz_handle_tokens ;;
    esac
  done

  if (( ! scripted )); then
    tui_cleanup
  fi
  return 0
}

# ============================================================
# SECTION: Examples mode
# ============================================================

# Run the renderer once with a synthetic input + a config override.
# Args: <preset> <theme> <prefix> <separator> <bar_style|"null">
_render_sample() {
  local preset="$1" theme="$2" prefix="$3" sep="$4" bar="$5"
  local cfg
  cfg="$(build_default_config | jq \
    --arg p "$preset" --arg t "$theme" --arg ps "$prefix" --arg s "$sep" --arg b "$bar" \
    --argjson presets "$PRESETS_JSON" '
      .preset=$p
      | .theme=$t
      | .lines=$presets[$p].lines
      | .global.prefix_style=$ps
      | .global.separator=$s
      | (if $b=="null" then .global.bar_style=null else .global.bar_style=$b end)
      | .global.color_depth="none"')"
  INPUT_JSON="$EXAMPLES_INPUT_JSON" \
    CONFIG_JSON="$cfg" \
    COLOR_DEPTH="none" \
    NOW_EPOCH=9999999999 \
    MOCK_GIT_STATE=out_of_repo \
    render_all
}

examples_catalog() {
  local only="${ONLY:-all}"
  local p t ps s b
  if [[ "$only" == "all" || "$only" == "presets" ]]; then
    echo "## Presets"
    for p in minimum compact default modern fancy everything maximum; do
      printf '[ %-10s ] %s\n' "$p" "$(_render_sample "$p" default emoji pipe null | head -n 1)"
    done
    echo
  fi
  if [[ "$only" == "all" || "$only" == "themes" ]]; then
    echo "## Themes"
    for t in default dark light graphite solarized dracula nord gruvbox tokyo-night catppuccin; do
      printf '[ %-12s ] %s\n' "$t" "$(_render_sample minimum "$t" emoji pipe null | head -n 1)"
    done
    echo
  fi
  if [[ "$only" == "all" || "$only" == "prefixes" ]]; then
    echo "## Prefix styles"
    for ps in none label emoji nerd ascii emoji+label label+emoji nerd+label; do
      printf '[ %-12s ] %s\n' "$ps" "$(_render_sample minimum default "$ps" pipe null | head -n 1)"
    done
    echo
  fi
  if [[ "$only" == "all" || "$only" == "separators" ]]; then
    echo "## Separators"
    for s in space pipe slash dot vbar dash bullet diamond arrow tri star sparkle gear check heart music chevron slant chevron_thin; do
      printf '[ %-12s ] %s\n' "$s" "$(_render_sample minimum default emoji "$s" null | head -n 1)"
    done
    echo
  fi
  if [[ "$only" == "all" || "$only" == "bars" ]]; then
    echo "## Bar styles"
    for b in blocks heavy line braille dots arrows ascii gradient; do
      printf '[ %-10s ] %s\n' "$b" "$(_render_sample fancy default emoji pipe "$b" | sed -n '1p')"
    done
  fi
}

# Combinatorial: 7 presets × 10 themes × 8 prefixes × 19 separators = 10,640 lines.
examples_all() {
  local p t ps s
  for p in minimum compact default modern fancy everything maximum; do
    for t in default dark light graphite solarized dracula nord gruvbox tokyo-night catppuccin; do
      for ps in none label emoji nerd ascii emoji+label label+emoji nerd+label; do
        for s in space pipe slash dot vbar dash bullet diamond arrow tri star sparkle gear check heart music chevron slant chevron_thin; do
          _render_sample "$p" "$t" "$ps" "$s" null | head -n 1
        done
      done
    done
  done
}

# Interactive examples (stub; full TUI version comes in Phase 10 addendum).
examples_interactive() {
  echo "statusline-bar: --examples interactive not yet implemented" >&2
  return 1
}

run_examples() {
  local mode="${1:-}"
  case "$mode" in
    "")
      printf '%s\n' \
        "statusline-bar examples" \
        "  1) Catalog       one preview per preset/theme/prefix/separator" \
        "  2) Interactive   browse-only TUI like the wizard" \
        "  3) All           combinatorial 7×10×8×19 = 10,640 lines (paged)"
      printf "  Enter choice [1-3, q]: "
      local choice; read -r choice
      case "$choice" in
        1) run_examples catalog ;;
        2) run_examples interactive ;;
        3) run_examples all ;;
        *) return 0 ;;
      esac ;;
    catalog) examples_catalog ;;
    all)
      if [[ -t 1 ]]; then examples_all | ${PAGER:-less}
      else                examples_all
      fi ;;
    interactive) examples_interactive ;;
    *) echo "unknown examples mode: $mode" >&2; return 2 ;;
  esac
}

main() {
  # Full argument parser. Sets OPT_* globals and strips parsed flags from "$@".
  OPT_HELP=0 OPT_VERSION=0 OPT_WIZARD=0 OPT_EXAMPLES=0 OPT_EXAMPLES_MODE=""
  OPT_CHECK=0 OPT_PRESET="" OPT_THEME="" OPT_NO_COLOR=0
  local _args=() _i=1
  while (( _i <= $# )); do
    case "${!_i}" in
      -h|--help)    OPT_HELP=1 ;;
      -V|--version) OPT_VERSION=1 ;;
      -c|--wizard)  OPT_WIZARD=1 ;;
      --check)      OPT_CHECK=1 ;;
      --no-color)   OPT_NO_COLOR=1 ;;
      --config)
        _i=$((_i+1)); CONFIG_PATH="${!_i}" ;;
      --preset)
        _i=$((_i+1)); OPT_PRESET="${!_i}" ;;
      --theme)
        _i=$((_i+1)); OPT_THEME="${!_i}" ;;
      --examples)
        OPT_EXAMPLES=1
        local next_idx=$((_i+1))
        if (( next_idx <= $# )) && [[ "${!next_idx}" != -* ]]; then
          OPT_EXAMPLES_MODE="${!next_idx}"
          _i=$next_idx
        fi ;;
      --only)
        _i=$((_i+1)); ONLY="${!_i}"; export ONLY ;;
      --tui-script)
        _i=$((_i+1)); OPT_TUI_SCRIPT="${!_i}" ;;
      --examples-all-count)
        examples_all | wc -l | tr -d ' '
        exit 0 ;;
      *) _args+=("${!_i}") ;;
    esac
    _i=$((_i+1))
  done
  set -- "${_args[@]}"
  # --dump-data is a test hook surfacing the embedded data tables.
  if [[ "${1:-}" == "--dump-data" ]]; then
    case "${2:-}" in
      themes)     jq -r 'keys_unsorted | join(" ")' <<<"$THEMES_JSON"; exit 0 ;;
      separators) jq -r 'keys_unsorted | join(" ")' <<<"$SEPARATORS_JSON"; exit 0 ;;
      bar_styles) jq -r 'keys_unsorted | join(" ")' <<<"$BAR_STYLES_JSON"; exit 0 ;;
      presets)    jq -r 'keys_unsorted | join(" ")' <<<"$PRESETS_JSON"; exit 0 ;;
      tokens)     jq -r 'keys_unsorted | join(" ")' <<<"$TOKENS_JSON"; exit 0 ;;
      examples_input) jq -r '.model.display_name' <<<"$EXAMPLES_INPUT_JSON"; exit 0 ;;
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
  if [[ "${1:-}" == "--dump-cap" ]]; then
    case "${2:-}" in
      color-depth) detect_color_depth; exit 0 ;;
      nerd-font)   detect_nerd_font; exit 0 ;;
      *) echo "unknown --dump-cap kind: ${2:-}" >&2; exit 2 ;;
    esac
  fi
  if [[ "${1:-}" == "--dump-color" ]]; then
    local _depth; _depth="$(detect_color_depth)"
    # Emit escaped form so expected files are diff-friendly.
    color_fg "$2" "$_depth" | sed 's/\x1b/\\033/g'
    echo
    exit 0
  fi
  if [[ "${1:-}" == "--dump-format" ]]; then
    case "${2:-}" in
      duration) fmt_duration_ms "${3:-0}"; exit 0 ;;
      percent)  fmt_percent "${3:-0}"; echo; exit 0 ;;
      bar)      render_bar "${3:-0}" "${4:-blocks}" "${5:-10}"; echo; exit 0 ;;
      *) echo "unknown --dump-format kind: ${2:-}" >&2; exit 2 ;;
    esac
  fi
  if [[ "${1:-}" == "--dump-prefix" ]]; then
    apply_prefix "$2" "$3" "$4"; echo
    exit 0
  fi
  if [[ "${1:-}" == "--dump-token" ]]; then
    INPUT_JSON="$(cat)"
    "tok_${2}"
    echo
    exit 0
  fi
  if [[ "${1:-}" == "--apply-format" ]]; then
    apply_format "$2" "$3" "$4" "$5" "$6" "$7"; echo
    exit 0
  fi
  if [[ "${1:-}" == "--dump-default-config" ]]; then
    build_default_config
    exit 0
  fi
  if [[ "${1:-}" == "--dump-loaded-config" ]]; then
    # If stdin has data, set INPUT_JSON so project-local lookup uses workspace dir.
    if [[ ! -t 0 ]]; then INPUT_JSON="$(cat)"; fi
    load_config
    echo "$CONFIG_JSON"
    exit 0
  fi
  if [[ "${1:-}" == "--check-auto-create" ]]; then
    if [[ ! -t 0 ]]; then INPUT_JSON="$(cat)"; fi
    load_config
    if [[ -z "${CONFIG_PATH:-}" ]]; then
      local p; p="$(_default_config_path)"
      save_config "$p" "$CONFIG_JSON"
      echo "created $p"
      exit 0
    fi
    echo "already-have: $CONFIG_PATH"
    exit 0
  fi
  if [[ "${1:-}" == "--check" ]]; then
    if check_config; then exit 0; else exit 1; fi
  fi
  if [[ "${1:-}" == "--dump-render-token" ]]; then
    INPUT_JSON="$(cat)"
    CONFIG_JSON="$(jq '.' "${CONFIG_PATH:-/dev/null}" 2>/dev/null)"
    local _cfg_depth; _cfg_depth="$(jq -r '.global.color_depth // "auto"' <<<"${CONFIG_JSON:-{\}}" 2>/dev/null)"
    if [[ "$_cfg_depth" == "auto" || -z "$_cfg_depth" ]]; then
      COLOR_DEPTH="$(detect_color_depth)"
    else
      COLOR_DEPTH="$_cfg_depth"
    fi
    NOW_EPOCH="${STATUSLINE_BAR_FAKE_NOW:-$(date +%s)}"
    render_token "$2"; echo
    exit 0
  fi
  if [[ "${1:-}" == "--dump-render-line" ]]; then
    INPUT_JSON="$(cat)"
    CONFIG_JSON="$(jq '.' "${CONFIG_PATH:-/dev/null}" 2>/dev/null)"
    local _cfg_depth; _cfg_depth="$(jq -r '.global.color_depth // "auto"' <<<"${CONFIG_JSON:-{\}}" 2>/dev/null)"
    if [[ "$_cfg_depth" == "auto" || -z "$_cfg_depth" ]]; then
      COLOR_DEPTH="$(detect_color_depth)"
    else
      COLOR_DEPTH="$_cfg_depth"
    fi
    NOW_EPOCH="${STATUSLINE_BAR_FAKE_NOW:-$(date +%s)}"
    render_line "$2"; echo
    exit 0
  fi
  if [[ "${1:-}" == "--dump-render-all" ]]; then
    INPUT_JSON="$(cat)"
    CONFIG_JSON="$(jq '.' "${CONFIG_PATH:-/dev/null}" 2>/dev/null)"
    local _cfg_depth; _cfg_depth="$(jq -r '.global.color_depth // "auto"' <<<"${CONFIG_JSON:-{\}}" 2>/dev/null)"
    if [[ "$_cfg_depth" == "auto" || -z "$_cfg_depth" ]]; then
      COLOR_DEPTH="$(detect_color_depth)"
    else
      COLOR_DEPTH="$_cfg_depth"
    fi
    NOW_EPOCH="${STATUSLINE_BAR_FAKE_NOW:-$(date +%s)}"
    render_all; echo
    exit 0
  fi
  # Standard flag exits
  (( OPT_HELP ))    && { print_help; exit 0; }
  (( OPT_VERSION )) && { print_version; exit 0; }
  (( OPT_CHECK ))   && { if check_config; then exit 0; else exit 1; fi; }
  (( OPT_WIZARD ))  && { run_wizard; exit $?; }
  (( OPT_EXAMPLES )) && { run_examples "$OPT_EXAMPLES_MODE"; exit $?; }
  (( OPT_NO_COLOR )) && export NO_COLOR=1

  # Render path
  if [[ -t 0 ]]; then
    # No piped data → prompt
    echo -n "No piped data detected. Set up config? (y/n) " >&2
    local ans; read -r ans
    case "$ans" in
      y|Y|yes) run_wizard; exit $? ;;
      *) print_help; exit 0 ;;
    esac
  fi

  INPUT_JSON="$(cat)"
  load_config

  # One-shot overrides
  if [[ -n "$OPT_PRESET" ]]; then
    CONFIG_JSON="$(jq --arg p "$OPT_PRESET" --argjson presets "$PRESETS_JSON" \
      '.preset=$p | .lines=$presets[$p].lines' <<<"$CONFIG_JSON")"
  fi
  if [[ -n "$OPT_THEME" ]]; then
    CONFIG_JSON="$(jq --arg t "$OPT_THEME" '.theme=$t' <<<"$CONFIG_JSON")"
  fi

  # First-run auto-create (silent; ignore write errors)
  if [[ -z "${CONFIG_PATH:-}" ]]; then
    save_config "$(_default_config_path)" "$CONFIG_JSON" 2>/dev/null || true
  fi

  # Resolve color depth from config or detection
  local _cfg_depth; _cfg_depth="$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")"
  if [[ "$_cfg_depth" == "auto" ]]; then
    COLOR_DEPTH="$(detect_color_depth)"
  else
    COLOR_DEPTH="$_cfg_depth"
  fi
  NOW_EPOCH="${STATUSLINE_BAR_FAKE_NOW:-$(date +%s)}"
  render_all
}

main "$@"
