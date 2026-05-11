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

main() {
  # Minimal pre-parse of --config so dump hooks see the right path. Strips
  # --config PATH from "$@" so the rest of dispatch sees only its own args.
  # (Full CLI parser comes in Phase 8.)
  local _args=() _i
  for (( _i=1; _i<=$#; _i++ )); do
    case "${!_i}" in
      --config)
        _i=$((_i+1))
        CONFIG_PATH="${!_i}" ;;
      *) _args+=("${!_i}") ;;
    esac
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
