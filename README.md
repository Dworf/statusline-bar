# statusline-bar

Customizable Claude Code statusline. Single bash file, no JavaScript, no network, no daemon.

```
🤖 Opus 4.7 (1M) | 🧠 4% | 💰 $0.40 | ⏱️ 5h ░░░░░░░░░░ 0% 🔄 4h 58m | ⏱️ 7d █░░░░░░░░░ 6% 🔄 5d 23h
💭 true | 💪 xhigh | 📁 my-project | 🌿 main | ➕ +128 | ➖ -42 | ⏳ 3m 50s
```

## Why

The Claude Code ecosystem already has a dozen excellent statuslines, each great at one thing. We wanted **one tool** that:

- ships every useful field — model, cost, context %, cache hit ratio, rate limits (5h + 7d) with countdowns, git branch + status + ahead/behind, vim mode, agent name, session id, plus zero-cost local readouts (clock, battery, memory, load average, hostname)
- looks great out of the box (7 presets, 10 themes, 8 progress-bar styles, truecolor support)
- is **trivial to install** — one bash file + `jq`, no Node, no Rust, no Python, no daemon
- stays customizable down to the smallest detail (per-token prefix, format, bar style, and separator-after overrides)

## Features

- **Single file**, ~1,750 lines of bash 3.2+. Drop it anywhere on `$PATH`.
- **Up to 4 lines** of statusline, each a freely-arranged token sequence.
- **39 tokens**: 26 from Claude Code's stdin JSON + 6 from `git` + 7 from local OS.
- **9 format variants** per token: `value`, `percent`, `progressbar`, `progressbar+percent`, `countdown`, `remaining`, `progressbar+percent+countdown`, `combined`, `flag`.
- **7 presets**: `minimum`, `compact`, `default`, `modern`, `fancy`, `everything`, `maximum`.
- **10 themes**: `default`, `dark`, `light`, `graphite`, `solarized`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `catppuccin`.
- **8 progress-bar styles**: `blocks`, `heavy`, `line`, `braille`, `dots`, `arrows`, `ascii`, `gradient` (sub-character precision via eighths).
- **8 prefix styles**: `none`, `label`, `emoji`, `nerd`, `ascii` + `emoji+label`, `label+emoji`, `nerd+label`.
- **19 separators** across 4 families: ASCII (3), Unicode (10), Decorative (3), Powerline / Nerd-Font (3).
- **Interactive TUI wizard** with always-visible live preview pane.
- **Auto-detected color depth** (truecolor / 256 / 16 / none) with `$NO_COLOR` honored.
- **Threshold-based coloring** with sane defaults — battery inverts (low % = critical), memory uses a relaxed table (80% is normal).
- **Configurable empty-data handling** (`hide` or `placeholder`).
- **JSON Schema** shipped at the repo root + `$schema` field in the auto-created config — VS Code, Cursor, JetBrains, and Neovim's LSP all give you autocomplete and inline docs while editing.
- **Project-level config** at `./.statusline-bar.json` overrides home-dir config.
- **No network calls.** Ever.

## Install

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Dworf/statusline-bar/v0.1.0/statusline-bar.sh \
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

## Quick configure

Launch the interactive wizard:

```bash
statusline-bar.sh -c
```

Arrow keys + Enter to navigate, Esc to go back, **s** to save, **r** to reset, **q** to quit. The bottom pane shows a live preview as you change settings.

## Browse

```bash
statusline-bar.sh --examples catalog
```

Prints one sample per preset / theme / prefix style / separator / bar style. For the full combinatorial tour, `--examples all` (slow; pipes through `$PAGER`).

## Catalog

- **39 tokens** — 26 from Claude stdin (model, context, cost, rate limits, vim mode, agent name, session id, …) + 6 git + 7 OS (clock, battery, memory, load, …)
- **7 presets** — `minimum`, `compact`, `default`, `modern`, `fancy`, `everything`, `maximum`
- **10 themes** — `default`, `dark`, `light`, `graphite`, `solarized`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `catppuccin`
- **8 prefix styles** — `none`, `label`, `emoji`, `nerd`, `ascii` + 3 combos
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

Validate any config with `statusline-bar.sh --check --config PATH`.

## CLI

```text
statusline-bar.sh [FLAGS]               render from stdin (Claude Code mode)
statusline-bar.sh -c | --wizard         interactive setup
statusline-bar.sh --examples [MODE]     browse presets/themes/etc
statusline-bar.sh --check               validate config; exit 0/1
statusline-bar.sh --preset NAME         one-shot render override
statusline-bar.sh --theme NAME          one-shot render override
statusline-bar.sh --no-color            disable ANSI output
statusline-bar.sh --config PATH         use specific config file
```

## Changelog

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