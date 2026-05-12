#!/usr/bin/env bash
# statusline-bar — customizable Claude Code statusline
# Single file. bash 3.2+ and jq required.
# https://github.com/Dworf/statusline-bar

set -u

VERSION="0.3.0"

# ============================================================
# SECTION: Embedded data — themes
# ============================================================

read -r -d '' THEMES_JSON <<'JSON' || true
{
  "default":          { "good":"#3fb950","warn":"#d29922","crit":"#f85149","dim":"#8b949e","accent":"",       "bar_style":"blocks" },
  "solarized":        { "good":"#859900","warn":"#b58900","crit":"#dc322f","dim":"#586e75","accent":"#2aa198","bar_style":"heavy"  },
  "graphite":         { "good":"bold",   "warn":"normal","crit":"normal","dim":"dim",    "accent":"bold",    "bar_style":"ascii"  },

  "light":            { "good":"#1a7f37","warn":"#bf8700","crit":"#cf222e","dim":"#57606a","accent":"#0969da","bar_style":"blocks" },
  "solarized-light":  { "good":"#859900","warn":"#b58900","crit":"#dc322f","dim":"#93a1a1","accent":"#d33682","bar_style":"heavy"  },
  "catppuccin-latte": { "good":"#40a02b","warn":"#df8e1d","crit":"#d20f39","dim":"#6c6f85","accent":"#fe640b","bar_style":"blocks" },
  "tokyo-day":        { "good":"#587539","warn":"#8c6c3e","crit":"#f52a65","dim":"#848cb5","accent":"#b14a87","bar_style":"blocks" },
  "ayu-light":        { "good":"#86b300","warn":"#fa8d3e","crit":"#f07171","dim":"#828c99","accent":"#a37acc","bar_style":"blocks" },
  "garden":           { "good":"#689f38","warn":"#ff8a65","crit":"#e57373","dim":"#9e9e9e","accent":"#ba68c8","bar_style":"blocks" },

  "dark":             { "good":"#00ff87","warn":"#ffaf00","crit":"#ff5f5f","dim":"#6a737d","accent":"#5fafff","bar_style":"blocks" },
  "dracula":          { "good":"#50fa7b","warn":"#f1fa8c","crit":"#ff5555","dim":"#6272a4","accent":"#ff79c6","bar_style":"blocks" },
  "nord":             { "good":"#a3be8c","warn":"#ebcb8b","crit":"#bf616a","dim":"#4c566a","accent":"#88c0d0","bar_style":"heavy"  },
  "gruvbox":          { "good":"#98971a","warn":"#d79921","crit":"#cc241d","dim":"#7c6f64","accent":"#d65d0e","bar_style":"heavy"  },
  "tokyo-night":      { "good":"#9ece6a","warn":"#e0af68","crit":"#f7768e","dim":"#565f89","accent":"#7dcfff","bar_style":"blocks" },
  "catppuccin":       { "good":"#a6e3a1","warn":"#f9e2af","crit":"#f38ba8","dim":"#6c7086","accent":"#f5c2e7","bar_style":"blocks" },
  "one-dark":         { "good":"#98c379","warn":"#e5c07b","crit":"#e06c75","dim":"#5c6370","accent":"#c678dd","bar_style":"blocks" },
  "rose-pine":        { "good":"#9ccfd8","warn":"#f6c177","crit":"#eb6f92","dim":"#908caa","accent":"#c4a7e7","bar_style":"blocks" },
  "monokai":          { "good":"#a6e22e","warn":"#e6db74","crit":"#f92672","dim":"#75715e","accent":"#fd971f","bar_style":"blocks" },
  "mocha":            { "good":"#aed581","warn":"#d4a574","crit":"#d2691e","dim":"#5d4037","accent":"#b08968","bar_style":"heavy"  },
  "silver":           { "good":"#81c784","warn":"#ffb300","crit":"#ef5350","dim":"#757575","accent":"#c0c0c0","bar_style":"line"   },
  "ocean":            { "good":"#4cc9b0","warn":"#ffd166","crit":"#ff6b6b","dim":"#90a4ae","accent":"#48cae4","bar_style":"heavy"  }
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
  "gradient":       { "fill":"█",   "empty":" ",        "gradient":true,
                      "eighths":["", "▏","▎","▍","▌","▋","▊","▉"] },
  "gradient_track": { "fill":"█",   "empty":"▒",   "gradient":true,
                      "eighths":["", "▓","▓","▓","▓","▓","▓","▓"] }
}
JSON

# ============================================================
# SECTION: Embedded data — presets
# ============================================================

read -r -d '' PRESETS_JSON <<'JSON' || true
{
  "minimum": {
    "lines": [ ["model","context","cost"] ],
    "token_formats": {}
  },
  "compact": {
    "lines": [ ["model","context","cost","git_branch","duration","rl_5h"] ],
    "token_formats": { "rl_5h": "percent" }
  },
  "default": {
    "lines": [
      ["model","context","cost","rl_5h","rl_7d"],
      ["thinking","effort","dir","worktree","git_branch","lines_added","lines_removed","duration"]
    ],
    "token_formats": {
      "rl_5h": "progressbar+percent+countdown",
      "rl_7d": "progressbar+percent+countdown"
    }
  },
  "modern": {
    "lines": [
      ["model","context","git_branch","git_staged","git_modified","cost"],
      ["rl_5h","rl_7d","duration"]
    ],
    "token_formats": {
      "rl_5h": "progressbar+percent",
      "rl_7d": "progressbar+percent"
    }
  },
  "fancy": {
    "lines": [
      ["model","context","cost","duration"],
      ["rl_5h","rl_7d"],
      ["dir","git_branch","git_status","thinking","effort","battery","clock"]
    ],
    "token_formats": {
      "context": "progressbar+percent",
      "rl_5h": "progressbar+percent+countdown",
      "rl_7d": "progressbar+percent+countdown",
      "battery": "progressbar+percent"
    }
  },
  "everything": {
    "lines": [
      ["model","session_name","session_id","context","tokens_input","tokens_output","context_size","context_remaining"],
      ["cache_hit","cost","api_duration","rl_5h","rl_7d","thinking","effort","output_style","version","agent_name","vim_mode","fast_mode","exceeds_200k"],
      ["dir","worktree","added_dirs","git_worktree","transcript","git_branch","git_status","git_staged","git_modified","git_untracked","git_ahead_behind","lines_added","lines_removed"],
      ["duration","clock","date","hostname","user","battery","memory","load"]
    ],
    "token_formats": {}
  },
  "maximum": {
    "lines": [
      ["model","session_name","session_id","context","tokens_input","tokens_output","context_size","context_remaining"],
      ["cache_hit","cost","api_duration","rl_5h","rl_7d","thinking","effort","output_style","version","agent_name","vim_mode","fast_mode","exceeds_200k"],
      ["dir","worktree","added_dirs","git_worktree","transcript","git_branch","git_status","git_staged","git_modified","git_untracked","git_ahead_behind","lines_added","lines_removed"],
      ["duration","clock","date","hostname","user","battery","memory","load"]
    ],
    "token_formats": {
      "context": "progressbar+percent+tokens",
      "context_remaining": "progressbar+percent",
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
  "model": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","compact","short","id","id_short"],
             "prefix": { "none":"", "label":"Model:", "emoji":"🤖", "nerd":"", "ascii":"[M]" } },
  "session_name": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Session:", "emoji":"📝", "nerd":"", "ascii":"[S]" } },
  "context": { "source":"claude", "default_prefix":"emoji", "default_format":"percent+tokens",
             "applicable_formats":["value","percent","progressbar","progressbar+percent","tokens","tokens+size","percent+tokens","progressbar+percent+tokens"],
             "prefix": { "none":"", "label":"Ctx:", "emoji":"🧠", "nerd":"", "ascii":"[C]" } },
  "tokens_input": { "source":"claude", "default_prefix":"emoji", "default_format":"short", "applicable_formats":["value","short"],
             "prefix": { "none":"", "label":"In:", "emoji":"📥", "nerd":"", "ascii":"[in]" } },
  "tokens_output": { "source":"claude", "default_prefix":"emoji", "default_format":"short", "applicable_formats":["value","short"],
             "prefix": { "none":"", "label":"Out:", "emoji":"📤", "nerd":"", "ascii":"[out]" } },
  "context_size": { "source":"claude", "default_prefix":"emoji", "default_format":"short", "applicable_formats":["value","short"],
             "prefix": { "none":"", "label":"CtxMax:", "emoji":"🪟", "nerd":"", "ascii":"[CW]" } },
  "context_remaining": { "source":"claude", "default_prefix":"emoji", "default_format":"percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"],
             "prefix": { "none":"", "label":"Free:", "emoji":"🆓", "nerd":"", "ascii":"[F]" } },
  "cache_hit": { "source":"claude", "default_prefix":"emoji", "default_format":"percent",
             "applicable_formats":["value","percent","progressbar","progressbar+percent"],
             "prefix": { "none":"", "label":"Cache:", "emoji":"💾", "nerd":"", "ascii":"[H]" } },
  "cost": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","per_hour","with_rate"],
             "prefix": { "none":"", "label":"Cost:", "emoji":"💰", "nerd":"", "ascii":"[$]" } },
  "duration": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Time:", "emoji":"⏳", "nerd":"", "ascii":"[T]" } },
  "api_duration": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"API:", "emoji":"📡", "nerd":"", "ascii":"[A]" } },
  "lines_added": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","count"],
             "prefix": { "none":"", "label":"Added:", "emoji":"➕", "nerd":"", "ascii":"+" } },
  "lines_removed": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","count"],
             "prefix": { "none":"", "label":"Removed:", "emoji":"➖", "nerd":"", "ascii":"-" } },
  "rl_5h": { "source":"claude", "default_prefix":"label", "default_format":"progressbar+percent+countdown",
             "applicable_formats":["value","percent","progressbar","progressbar+percent","countdown","remaining","progressbar+percent+countdown","progressbar+percent+remaining"],
             "prefix": { "none":"", "label":"5h", "emoji":"🕔 5h", "nerd":" 5h", "ascii":"[5h]" } },
  "rl_7d": { "source":"claude", "default_prefix":"label", "default_format":"progressbar+percent+countdown",
             "applicable_formats":["value","percent","progressbar","progressbar+percent","countdown","remaining","progressbar+percent+countdown","progressbar+percent+remaining"],
             "prefix": { "none":"", "label":"7d", "emoji":"🕖 7d", "nerd":" 7d", "ascii":"[7d]" } },
  "thinking": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value","flag"],
             "prefix": { "none":"", "label":"Think:", "emoji":"💭", "nerd":"", "ascii":"[?]" } },
  "effort": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Effort:", "emoji":"💪", "nerd":"", "ascii":"[E]" } },
  "output_style": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Style:", "emoji":"🎨", "nerd":"", "ascii":"[Y]" } },
  "version": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Version:", "emoji":"🏷️", "nerd":"", "ascii":"[V]" } },
  "fast_mode": { "source":"claude", "default_prefix":"emoji", "default_format":"flag", "applicable_formats":["flag","value"],
             "prefix": { "none":"", "label":"Fast", "emoji":"⚡️", "nerd":"", "ascii":"[F]" } },
  "exceeds_200k": { "source":"claude", "default_prefix":"emoji", "default_format":"flag", "applicable_formats":["flag","value"],
             "prefix": { "none":"", "label":">200k", "emoji":"📈", "nerd":"", "ascii":"[>]" } },
  "dir": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Dir:", "emoji":"📁", "nerd":"", "ascii":"[D]" } },
  "worktree": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Tree:", "emoji":"🌳", "nerd":"", "ascii":"[W]" } },
  "vim_mode": { "source":"claude", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Vim:", "emoji":"⌨️", "nerd":"", "ascii":"[Vm]" } },
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
             "prefix": { "none":"", "label":"AB:", "emoji":"🔀", "nerd":"", "ascii":"[AB]" } },
  "clock": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Time:", "emoji":"🕒", "nerd":"", "ascii":"[t]" } },
  "date": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Date:", "emoji":"📅", "nerd":"", "ascii":"[d]" } },
  "hostname": { "source":"os", "default_prefix":"emoji", "default_format":"value", "applicable_formats":["value"],
             "prefix": { "none":"", "label":"Host:", "emoji":"🖥️", "nerd":"", "ascii":"[h]" } },
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
  "model": { "id": "claude-opus-4-7[1m]", "display_name": "Opus 4.7 (1M context)" },
  "workspace": { "current_dir": "/tmp/x", "added_dirs": [] },
  "effort": { "level": "xhigh" },
  "thinking": { "enabled": true },
  "output_style": { "name": "default" },
  "version": "2.1.139",
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
    "total_input_tokens": 49950,
    "total_output_tokens": 50,
    "context_window_size": 100000,
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
  statusline-bar.sh [FLAGS]            render from stdin (Claude Code mode)
  statusline-bar.sh -w | --wizard      interactive setup
  statusline-bar.sh -e | --examples    print a catalog of presets/themes/etc
  statusline-bar.sh -c | --check       validate config; exit 0/1

Flags:
  -h, --help                show this help
  -V, --version             print version
  -w, --wizard              enter setup wizard
  -e, --examples            print a catalog of presets / themes / prefixes /
                            separators / bar styles, with samples
  -c, --check               validate config and exit
      --config PATH         use this config file instead of default
      --preset NAME         one-shot render with this preset
      --theme NAME          one-shot render with this theme
      --no-color            disable ANSI color output

To customize colors, layout, tokens, etc., launch the wizard:
  statusline-bar.sh -w

Config: $(_help_config_status)
Docs:   https://github.com/Dworf/statusline-bar
EOF
}

# Resolve the same lookup chain load_config uses, but only check existence.
# Used in --help so users see whether they're on defaults or a real file.
_help_config_status() {
  local explicit="${CONFIG_PATH:-}"
  if [[ -n "$explicit" && -f "$explicit" ]]; then
    echo "using $explicit"
  elif [[ -n "${STATUSLINE_BAR_CONFIG:-}" && -f "$STATUSLINE_BAR_CONFIG" ]]; then
    echo "using \$STATUSLINE_BAR_CONFIG = $STATUSLINE_BAR_CONFIG"
  elif [[ -f "$PWD/.statusline-bar.json" ]]; then
    echo "using $PWD/.statusline-bar.json (project-local)"
  elif [[ -n "${XDG_CONFIG_HOME:-}" && -f "$XDG_CONFIG_HOME/statusline-bar/config.json" ]]; then
    echo "using $XDG_CONFIG_HOME/statusline-bar/config.json"
  elif [[ -f "$HOME/.config/statusline-bar/config.json" ]]; then
    echo "using $HOME/.config/statusline-bar/config.json"
  else
    echo "no config file found — using built-in defaults (run with -w to create one)"
  fi
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

# Emit foreground SGR for COLOR at DEPTH. Empty if depth=none, or if COLOR
# is the empty string (sentinel for "no override — inherit terminal default").
color_fg() {
  local color="$1" depth="$2"
  case "$depth" in
    none) return ;;
  esac
  [[ -z "$color" ]] && return
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

# _strip_trailing_paren <s> → drop a single trailing " (...)" or " [...]"
# group plus any whitespace before it. Used by the model token's short
# formats: "Opus 4.7 (1M context)" → "Opus 4.7"; "claude-opus-4-7[1m]"
# → "claude-opus-4-7". Anything in the middle is left alone.
_strip_trailing_paren() {
  local s="$1"
  s="$(printf '%s' "$s" | sed -E 's/[[:space:]]*\([^()]*\)[[:space:]]*$//')"
  s="$(printf '%s' "$s" | sed -E 's/[[:space:]]*\[[^][]*\][[:space:]]*$//')"
  printf '%s' "$s"
}

# _strip_paren_context <s> → drop just the word " context" (and any
# surrounding whitespace) from inside the trailing (...) group. The
# parens stay. Used by the model `compact` format:
# "Opus 4.7 (1M context)" → "Opus 4.7 (1M)".
_strip_paren_context() {
  printf '%s' "$1" | sed -E 's/\(([^()]*)[[:space:]]+context[[:space:]]*\)$/(\1)/'
}

# _fmt_short <n> → human-readable abbreviation for token counts:
# < 1000 stays as integer; ≥ 1000 → "12k" / "999k"; ≥ 1000000 → "1.2M"
# / "10M" (trailing .0 elided). Used by tokens_input/output, context_size,
# and the context token's combined token-count formats.
_fmt_short() {
  awk -v n="$1" 'BEGIN {
    if (n+0 <= 0) { printf "0"; exit }
    if (n >= 1000000) {
      v = n / 1000000.0
      if (v == int(v)) printf "%dM", v
      else printf "%.1fM", v
    } else if (n >= 1000) {
      printf "%dk", n / 1000
    } else {
      printf "%d", n
    }
  }'
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
    local eighths echar
    eighths="$(awk -v p="$pct" -v w="$width" 'BEGIN { printf "%d", int((p*w*8/100) + 0.5) }')"
    if (( eighths < 0 )); then eighths=0; fi
    local max=$(( width * 8 ))
    if (( eighths > max )); then eighths="$max"; fi
    local full=$(( eighths / 8 ))
    local rem=$(( eighths % 8 ))
    local partial_count=$(( rem > 0 ? 1 : 0 ))
    local empty=$(( width - full - partial_count ))
    echar="$(_bar_empty_char "$style")"
    local i out=""
    for ((i=0; i<full; i++)); do out+="█"; done
    if (( rem > 0 )); then out+="$(_bar_eighth "$style" "$rem")"; fi
    for ((i=0; i<empty; i++)); do out+="$echar"; done
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

# Project session cost to an hourly burn rate based on wall-clock
# duration ("$6.26/hr"). Emits nothing when cost or duration is
# missing / zero — used by the cost token's per_hour / with_rate
# formats. Format-side helper, intentionally cost-shaped (not generic).
_cost_per_hour() {
  local c d
  c="$(jq -r '.cost.total_cost_usd // empty' <<<"$INPUT_JSON")"
  d="$(jq -r '.cost.total_duration_ms // empty' <<<"$INPUT_JSON")"
  [[ -z "$c" || -z "$d" ]] && return
  awk -v c="$c" -v d="$d" 'BEGIN {
    if (d+0 <= 0) exit 0
    printf "$%.2f/hr", c / (d / 3600000.0)
  }'
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
tok_context() { jq -r '.context_window.used_percentage // empty' <<<"$INPUT_JSON"; }
tok_tokens_input()      { jq -r '.context_window.total_input_tokens  // empty' <<<"$INPUT_JSON"; }
tok_tokens_output()     { jq -r '.context_window.total_output_tokens // empty' <<<"$INPUT_JSON"; }
tok_context_size()      { jq -r '.context_window.context_window_size // empty' <<<"$INPUT_JSON"; }
tok_context_remaining() {
  # Prefer .remaining_percentage when present; otherwise derive from used.
  local r u
  r="$(jq -r '.context_window.remaining_percentage // empty' <<<"$INPUT_JSON")"
  if [[ -n "$r" ]]; then printf '%s' "$r"; return; fi
  u="$(jq -r '.context_window.used_percentage // empty' <<<"$INPUT_JSON")"
  [[ -z "$u" ]] && return
  awk -v u="$u" 'BEGIN { printf "%d", 100 - (u+0) }'
}
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
# Helper: run a git invocation in the workspace dir, or directly (without
# cd) when MOCK_GIT_STATE is set — the mock binary on PATH responds to the
# env var regardless of cwd. The cd is only meaningful for real git.
_git_run() {
  if [[ -n "${MOCK_GIT_STATE:-}" ]]; then
    git "$@" 2>/dev/null
    return
  fi
  local d; d="$(_git_workspace)"
  [[ -z "$d" ]] && return 1
  ( cd "$d" 2>/dev/null && git "$@" 2>/dev/null )
}
_git_check() {
  if [[ -n "${MOCK_GIT_STATE:-}" ]]; then
    git rev-parse --git-dir >/dev/null 2>&1
    return $?
  fi
  local d; d="$(_git_workspace)"
  [[ -z "$d" ]] && return 1
  ( cd "$d" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1 )
}

tok_git_branch() {
  _git_check || return
  _git_run branch --show-current
}
tok_git_staged() {
  _git_check || return
  _git_run diff --cached --numstat | wc -l | tr -d ' '
}
tok_git_modified() {
  _git_check || return
  _git_run diff --numstat | wc -l | tr -d ' '
}
tok_git_untracked() {
  _git_check || return
  _git_run ls-files --others --exclude-standard | wc -l | tr -d ' '
}
tok_git_status() {
  _git_check || return
  printf '+%s|~%s|?%s' "$(tok_git_staged)" "$(tok_git_modified)" "$(tok_git_untracked)"
}
tok_git_ahead_behind() {
  _git_check || return
  local raw a b
  raw="$(_git_run rev-list --left-right --count @{u}...HEAD)"
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
    compact)
      # Model-only today: drop the " context" qualifier from inside the
      # trailing (...) of display_name. "Opus 4.7 (1M context)" → "Opus 4.7
      # (1M)". Other tokens pass through unchanged.
      case "$id" in
        model)
          local _dn; _dn="$(jq -r '.model.display_name // ""' <<<"$INPUT_JSON")"
          printf '%s' "$(_strip_paren_context "$_dn")" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    short)
      # For model: strip a trailing (...) or [...] modifier from
      # display_name. "Opus 4.7 (1M context)" → "Opus 4.7".
      # For numeric tokens (tokens_input/output, context_size): render
      # a human-friendly short form ("202378" → "202k", "1000000" → "1M").
      case "$id" in
        model)
          local _dn; _dn="$(jq -r '.model.display_name // ""' <<<"$INPUT_JSON")"
          printf '%s' "$(_strip_trailing_paren "$_dn")" ;;
        tokens_input|tokens_output|context_size)
          _fmt_short "$raw" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    id)
      # Model-only today: emit .model.id verbatim ("claude-opus-4-7[1m]").
      case "$id" in
        model) jq -r '.model.id // ""' <<<"$INPUT_JSON" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    id_short)
      # Model-only today: emit .model.id with trailing (...) / [...]
      # stripped ("claude-opus-4-7[1m]" → "claude-opus-4-7").
      case "$id" in
        model)
          local _mid; _mid="$(jq -r '.model.id // ""' <<<"$INPUT_JSON")"
          printf '%s' "$(_strip_trailing_paren "$_mid")" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    count)
      # Strip a leading +/- sign (e.g. lines_added "+128" → "128",
      # lines_removed "-42" → "42"). Other values pass through unchanged.
      printf '%s' "${raw#[+-]}" ;;
    tokens)
      # context-only: short-form of total_input_tokens ("202k").
      case "$id" in
        context)
          local _it; _it="$(jq -r '.context_window.total_input_tokens // 0' <<<"$INPUT_JSON")"
          _fmt_short "$_it" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    "tokens+size")
      # context-only: used / window-size short forms ("202k/1M").
      case "$id" in
        context)
          local _it _sz
          _it="$(jq -r '.context_window.total_input_tokens // 0' <<<"$INPUT_JSON")"
          _sz="$(jq -r '.context_window.context_window_size // 0' <<<"$INPUT_JSON")"
          printf '%s/%s' "$(_fmt_short "$_it")" "$(_fmt_short "$_sz")" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    "percent+tokens")
      # context-only: "20% (202k/1M)".
      case "$id" in
        context)
          [[ -z "$raw" ]] && return
          local _p="${raw%%|*}" _it _sz
          _it="$(jq -r '.context_window.total_input_tokens // 0' <<<"$INPUT_JSON")"
          _sz="$(jq -r '.context_window.context_window_size // 0' <<<"$INPUT_JSON")"
          printf '%s (%s/%s)' \
            "$(fmt_percent "$_p")" \
            "$(_fmt_short "$_it")" \
            "$(_fmt_short "$_sz")" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    "progressbar+percent+tokens")
      # context-only: bar + "20% (202k/1M)".
      case "$id" in
        context)
          [[ -z "$raw" ]] && return
          local _p="${raw%%|*}" _it _sz
          _it="$(jq -r '.context_window.total_input_tokens // 0' <<<"$INPUT_JSON")"
          _sz="$(jq -r '.context_window.context_window_size // 0' <<<"$INPUT_JSON")"
          printf '%s %s (%s/%s)' \
            "$(render_bar "$_p" "$bar_style" "$bar_width")" \
            "$(fmt_percent "$_p")" \
            "$(_fmt_short "$_it")" \
            "$(_fmt_short "$_sz")" ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    per_hour)
      # cost-only: project total_cost_usd over total_duration_ms to an
      # hourly burn rate ("$6.26/hr"). Blank if duration is missing/zero.
      case "$id" in
        cost) _cost_per_hour ;;
        *) printf '%s' "$raw" ;;
      esac ;;
    with_rate)
      # cost-only: absolute cost + projected hourly rate side-by-side
      # ("$0.40 ($6.26/hr)"). Falls back to plain value if duration=0.
      case "$id" in
        cost)
          local _rate; _rate="$(_cost_per_hour)"
          if [[ -n "$_rate" ]]; then printf '%s (%s)' "$raw" "$_rate"
          else printf '%s' "$raw"; fi ;;
        *) printf '%s' "$raw" ;;
      esac ;;
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
    "progressbar+percent+remaining")
      [[ -z "$raw" ]] && return
      local p="${raw%%|*}" r="${raw##*|}"
      local diff=$(( r - now ))
      (( diff < 0 )) && diff=0
      printf '%s %s 🔄 in %s' \
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
      local pe pl pl_bare
      pe="$(jq -r --arg id "$id" '.[$id].prefix.emoji' <<<"$TOKENS_JSON")"
      pl="$(jq -r --arg id "$id" '.[$id].prefix.label' <<<"$TOKENS_JSON")"
      pl_bare="${pl%:}"
      # If the emoji prefix already contains the label text (e.g. rl_5h's
      # "🕔 5h" + label "5h"), don't repeat it.
      if [[ -n "$pl_bare" && "$pe" == *"$pl_bare" ]]; then
        printf '%s %s' "$pe" "$value"
      else
        printf '%s %s %s' "$pe" "$pl" "$value"
      fi ;;
    label+emoji)
      local pe pl pl_bare
      pe="$(jq -r --arg id "$id" '.[$id].prefix.emoji' <<<"$TOKENS_JSON")"
      pl="$(jq -r --arg id "$id" '.[$id].prefix.label' <<<"$TOKENS_JSON")"
      pl_bare="${pl%:}"
      if [[ -n "$pl_bare" && "$pe" == *"$pl_bare" ]]; then
        printf '%s %s' "$pe" "$value"
      else
        printf '%s %s %s' "$pl_bare" "$pe" "$value"
      fi ;;
    nerd+label)
      local pn pl pl_bare
      pn="$(jq -r --arg id "$id" '.[$id].prefix.nerd' <<<"$TOKENS_JSON")"
      pl="$(jq -r --arg id "$id" '.[$id].prefix.label' <<<"$TOKENS_JSON")"
      pl_bare="${pl%:}"
      if [[ -n "$pl_bare" && "$pn" == *"$pl_bare" ]]; then
        printf '%s %s' "$pn" "$value"
      else
        printf '%s %s %s' "$pn" "$pl" "$value"
      fi ;;
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
      empty_behavior: "placeholder",
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
  local valid_themes="default solarized graphite light solarized-light catppuccin-latte tokyo-day ayu-light garden dark dracula nord gruvbox tokyo-night catppuccin one-dark rose-pine monokai mocha silver ocean"
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
    context|cache_hit|rl_5h|rl_7d)
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
    context_remaining)
      # Inverted mirror of context's 70/90 used thresholds:
      # ≥30% free → good, 10-29% → warn, <10% → crit.
      pct="$(awk -v v="$raw" 'BEGIN{printf "%d", v+0}')"
      if   (( pct < 10 )); then _theme_var "$theme" crit
      elif (( pct < 30 )); then _theme_var "$theme" warn
      else                      _theme_var "$theme" good
      fi ;;
    memory)
      pct="$(awk -v v="$raw" 'BEGIN{printf "%d", v+0}')"
      if   (( pct >= 95 )); then _theme_var "$theme" crit
      elif (( pct >= 80 )); then _theme_var "$theme" warn
      else                       _theme_var "$theme" good
      fi ;;
    lines_added)   _theme_var "$theme" good ;;
    lines_removed) _theme_var "$theme" crit ;;
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
  empty_behavior="$(jq -r '.global.empty_behavior // "placeholder"' <<<"$CONFIG_JSON")"
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
  # If this token is the currently-focused one in the wizard preview,
  # underline the content and wrap it in bright-yellow ▶ ◀ markers. The
  # token's actual color is preserved (markers use their own color, the
  # underline is an orthogonal ANSI attribute). When color depth is
  # "none" the markers degrade to plain text without ANSI.
  if [[ -n "${RENDER_HIGHLIGHT_ID:-}" && "$RENDER_HIGHLIGHT_ID" == "$id" ]]; then
    case "$COLOR_DEPTH" in
      none) printf '▶ %s ◀' "$with_prefix" ;;
      *)    printf '\033[1;93m▶\033[0m \033[4m%s%s\033[0m \033[1;93m◀\033[0m' \
              "$color_esc" "$with_prefix" ;;
    esac
    return
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
      # Highlight this separator if the wizard is focused on its row.
      # Same visual idiom as the token highlight: bright-yellow ▶ ◀ markers
      # with the separator itself underlined. Falls back to plain ASCII
      # markers when color depth is "none".
      if [[ -n "${RENDER_HIGHLIGHT_SEP_AFTER:-}" && "$RENDER_HIGHLIGHT_SEP_AFTER" == "$prev_id_for_sep" ]]; then
        case "$COLOR_DEPTH" in
          none) result+="▶ ${sep} ◀" ;;
          *)    result+="$(printf '\033[1;93m▶\033[0m \033[4m%s\033[0m \033[1;93m◀\033[0m' "$sep")" ;;
        esac
      else
        result+="$sep"
      fi
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
          "[1")
            # Modified arrow: terminals send \e[1;<mod><dir> for Shift / etc.
            #   mod=2 → Shift, 5 → Ctrl, 6 → Ctrl+Shift, ...
            local more
            if IFS= read -rsn3 -t 0.05 more; then
              case "$more" in
                ";2A") KEY=shift-up;    return ;;
                ";2B") KEY=shift-down;  return ;;
                ";2C") KEY=shift-right; return ;;
                ";2D") KEY=shift-left;  return ;;
              esac
            fi ;;
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
WIZARD_NERD_FONT="unknown"

# Per-screen tooltip arrays. Index matches the cursor row on that screen.
# The tooltip is rendered below the keybind footer; it changes as the
# cursor moves so users always see context for the focused item.

_TOOLTIPS_MAIN=(
  "Preset: factory layouts that pre-fill lines + per-token formats. Theme/prefix/separator stay independent."
  "Theme: color palette only. Switching themes does not change which tokens render or how they're labeled."
  "Prefix style: global default for how every token is labeled (emoji / nerd / label / ascii / none + combos). Per-token override available."
  "Separator: global string inserted between tokens on a line. Per-token override via Tokens & lines."
  "Bar style: characters used by progressbar tokens. Theme's suggestion applies unless set."
  "Tokens & lines: add/remove/reorder tokens; switch between up to 4 lines; edit separators inline."
  "Empty data: when a token has no value — hide it (compact) or show a placeholder."
  "Color depth: auto-detects from \$NO_COLOR / \$COLORTERM / tput colors. Pin to override."
  "Reset to defaults: wipes all customizations and restores the factory config. Save (s) to persist; q to discard."
)

_TOOLTIPS_TOKEN_DETAIL=(
  "Prefix: how this token is labeled. Override the global prefix style for just this token."
  "Format: how the value is rendered. Bar / percent / countdown choices depend on the token type."
  "Bar style: bar characters used by this token. Override global / theme suggestion just for this token."
  "Reset to defaults: removes ALL per-token overrides for this token (prefix, format, bar, separator-after)."
)

# Parallel to _PRESETS — one line per preset, shown when its row is focused
# on the Preset screen. Use them to communicate scope ("how many tokens") and
# intent (what kind of layout) without making users scroll the preview.
_TOOLTIPS_PRESET=(
  "Minimum: 1 line, 3 tokens — model, context %, cost. Smallest possible statusline."
  "Compact: 1 line, 6 tokens — adds git branch, duration, and the 5h rate limit (as % only)."
  "Default: 2 lines, 13 tokens — usage row on top; thinking / dir / git / counters / duration below."
  "Modern: 2 lines, 9 tokens — git staged/modified inline; rate-limit bars + duration on line 2."
  "Fancy: 3 lines, 13 tokens — context bar, rate-limit bars, OS chrome (battery, clock), git status."
  "Everything: 4 lines, all 42 tokens, each using its default format. Coverage over compactness."
  "Maximum: same 42 tokens as Everything, but with progress bars, countdowns, and combined views where applicable."
)

# Count how many config fields differ from the built-in defaults. Used to
# show / hide the dynamic "Reset to defaults" row on the main menu.
_wiz_count_customizations() {
  jq --argjson def "$(build_default_config)" '
    [
      (if .preset                != $def.preset                then 1 else empty end),
      (if .theme                 != $def.theme                 then 1 else empty end),
      (if .global.prefix_style   != $def.global.prefix_style   then 1 else empty end),
      (if .global.separator      != $def.global.separator      then 1 else empty end),
      (if .global.bar_style      != $def.global.bar_style      then 1 else empty end),
      (if .global.color_depth    != $def.global.color_depth    then 1 else empty end),
      (if .global.empty_behavior != $def.global.empty_behavior then 1 else empty end),
      (if .global.placeholder    != $def.global.placeholder    then 1 else empty end),
      (if .global.bar_width      != $def.global.bar_width      then 1 else empty end),
      (if .lines                 != $def.lines                 then 1 else empty end),
      ((.tokens // {}) | length)
    ] | add // 0
  ' <<<"$CONFIG_JSON"
}

_wiz_help_tooltip() {
  local screen="$1" tip="" arr_name=""
  case "$screen" in
    main)         arr_name="_TOOLTIPS_MAIN" ;;
    preset)       arr_name="_TOOLTIPS_PRESET" ;;
    token_detail) arr_name="_TOOLTIPS_TOKEN_DETAIL" ;;
    tokens_lines)
      if [[ "$TL_ZONE" == "tabs" ]]; then
        local nlines; nlines="$(_tl_num_lines)"
        if (( TL_TAB_POS == nlines )); then
          tip="Press Enter to add a new (empty) line. Max 4 lines total."
        else
          tip="Line tab — ←/→ to switch active line; d to delete this line; ↓ enters its token list (↑ jumps to the last token)."
        fi
      elif (( $(_tl_line_count) == 0 )); then
        tip="Empty line — press a to add your first token."
      else
        if (( TL_TOKEN_ROW % 2 == 0 )); then
          tip="Token row — Enter opens its detail screen. Shift+↑↓ moves it up/down. d deletes (last token also removes the line)."
        else
          tip="Separator row — Enter picks a new separator just for this position. d resets it to the global default."
        fi
      fi ;;
    sep_picker)   tip="Picking a separator writes \`tokens.<id>.separator_after\` for just this position. (use global) clears the override." ;;
    token_picker)
      local _picked_id="${TOK_PICKER_LIST[$WIZARD_CURSOR]:-}"
      if [[ -n "$_picked_id" ]]; then
        tip="$_picked_id — $(_token_description "$_picked_id")"
      else
        tip="✓ next to a token means it's already used somewhere. Selecting one inserts it after the cursor on the active line."
      fi ;;
  esac
  if [[ -z "$tip" && -n "$arr_name" ]]; then
    eval "tip=\${${arr_name}[$WIZARD_CURSOR]:-}"
  fi
  if [[ -n "$tip" ]]; then
    printf -- '─%.0s' {1..60}; printf '\n'
    printf '  ⓘ  %s\n' "$tip"
  fi
}

# Format a per-item hint about Nerd-font availability. Used in the example
# column of submenus where the item requires (or would benefit from) a
# Nerd Font.
#   $1 = "needed" (the chars truly need a Nerd Font to render right)
#        or "placeholder" (the v0.1.0 glyph map is empty so the prefix
#        looks the same regardless of font; track detection but flag the
#        v0.1.1 follow-up)
_nerd_hint() {
  local kind="$1"
  case "$WIZARD_NERD_FONT" in
    yes)
      case "$kind" in
        placeholder) echo "(Nerd Font ✓ — glyphs land in v0.1.1)" ;;
        *)           echo "(Nerd Font ✓ detected)" ;;
      esac ;;
    no)
      echo "(Nerd Font ✗ — install: nerdfonts.com)" ;;
    *)
      echo "(Nerd Font: status unknown)" ;;
  esac
}

_wiz_next_key() {
  # OPT_TUI_SCRIPT (set once by the parser) signals scripted mode. WIZARD_TUI_SCRIPT
  # is the consumable buffer — checking it here would block on tui_read_key once
  # the script is exhausted, instead of cleanly exiting.
  if [[ -n "${OPT_TUI_SCRIPT:-}" ]]; then
    local c="${WIZARD_TUI_SCRIPT:0:1}"
    WIZARD_TUI_SCRIPT="${WIZARD_TUI_SCRIPT:1}"
    # Single-char protocol for scripted input (tests):
    #   D=down  U=up  L=left  R=right  \n=enter
    #   J=shift-down  K=shift-up  (in-line move)
    #   s=save  r=reset  q=quit  ESC=esc
    #   lowercase a/d/m/p reach the screen as char:a / char:d / etc.
    case "$c" in
      q) KEY=quit ;;
      s) KEY=save ;;
      r) KEY=reset ;;
      D) KEY=down ;;
      U) KEY=up ;;
      L) KEY=left ;;
      R) KEY=right ;;
      J) KEY=shift-down ;;
      K) KEY=shift-up ;;
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
  local total_tokens; total_tokens="$(jq -r '[.lines[][]] | length' <<<"$CONFIG_JSON")"
  local items=("Preset" "Theme" "Prefix style" "Separator" "Bar style" "Tokens & lines" "Empty data" "Color depth")
  local vals=("$preset" "$theme" "$prefix" "$sep" "$bar" "$lines lines · $total_tokens tokens" "$(jq -r '.global.empty_behavior // "placeholder"' <<<"$CONFIG_JSON")" "$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")")
  # Conditional 9th row: appears only when something differs from defaults.
  local custom_count; custom_count="$(_wiz_count_customizations)"
  if (( custom_count > 0 )); then
    items+=("Reset to defaults")
    vals+=("$custom_count customization$([[ "$custom_count" == "1" ]] || echo s) — Enter to reset all")
  fi
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
  _wiz_help_tooltip main
}

_wiz_handle_main() {
  # The "Reset to defaults" row is conditional (only when customizations
  # exist), so the max cursor index varies between 7 and 8.
  local _custom; _custom="$(_wiz_count_customizations)"
  local _max=7; (( _custom > 0 )) && _max=8
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$_max; fi ;;
    down)
      if (( WIZARD_CURSOR < _max )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter|right)
      local cur
      case "$WIZARD_CURSOR" in
        0) cur="$(jq -r '.preset // ""' <<<"$CONFIG_JSON")"
           _wiz_push preset    "$(_index_of _PRESETS    "$cur")" ;;
        1) cur="$(jq -r '.theme' <<<"$CONFIG_JSON")"
           local _ti; _ti="$(_index_of _THEMES "$cur")"
           # _THEMES contains section dividers; don't land the cursor on one.
           while [[ "${_THEMES[$_ti]}" == __SEC__\ * ]]; do _ti=$((_ti+1)); done
           _wiz_push theme "$_ti" ;;
        2) cur="$(jq -r '.global.prefix_style' <<<"$CONFIG_JSON")"
           _wiz_push prefix    "$(_index_of _PREFIXES   "$cur")" ;;
        3) cur="$(jq -r '.global.separator' <<<"$CONFIG_JSON")"
           _wiz_push separator "$(_index_of _SEPARATORS "$cur")" ;;
        4) cur="$(jq -r '.global.bar_style // ""' <<<"$CONFIG_JSON")"
           if [[ -z "$cur" || "$cur" == "null" ]]; then
             _wiz_push bar 0
           else
             _wiz_push bar "$(_index_of _BARS "$cur")"
           fi ;;
        5) _wiz_push tokens_lines ;;
        6) cur="$(jq -r '.global.empty_behavior // "placeholder"' <<<"$CONFIG_JSON")"
           _wiz_push empty     "$(_index_of _EMPTY      "$cur")" ;;
        7) cur="$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")"
           _wiz_push depth     "$(_index_of _DEPTH      "$cur")" ;;
        8) # Conditional "Reset to defaults" row
           CONFIG_JSON="$(build_default_config)"
           WIZARD_DIRTY=1
           WIZARD_CURSOR=0 ;;
      esac ;;
  esac
}

# Generic selection-screen helper used by preset/theme/prefix/sep/bar/empty/depth.
# Args: <title> <items-array-name> <current-getter-jq-expr> <jq-set-fn-name>
# This is too unwieldy to factor cleanly in bash 3.2 — we inline each screen below.

_wiz_draw_select() {  # title, current_value, mutation, examples-array-name, header, items[]...
  local title="$1" cur="$2" mutation="$3" ex_arr="$4" header="$5"; shift 5
  local items=("$@")
  tui_clear
  printf '  statusline-bar ▸ %s\n\n' "$title"
  if [[ -n "$header" ]]; then
    # 4-char marker + 16-char name + 2 spaces = 22 cols before example column
    printf '%22s%s\n' "" "$header"
  fi
  local i name marker is_current ex
  for ((i=0; i<${#items[@]}; i++)); do
    name="${items[$i]}"
    # Section header rows: dim text, no marker, no example column. Used by
    # the theme picker to label terminal-compatibility groups.
    if [[ "$name" == __SEC__\ * ]]; then
      printf '\n  \033[2m── %s ──\033[0m\n' "${name#__SEC__ }"
      continue
    fi
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
  printf '  ↑↓ navigate (wraps)   Enter select   Esc back   s save   r reset   q quit\n'
}

# Each selection screen is wrapped as a small draw+handle pair using a shared list.
_PRESETS=(minimum compact default modern fancy everything maximum)
# Theme list with inline section headers. Items starting with "__SEC__ "
# render as group labels (no marker, no example, dimmed) and are skipped
# by cursor navigation. The grouping matches terminal compatibility:
#   Auto / adaptive — palettes that read well on either light or dark bg
#   Light terminals — designed for light bg (high-contrast dark text)
#   Dark terminals  — designed for dark bg (bright/saturated text)
_THEMES=(
  "__SEC__ Auto / adaptive  (works in either light or dark terminals)"
  default solarized graphite
  "__SEC__ Light terminals"
  light solarized-light catppuccin-latte tokyo-day ayu-light garden
  "__SEC__ Dark terminals"
  dark dracula nord gruvbox tokyo-night catppuccin one-dark rose-pine monokai mocha silver ocean
)
_PREFIXES=(none label emoji nerd ascii emoji+label label+emoji nerd+label)
_SEPARATORS=(space pipe slash dot vbar dash bullet diamond arrow tri star sparkle gear check heart music chevron slant chevron_thin)
_BARS=("(theme default)" blocks heavy line braille dots arrows ascii gradient gradient_track)
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

# _PREFIXES_EX and _SEPARATORS_EX are rebuilt at wizard start (so the
# Nerd-Font status hint reflects the current detection result).
_PREFIXES_EX=()
_SEPARATORS_EX=()

_build_prefix_examples() {
  local hint; hint="$(_nerd_hint placeholder)"
  _PREFIXES_EX=(
    "Opus"
    "Model: Opus"
    "🤖 Opus"
    "Opus  $hint"
    "[M] Opus"
    "🤖 Model: Opus"
    "Model 🤖 Opus"
    "Model: Opus  $hint"
  )
}

_build_separator_examples() {
  local hint; hint="$(_nerd_hint needed)"
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
    "a  b  c  $hint"
    "a  b  c  $hint"
    "a  b  c  $hint"
  )
}

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
  "█████▒▒▒▒▒"
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

# Build inline theme swatches dynamically (one per _THEMES entry).
# Each row shows: good/warn/crit color dots, the accent color applied to
# "Aa" (representing how regular text is colored), and the bar style the
# theme suggests when global.bar_style is null.
# Run once at wizard start so we don't pay color_fg overhead per redraw.
_THEMES_EX=()
_build_theme_examples() {
  _THEMES_EX=()
  local t s good warn crit accent bar reset
  reset="$(color_reset "$WIZARD_COLOR_DEPTH")"
  for t in "${_THEMES[@]}"; do
    # Section markers stay in _THEMES so the picker draws group labels,
    # but they have no theme data — push an empty example to preserve
    # parallel-array indexing.
    if [[ "$t" == __SEC__\ * ]]; then
      _THEMES_EX+=( "" )
      continue
    fi
    s="${t//-/_}"
    eval "good=\$THEME_${s}_good"
    eval "warn=\$THEME_${s}_warn"
    eval "crit=\$THEME_${s}_crit"
    eval "accent=\$THEME_${s}_accent"
    eval "bar=\$THEME_${s}_bar_style"
    local g w c a
    g="$(color_fg "$good"   "$WIZARD_COLOR_DEPTH")●${reset}"
    w="$(color_fg "$warn"   "$WIZARD_COLOR_DEPTH")●${reset}"
    c="$(color_fg "$crit"   "$WIZARD_COLOR_DEPTH")●${reset}"
    a="$(color_fg "$accent" "$WIZARD_COLOR_DEPTH")Aa${reset}"
    # Columns aligned with the header "good warn crit  text  bar style":
    #   "  ●     ●     ●    Aa     blocks"
    _THEMES_EX+=( "  $g    $w    $c     $a    $bar" )
  done
}

_wiz_select_handle() {  # items_array_name jq_set_expression
  local arr_name="$1" set_expr="$2"
  local size; eval "size=\${#${arr_name}[@]}"
  # Helper: is items[$1] a section divider (skipped by navigation)?
  local _is_sec_v
  _is_sec() { eval "_is_sec_v=\${${arr_name}[$1]}"; [[ "$_is_sec_v" == __SEC__\ * ]]; }
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$((size-1)); fi
      # Keep moving past section dividers; if we wrap all the way back to
      # the start, stop (defensive — a list of only sections is malformed).
      local _guard=0
      while _is_sec "$WIZARD_CURSOR" && (( _guard < size )); do
        if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
        else WIZARD_CURSOR=$((size-1)); fi
        _guard=$((_guard+1))
      done ;;
    down)
      if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi
      local _guard=0
      while _is_sec "$WIZARD_CURSOR" && (( _guard < size )); do
        if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
        else WIZARD_CURSOR=0; fi
        _guard=$((_guard+1))
      done ;;
    enter)
      # Defensive: cursor should never land on a section — but if it
      # somehow does, ignore Enter rather than write a marker as the value.
      if _is_sec "$WIZARD_CURSOR"; then return; fi
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
  _wiz_draw_select "Preset" "$cur" '.preset=$v | .lines=$presets[$v].lines' _PRESETS_EX "" "${_PRESETS[@]}"
  _wiz_help_tooltip preset
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
  _wiz_draw_select "Theme" "$cur" '.theme=$v' _THEMES_EX "good warn crit  text  bar style" "${_THEMES[@]}"
}
_wiz_handle_theme() { _wiz_select_handle _THEMES '.theme=$v'; }

_wiz_draw_prefix() {
  local cur; cur="$(jq -r '.global.prefix_style' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Prefix style" "$cur" '.global.prefix_style=$v' _PREFIXES_EX "" "${_PREFIXES[@]}"
}
_wiz_handle_prefix() { _wiz_select_handle _PREFIXES '.global.prefix_style=$v'; }

_wiz_draw_separator() {
  local cur; cur="$(jq -r '.global.separator' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Separator" "$cur" '.global.separator=$v' _SEPARATORS_EX "" "${_SEPARATORS[@]}"
}
_wiz_handle_separator() { _wiz_select_handle _SEPARATORS '.global.separator=$v'; }

_wiz_draw_bar() {
  local cur; cur="$(jq -r '.global.bar_style // ""' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Bar style" "$cur" '.global.bar_style=$v' _BARS_EX "" "${_BARS[@]}"
}
_wiz_handle_bar() { _wiz_select_handle _BARS '.global.bar_style=$v'; }

_wiz_draw_empty() {
  local cur; cur="$(jq -r '.global.empty_behavior // "placeholder"' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Empty data" "$cur" '.global.empty_behavior=$v' _EMPTY_EX "" "${_EMPTY[@]}"
}
_wiz_handle_empty() { _wiz_select_handle _EMPTY '.global.empty_behavior=$v'; }

_wiz_draw_depth() {
  local cur; cur="$(jq -r '.global.color_depth // "auto"' <<<"$CONFIG_JSON")"
  _wiz_draw_select "Color depth" "$cur" '.global.color_depth=$v' _DEPTH_EX "" "${_DEPTH[@]}"
}
_wiz_handle_depth() { _wiz_select_handle _DEPTH '.global.color_depth=$v'; }

# ============================================================
# SECTION: Tokens & Lines screen
# ============================================================
# State:
#   TL_ZONE        : "tabs" (cursor on the line tabs row) | "tokens" (in list)
#   TL_TAB_POS     : 0..N where N = #lines (TAB_POS=N selects the + button)
#   TL_ACTIVE_LINE : currently-edited line index (kept in sync with TL_TAB_POS
#                    when in tabs zone and TAB_POS < N)
#   TL_TOKEN_ROW   : cursor within the active line's row list:
#                      - empty line: only row 0 (the placeholder)
#                      - K tokens: rows 0..2K-2 (even = token, odd = separator)
#   TL_MARK_LINE   : "" or line index of marked token (cross-line cut/paste)
#   TL_MARK_POS    : "" or token index of marked token

TL_ZONE="tabs"
TL_TAB_POS=0
TL_ACTIVE_LINE=0
TL_TOKEN_ROW=0
TL_MARK_LINE=""
TL_MARK_POS=""

# True if the active line has zero tokens.
_tl_line_empty() {
  local n; n="$(jq -r --argjson i "$TL_ACTIVE_LINE" '.lines[$i] | length' <<<"$CONFIG_JSON")"
  [[ "$n" == "0" ]]
}

# Number of tokens in the active line.
_tl_line_count() {
  jq -r --argjson i "$TL_ACTIVE_LINE" '.lines[$i] | length' <<<"$CONFIG_JSON"
}

# Total displayable rows in the active line (token rows + inline separator rows).
# Returns 1 for an empty line (the placeholder row).
_tl_line_rows() {
  local n; n="$(_tl_line_count)"
  if (( n == 0 )); then echo 1
  else echo $(( n * 2 - 1 ))
  fi
}

# Number of lines currently configured.
_tl_num_lines() {
  jq -r '.lines | length' <<<"$CONFIG_JSON"
}

# Token id at row position $1 (must be an even position with at least 1 token).
_tl_token_at() {
  local row="$1"
  local tok_idx=$(( row / 2 ))
  jq -r --argjson i "$TL_ACTIVE_LINE" --argjson j "$tok_idx" '.lines[$i][$j]' <<<"$CONFIG_JSON"
}

# Effective separator id and source ("global" or "override") between tokens
# at indices $1 and $1+1. Echoes "id|source".
_tl_separator_at() {
  local prev_idx="$1"
  local prev_id; prev_id="$(jq -r --argjson i "$TL_ACTIVE_LINE" --argjson j "$prev_idx" '.lines[$i][$j]' <<<"$CONFIG_JSON")"
  local override
  override="$(jq -r --arg id "$prev_id" '.tokens[$id].separator_after // empty' <<<"$CONFIG_JSON")"
  if [[ -n "$override" && "$override" != "null" ]]; then
    echo "$override|override"
  else
    echo "$(jq -r '.global.separator' <<<"$CONFIG_JSON")|global"
  fi
}

# Render the line-tabs row at the top.
_tl_draw_tabs() {
  local n total; n="$(_tl_num_lines)"
  printf '  Line:  '
  local i
  for ((i=0; i<n; i++)); do
    if (( i == TL_TAB_POS )) && [[ "$TL_ZONE" == "tabs" ]]; then
      printf '[%d] ' $((i+1))
    elif (( i == TL_ACTIVE_LINE )); then
      printf '⟨%d⟩ ' $((i+1))
    else
      printf ' %d  ' $((i+1))
    fi
  done
  # + button (only if under max)
  if (( n < 4 )); then
    if (( TL_TAB_POS == n )) && [[ "$TL_ZONE" == "tabs" ]]; then
      printf '[+]'
    else
      printf ' + '
    fi
  fi
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
}

# Render the token list for the active line.
_tl_draw_tokens() {
  local count; count="$(_tl_line_count)"
  if (( count == 0 )); then
    if [[ "$TL_ZONE" == "tokens" ]]; then
      printf '  › (empty — press '\''a'\'' to add a token)\n'
    else
      printf '    (empty — press '\''a'\'' to add a token)\n'
    fi
    return
  fi
  local i tok mark cur sep_info sep_id sep_source
  for ((i=0; i<count; i++)); do
    tok="$(jq -r --argjson l "$TL_ACTIVE_LINE" --argjson j "$i" '.lines[$l][$j]' <<<"$CONFIG_JSON")"
    # Cursor marker
    if [[ "$TL_ZONE" == "tokens" ]] && (( TL_TOKEN_ROW == i*2 )); then
      cur="› "
    else
      cur="  "
    fi
    # Mark indicator (cross-line move)
    if [[ "$TL_MARK_LINE" == "$TL_ACTIVE_LINE" && "$TL_MARK_POS" == "$i" ]]; then
      mark="*"
    else
      mark=" "
    fi
    printf '%s%s%2d. %s\n' "$cur" "$mark" $((i+1)) "$tok"
    # Inline separator row (only if not the last token)
    if (( i < count - 1 )); then
      sep_info="$(_tl_separator_at "$i")"
      sep_id="${sep_info%|*}"
      sep_source="${sep_info#*|}"
      if [[ "$TL_ZONE" == "tokens" ]] && (( TL_TOKEN_ROW == i*2 + 1 )); then
        printf '  ›       ↓ %s (%s)\n' "$sep_id" "$sep_source"
      else
        printf '          ↓ %s (%s)\n' "$sep_id" "$sep_source"
      fi
    fi
  done
}

_wiz_draw_tokens_lines() {
  tui_clear
  printf '  statusline-bar ▸ Tokens & lines\n\n'
  _tl_draw_tabs
  local on_plus=0 nlines
  nlines="$(_tl_num_lines)"
  [[ "$TL_ZONE" == "tabs" ]] && (( TL_TAB_POS == nlines )) && on_plus=1
  if (( on_plus )); then
    printf '\n  ‹+› — Add a new line\n\n'
    printf '  Press Enter to add an empty line (up to %d lines total; you have %d).\n' 4 "$nlines"
    printf '  The new line becomes the active one; ↓ to enter its token list.\n\n'
  else
    _tl_draw_tokens
  fi
  printf -- '─%.0s' {1..60}; printf '\n'
  # Highlight in the preview: focused token (on token row) OR the separator
  # whose row is focused (on separator row).
  local hl="" hl_sep=""
  if [[ "$TL_ZONE" == "tokens" ]]; then
    local count; count="$(_tl_line_count)"
    if (( count > 0 )); then
      if (( TL_TOKEN_ROW % 2 == 0 )); then
        hl="$(_tl_token_at "$TL_TOKEN_ROW")"
      else
        local _pi=$(( (TL_TOKEN_ROW - 1) / 2 ))
        hl_sep="$(jq -r --argjson l "$TL_ACTIVE_LINE" --argjson j "$_pi" '.lines[$l][$j]' <<<"$CONFIG_JSON")"
      fi
    fi
  fi
  printf '  Preview (all lines):\n'
  RENDER_HIGHLIGHT_ID="$hl" RENDER_HIGHLIGHT_SEP_AFTER="$hl_sep" _wiz_preview_line
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  if [[ "$TL_ZONE" == "tabs" ]]; then
    printf '  ←→ switch line   ↓ enter list   Enter on + adds line   d delete line\n'
    printf '  s save   r reset   Esc back\n'
  else
    if [[ -n "$TL_MARK_LINE" ]]; then
      printf '  * Mark active — navigate to target and press p to paste   m cancel mark\n'
      printf '  s save   r reset   Esc back\n'
    else
      printf '  ↑↓ navigate   ←→ switch line   Shift+↑↓ move   Enter edit\n'
      printf '  a add   c change   d delete   m mark   s save   r reset   Esc back\n'
    fi
  fi
  _wiz_help_tooltip tokens_lines
}

# Unsaved-changes prompt shown when quitting the wizard with dirty config.
# Sets $WIZARD_PROMPT_RESULT to one of: save | discard | cancel.
# Does NOT use $(...) — that would capture the prompt's display output and
# the user would see nothing on the terminal. Sets a global instead.
# In scripted mode, an exhausted input buffer means "the script intends to
# stop here" — treat it as discard so we don't infinite-loop reading nothing.
WIZARD_PROMPT_RESULT=""
_wiz_dirty_prompt() {
  if [[ -n "${OPT_TUI_SCRIPT:-}" && -z "$WIZARD_TUI_SCRIPT" ]]; then
    WIZARD_PROMPT_RESULT="discard"; return
  fi
  tui_clear
  printf '\n  Unsaved changes detected.\n\n'
  printf '  Press s to save and quit\n'
  printf '        d to discard and quit\n'
  printf '        c (or any other key) to keep editing\n'
  _wiz_next_key
  case "$KEY" in
    save|char:s|char:S) WIZARD_PROMPT_RESULT="save" ;;
    char:d|char:D)      WIZARD_PROMPT_RESULT="discard" ;;
    *)                  WIZARD_PROMPT_RESULT="cancel" ;;
  esac
}

# Confirmation prompt overlay. Reuses _wiz_next_key for scripted/real input.
# Args: $1 = message.
# Returns 0 if confirmed (y), 1 otherwise.
_tl_confirm() {
  tui_clear
  printf '  %s\n\n' "$1"
  printf '  Press y to confirm, any other key to cancel.\n'
  _wiz_next_key
  case "$KEY" in
    char:y|char:Y) return 0 ;;
    *) return 1 ;;
  esac
}

# Delete the active line entirely. If it was the only line, replace it with
# an empty line so we always have ≥1.
_tl_delete_active_line() {
  CONFIG_JSON="$(jq --argjson i "$TL_ACTIVE_LINE" '
    .lines |= ( del(.[$i]) )
    | if (.lines | length) == 0 then .lines = [[]] else . end
  ' <<<"$CONFIG_JSON")"
  WIZARD_DIRTY=1
  # Adjust cursor: stay in tabs zone, clamp position
  local n; n="$(_tl_num_lines)"
  if (( TL_ACTIVE_LINE >= n )); then TL_ACTIVE_LINE=$((n-1)); fi
  TL_TAB_POS="$TL_ACTIVE_LINE"
  TL_ZONE="tabs"
}

# Insert a token id after the current cursor position in the active line.
# If line is empty, makes it the first token.
_tl_insert_token() {
  local new_id="$1"
  local count; count="$(_tl_line_count)"
  local insert_at
  if (( count == 0 )); then
    insert_at=0
  else
    # If cursor is on a token row, insert after that token.
    # If on a separator row, insert between the two tokens.
    if (( TL_TOKEN_ROW % 2 == 0 )); then
      insert_at=$(( (TL_TOKEN_ROW / 2) + 1 ))
    else
      insert_at=$(( (TL_TOKEN_ROW - 1) / 2 + 1 ))
    fi
  fi
  CONFIG_JSON="$(jq --argjson i "$TL_ACTIVE_LINE" --argjson p "$insert_at" --arg id "$new_id" '
    .lines[$i] |= ( .[0:$p] + [$id] + .[$p:] )
  ' <<<"$CONFIG_JSON")"
  WIZARD_DIRTY=1
  TL_TOKEN_ROW=$(( insert_at * 2 ))
}

# Delete the token at current cursor position. If that leaves the line empty,
# delete the line too (unless it's the only line, then keep it empty).
_tl_delete_token_at_cursor() {
  local count; count="$(_tl_line_count)"
  (( count == 0 )) && return
  if (( TL_TOKEN_ROW % 2 != 0 )); then
    # Cursor on a separator row: remove the override (back to global)
    local prev_idx=$(( (TL_TOKEN_ROW - 1) / 2 ))
    local prev_id; prev_id="$(jq -r --argjson i "$TL_ACTIVE_LINE" --argjson j "$prev_idx" '.lines[$i][$j]' <<<"$CONFIG_JSON")"
    CONFIG_JSON="$(jq --arg id "$prev_id" '
      if .tokens[$id]? then .tokens[$id] |= del(.separator_after) else . end
    ' <<<"$CONFIG_JSON")"
    WIZARD_DIRTY=1
    return
  fi
  local tok_idx=$(( TL_TOKEN_ROW / 2 ))
  if (( count == 1 )); then
    # Last token on this line — delete the line too
    _tl_delete_active_line
    return
  fi
  CONFIG_JSON="$(jq --argjson i "$TL_ACTIVE_LINE" --argjson j "$tok_idx" '
    .lines[$i] |= del(.[$j])
  ' <<<"$CONFIG_JSON")"
  WIZARD_DIRTY=1
  # Move cursor: stay on same row if possible, else step back
  local new_count=$(( count - 1 ))
  local max_row=$(( new_count * 2 - 1 - 1 ))
  (( max_row < 0 )) && max_row=0
  if (( TL_TOKEN_ROW > max_row )); then TL_TOKEN_ROW="$max_row"; fi
  if (( TL_TOKEN_ROW % 2 != 0 )); then TL_TOKEN_ROW=$((TL_TOKEN_ROW-1)); fi
}

# Swap two tokens within the active line (move current token up or down).
_tl_swap_tokens() {
  local direction="$1"  # "up" or "down"
  local count; count="$(_tl_line_count)"
  (( count < 2 )) && return
  if (( TL_TOKEN_ROW % 2 != 0 )); then return; fi  # only on token rows
  local j=$(( TL_TOKEN_ROW / 2 )) other
  if [[ "$direction" == "up" ]]; then
    (( j == 0 )) && return
    other=$((j-1))
  else
    (( j >= count - 1 )) && return
    other=$((j+1))
  fi
  CONFIG_JSON="$(jq --argjson i "$TL_ACTIVE_LINE" --argjson a "$j" --argjson b "$other" '
    .lines[$i] |= ( .[:[$a, $b] | min] + [.[ [$a, $b] | max ], .[ [$a, $b] | min ]] + .[[$a, $b] | max + 1:] )
  ' <<<"$CONFIG_JSON")"
  WIZARD_DIRTY=1
  TL_TOKEN_ROW=$((other * 2))
}

_wiz_handle_tokens_lines() {
  local count num_lines
  count="$(_tl_line_count)"
  num_lines="$(_tl_num_lines)"

  if [[ "$TL_ZONE" == "tabs" ]]; then
    local tabs_count=$num_lines
    (( num_lines < 4 )) && tabs_count=$((num_lines+1))
    case "$KEY" in
      left)
        if (( TL_TAB_POS > 0 )); then TL_TAB_POS=$((TL_TAB_POS-1))
        else TL_TAB_POS=$((tabs_count-1)); fi
        # Sync ACTIVE_LINE if we're on a real line tab
        (( TL_TAB_POS < num_lines )) && TL_ACTIVE_LINE="$TL_TAB_POS"
        TL_TOKEN_ROW=0 ;;
      right)
        if (( TL_TAB_POS < tabs_count - 1 )); then TL_TAB_POS=$((TL_TAB_POS+1))
        else TL_TAB_POS=0; fi
        (( TL_TAB_POS < num_lines )) && TL_ACTIVE_LINE="$TL_TAB_POS"
        TL_TOKEN_ROW=0 ;;
      down)
        if (( TL_TAB_POS < num_lines )); then
          TL_ZONE="tokens"
          TL_TOKEN_ROW=0
        fi ;;
      up)
        # Wrap up from the tabs row to the bottom of the active line's
        # token list — symmetric with down-at-bottom returning to tabs.
        if (( TL_TAB_POS < num_lines )); then
          TL_ACTIVE_LINE="$TL_TAB_POS"
          TL_ZONE="tokens"
          local _max_row; _max_row="$(_tl_line_rows)"
          TL_TOKEN_ROW=$((_max_row - 1))
        fi ;;
      enter)
        if (( TL_TAB_POS == num_lines )) && (( num_lines < 4 )); then
          # + button: add an empty line
          CONFIG_JSON="$(jq '.lines += [[]]' <<<"$CONFIG_JSON")"
          WIZARD_DIRTY=1
          TL_ACTIVE_LINE="$num_lines"
          TL_TAB_POS="$num_lines"
        fi ;;
      char:d)
        # Delete the line currently focused in tabs
        if (( TL_TAB_POS < num_lines )); then
          if (( num_lines == 1 )); then
            local lcount; lcount="$(jq -r '.lines[0] | length' <<<"$CONFIG_JSON")"
            if (( lcount > 0 )); then
              if ! _tl_confirm "Delete the only line (it has $lcount token(s))? It will be replaced by an empty line."; then return; fi
              CONFIG_JSON="$(jq '.lines = [[]]' <<<"$CONFIG_JSON")"
              WIZARD_DIRTY=1
            fi
          else
            local lcount; lcount="$(jq -r --argjson i "$TL_TAB_POS" '.lines[$i] | length' <<<"$CONFIG_JSON")"
            if (( lcount > 0 )); then
              if ! _tl_confirm "Delete line $((TL_TAB_POS+1)) ($lcount token(s))?"; then return; fi
            fi
            TL_ACTIVE_LINE="$TL_TAB_POS"
            _tl_delete_active_line
          fi
        fi ;;
      esc) _wiz_pop ;;
    esac
    return
  fi

  # Tokens zone
  local max_row; max_row="$(_tl_line_rows)"; max_row=$((max_row-1))
  case "$KEY" in
    up)
      if (( TL_TOKEN_ROW > 0 )); then TL_TOKEN_ROW=$((TL_TOKEN_ROW-1))
      else TL_ZONE="tabs"; TL_TAB_POS="$TL_ACTIVE_LINE"; fi ;;
    down)
      if (( TL_TOKEN_ROW < max_row )); then TL_TOKEN_ROW=$((TL_TOKEN_ROW+1))
      else TL_ZONE="tabs"; TL_TAB_POS="$TL_ACTIVE_LINE"; fi ;;
    left)
      # Cycle through lines AND the + add-line button (wraps).
      if (( TL_ACTIVE_LINE > 0 )); then
        TL_ACTIVE_LINE=$((TL_ACTIVE_LINE-1))
        TL_TOKEN_ROW=0
      elif (( num_lines < 4 )); then
        TL_ZONE="tabs"; TL_TAB_POS="$num_lines"  # + position
      else
        TL_ACTIVE_LINE=$((num_lines-1))
        TL_TOKEN_ROW=0
      fi ;;
    right)
      if (( TL_ACTIVE_LINE < num_lines-1 )); then
        TL_ACTIVE_LINE=$((TL_ACTIVE_LINE+1))
        TL_TOKEN_ROW=0
      elif (( num_lines < 4 )); then
        TL_ZONE="tabs"; TL_TAB_POS="$num_lines"  # +
      else
        TL_ACTIVE_LINE=0
        TL_TOKEN_ROW=0
      fi ;;
    shift-up)   _tl_swap_tokens up   ;;
    shift-down) _tl_swap_tokens down ;;
    enter)
      if (( count == 0 )); then return; fi
      if (( TL_TOKEN_ROW % 2 == 0 )); then
        # Token row: open token detail
        WIZARD_TOKEN_DETAIL="$(_tl_token_at "$TL_TOKEN_ROW")"
        _wiz_push token_detail 0
      else
        # Separator row: open separator picker; land cursor on the current override.
        local prev_idx=$(( (TL_TOKEN_ROW - 1) / 2 ))
        TL_SEP_PICKER_TOKEN="$(jq -r --argjson i "$TL_ACTIVE_LINE" --argjson j "$prev_idx" '.lines[$i][$j]' <<<"$CONFIG_JSON")"
        local _sep_cur; _sep_cur="$(jq -r --arg id "$TL_SEP_PICKER_TOKEN" '.tokens[$id].separator_after // empty' <<<"$CONFIG_JSON")"
        local _sep_idx=0
        if [[ -n "$_sep_cur" && "$_sep_cur" != "null" ]]; then
          # _SEP_PICKER[0] = "(use global)", so explicit-override index = _index_of _SEPARATORS + 1
          local _s; _s="$(_index_of _SEPARATORS "$_sep_cur")"
          _sep_idx=$((_s + 1))
        fi
        _wiz_push sep_picker "$_sep_idx"
      fi ;;
    char:a)
      TL_PICKER_MODE="add"
      _tl_build_picker
      _wiz_push token_picker 0 ;;
    char:c)
      # Replace the focused token with another from the catalog.
      if (( count == 0 )) || (( TL_TOKEN_ROW % 2 != 0 )); then return; fi
      TL_PICKER_MODE="replace"
      _tl_build_picker
      local _cur_tok; _cur_tok="$(_tl_token_at "$TL_TOKEN_ROW")"
      local _pidx; _pidx="$(_index_of TOK_PICKER_LIST "$_cur_tok")"
      _wiz_push token_picker "$_pidx" ;;
    char:d)
      if (( count == 0 )); then return; fi
      _tl_delete_token_at_cursor ;;
    char:m)
      if (( count == 0 )); then return; fi
      if (( TL_TOKEN_ROW % 2 == 0 )); then
        TL_MARK_LINE="$TL_ACTIVE_LINE"
        TL_MARK_POS=$(( TL_TOKEN_ROW / 2 ))
      fi ;;
    char:p)
      if [[ -z "$TL_MARK_LINE" ]]; then return; fi
      _tl_paste_mark ;;
    esc) _wiz_pop ;;
  esac
}

# Move the marked token from (TL_MARK_LINE, TL_MARK_POS) to the position
# after the current cursor in the active line. Handles same-line and
# cross-line moves; clears the mark afterward.
_tl_paste_mark() {
  local src_line="$TL_MARK_LINE" src_idx="$TL_MARK_POS"
  local dst_line="$TL_ACTIVE_LINE"
  # Compute destination insert index
  local dst_idx count; count="$(_tl_line_count)"
  if (( count == 0 )); then dst_idx=0
  elif (( TL_TOKEN_ROW % 2 == 0 )); then dst_idx=$(( (TL_TOKEN_ROW / 2) + 1 ))
  else dst_idx=$(( (TL_TOKEN_ROW - 1) / 2 + 1 ))
  fi
  # Get the moved token id
  local tok; tok="$(jq -r --argjson l "$src_line" --argjson j "$src_idx" '.lines[$l][$j]' <<<"$CONFIG_JSON")"
  if [[ "$src_line" == "$dst_line" ]]; then
    # Same-line move
    if (( dst_idx > src_idx )); then dst_idx=$((dst_idx-1)); fi
    CONFIG_JSON="$(jq --argjson l "$src_line" --argjson s "$src_idx" --argjson d "$dst_idx" '
      .lines[$l] |= (del(.[$s]) | .[0:$d] + [.[$s]] + .[$d:])
    ' <<<"$CONFIG_JSON")"
    # The above replaces .[ $s ] with the now-shifted version — simpler to do via two-step:
    CONFIG_JSON="$(jq --argjson l "$src_line" --argjson s "$src_idx" --argjson d "$dst_idx" --arg t "$tok" '
      .lines[$l] |= ( del(.[$s]) )
      | .lines[$l] |= ( .[0:$d] + [$t] + .[$d:] )
    ' <<<"$CONFIG_JSON")"
  else
    # Cross-line: delete from source, insert into dest
    CONFIG_JSON="$(jq --argjson sl "$src_line" --argjson s "$src_idx" --argjson dl "$dst_line" --argjson d "$dst_idx" --arg t "$tok" '
      .lines[$sl] |= del(.[$s])
      | .lines[$dl] |= ( .[0:$d] + [$t] + .[$d:] )
    ' <<<"$CONFIG_JSON")"
  fi
  WIZARD_DIRTY=1
  TL_MARK_LINE=""; TL_MARK_POS=""
  TL_TOKEN_ROW=$(( dst_idx * 2 ))
}

# ============================================================
# SECTION: Token picker (Tokens & Lines → press 'a')
# ============================================================
# Full-screen grouped list of all 42 tokens. Pressing Enter inserts the
# selected token after the cursor in the calling Tokens & Lines screen.

TOK_PICKER_LIST=()    # ordered ids
TOK_PICKER_GROUPS=()  # parallel: source label for each id (for grouping display)
TOK_PICKER_SAMPLES=() # parallel: full render sample (emoji + value, etc.)
TL_PICKER_MODE="add"  # "add" (insert after cursor) or "replace" (swap focused token)

_tl_build_picker() {
  TOK_PICKER_LIST=(); TOK_PICKER_GROUPS=(); TOK_PICKER_SAMPLES=()
  # Force emoji+label so the picker shows icon + label + value (richer than
  # plain emoji, easier to identify each token at a glance).
  local picker_cfg; picker_cfg="$(jq '.global.prefix_style="emoji+label"' <<<"$CONFIG_JSON")"
  # Enrich the synthetic input so flag tokens (fast_mode, exceeds_200k) and
  # optional fields (vim, agent, git_worktree) show what they look like
  # when present. Without this, those tokens render as empty in the picker.
  local picker_input
  picker_input="$(jq '
    .fast_mode = true
    | .exceeds_200k_tokens = true
    | .vim = {"mode":"NORMAL"}
    | .agent = {"name":"demo-agent"}
    | .workspace.git_worktree = "feature-x"
  ' <<<"$EXAMPLES_INPUT_JSON")"
  local id src sample
  while IFS= read -r id; do
    src="$(jq -r --arg id "$id" '.[$id].source' <<<"$TOKENS_JSON")"
    sample="$(INPUT_JSON="$picker_input" \
      CONFIG_JSON="$picker_cfg" \
      COLOR_DEPTH="$WIZARD_COLOR_DEPTH" \
      NOW_EPOCH=9999999999 \
      MOCK_GIT_STATE=in_repo \
      render_token "$id")"
    TOK_PICKER_LIST+=("$id")
    TOK_PICKER_GROUPS+=("$src")
    TOK_PICKER_SAMPLES+=("$sample")
  done < <( jq -r 'keys_unsorted[]' <<<"$TOKENS_JSON" )
}

# One-line description per token id. Used by the picker's tooltip line.
_token_description() {
  case "$1" in
    model)            echo "Current Claude model display name" ;;
    session_name)     echo "Custom session name set via --name or /rename" ;;
    context)          echo "% of context window used; rich formats include tokens used and window size" ;;
    tokens_input)     echo "Total input tokens this session (e.g. 202k)" ;;
    tokens_output)    echo "Total output tokens this session (e.g. 265)" ;;
    context_size)     echo "Configured context window size (e.g. 1M)" ;;
    context_remaining) echo "% of context window still available" ;;
    cache_hit)        echo "% of input tokens served from cache" ;;
    cost)             echo "Session cost in USD (formatted \$0.40)" ;;
    duration)         echo "Total wall-clock time since session start" ;;
    api_duration)     echo "Time spent waiting for API responses" ;;
    lines_added)      echo "Lines of code added in this session (+128)" ;;
    lines_removed)    echo "Lines of code removed in this session (-42)" ;;
    rl_5h)            echo "5-hour rate limit % + reset countdown" ;;
    rl_7d)            echo "7-day rate limit % + reset countdown" ;;
    thinking)         echo "Whether extended thinking is enabled" ;;
    effort)           echo "Current reasoning effort (low/medium/high/xhigh/max)" ;;
    output_style)     echo "Active output style name" ;;
    version)          echo "Claude Code version" ;;
    fast_mode)        echo "Fast mode flag (shows only when true)" ;;
    exceeds_200k)     echo "Token-count-over-200k flag (shows only when true)" ;;
    dir)              echo "Workspace directory basename" ;;
    worktree)         echo "Worktree name (--worktree sessions only)" ;;
    vim_mode)         echo "Current vim mode (NORMAL/INSERT/VISUAL)" ;;
    agent_name)       echo "Name of the running --agent" ;;
    session_id)       echo "Session UUID (first 8 chars)" ;;
    added_dirs)       echo "Count of dirs added via /add-dir" ;;
    git_worktree)     echo "Git worktree name (set for any linked worktree)" ;;
    transcript)       echo "Basename of the transcript file" ;;
    git_branch)       echo "Current git branch name" ;;
    git_status)       echo "Combined +staged ~modified ?untracked counts" ;;
    git_staged)       echo "Count of staged files" ;;
    git_modified)     echo "Count of modified-but-unstaged files" ;;
    git_untracked)    echo "Count of untracked files" ;;
    git_ahead_behind) echo "Ahead/behind count vs upstream" ;;
    clock)            echo "Current time (HH:MM)" ;;
    date)             echo "Current date (YYYY-MM-DD)" ;;
    hostname)         echo "Short hostname" ;;
    user)             echo "Current user (\$USER)" ;;
    battery)          echo "Battery % (low % = critical color)" ;;
    memory)           echo "Memory used % (relaxed thresholds; 80% is normal)" ;;
    load)             echo "1-minute load average" ;;
    *)                echo "" ;;
  esac
}

_wiz_draw_token_picker() {
  tui_clear
  if [[ "${TL_PICKER_MODE:-add}" == "replace" ]]; then
    printf '  statusline-bar ▸ Tokens & lines ▸ Change token\n\n'
  else
    printf '  statusline-bar ▸ Tokens & lines ▸ Add token\n\n'
  fi
  # Set of ids already used somewhere in any line
  local used_ids
  used_ids="$(jq -r '[.lines[][]] | unique | join(" ")' <<<"$CONFIG_JSON")"
  local i id src last_src="" marker check sample
  for ((i=0; i<${#TOK_PICKER_LIST[@]}; i++)); do
    id="${TOK_PICKER_LIST[$i]}"
    src="${TOK_PICKER_GROUPS[$i]}"
    sample="${TOK_PICKER_SAMPLES[$i]}"
    if [[ "$src" != "$last_src" ]]; then
      printf '\n  %s:\n' "$src"
      last_src="$src"
    fi
    marker="  "
    (( i == WIZARD_CURSOR )) && marker="› "
    if grep -qw "$id" <<<"$used_ids"; then check="✓"; else check=" "; fi
    printf '%s%s %-20s  %s\n' "$marker" "$check" "$id" "$sample"
  done
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  ↑↓ navigate (wraps)   Enter add   s save   r reset   Esc cancel\n'
  _wiz_help_tooltip token_picker
}

_wiz_handle_token_picker() {
  local size=${#TOK_PICKER_LIST[@]}
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$((size-1)); fi ;;
    down)
      if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter)
      local chosen="${TOK_PICKER_LIST[$WIZARD_CURSOR]}"
      if [[ "${TL_PICKER_MODE:-add}" == "replace" ]]; then
        local tok_idx=$(( TL_TOKEN_ROW / 2 ))
        CONFIG_JSON="$(jq --argjson l "$TL_ACTIVE_LINE" --argjson j "$tok_idx" --arg id "$chosen" '
          .lines[$l][$j] = $id
        ' <<<"$CONFIG_JSON")"
        WIZARD_DIRTY=1
      else
        _tl_insert_token "$chosen"
      fi
      TL_PICKER_MODE="add"
      _wiz_pop ;;
    esc|left)
      TL_PICKER_MODE="add"
      _wiz_pop ;;
  esac
}

# ============================================================
# SECTION: Separator picker (Tokens & Lines → Enter on a separator row)
# ============================================================
# Shows the 19 separators plus an extra synthetic "(use global)" entry that
# clears the token's separator_after override.

TL_SEP_PICKER_TOKEN=""
_SEP_PICKER=("(use global)" "${_SEPARATORS[@]}")
_SEP_PICKER_EX=()

_build_sep_picker_examples() {
  local global_id; global_id="$(jq -r '.global.separator // "pipe"' <<<"$CONFIG_JSON")"
  local global_ex_idx; global_ex_idx="$(_index_of _SEPARATORS "$global_id")"
  local global_ex="${_SEPARATORS_EX[$global_ex_idx]}"
  _SEP_PICKER_EX=("$global_ex  (current global: $global_id)" "${_SEPARATORS_EX[@]}")
}

_wiz_draw_sep_picker() {
  tui_clear
  printf '  statusline-bar ▸ Tokens & lines ▸ Separator after `%s`\n\n' "$TL_SEP_PICKER_TOKEN"
  local cur
  cur="$(jq -r --arg id "$TL_SEP_PICKER_TOKEN" '.tokens[$id].separator_after // empty' <<<"$CONFIG_JSON")"
  [[ -z "$cur" || "$cur" == "null" ]] && cur="(use global)"
  _wiz_draw_select_inner "$cur" _SEP_PICKER _SEP_PICKER_EX
  printf -- '─%.0s' {1..60}; printf '\n'
  # Preview only changes THIS token's separator_after override — not the global.
  local focused="${_SEP_PICKER[$WIZARD_CURSOR]}"
  local cfg
  if [[ "$focused" == "(use global)" ]]; then
    cfg="$(jq --arg id "$TL_SEP_PICKER_TOKEN" '
      if .tokens[$id]? then .tokens[$id] |= del(.separator_after) else . end
    ' <<<"$CONFIG_JSON")"
  else
    cfg="$(jq --arg id "$TL_SEP_PICKER_TOKEN" --arg v "$focused" '
      .tokens[$id].separator_after = $v
    ' <<<"$CONFIG_JSON")"
  fi
  printf '  Preview (all lines, focused: %s):\n' "$focused"
  INPUT_JSON="$EXAMPLES_INPUT_JSON" \
    CONFIG_JSON="$cfg" \
    COLOR_DEPTH="$WIZARD_COLOR_DEPTH" \
    NOW_EPOCH=9999999999 \
    MOCK_GIT_STATE=out_of_repo \
    RENDER_HIGHLIGHT_ID="$TL_SEP_PICKER_TOKEN" \
    render_all
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  ↑↓ navigate (wraps)   Enter select   s save   r reset   Esc cancel\n'
  _wiz_help_tooltip sep_picker
}

# Compact item-list renderer used by sep_picker (no header, no preview block).
_wiz_draw_select_inner() {
  local cur="$1" arr_name="$2" ex_arr="$3"
  local size; eval "size=\${#${arr_name}[@]}"
  local i name marker is_current ex
  for ((i=0; i<size; i++)); do
    eval "name=\${${arr_name}[$i]}"
    marker="  "
    (( i == WIZARD_CURSOR )) && marker="› "
    is_current=0
    [[ "$name" == "$cur" ]] && is_current=1
    if (( is_current )); then marker+="● "; else marker+="  "; fi
    if [[ -n "$ex_arr" ]]; then eval "ex=\${${ex_arr}[$i]:-}"; else ex=""; fi
    if [[ -n "$ex" ]]; then printf '%s%-16s  %s\n' "$marker" "$name" "$ex"
    else printf '%s%s\n' "$marker" "$name"
    fi
  done
}

# ============================================================
# SECTION: Token detail (Enter on a token row)
# ============================================================
# Edits per-token overrides for: prefix, format, bar_style, separator_after.
# Each override is settable to "(inherit global)" which deletes the override.

WIZARD_TOKEN_DETAIL=""
TL_FIELD=""   # which sub-field we're editing in the field-picker

_wiz_draw_token_detail() {
  tui_clear
  local id="$WIZARD_TOKEN_DETAIL"
  printf '  statusline-bar ▸ Tokens & lines ▸ %s\n\n' "$id"
  local cur_prefix cur_format cur_bar
  cur_prefix="$(jq -r --arg id "$id" '.tokens[$id].prefix // "(inherit global)"' <<<"$CONFIG_JSON")"
  cur_format="$(jq -r --arg id "$id" --argjson tokens "$TOKENS_JSON" '.tokens[$id].format // $tokens[$id].default_format' <<<"$CONFIG_JSON")"
  cur_bar="$(jq -r --arg id "$id" '.tokens[$id].bar_style // "(inherit global)"' <<<"$CONFIG_JSON")"
  # separator_after lives on the inline separator row in Tokens & lines, not here.
  local rows=("Prefix [$cur_prefix]" "Format [$cur_format]" "Bar style [$cur_bar]" "Reset to defaults")
  local i marker
  for ((i=0; i<${#rows[@]}; i++)); do
    marker="  "; (( i == WIZARD_CURSOR )) && marker="› "
    printf '%s%s\n' "$marker" "${rows[$i]}"
  done
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  Preview (all lines, focused: %s):\n' "$id"
  RENDER_HIGHLIGHT_ID="$id" _wiz_preview_line
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  ↑↓ navigate (wraps)   Enter edit field   s save   r reset   Esc back\n'
  _wiz_help_tooltip token_detail
}

_wiz_handle_token_detail() {
  local id="$WIZARD_TOKEN_DETAIL"
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=3; fi ;;
    down)
      if (( WIZARD_CURSOR < 3 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter)
      case "$WIZARD_CURSOR" in
        0) TL_FIELD=prefix;    _wiz_push token_field "$(_tl_field_initial_cursor "$id" prefix)" ;;
        1) TL_FIELD=format;    _wiz_push token_field "$(_tl_field_initial_cursor "$id" format)" ;;
        2) TL_FIELD=bar_style; _wiz_push token_field "$(_tl_field_initial_cursor "$id" bar_style)" ;;
        3) CONFIG_JSON="$(jq --arg id "$id" 'del(.tokens[$id])' <<<"$CONFIG_JSON")"
           WIZARD_DIRTY=1 ;;
      esac ;;
    esc|left) _wiz_pop ;;
  esac
}

# Compute initial cursor index for the token_field picker. Returns 0 when
# there's no override (which lands on "(inherit ...)"), or the index of
# the current override in the picker's full item list (1-based after
# the synthetic "(inherit ...)" first row).
_tl_field_initial_cursor() {
  local id="$1" field="$2"
  local cur; cur="$(jq -r --arg id "$id" --arg f "$field" '.tokens[$id][$f] // empty' <<<"$CONFIG_JSON")"
  if [[ -z "$cur" || "$cur" == "null" ]]; then echo 0; return; fi
  case "$field" in
    prefix)
      local idx; idx="$(_index_of _PREFIXES "$cur")"
      echo $((idx + 1)) ;;
    format)
      local i=1 fmt
      while IFS= read -r fmt; do
        if [[ "$fmt" == "$cur" ]]; then echo "$i"; return; fi
        i=$((i+1))
      done < <( jq -r --arg id "$id" '.[$id].applicable_formats[]' <<<"$TOKENS_JSON" )
      echo 0 ;;
    bar_style)
      local bars=(blocks heavy line braille dots arrows ascii gradient gradient_track) i
      for ((i=0; i<${#bars[@]}; i++)); do
        if [[ "${bars[$i]}" == "$cur" ]]; then echo $((i+1)); return; fi
      done
      echo 0 ;;
  esac
}

# Generic per-field picker. Picks the items list based on $TL_FIELD.
# Right-side examples render the focused token with each option applied,
# so users compare actual outputs (not generic labels).
_wiz_draw_token_field() {
  tui_clear
  local id="$WIZARD_TOKEN_DETAIL"
  printf '  statusline-bar ▸ Tokens & lines ▸ %s ▸ %s\n\n' "$id" "$TL_FIELD"
  local items=() examples=() cur
  case "$TL_FIELD" in
    prefix)
      items=("(inherit global)" "${_PREFIXES[@]}")
      cur="$(jq -r --arg id "$id" '.tokens[$id].prefix // "(inherit global)"' <<<"$CONFIG_JSON")" ;;
    format)
      items=("(inherit default)")
      while IFS= read -r f; do items+=("$f"); done < <( jq -r --arg id "$id" '.[$id].applicable_formats[]' <<<"$TOKENS_JSON" )
      cur="$(jq -r --arg id "$id" '.tokens[$id].format // "(inherit default)"' <<<"$CONFIG_JSON")" ;;
    bar_style)
      items=("(inherit global)" blocks heavy line braille dots arrows ascii gradient gradient_track)
      cur="$(jq -r --arg id "$id" '.tokens[$id].bar_style // "(inherit global)"' <<<"$CONFIG_JSON")" ;;
  esac
  TL_FIELD_ITEMS=("${items[@]}")
  # Build the example column for the current field.
  _build_token_field_examples "$id" "$TL_FIELD"
  examples=("${TL_FIELD_EX[@]}")
  local i name marker
  for ((i=0; i<${#items[@]}; i++)); do
    name="${items[$i]}"
    marker="  "; (( i == WIZARD_CURSOR )) && marker="› "
    [[ "$name" == "$cur" ]] && marker+="● " || marker+="  "
    if [[ -n "${examples[$i]:-}" ]]; then
      printf '%s%-20s  %s\n' "$marker" "$name" "${examples[$i]}"
    else
      printf '%s%s\n' "$marker" "$name"
    fi
  done
  printf -- '─%.0s' {1..60}; printf '\n'
  # Preview: apply focused option to this token only (per-token override).
  printf '  Preview (focused: %s):\n' "${items[$WIZARD_CURSOR]}"
  local focused="${items[$WIZARD_CURSOR]}"
  local cfg
  if [[ "$focused" == "(inherit global)" || "$focused" == "(inherit default)" ]]; then
    cfg="$(jq --arg id "$id" --arg f "$TL_FIELD" '
      if .tokens[$id]? then .tokens[$id] |= del(.[$f]) else . end
    ' <<<"$CONFIG_JSON")"
  else
    cfg="$(jq --arg id "$id" --arg f "$TL_FIELD" --arg v "$focused" '
      .tokens[$id][$f] = $v
    ' <<<"$CONFIG_JSON")"
  fi
  INPUT_JSON="$EXAMPLES_INPUT_JSON" \
    CONFIG_JSON="$cfg" \
    COLOR_DEPTH="$WIZARD_COLOR_DEPTH" \
    NOW_EPOCH=9999999999 \
    MOCK_GIT_STATE=out_of_repo \
    RENDER_HIGHLIGHT_ID="$id" \
    render_all
  printf '\n'
  printf -- '─%.0s' {1..60}; printf '\n'
  printf '  ↑↓ navigate (wraps)   Enter select   s save   r reset   Esc cancel\n'
}

# Build TL_FIELD_EX parallel to TL_FIELD_ITEMS: each entry is the rendering
# of the token under that field option, so users see what each choice does.
TL_FIELD_EX=()
_build_token_field_examples() {
  local id="$1" field="$2"
  TL_FIELD_EX=()
  local i name cfg out
  for ((i=0; i<${#TL_FIELD_ITEMS[@]}; i++)); do
    name="${TL_FIELD_ITEMS[$i]}"
    if [[ "$name" == "(inherit global)" || "$name" == "(inherit default)" ]]; then
      cfg="$(jq --arg id "$id" --arg f "$field" '
        if .tokens[$id]? then .tokens[$id] |= del(.[$f]) else . end
      ' <<<"$CONFIG_JSON")"
    else
      cfg="$(jq --arg id "$id" --arg f "$field" --arg v "$name" '
        .tokens[$id][$f] = $v
      ' <<<"$CONFIG_JSON")"
    fi
    out="$(INPUT_JSON="$EXAMPLES_INPUT_JSON" \
      CONFIG_JSON="$cfg" \
      COLOR_DEPTH="$WIZARD_COLOR_DEPTH" \
      NOW_EPOCH=9999999999 \
      MOCK_GIT_STATE=out_of_repo \
      render_token "$id")"
    TL_FIELD_EX+=("$out")
  done
}

_wiz_handle_token_field() {
  local size=${#TL_FIELD_ITEMS[@]}
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$((size-1)); fi ;;
    down)
      if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter)
      local id="$WIZARD_TOKEN_DETAIL" v="${TL_FIELD_ITEMS[$WIZARD_CURSOR]}"
      if [[ "$v" == "(inherit global)" || "$v" == "(inherit default)" || "$v" == "(use global)" ]]; then
        # Delete the override
        CONFIG_JSON="$(jq --arg id "$id" --arg f "$TL_FIELD" '
          if .tokens[$id]? then .tokens[$id] |= del(.[$f]) else . end
        ' <<<"$CONFIG_JSON")"
      else
        CONFIG_JSON="$(jq --arg id "$id" --arg f "$TL_FIELD" --arg v "$v" '
          .tokens[$id][$f] = $v
        ' <<<"$CONFIG_JSON")"
      fi
      WIZARD_DIRTY=1
      _wiz_pop ;;
    esc|left) _wiz_pop ;;
  esac
}

_wiz_handle_sep_picker() {
  local size=${#_SEP_PICKER[@]}
  case "$KEY" in
    up)
      if (( WIZARD_CURSOR > 0 )); then WIZARD_CURSOR=$((WIZARD_CURSOR-1))
      else WIZARD_CURSOR=$((size-1)); fi ;;
    down)
      if (( WIZARD_CURSOR < size-1 )); then WIZARD_CURSOR=$((WIZARD_CURSOR+1))
      else WIZARD_CURSOR=0; fi ;;
    enter)
      local choice="${_SEP_PICKER[$WIZARD_CURSOR]}"
      if [[ "$choice" == "(use global)" ]]; then
        CONFIG_JSON="$(jq --arg id "$TL_SEP_PICKER_TOKEN" '
          if .tokens[$id]? then .tokens[$id] |= del(.separator_after) else . end
        ' <<<"$CONFIG_JSON")"
      else
        CONFIG_JSON="$(jq --arg id "$TL_SEP_PICKER_TOKEN" --arg v "$choice" '
          .tokens[$id].separator_after = $v
        ' <<<"$CONFIG_JSON")"
      fi
      WIZARD_DIRTY=1
      _wiz_pop ;;
    esc|left) _wiz_pop ;;
  esac
}

run_wizard() {
  if [[ -z "${CONFIG_JSON:-}" ]]; then load_config; fi
  WIZARD_STACK=(main)
  WIZARD_CURSOR_STACK=()
  WIZARD_CURSOR=0
  WIZARD_DIRTY=0
  WIZARD_FLASH=""
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
  WIZARD_NERD_FONT="$(detect_nerd_font)"
  _build_theme_examples
  _build_prefix_examples
  _build_separator_examples
  _build_sep_picker_examples

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
      tokens_lines) _wiz_draw_tokens_lines ;;
      token_picker) _wiz_draw_token_picker ;;
      sep_picker)   _wiz_draw_sep_picker ;;
      token_detail) _wiz_draw_token_detail ;;
      token_field)  _wiz_draw_token_field ;;
    esac
    # Post-save flash: shown for one frame after a submenu save, so users
    # get visible confirmation. Cleared on the next key press.
    if [[ -n "$WIZARD_FLASH" ]]; then
      printf '  \033[1;32m✓ %s\033[0m\n' "$WIZARD_FLASH"
      WIZARD_FLASH=""
    fi
    _wiz_next_key
    # Global shortcuts (apply on any screen)
    case "$KEY" in
      save)
        local _save_path="${CONFIG_PATH:-$(_default_config_path)}"
        save_config "$_save_path" "$CONFIG_JSON"
        WIZARD_DIRTY=0
        # Save never exits — flash a confirmation and stay on the current
        # screen. Use q to leave the wizard once saved.
        WIZARD_FLASH="Saved to $_save_path"
        continue ;;
      reset)
        # `r` resets at the granularity of the current screen, so users
        # don't lose unrelated work:
        #   token_field  → drop the override for just this field on this token
        #   token_detail → drop all overrides for just this token
        #   tokens_lines → reset .lines + .tokens to the active preset's
        #                  layout (keep theme / prefix / separator / etc.)
        #   anywhere else → reset the entire config to factory defaults
        case "$screen" in
          token_field)
            local _tid="$WIZARD_TOKEN_DETAIL" _tf="$TL_FIELD"
            CONFIG_JSON="$(jq --arg id "$_tid" --arg f "$_tf" '
              if .tokens[$id]? then .tokens[$id] |= del(.[$f]) else . end
              | if (.tokens[$id] // {}) == {} then del(.tokens[$id]) else . end
            ' <<<"$CONFIG_JSON")"
            ;;
          token_detail)
            local _tid="$WIZARD_TOKEN_DETAIL"
            CONFIG_JSON="$(jq --arg id "$_tid" 'del(.tokens[$id])' <<<"$CONFIG_JSON")"
            ;;
          tokens_lines)
            local _preset; _preset="$(jq -r '.preset // "default"' <<<"$CONFIG_JSON")"
            CONFIG_JSON="$(jq --argjson presets "$PRESETS_JSON" --arg p "$_preset" '
              .lines = ($presets[$p].lines // .lines)
              | .tokens = {}
            ' <<<"$CONFIG_JSON")"
            ;;
          *)
            CONFIG_JSON="$(build_default_config)"
            ;;
        esac
        WIZARD_DIRTY=1
        continue ;;
      quit|esc)
        # On a submenu: pop back to main.
        # On main: trigger the quit flow (with dirty-check if needed).
        # Esc on a submenu falls through to its own pop handler below.
        if [[ "$KEY" == "esc" && "$screen" != "main" ]]; then
          : # let per-screen handler do the pop
        elif [[ "$screen" != "main" ]]; then
          _wiz_pop; continue
        else
          # Main: quit (with dirty prompt if needed)
          if (( WIZARD_DIRTY )); then
            _wiz_dirty_prompt
            case "$WIZARD_PROMPT_RESULT" in
              save) save_config "${CONFIG_PATH:-$(_default_config_path)}" "$CONFIG_JSON"
                    WIZARD_DIRTY=0; break ;;
              discard) break ;;
              cancel|*) continue ;;
            esac
          else
            break
          fi
        fi ;;
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
      tokens_lines) _wiz_handle_tokens_lines ;;
      token_picker) _wiz_handle_token_picker ;;
      sep_picker)   _wiz_handle_sep_picker ;;
      token_detail) _wiz_handle_token_detail ;;
      token_field)  _wiz_handle_token_field ;;
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
# Color depth tracks the real terminal: themes visibly differ when invoked
# from a TTY; tests force NO_COLOR=1 so output stays diff-stable.
# Args: <preset> <theme> <prefix> <separator> <bar_style|"null">
_render_sample() {
  local preset="$1" theme="$2" prefix="$3" sep="$4" bar="$5"
  local cfg depth
  cfg="$(build_default_config | jq \
    --arg p "$preset" --arg t "$theme" --arg ps "$prefix" --arg s "$sep" --arg b "$bar" \
    --argjson presets "$PRESETS_JSON" '
      .preset=$p
      | .theme=$t
      | .lines=$presets[$p].lines
      | .global.prefix_style=$ps
      | .global.separator=$s
      | (if $b=="null" then .global.bar_style=null else .global.bar_style=$b end)')"
  depth="$(detect_color_depth)"
  INPUT_JSON="$EXAMPLES_INPUT_JSON" \
    CONFIG_JSON="$cfg" \
    COLOR_DEPTH="$depth" \
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
    for t in default solarized graphite light solarized-light catppuccin-latte tokyo-day ayu-light garden dark dracula nord gruvbox tokyo-night catppuccin one-dark rose-pine monokai mocha silver ocean; do
      printf '[ %-16s ] %s\n' "$t" "$(_render_sample minimum "$t" emoji pipe null | head -n 1)"
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
    for b in blocks heavy line braille dots arrows ascii gradient gradient_track; do
      printf '[ %-10s ] %s\n' "$b" "$(_render_sample fancy default emoji pipe "$b" | sed -n '1p')"
    done
  fi
}

run_examples() {
  # The interactive and combinatorial-all modes were dropped in v0.3.0 —
  # catalog mode covers the same need and is fast / predictable. The
  # accepted argument is preserved for backwards compatibility (any value
  # routes to the same catalog).
  examples_catalog
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
      -w|--wizard)  OPT_WIZARD=1 ;;
      -c|--check)   OPT_CHECK=1 ;;
      --no-color)   OPT_NO_COLOR=1 ;;
      --config)
        _i=$((_i+1)); CONFIG_PATH="${!_i}" ;;
      --preset)
        _i=$((_i+1)); OPT_PRESET="${!_i}" ;;
      --theme)
        _i=$((_i+1)); OPT_THEME="${!_i}" ;;
      -e|--examples)
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

  # Render path. With no piped data, print help and exit (same as -h).
  if [[ -t 0 ]]; then
    print_help; exit 0
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
