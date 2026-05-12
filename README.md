# statusline-bar

Customizable Claude Code statusline. Single bash file, no JavaScript, no network, no daemon.

```
🤖 Opus 4.7 (1M) | 🧠 4% | 💰 $0.40 | 🕔 ░░░░░░░░░░ 0% 🔄 4h 58m | 🕖 █░░░░░░░░░ 6% 🔄 5d 23h
💭 true | 💪 xhigh | 📁 my-project | 🌿 main | ➕ +128 | ➖ -42 | ⏳ 3m 50s
```

## Why

The Claude Code ecosystem already has a dozen excellent statuslines, each great at one thing. We wanted **one tool** that:

- ships every useful field — model, cost, context %, cache hit ratio, rate limits (5h + 7d) with countdowns, git branch + status + ahead/behind, vim mode, agent name, session id, plus zero-cost local readouts (clock, battery, memory, load average, hostname)
- looks great out of the box (7 presets, 10 themes, 8 progress-bar styles, truecolor support)
- is **trivial to install** — one bash file + `jq`, no Node, no Rust, no Python, no daemon
- stays customizable down to the smallest detail (per-token prefix, format, bar style, and separator-after overrides)

## Features

- **Single file**, ~3,000 lines of bash 3.2+. Drop it anywhere on `$PATH`.
- **Up to 4 lines** of statusline, each a freely-arranged token sequence.
- **39 tokens**: 26 from Claude Code's stdin JSON + 6 from `git` + 7 from local OS.
- **9 format variants** per token: `value`, `percent`, `progressbar`, `progressbar+percent`, `countdown`, `remaining`, `progressbar+percent+countdown`, `combined`, `flag`.
- **7 presets**: `minimum`, `compact`, `default`, `modern`, `fancy`, `everything`, `maximum`.
- **10 themes**: `default`, `dark`, `light`, `graphite`, `solarized`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `catppuccin`.
- **8 progress-bar styles**: `blocks`, `heavy`, `line`, `braille`, `dots`, `arrows`, `ascii`, `gradient` (sub-character precision via eighths).
- **8 prefix styles**: `none`, `label`, `emoji`, `nerd`, `ascii` + `emoji+label`, `label+emoji`, `nerd+label`.
- **19 separators** across 4 families: ASCII (3), Unicode (10), Decorative (3), Powerline / Nerd-Font (3).
- **Interactive TUI wizard** with always-visible live preview pane and a dedicated **Tokens & lines** screen for add / change / delete / reorder, inline separator editing, and per-token overrides.
- **Auto-detected color depth** (truecolor / 256 / 16 / none) with `$NO_COLOR` honored.
- **Threshold-based coloring** with sane defaults — battery inverts (low % = critical), memory uses a relaxed table (80% is normal).
- **Configurable empty-data handling** (`hide` or `placeholder`).
- **JSON Schema** shipped at the repo root + `$schema` field in the auto-created config — VS Code, Cursor, JetBrains, and Neovim's LSP all give you autocomplete and inline docs while editing.
- **Project-level config** at `./.statusline-bar.json` overrides home-dir config.
- **No network calls.** Ever.

## Install

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Dworf/statusline-bar/v0.3.0/statusline-bar.sh \
  -o ~/.local/bin/statusline-bar.sh
chmod +x ~/.local/bin/statusline-bar.sh
```

Then point Claude Code's `statusLine.command` at the absolute path. In `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/you/.local/bin/statusline-bar.sh"
  }
}
```

Requirements: `bash` 3.2+ and `jq` (both default on macOS / mainstream Linux). Optional: `git`, `fc-list`, `pmset`/`/sys/class/power_supply` for richer tokens.

### Nerd Fonts (optional)

A few separators (`chevron`, `slant`, `chevron_thin`) and the `nerd` / `nerd+label` prefix styles use [Nerd Font](https://www.nerdfonts.com/) glyphs. The wizard detects whether you have one installed and labels those options accordingly. If you don't, the script still works — every other separator / prefix style renders fine without.

**Install a Nerd Font:**

- **macOS** (Homebrew): `brew install --cask font-jetbrains-mono-nerd-font` (any of the [Nerd Fonts casks](https://github.com/Homebrew/homebrew-cask-fonts) works — pick the family you like)
- **Linux** (Debian/Ubuntu): `sudo apt install fonts-firacode` for FiraCode-Nerd-equivalent, or download a release zip from [github.com/ryanoasis/nerd-fonts/releases](https://github.com/ryanoasis/nerd-fonts/releases) and extract to `~/.local/share/fonts/`, then `fc-cache -f`
- **Arch**: `sudo pacman -S ttf-nerd-fonts-symbols` for symbol-only, or any `ttf-*-nerd` package for a full family
- **Manual**: download a `.zip` from [nerdfonts.com](https://www.nerdfonts.com/font-downloads) and install via your OS's font manager

Then set your terminal's font to the Nerd Font variant (e.g. "JetBrainsMono Nerd Font" instead of "JetBrainsMono"). Restart the terminal and the wizard's hint will switch to `Nerd Font ✓ detected`.

## Quick configure

Launch the interactive wizard:

```bash
statusline-bar.sh -w        # or --wizard
```

The wizard opens on a main menu with rows for preset, theme, prefix style, separator, bar style, **Tokens & lines** (the full layout editor — see below), empty-data behavior, and color depth. Use:

- **↑/↓** to navigate, **←/→** to switch where applicable, **Enter** to drill in
- **s** save, **r** reset to defaults, **q** quit (prompts to save if unsaved changes)
- **Esc** goes back one level

The bottom pane is a live preview that re-renders as you change settings. The focused token / separator is **underlined and wrapped in `▶ ◀` markers** so its real colors stay visible.

Inside **Tokens & lines** you get:

- A horizontal line tab strip (`[1]  2   3   +`) — `←/→` switches the active line, `↓` enters the token list, `d` deletes a line, Enter on `+` adds a new one (up to 4).
- Token rows + always-visible inline separator rows (`↓ pipe (global)` / `↓ star (override)`).
- **a** add a token, **c** change it, **d** delete, **m** mark for cross-line move, **p** paste, **Shift+↑/↓** move within the line.
- Enter on a token opens its per-override detail screen; Enter on a separator row opens a separator picker scoped to that one position.

## Browse

```bash
statusline-bar.sh -e        # or --examples
```

Prints a catalog: one sample per preset, theme, prefix style, separator, and bar style. Uses your real terminal's color depth, so themes visibly differ — what you see is what you'd get if you picked it. Pipe through `less -R` if you want pagination with ANSI.

## Reference

- **39 tokens** — 26 from Claude stdin (model, context, cost, rate limits, vim mode, agent name, session id, …) + 6 git + 7 OS (clock, battery, memory, load, …)
- **7 presets** — `minimum`, `compact`, `default`, `modern`, `fancy`, `everything`, `maximum`
- **10 themes** — `default`, `dark`, `light`, `graphite`, `solarized`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `catppuccin`
- **8 prefix styles** — `none`, `label`, `emoji`, `nerd`, `ascii` + `emoji+label`, `label+emoji`, `nerd+label`
- **19 separators** — ASCII (3), Unicode (10), Decorative (3), Powerline (3)
- **8 bar styles** — `blocks`, `heavy`, `line`, `braille`, `dots`, `arrows`, `ascii`, `gradient`
- **9 formats** — `value`, `percent`, `progressbar`, `progressbar+percent`, `countdown`, `remaining`, `progressbar+percent+countdown`, `combined`, `flag`

Globals can be overridden per-token via `tokens.<id>.prefix`, `.format`, `.bar_style`, `.separator_after`.

## Configuration

Config lookup order (highest precedence first):

1. `--config PATH` flag
2. `$STATUSLINE_BAR_CONFIG`
3. `./.statusline-bar.json` (project-local — pin a per-project statusline)
4. `$XDG_CONFIG_HOME/statusline-bar/config.json`
5. `~/.config/statusline-bar/config.json`
6. Built-in defaults

The auto-created config includes a `$schema` field pointing at this repo's `schema.json` — VS Code, Cursor, JetBrains, and Neovim's LSP all give you autocomplete and inline docs while editing.

Validate any config with `statusline-bar.sh -c --config PATH` (or `--check`).

## CLI

```text
statusline-bar.sh [FLAGS]            render from stdin (Claude Code mode)
statusline-bar.sh -w | --wizard      interactive setup
statusline-bar.sh -e | --examples    print a catalog of presets/themes/etc
statusline-bar.sh -c | --check       validate config; exit 0/1

Flags:
  -h, --help                show help
  -V, --version             print version
  -w, --wizard              enter setup wizard
  -e, --examples            print the catalog
  -c, --check               validate config and exit
      --config PATH         use this config file instead of default
      --preset NAME         one-shot render with this preset
      --theme NAME          one-shot render with this theme
      --no-color            disable ANSI color output
```

`statusline-bar.sh` with no flags and no stdin prints the help (same as `-h`). When piped JSON arrives on stdin (i.e. Claude Code calls it), it renders the statusline.

## Changelog

### 0.3.0 — 2026-05-12

**Tokens & lines** — a full TUI for managing your statusline layout, plus a lot of preview-pane polish.

- **New "Tokens & lines" screen** replaces the old `Lines` / `Tokens` placeholders on the main menu. Manage every line and every token from one place:
  - Horizontal **line tabs** (`[1] [2] [3] +`) at the top — `←`/`→` switches the active line, `↓` enters the token list, Enter on `+` adds a new line (up to 4), `d` deletes a line with confirmation if non-empty.
  - Token rows + **inline separator rows** (always visible, labeled `↓ pipe (global)` or `↓ star (override)`).
  - `a` add a token, `c` change the token at cursor, `d` delete, `m` mark for cross-line move, `p` paste, `Shift+↑↓` move within a line, Enter on a token opens its detail screen, Enter on a separator row opens a separator picker scoped to that one position (with a `(use global)` row that clears the override).
  - `←`/`→` from inside the tokens zone also cycle through lines + the `+` tab (no need to climb back up).
- **Token picker**: 39 tokens grouped by source (Claude stdin / git / OS), each row showing a live `emoji+label` sample rendered with synthetic data (e.g. `🤖 Model: Opus 4.7 (1M)`, `🕔 5h █████░░░░░ 50% 🔄 0s`). `✓` marks tokens already used somewhere. Cursor on a row tooltips its one-line description ("context_pct — % of context window used (formatted 4%)" etc.). Used by both `a add` and `c change`.
- **Token detail screen** for per-token overrides: `prefix`, `format`, `bar_style`, and `Reset to defaults`. Each sub-picker opens with the cursor on the currently-active value, and the right-side example column renders the actual token under that option so you can compare outputs directly. `r` resets just this token (screen-aware shortcut).
- **Preview highlighting** redesigned. The focused token / separator no longer reverse-video-inverts colors (which lied about how it would actually render). Now the focused content is **underlined** and wrapped in bold-bright-yellow `▶ ◀` markers — colors stay accurate.
- **Unsaved-changes prompt** when you press `q` or `Esc` on the main menu with edits pending — choose `s` save+quit, `d` discard+quit, or any other key to cancel and keep editing. Previously the prompt wasn't reachable because of a subshell-captured-output bug.
- **Conditional "Reset to defaults" row** appears at the bottom of the main menu when the config diverges from factory defaults, with a count of customizations.
- **CLI cleanup**:
  - `--examples` now always prints the catalog; the `interactive` and `all` sub-modes (and the sub-picker prompt) are gone.
  - Catalog output now uses your real terminal color depth — 10 themes visibly differ instead of looking identical.
- **Prefix data cleanups** for cleaner picker samples:
  - `rl_5h` / `rl_7d` emoji `⏱️ 5h` / `⏱️ 7d` → `🕔` / `🕖` (removes the duplicated `5h 5h` under `emoji+label`).
  - `lines_added` / `lines_removed` labels `+:` / `-:` → `Added:` / `Removed:`.
  - `version` label `v` → `Version:`.
  - VS-16 variation selectors added to `🏷️` / `⚡️` / `⌨️` / `🖥️` so they render as wide emojis (consistent column count with other prefixes).
  - `git_ahead_behind` icon `⇅` (math symbol) → `🔀` (proper emoji).
- **`git_run` helper** so git tokens work from a synthetic input (mock-on-PATH) even when the workspace dir doesn't exist on disk.
- Lots of small wizard fixes from earlier in this cycle: cursor restoration on return from sub-menus, wrap-around navigation, per-item examples on every selection screen, theme menu columns (`good warn crit text bar style`), live Nerd-Font detection labels, breadcrumbs on every screen, dynamic `Config:` line in `--help`, `-w/-c/-e` short-flag remap.

Known follow-ups for v0.4.0: per-token + global colors (`text`, `prefix`, `separator`), full Nerd-Font glyph mapping for the `nerd` / `nerd+label` prefix styles.

Tests: 115 e2e cases passing.

### 0.2.0 — 2026-05-11

Wizard polish, CLI cleanup, and live Nerd-Font detection.

- **Wizard live preview** updates every time you move the cursor in any sub-menu (preset / theme / prefix / separator / bar / empty / depth) — the bottom pane now reflects the *focused* option, not the current saved config.
- **Cursor memory** — sub-menus open with the cursor on the currently-selected item, not row 0. Returning to a parent menu restores the cursor to the row you came from.
- **Wrap-around navigation** — `↑` at the top jumps to the last item; `↓` at the bottom jumps to the first.
- **Per-item example previews** on the right side of every sub-menu so you can compare all options at a glance: separator characters drawn literally (`a │ b │ c`), `model` token rendered in each prefix style, 10-char bars at 50% in each bar style, etc.
- **Theme menu columns** — `good / warn / crit / text / bar style` header above the swatches, with `Aa` shown in the theme's accent color (= what regular non-threshold tokens look like) plus the suggested bar style each theme uses when `global.bar_style` is `null`.
- **Live Nerd-Font detection** surfaced inline:
  - Separator menu (chevron / slant / chevron_thin): `(Nerd Font ✓ detected)` / `(Nerd Font ✗ — install: nerdfonts.com)` / `(Nerd Font: status unknown)`
  - Prefix menu (nerd / nerd+label): same detection plus a note that the per-token glyph map is empty in v0.2.0 and ships in a follow-up.
- **Breadcrumbs** on every screen — `statusline-bar ▸ Theme`, `statusline-bar ▸ Separator`, etc.
- **Theme colors actually differ** in the wizard preview now — the preview uses the real terminal color depth instead of hardcoded `none`.
- **CLI flag remap**: `-w` for wizard (was `-c`), `-c` for `--check`, `-e` for `--examples`.
- **Bare invocation prints help** instead of prompting `set up config? (y/n)`. Help text now includes the wizard hint and a dynamic `Config:` line showing which file is in use (or `no config file found — using built-in defaults`).
- **Bug fixes**:
  - `_wiz_next_key` no longer hangs when a scripted input is exhausted (it now checks the parse-time `OPT_TUI_SCRIPT` instead of the consumed buffer).
  - bash 3.2 sparse-array trap in the cursor-stack pop path — arrays are now sliced rather than `unset`-ed.
  - Wizard's `tui_cleanup` survives non-TTY stty failures.

### 0.1.0 — 2026-05-11

- Initial release. 39 tokens, 7 presets, 10 themes, 8 prefix styles, 19 separators, 8 bar styles, 9 formats, per-token overrides.
- Interactive TUI wizard for preset / theme / prefix / separator / bar / empty / color-depth.
- `--examples catalog` and `--examples all` modes.
- Project-level config (`./.statusline-bar.json`) and `schema.json` for editor autocomplete.
- 114 end-to-end test cases.
- Known follow-ups for v0.1.1: TUI line-editor (add / reorder / remove lines), TUI per-token overrides (prefix/format/bar/separator-after), `--examples interactive` mode, full Nerd-font glyph mapping for the `nerd` prefix style.

## Contributing

Issues and PRs welcome at https://github.com/Dworf/statusline-bar.

Run the test suite before submitting:

```bash
./test/run-tests.sh
```

## License

MIT — see LICENSE.

## Acknowledgements

- **Anthropic** for [Claude Code](https://claude.com/product/claude-code) and the open statusline interface that makes this possible.
- The broader **Claude Code statusline community** — the many open-source statusline projects whose presets, layouts, themes, progress-bar styles, and rendering ideas inspired this one.