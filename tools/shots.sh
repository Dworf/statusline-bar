#!/usr/bin/env bash
# ============================================================
# tools/shots.sh — generate the README screenshots from real output
# ============================================================
# Dev tooling only. It never touches statusline-bar.sh and adds no runtime
# dependency: the shipped script still needs nothing beyond bash 3.2+ and jq
# (ADR 0002). This generator additionally wants headless Chrome, which is a
# maintainer-machine concern, not a user-facing one.
#
# Usage:
#   tools/shots.sh              # build every recipe
#   tools/shots.sh hero         # build one recipe by name
#   tools/shots.sh --list       # list recipe names
#   OUT_DIR=/tmp/x tools/shots.sh hero    # write elsewhere (determinism check)
#
# Pipeline, per recipe:
#   1. build a config from the script's OWN defaults (--dump-default-config)
#   2. render tokens with --dump-render-token under the env the e2e suite pins
#   3. convert the ANSI to HTML (ansi_to_html below)
#   4. lay the page out and measure it in headless Chrome (--dump-dom)
#   5. screenshot it at the measured height (--screenshot)
#
# Determinism is the point: the env below is exactly what test/cases.sh pins
# for its render cases, so two runs of the same recipe are byte-identical
# PNGs. Nothing here reads the clock, the real git repo, or the real machine.
#
# SAFETY: every invocation of statusline-bar.sh goes through sb(), which
# always passes --config pointing at a generated throwaway. Never add a code
# path that runs the script bare — with no config it resolves to the
# maintainer's real ~/.config/statusline-bar/config.json (ADR 0004), and the
# wizard SAVES to whatever config it loaded. This file never runs the wizard.

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TOOLS_DIR/.." && pwd)"
SCRIPT="$ROOT/statusline-bar.sh"
# test/sample-input.json is the schema reference and the goldens' fixture; its
# values are picked for test determinism, not for looking good (both rate
# limits reset exactly at the pinned clock, so they render "0s"). The hero gets
# its own synthetic payload — still no real capture, no real paths or
# usernames (ADR 0005) — and the test fixture is left alone.
PAYLOAD="$ROOT/test/sample-input.json"
HERO_INPUT="$TOOLS_DIR/hero-input.json"
OUT_DIR="${OUT_DIR:-$ROOT/screenshots}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/statusline-bar-shots.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# The synthetic workspace dir that sample-input.json points at. Several token
# render functions cd into it, and the mock git reports it as the toplevel.
mkdir -p /tmp/statusline-bar-test

# ============================================================
# SECTION: pinned environment
# ============================================================
# Same values test/cases.sh uses for its render/e2e cases (FAKE_NOW,
# MOCK_GIT_STATE) and for its wizard cases (FAKE_MEMORY/LOAD/BATTERY,
# HOSTNAME_OVERRIDE). COLORTERM=truecolor so detect_color_depth cannot fall
# back to a narrower palette on a different machine.
PINNED_ENV=(
  STATUSLINE_BAR_FAKE_NOW=9999999999
  MOCK_GIT_STATE=in_repo
  STATUSLINE_BAR_FAKE_MEMORY=50
  STATUSLINE_BAR_FAKE_LOAD=1.0
  STATUSLINE_BAR_FAKE_BATTERY=92
  HOSTNAME_OVERRIDE=mac
  USER=alice
  COLORTERM=truecolor
  NO_COLOR=
  STATUSLINE_BAR_DEBUG_INPUT=off
)

# Per-call additions to PINNED_ENV (the wizard recipes need TERM and the nerd
# override that test/cases.sh gives its wizard cases). Set it, call sb, reset.
SB_EXTRA_ENV=()

# sb <config-path> [args...] — run statusline-bar.sh under the pinned env.
# test/bin is prepended to PATH so MOCK_GIT_STATE reaches the mock git.
sb() {
  local cfg="$1"; shift
  PATH="$ROOT/test/bin:$PATH" /usr/bin/env "${PINNED_ENV[@]}" \
    ${SB_EXTRA_ENV[@]+"${SB_EXTRA_ENV[@]}"} \
    "$SCRIPT" --config "$cfg" "$@"
}

die() { printf 'shots: %s\n' "$*" >&2; exit 1; }

# ============================================================
# SECTION: ANSI -> HTML
# ============================================================
# The render path emits only these SGR codes (see color_fg / color_reset):
#   0 reset, 1 bold, 2 dim, 22 normal, 38;2;R;G;B truecolor,
#   38;5;N 256-colour, 37 white (the 16-colour depth).
# The wizard adds 4 (underline) and the 90-97 brights, so they are handled
# too — cheap, and it keeps future recipes (menus, showrooms) working.
ansi_to_html() {
  awk '
    function htmlesc(s) {
      gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s)
      return s
    }
    # 256-colour index -> #rrggbb
    function x256(n,   r, g, b, v, i) {
      if (n < 16) return basic[n]
      if (n < 232) {
        i = n - 16
        r = int(i / 36); g = int((i % 36) / 6); b = i % 6
        return sprintf("#%02x%02x%02x", cube[r], cube[g], cube[b])
      }
      v = 8 + (n - 232) * 10
      return sprintf("#%02x%02x%02x", v, v, v)
    }
    function style(   s) {
      s = ""
      if (fg != "")  s = s "color:" fg ";"
      if (bold)      s = s "font-weight:700;"
      if (dim)       s = s "opacity:.6;"
      if (ul)        s = s "text-decoration:underline;"
      return s
    }
    function emit(text,   st) {
      if (text == "") return ""
      st = style()
      if (st == "") return htmlesc(text)
      return "<span style=\"" st "\">" htmlesc(text) "</span>"
    }
    function reset() { fg = ""; bold = 0; dim = 0; ul = 0 }
    function apply(code,   n, p, i) {
      if (code == "") { reset(); return }
      n = split(code, p, ";")
      for (i = 1; i <= n; i++) {
        if (p[i] == "" || p[i] == "0")       reset()
        else if (p[i] == "1")                bold = 1
        else if (p[i] == "2")                dim = 1
        else if (p[i] == "4")                ul = 1
        else if (p[i] == "22")             { bold = 0; dim = 0 }
        else if (p[i] == "24")               ul = 0
        else if (p[i] == "39")               fg = ""
        else if (p[i] == "38") {
          if (p[i+1] == "2")      { fg = sprintf("#%02x%02x%02x", p[i+2], p[i+3], p[i+4]); i += 4 }
          else if (p[i+1] == "5") { fg = x256(p[i+2] + 0); i += 2 }
        }
        else if (p[i] + 0 >= 30 && p[i] + 0 <= 37) fg = basic[p[i] - 30]
        else if (p[i] + 0 >= 90 && p[i] + 0 <= 97) fg = basic[p[i] - 82]
      }
    }
    BEGIN {
      ESC = sprintf("%c", 27)
      RE  = ESC "\\[[0-9;]*m"
      split("0 95 135 175 215 255", cube, " ")
      cube[0] = 0; cube[1] = 95; cube[2] = 135; cube[3] = 175; cube[4] = 215; cube[5] = 255
      # xterm base 16, tuned to a dark terminal
      split("#484f58 #f85149 #3fb950 #d29922 #58a6ff #bc8cff #39c5cf #b1bac4 " \
            "#6e7681 #ff7b72 #56d364 #e3b341 #79c0ff #d2a8ff #56d4dd #f0f6fc", b, " ")
      for (i = 0; i < 16; i++) basic[i] = b[i+1]
      reset()
    }
    {
      line = $0; out = ""
      while (match(line, RE)) {
        out  = out emit(substr(line, 1, RSTART - 1))
        apply(substr(line, RSTART + 2, RLENGTH - 3))
        line = substr(line, RSTART + RLENGTH)
      }
      out = out emit(line)
      # Newline BETWEEN records, never after the last one: a single-line token
      # render has to come back with no trailing newline (the hero splices it
      # into a span), while a multi-line screen has to keep its line breaks.
      if (NR > 1) printf "\n"
      printf "%s", out
    }
  '
}

# Pull one screen out of a scripted wizard run. The wizard repaints the whole
# screen through `tput clear`, so the stream is N screens separated by ESC[2J;
# a screen is identified by its exact title line rather than by position,
# because quitting unwinds the stack and repaints every parent on the way out
# (so the LAST screen is always Main, whatever you navigated to).
#   wiz_screen <raw-file> <exact title, e.g. "statusline-bar ▸ Theme">
wiz_screen() {
  awk -v pat="$2" '
    BEGIN {
      ESC  = sprintf("%c", 27)
      MARK = ESC "\\[2J"
      PRE  = "^(" ESC "\\[[0-9;]*[A-Za-z])+"
      n = 0
    }
    {
      line = $0
      if (match(line, MARK)) {
        n++
        sub(PRE, "", line)
        screen[n] = line
        t = line; sub(/^ +/, "", t); sub(/ +$/, "", t)
        title[n] = t
      } else if (n > 0) {
        screen[n] = screen[n] "\n" line
      }
    }
    END {
      pick = 0
      for (i = 1; i <= n; i++) if (title[i] == pat) pick = i
      if (pick == 0) {
        printf "no screen titled \"%s\" in %d screens:\n", pat, n > "/dev/stderr"
        for (i = 1; i <= n; i++) printf "  %d: %s\n", i, title[i] > "/dev/stderr"
        exit 1
      }
      printf "%s", screen[pick]
    }
  ' "$1"
}

# ============================================================
# SECTION: Chrome
# ============================================================
CHROME_COMMON=(
  --headless
  --disable-gpu
  --hide-scrollbars
  --force-device-scale-factor=2
  --default-background-color=00000000
  --disable-lcd-text
  --font-render-hinting=none
)

# shoot <html> <png> <css-width>
# Two passes: the page measures itself (it does its own fitting and marker
# placement in JS), we read the height back out of the DOM, then screenshot at
# exactly that size so nothing is clipped and no dead space is captured.
shoot() {
  local html="$1" png="$2" width="$3" height
  [[ -x "$CHROME" ]] || die "Chrome not found at $CHROME (override with \$CHROME)"
  height="$(
    "$CHROME" "${CHROME_COMMON[@]}" --window-size="$width,2000" \
      --dump-dom "file://$html" 2>/dev/null \
    | tr -d '\n' | sed -n 's/.*id="__h"[^>]*>\([0-9][0-9]*\)<.*/\1/p'
  )"
  [[ -n "$height" ]] || die "could not measure page height for $html"
  "$CHROME" "${CHROME_COMMON[@]}" --window-size="$width,$height" \
    --screenshot="$png" "file://$html" >/dev/null 2>&1
  [[ -s "$png" ]] || die "Chrome produced no image at $png"
  printf '  %-44s %5s x %-5s css (x2)\n' "$(basename "$png")" "$width" "$height"
}

# shoot_auto <html> <png>
# For content-sized images (a rendered statusline, a catalog section, a wizard
# screen): the page has no layout of its own to do, so pass one measures the
# card at a window far wider than any content can be, and pass two captures at
# exactly that size. Nothing is clipped and nothing is padded.
shoot_auto() {
  local html="$1" png="$2" dims w h
  [[ -x "$CHROME" ]] || die "Chrome not found at $CHROME (override with \$CHROME)"
  dims="$(
    "$CHROME" "${CHROME_COMMON[@]}" --window-size="4000,6000" \
      --dump-dom "file://$html" 2>/dev/null \
    | tr -d '\n' \
    | sed -n 's/.*id="__w"[^>]*>\([0-9][0-9]*\)<.*id="__h"[^>]*>\([0-9][0-9]*\)<.*/\1 \2/p'
  )"
  w="${dims%% *}"; h="${dims##* }"
  [[ -n "$w" && -n "$h" ]] || die "could not measure $html"
  (( w < 3900 )) || die "$html is ${w}px wide — wider than the measuring window"
  "$CHROME" "${CHROME_COMMON[@]}" --window-size="$w,$h" \
    --screenshot="$png" "file://$html" >/dev/null 2>&1
  [[ -s "$png" ]] || die "Chrome produced no image at $png"
  printf '  %-44s %5s x %-5s css (x2)\n' "$(basename "$png")" "$w" "$h"
}

# ============================================================
# SECTION: plain terminal page
# ============================================================
# Everything except the hero is "a block of real terminal output on a surface".
# Dark is the default; the showroom pairs also render on a light surface,
# because half the shipped themes are built for light terminals and a dark-only
# showroom would misrepresent them.
plain_head() {   # <dark|light> <font-px>
  printf '<!doctype html><html data-mode="%s"><head><meta charset="utf-8">' "$1"
  printf '<title>statusline-bar</title>\n<style>\n'
  cat <<'CSS'
  :root {
    --bg: #0d1117; --fg: #c9d1d9;
    --mono: "JetBrainsMono Nerd Font", "JetBrainsMono NF", "JetBrains Mono",
            "SFMono-Regular", Menlo, monospace;
  }
  html[data-mode="light"] { --bg: #ffffff; --fg: #1f2328; }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; background: var(--bg); color: var(--fg); }
  body { -webkit-font-smoothing: antialiased; }
  #card { display: inline-block; padding: 14px 18px; }
CSS
  printf '  .term { font-family: var(--mono); font-size: %spx; line-height: 1.5;\n' "$2"
  printf '          white-space: pre; font-variant-ligatures: none; margin: 0; }\n'
  printf '</style></head><body>\n'
}

plain_tail() {
  cat <<'JS'
<div id="__w" style="display:none"></div><div id="__h" style="display:none"></div>
<script>
(function () {
  var r = document.getElementById('card').getBoundingClientRect();
  document.getElementById('__w').textContent = Math.ceil(r.width);
  document.getElementById('__h').textContent = Math.ceil(r.height);
})();
</script></body></html>
JS
}

# ansi_shot <ansi-file> <out-png> <dark|light> <font-px>
ansi_shot() {
  local src="$1" png="$2" mode="$3" fs="$4"
  local html="$WORK/$(basename "${png%.png}").$mode.html"
  { plain_head "$mode" "$fs"
    printf '<div id="card"><div class="term">'
    ansi_to_html < "$src"
    printf '</div></div>\n'
    plain_tail
  } > "$html"
  mkdir -p "$(dirname "$png")"
  shoot_auto "$html" "$png"
}

# ============================================================
# SECTION: shared page chrome
# ============================================================
# One palette, one background. Deliberately a single dark surface rather than
# a theme-reactive one: a solid dark block reads correctly inside both the
# light and the dark GitHub themes, whereas a transparent background would
# invert the terminal colours on light.
page_head() {
  cat <<'CSS'
<!doctype html><html><head><meta charset="utf-8"><title>statusline-bar</title>
<style>
  :root {
    --bg:      #0d1117;
    --panel:   #161b22;
    --edge:    #30363d;
    --fg:      #c9d1d9;
    --muted:   #8b949e;
    --accent:  #58a6ff;
    --mono: "JetBrainsMono Nerd Font", "JetBrainsMono NF", "JetBrains Mono",
            "SFMono-Regular", Menlo, monospace;
    --sans: -apple-system, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
  }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; background: var(--bg); color: var(--fg); }
  body { font-family: var(--sans); -webkit-font-smoothing: antialiased; }
  /* Padding is kept tight on purpose: every pixel spent on margins is a pixel
     the statusline cannot use, and the statusline's font size is whatever is
     left after the longest line has to fit. */
  #card { padding: 22px 20px 24px; }
  .caption {
    font: 600 11px/1 var(--sans); color: var(--muted);
    letter-spacing: .09em; text-transform: uppercase; margin-bottom: 14px;
  }
  .caption b { color: var(--accent); font-weight: 700; }
  .stage {
    background: var(--panel); border: 1px solid var(--edge); border-radius: 7px;
    padding: 9px 10px 11px; margin-bottom: 19px;
  }
  /* The two rendered rows sit directly on top of each other, at their own
     line-height, exactly as a terminal would print them. Markers go OUTSIDE
     that pair — above the first row, below the second — each with a 1px
     connector running back to the token it labels. Nothing is allowed
     between the rows. */
  .rowline { line-height: 0; }
  .line {
    display: inline-block;  /* shrink-to-fit, so the measured width is the content */
    vertical-align: top;
    font-family: var(--mono); white-space: pre; line-height: 1.55;
    font-variant-ligatures: none;
  }
  /* 13px bubble + 10px connector; no margin, so the connector runs right up
     to the row's box and the association is unambiguous. */
  .markers { position: relative; height: 23px; }
  .mk {
    position: absolute; transform: translateX(-50%);
    font: 700 9.5px/13px var(--sans); text-align: center;
    width: 13px; height: 13px; border-radius: 50%;
    background: var(--accent); color: #05090f;
  }
  .tick {
    position: absolute; transform: translateX(-50%);
    width: 1px; height: 10px; background: var(--accent); opacity: .7;
  }
  .markers.top .mk   { top: 0; }
  .markers.top .tick { top: 13px; }   /* hangs down from the bubble to row 1 */
  .markers.bot .tick { top: 0; }      /* rises from row 2 up to the bubble */
  .markers.bot .mk   { top: 10px; }
  .sep { color: var(--muted); opacity: .55; }
  /* CSS columns rather than a grid: one description wraps to two lines, and a
     grid would stretch its whole row to match. Columns flow instead, so the
     legend reads top-to-bottom down the left column, then the right. */
  .legend { columns: 2; column-gap: 24px; }
  .item {
    display: flex; align-items: flex-start; gap: 7px;
    break-inside: avoid; margin-bottom: 5px;
  }
  .item .n {
    flex: 0 0 auto; margin-top: 1px;
    font: 700 9.5px/13px var(--sans); text-align: center;
    width: 13px; height: 13px; border-radius: 50%;
    background: var(--accent); color: #05090f;
  }
  .item .t { font: 400 11px/1.35 var(--sans); color: var(--muted); }
  .item .t b { font-family: var(--mono); font-weight: 600; color: var(--fg); }
</style></head><body>
CSS
}

# The layout script. Three jobs:
#   1. fit   — pick one font size so the widest row fills the stage exactly,
#              measured at a large base size for sub-pixel accuracy.
#   2. mark  — put a numbered bubble over the centre of each real token span,
#              so the markers track the actual glyphs instead of guessed
#              offsets. Row 1's markers go in the strip above the pair of
#              rows, row 2's in the strip below. A left-to-right nudge keeps
#              adjacent bubbles apart.
#   3. size  — never let the legend out-shout its subject: the legend text is
#              capped at the fitted statusline size.
page_tail() {
  cat <<'JS'
<div id="__h" style="display:none"></div>
<script>
(function () {
  var BASE = 72, MAXPX = 17, MINGAP = 14, LEGEND_MAX = 11;
  var lines = [].slice.call(document.querySelectorAll('.line'));
  var avail = document.querySelector('.stage').clientWidth
            - 20; /* .stage horizontal padding */
  var widest = 0;
  lines.forEach(function (el) {
    el.style.fontSize = BASE + 'px';
    widest = Math.max(widest, el.getBoundingClientRect().width);
  });
  var size = Math.min(MAXPX, BASE * avail / widest);
  lines.forEach(function (el) { el.style.fontSize = size.toFixed(4) + 'px'; });

  var strips = { '0': document.querySelector('.markers.top'),
                 '1': document.querySelector('.markers.bot') };
  lines.forEach(function (line) {
    var row  = strips[line.getAttribute('data-i')];
    var base = row.getBoundingClientRect();
    var prev = -1e9;
    [].slice.call(line.querySelectorAll('.tok')).forEach(function (tok) {
      var r = tok.getBoundingClientRect();
      var x = r.left - base.left + r.width / 2;
      if (x < prev + MINGAP) x = prev + MINGAP;
      prev = x;
      var mk = document.createElement('span');
      mk.className = 'mk'; mk.style.left = x.toFixed(2) + 'px';
      mk.textContent = tok.getAttribute('data-n');
      row.appendChild(mk);
      var tk = document.createElement('span');
      tk.className = 'tick'; tk.style.left = x.toFixed(2) + 'px';
      row.appendChild(tk);
    });
  });

  var lsize = Math.min(LEGEND_MAX, size);
  [].slice.call(document.querySelectorAll('.item .t')).forEach(function (el) {
    el.style.fontSize = lsize.toFixed(4) + 'px';
  });

  document.getElementById('__h').textContent =
    Math.ceil(document.documentElement.getBoundingClientRect().height);
})();
</script></body></html>
JS
}

# ============================================================
# SECTION: the base config every recipe starts from
# ============================================================
# Not hand-written: it is whatever `--dump-default-config` says the shipped
# default is, with one field forced. Colour depth has to be pinned or the
# render would depend on the terminal that happens to run the generator.
# Built once per run and reused.
base_config() {
  local cfg="$WORK/base.json"
  if [[ ! -s "$cfg" ]]; then
    local boot="$WORK/boot.json"
    printf '{"version":1}\n' > "$boot"
    sb "$boot" --dump-default-config < /dev/null \
      | jq '.global.color_depth = "truecolor"' > "$cfg"
  fi
  printf '%s' "$cfg"
}

# Font size shared by every non-hero image, so the whole set reads as one
# family rather than as N separately-zoomed captures.
TERM_FS=12

# ============================================================
# SECTION: recipe — hero
# ============================================================
# The README's lead image: the default preset rendered for real, every token
# numbered, with a legend whose wording is lifted from the script's own
# catalog so it cannot drift from the code.
recipe_hero() {
  [[ -f "$HERO_INPUT" ]] || die "hero payload not found at $HERO_INPUT"
  # tok_dir cds into workspace.current_dir and asks git for the toplevel; the
  # test mock answers with its own fixture path for any cwd it can reach, so
  # the hero's payload points at a path that does not exist and the token
  # falls back to that path's basename. If the path ever springs into
  # existence the dir token silently changes, so say so loudly instead.
  local hero_cwd; hero_cwd="$(jq -r '.workspace.current_dir' "$HERO_INPUT")"
  if [[ -e "$hero_cwd" ]]; then
    die "$hero_cwd exists; the hero payload needs an absent path (see its _comment)"
  fi

  local cfg; cfg="$(base_config)"

  local ids_l0 ids_l1
  ids_l0="$(jq -r '.lines[0][]' "$cfg")"
  ids_l1="$(jq -r '.lines[1][]' "$cfg")"

  # Descriptions straight out of the wizard's catalog:
  #   [ id                 ] <sample>   ⓘ <description>
  local descs="$WORK/descs.txt"
  sb "$cfg" --examples catalog --only tokens < /dev/null \
    | awk -v q='ⓘ' '
        BEGIN { RE = sprintf("%c", 27) "\\[[0-9;]*m" }
        index($0, "[ ") == 1 && index($0, q) > 0 {
          id = substr($0, 3, index($0, "]") - 3); gsub(/ +$/, "", id)
          d  = substr($0, index($0, q) + length(q) + 1)
          gsub(RE, "", d); gsub(/^ +| +$/, "", d)
          print id "\t" d
        }' > "$descs"
  [[ -s "$descs" ]] || die "could not parse the token catalog"

  # _sep_chars is internal; the rendered line is the source of truth for the
  # separator, so take it from a real render instead of guessing.
  local sep
  sep="$(hero_separator "$cfg")"

  # Both counts come from the script, so the caption ages with the catalog
  # instead of going stale the way the hand-captured shots did.
  local shown total preset
  shown="$(jq -r '[.lines[][]] | length' "$cfg")"
  total="$(sb "$cfg" --dump-data tokens < /dev/null | wc -w | tr -d ' ')"
  preset="$(jq -r '.preset' "$cfg")"

  local html="$WORK/hero.html" n=0
  { page_head
    printf '<div id="card">\n'
    printf '<div class="caption">statusline-bar &nbsp;·&nbsp; <b>%s</b> preset &nbsp;·&nbsp; %s of %s tokens</div>\n' \
      "$preset" "$shown" "$total"
    # Marker strip, both rendered rows back to back, marker strip. Nothing is
    # emitted between the two rows — they have to read as one statusline.
    printf '<div class="stage">\n<div class="markers top"></div>\n'
    local line_ids i=0
    for line_ids in "$ids_l0" "$ids_l1"; do
      printf '<div class="rowline"><span class="line" data-i="%s">' "$i"
      local first=1 id body
      while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        body="$(sb "$cfg" --dump-render-token "$id" < "$HERO_INPUT" | ansi_to_html)"
        [[ -z "$body" ]] && die "token '$id' rendered empty — the hero would mis-number"
        (( first )) || printf '<span class="sep">%s</span>' "$sep"
        first=0
        n=$((n + 1))
        printf '<span class="tok" data-id="%s" data-n="%s">%s</span>' "$id" "$n" "$body"
      done <<< "$line_ids"
      printf '</span></div>\n'
      i=$((i + 1))
    done
    printf '<div class="markers bot"></div>\n</div>\n<div class="legend">\n'
    n=0
    for line_ids in "$ids_l0" "$ids_l1"; do
      while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        n=$((n + 1))
        local desc
        desc="$(awk -F'\t' -v k="$id" '$1 == k { print $2; exit }' "$descs")"
        [[ -n "$desc" ]] || die "no catalog description for token '$id'"
        printf '<div class="item"><span class="n">%s</span><span class="t"><b>%s</b> — %s</span></div>\n' \
          "$n" "$id" "$(printf '%s' "$desc" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
      done <<< "$line_ids"
    done
    printf '</div>\n</div>\n'
    page_tail
  } > "$html"

  mkdir -p "$OUT_DIR"
  if [[ -n "${KEEP_HTML:-}" ]]; then cp "$html" "$OUT_DIR/hero.html"; fi
  # 960 css x2 = a 1920px PNG, the ballpark the hand-captured shots live in.
  shoot "$html" "$OUT_DIR/hero.png" 960
}

# The separator the config asks for, taken from a real render rather than
# from the script's internals: render two tokens standalone, render the line
# they belong to, and the leftover in the middle is the separator.
hero_separator() {
  local cfg="$1" a b whole
  a="$(sb "$cfg" --dump-render-token "$(jq -r '.lines[0][0]' "$cfg")" < "$HERO_INPUT")"
  b="$(sb "$cfg" --dump-render-token "$(jq -r '.lines[0][1]' "$cfg")" < "$HERO_INPUT")"
  whole="$(sb "$cfg" --dump-render-line 0 < "$HERO_INPUT")"
  whole="${whole#"$a"}"
  printf '%s' "${whole%%"$b"*}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# ============================================================
# SECTION: recipes — presets
# ============================================================
# One rendered statusline per preset, through the REAL render path (no
# --dump-*): `--preset NAME` re-materialises .lines from the preset table and
# render_token then picks up that preset's per-token formats, which a
# --dump-render-* call would skip. All of them use the hero payload, so the
# presets can actually be compared against each other.
shot_preset() {   # <file-stem> <preset> [prefix_style]
  local stem="$1" preset="$2" prefix="${3:-}"
  local base; base="$(base_config)"
  local cfg="$WORK/preset-$stem.json" raw="$WORK/preset-$stem.ansi"
  jq --arg pre "$prefix" \
     'if $pre != "" then .global.prefix_style = $pre else . end' \
     "$base" > "$cfg"
  sb "$cfg" --preset "$preset" < "$HERO_INPUT" > "$raw"
  [[ -s "$raw" ]] || die "preset '$preset' rendered nothing"
  ansi_shot "$raw" "$OUT_DIR/$stem.png" dark "$TERM_FS"
}

recipe_presets() {
  shot_preset preset_default       default
  shot_preset preset_minimum       minimum
  shot_preset preset_compact       compact
  shot_preset preset_focus         focus
  shot_preset preset_coder         coder
  shot_preset preset_modern        modern
  shot_preset preset_rates_dark    rates
  shot_preset preset_cache         cache
  shot_preset preset_fancy_dark    fancy
  shot_preset preset_default_nerd  default nerd
  shot_preset preset_default_ascii default ascii
}

# ============================================================
# SECTION: recipes — showrooms
# ============================================================
# Each catalog section, on both surfaces. The light pass exists because nine of
# the 21 themes are built for light terminals; showing them only on #0d1117
# would be a lie about half the catalog.
shot_showroom() {   # <file-stem-base> <catalog section>
  local base_name="$1" section="$2"
  local cfg raw; cfg="$(base_config)"; raw="$WORK/showroom-$section.ansi"
  sb "$cfg" --examples catalog --only "$section" < /dev/null > "$raw"
  [[ -s "$raw" ]] || die "catalog section '$section' printed nothing"
  ansi_shot "$raw" "$OUT_DIR/${base_name}_dark.png"  dark  "$TERM_FS"
  ansi_shot "$raw" "$OUT_DIR/${base_name}_light.png" light "$TERM_FS"
}

recipe_showrooms() {
  shot_showroom showroom_presets     presets
  shot_showroom showroom_themes      themes
  shot_showroom showroom_prefix_sets prefixes
  shot_showroom showroom_seperators  separators   # sic — the shipped filename
  shot_showroom showroom_barstyles   bars
  shot_showroom showroom_tokens      tokens
}

# ============================================================
# SECTION: recipes — wizard menus
# ============================================================
# Driven by --wizard --tui-script, the way test/cases.sh drives its wizard
# cases: D/U/L/R arrows, \n enter, q quit, lowercase letters as themselves.
#
# SAFETY: the wizard SAVES to whatever config it loaded. Every run here gets a
# throwaway copy inside $WORK via an explicit --config, and no script below
# ever sends 's'. Never let one of these run without --config.
#
# The target screen is found by its exact title, not by position: when the
# script runs out, the wizard treats that as quit and unwinds the stack,
# repainting every parent screen on the way out — so the last screen painted is
# always Main no matter where you navigated to.
shot_menu() {   # <file-stem> <tui-script> <exact screen title>
  local stem="$1" script="$2" title="$3"
  # An empty --tui-script is not "do nothing" — the wizard reads it as "not
  # scripted" and drops into the interactive key loop, which with stdin at
  # /dev/null spins forever. Hence $'...' quoting for every script below
  # (command substitution eats trailing newlines) and this guard.
  [[ -n "$script" ]] || die "menu '$stem': empty tui-script would hang the wizard"
  local base; base="$(base_config)"
  local cfg="$WORK/menu-$stem.json" raw="$WORK/menu-$stem.raw" scr="$WORK/menu-$stem.ansi"
  cp "$base" "$cfg"
  SB_EXTRA_ENV=(TERM=xterm-256color STATUSLINE_BAR_FORCE_NERD=no)
  sb "$cfg" --wizard --tui-script "$script" < /dev/null > "$raw" 2>&1
  SB_EXTRA_ENV=()
  wiz_screen "$raw" "$title" > "$scr" || die "menu '$stem': $title not reached"
  ansi_shot "$scr" "$OUT_DIR/$stem.png" dark "$TERM_FS"
}

# Main-menu cursor rows: 0 Preset, 1 Theme, 2 Prefix style, 3 Separator,
# 4 Bar style, 5 Tokens & lines, 6 Empty data, 7 Color depth.
# In Tokens & lines, Enter lands in the tabs zone; one D drops into the token
# list at row 0, and each further D steps a row (token, separator, token, ...),
# so token #n of the active line is row 2n.
recipe_menus() {
  local T='statusline-bar ▸'
  shot_menu menu_main         'q'                  "$T Main"
  shot_menu menu_preset       $'\n'                "$T Preset"
  shot_menu menu_theme        $'D\n'               "$T Theme"
  shot_menu menu_prefixstyle  $'DD\n'              "$T Prefix style"
  shot_menu menu_seperator    $'DDD\n'             "$T Separator"
  shot_menu menu_barstyle     $'DDDD\n'            "$T Bar style"
  shot_menu menu_tokens_lines $'DDDDD\nD'          "$T Tokens & lines"
  shot_menu menu_tokens_lines_add_token \
                              $'DDDDD\nDa'         "$T Tokens & lines ▸ Add token"
  shot_menu menu_tokens_lines_model \
                              $'DDDDD\nD\n'        "$T Tokens & lines ▸ model"
  shot_menu menu_tokens_lines_model_prefix \
                              $'DDDDD\nD\n\n'      "$T Tokens & lines ▸ model ▸ prefix"
  shot_menu menu_tokens_lines_model_format \
                              $'DDDDD\nD\nD\n'     "$T Tokens & lines ▸ model ▸ format"
  # rl_5h is token #3 on line 0 -> row 6: one D to enter the list, six to walk.
  shot_menu menu_tokens_lines_rl5h_format \
                              $'DDDDD\nDDDDDDD\nD\n' \
                                                   "$T Tokens & lines ▸ rl_5h ▸ format"
}

# ============================================================
# SECTION: driver
# ============================================================
RECIPES=(hero presets showrooms menus)

case "${1:-}" in
  --list|-l) printf '%s\n' "${RECIPES[@]}"; exit 0 ;;
  -h|--help)
    sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
esac

command -v jq >/dev/null 2>&1 || die "jq is required"
[[ -x "$SCRIPT" ]] || die "statusline-bar.sh not found at $SCRIPT"
[[ -f "$PAYLOAD" ]] || die "payload not found at $PAYLOAD"

wanted=("$@")
(( ${#wanted[@]} )) || wanted=("${RECIPES[@]}")

for name in "${wanted[@]}"; do
  if ! declare -F "recipe_$name" >/dev/null; then
    die "unknown recipe '$name' (known: ${RECIPES[*]})"
  fi
  printf 'shots: %s\n' "$name"
  "recipe_$name"
done
