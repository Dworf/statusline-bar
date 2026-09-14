# statusline-bar

Customizable Claude Code statusline. Single bash file, no JavaScript, no network, no daemon.

The `default` preset rendered against a real Claude Code session:

![default preset rendered in the terminal — two lines covering model, context, cost, rate limits, git status, line counters, and duration](screenshots/preset_default.png)

Run `--examples` to see this and every other preset, theme, prefix style, separator, and bar rendered live in your terminal — the catalog below shows the same output as screenshots.

<details>
<summary>Text-only version (copy-pasteable)</summary>

```
🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40 | 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s
💭 true | 💪 xhigh | 📁 example_dir | 🌳 main | 🌿 feat/wizard | 📊 +3 ~5 ?2 | 🔀 ↑2 ↓1 | ➕ +128 | ➖ -42 | ⏳ 3m 50s
```

</details>

## Why

The Claude Code ecosystem already has a dozen excellent statuslines, each great at one thing. We wanted **one tool** that:

- ships every useful field — model, cost, context %, cache hit ratio, rate limits (5h + 7d) with countdowns, git branch + status + ahead/behind, vim mode, agent name, session id, plus zero-cost local readouts (clock, battery, memory, load average, hostname)
- looks great out of the box (12 presets, 21 themes, 12 progress-bar styles, truecolor support)
- is **trivial to install** — one bash file + `jq`, no Node, no Rust, no Python, no daemon
- stays customizable down to the smallest detail (per-token prefix, format, bar style, and separator-after overrides)

## Features

- **Single file**, ~3,900 lines of bash 3.2+. Drop it anywhere on `$PATH`.
- **Up to 4 lines** of statusline, each a freely-arranged token sequence.
- **48 tokens**: 35 from Claude Code's stdin JSON + 6 from `git` + 7 from local OS.
- **Many format variants** per token — bars, percents, countdowns, combined views, compact model names, hourly cost projections, token-count combos, short-form durations, etc. Each token advertises only the formats that make sense for its data.
- **12 presets**: `minimum`, `compact`, `focus`, `coder`, `default`, `modern`, `rates`, `cache`, `claude`, `fancy`, `everything`, `maximum`.
- **21 themes**: grouped by terminal compatibility — Auto / adaptive (3), Light terminals (6), Dark terminals (12).
- **12 progress-bar styles**: `blocks`, `heavy`, `line`, `braille`, `dots`, `arrows`, `ascii`, plus 5 sub-character precision variants — `gradient`, `gradient_dots`, `gradient_fade`, `gradient_shade`, `gradient_braille`.
- **8 prefix styles**: `none`, `label`, `emoji`, `nerd`, `ascii` + `emoji+label`, `label+emoji`, `nerd+label`.
- **19 separators** across 4 families: ASCII (3), Unicode (10), Decorative (3), Powerline / Nerd-Font (3).
- **Interactive TUI wizard** with always-visible live preview pane and a dedicated **Tokens & lines** screen for add / change / delete / reorder, inline separator editing, and per-token overrides.
- **Auto-detected color depth** (truecolor / 256 / 16 / none) with `$NO_COLOR` honored.
- **Threshold-based coloring** with sane defaults — battery inverts (low % = critical), memory uses a relaxed table (80% is normal), context-remaining mirrors context-used in reverse.
- **Configurable empty-data handling** (default: `placeholder` shows `—`; can switch to `hide` to drop empty tokens).
- **JSON Schema** shipped at the repo root + `$schema` field in the auto-created config — VS Code, Cursor, JetBrains, and Neovim's LSP all give you autocomplete and inline docs while editing.
- **Project-level config** at `./.statusline-bar.json` overrides home-dir config.
- **No network calls.** Ever.

## Install

Clone the repo somewhere stable on your machine (anywhere works — `~/code`, `~/.local/share`, etc.) and point Claude Code at the script:

```bash
mkdir -p ~/.local/share
git clone https://github.com/Dworf/statusline-bar.git ~/.local/share/statusline-bar
chmod +x ~/.local/share/statusline-bar/statusline-bar.sh
```

To upgrade later, `cd ~/.local/share/statusline-bar && git pull`.

### Wire it up in Claude Code

Claude Code reads its settings from **`~/.claude/settings.json`** (your user-level config). If the file doesn't exist yet, create it. If it already has other settings — model defaults, MCP servers, permissions, hooks, etc. — **don't overwrite it**: add the `statusLine` key alongside whatever's already there. The whole file is a single JSON object.

Existing config with other top-level keys — your file already has things like `model`, `permissions`, `hooks`, etc. **Add only the `statusLine` block** as one more sibling:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/YOUR_USERNAME/.local/share/statusline-bar/statusline-bar.sh"
  }
}
```

So your merged file ends up looking like this — `statusLine` is the new bit, everything else was already there:

```json
{
  "model": "...",
  "permissions": { ... },
  "statusLine": {
    "type": "command",
    "command": "/Users/YOUR_USERNAME/.local/share/statusline-bar/statusline-bar.sh"
  }
}
```

Heads up on JSON's no-trailing-commas rule: if your previously-last key didn't have a comma after its closing `}` or `]`, you need to add one when you append `statusLine` after it. Most JSON-aware editors (VS Code, Cursor, etc.) flag this automatically.

The `command` path must be **absolute** — `~` and `$HOME` aren't expanded. Replace `YOUR_USERNAME` (or paste the full path from `realpath ~/.local/share/statusline-bar/statusline-bar.sh`). On Windows: use the WSL or Git Bash path.

Restart Claude Code (or open a new session) and the statusline appears at the bottom. If it doesn't, run the script manually against the bundled sample input to confirm it works:

```bash
~/.local/share/statusline-bar/statusline-bar.sh < ~/.local/share/statusline-bar/test/sample-input.json
```

You should see a populated two-line statusline (model, context, cost, rate limits, git info, …) — the same layout you'd see in a real Claude Code session.

### Requirements

`bash` 3.2+ (ships everywhere) and `jq`. Install `jq` if you don't already have it:

| OS | Install |
|---|---|
| macOS | `brew install jq` |
| Debian / Ubuntu / WSL | `sudo apt install jq` |
| Fedora / RHEL | `sudo dnf install jq` |
| Arch | `sudo pacman -S jq` |
| Windows | `winget install jqlang.jq` (or `choco install jq` / `scoop install jq`) |

Check it's working: `jq --version` should print something like `jq-1.7.1`.

Optional: `git` (for git tokens), `fc-list` (for Nerd Font detection), `pmset` / `/sys/class/power_supply` (for the battery token).

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

![Wizard main menu showing preset, theme, prefix style, separator, bar style, Tokens & lines, empty data, and color depth rows; live preview pane at the bottom](screenshots/menu_main.png)

The bottom pane is a live preview that re-renders as you change settings. The focused token / separator is **underlined and wrapped in `▶ ◀` markers** so its real colors stay visible.

Picker screens for the single-choice settings (preset, theme, prefix, separator, bar) all follow the same pattern — list of options on the left, per-option sample on the right, full statusline preview at the bottom:

<table>
  <tr>
    <td><img src="screenshots/menu_preset.png" alt="Preset picker — 12 presets each with a short description and token count" /></td>
    <td><img src="screenshots/menu_theme.png" alt="Theme picker — 21 themes grouped by terminal compatibility, each with good/warn/crit color swatches" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/menu_prefixstyle.png" alt="Prefix style picker — 8 styles each with a token render sample" /></td>
    <td><img src="screenshots/menu_seperator.png" alt="Separator picker — 19 separators each with a literal char preview" /></td>
  </tr>
  <tr>
    <td colspan="2"><img src="screenshots/menu_barstyle.png" alt="Bar style picker — 12 bar styles each with a 50% sample bar" /></td>
  </tr>
</table>

The **Tokens & lines** screen is the layout editor — line tabs at the top, token list with inline separators in the middle, live full preview at the bottom:

![Tokens & lines main screen showing line tabs, token list with inline separator rows, and live preview](screenshots/menu_tokens_lines.png)

Drill into any token to edit its per-token prefix / format / bar style overrides:

<table>
  <tr>
    <td><img src="screenshots/menu_tokens_lines_model.png" alt="Token detail screen for model — prefix, format, bar style, reset rows" /></td>
    <td><img src="screenshots/menu_tokens_lines_model_format.png" alt="Format picker for model token — value, compact, short, id, id_short each with a sample render" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/menu_tokens_lines_model_prefix.png" alt="Prefix override picker for model — inherit global + 8 prefix styles" /></td>
    <td><img src="screenshots/menu_tokens_lines_rl5h_format.png" alt="Format picker for rl_5h — 12 formats from value through progressbar+percent+remaining_short" /></td>
  </tr>
</table>

Hit `a` from any line to add a token — the picker shows all 48 grouped by source, each row with a live sample and a `✓` mark next to tokens already used somewhere:

![Token picker — 48 tokens grouped by Claude session / Git / Local OS, each row showing the rendered sample](screenshots/menu_tokens_lines_add_token.png)

### Tune it live alongside Claude Code

You can keep the wizard open in one terminal and have a real Claude Code session running in another. Every time you press **`s` save** in the wizard, the new config lands on disk — and Claude Code picks it up on its next statusline refresh, using **your actual live data** (current cost, real rate-limit countdowns, real git status, etc.) instead of the wizard's synthetic preview.

Claude Code refreshes the statusline on each **tick** — basically anything that updates its UI. The easiest trigger is typing `/` in CC and selecting any slash command (e.g. `/help`, `/status`); CC re-reads the statusline config and re-runs the script immediately. Tweak in the wizard → save → tick CC → see the change live.

Inside **Tokens & lines** you get:

- A horizontal line tab strip (`[1]  2   3   +`) — `←/→` switches the active line, `↓` enters the token list, `d` deletes a line, Enter on `+` adds a new one (up to 4).
- Token rows + always-visible inline separator rows (`↓ pipe (global)` / `↓ star (override)`).
- **a** add a token, **c** change it, **d** delete, **m** mark for cross-line move, **p** paste, **Shift+↑/↓** move within the line.
- Enter on a token opens its per-override detail screen; Enter on a separator row opens a separator picker scoped to that one position.

## Browse

```bash
statusline-bar.sh -e                  # full catalog
statusline-bar.sh -e tokens           # just the tokens section
statusline-bar.sh -e themes           # just themes
statusline-bar.sh -e bars             # just bar styles
                  # presets | themes | prefixes | separators | bars | tokens
```

Prints a catalog with one row per option, rendered live against synthetic data. Uses your real terminal's color depth, so themes visibly differ — what you see is what you'd get if you picked it. Pipe through `less -R` if you want pagination with ANSI. See the [Showcase](#showcase) below for the full output.

## Reference

Every catalog in full — presets, themes, prefix styles, separators, bar
styles, all 48 tokens and their formats — plus the config schema, the wizard
keymap and the complete CLI: see [REFERENCE.md](REFERENCE.md).

## Changelog

Release history lives in [CHANGELOG.md](CHANGELOG.md).

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