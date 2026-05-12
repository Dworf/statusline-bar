# statusline-bar

Customizable Claude Code statusline. Single bash file, no JavaScript, no network, no daemon.

The `default` preset rendered with the synthetic example data (run `--examples` to see this and every other preset, theme, prefix style, separator, and bar):

```
🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40 | 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s
💭 true | 💪 xhigh | 📁 example_dir | 🌳 main | 🌿 feat/wizard | 📊 +3 ~5 ?2 | 🔀 ↑2 ↓1 | ➕ +128 | ➖ -42 | ⏳ 3m 50s
```

## Why

The Claude Code ecosystem already has a dozen excellent statuslines, each great at one thing. We wanted **one tool** that:

- ships every useful field — model, cost, context %, cache hit ratio, rate limits (5h + 7d) with countdowns, git branch + status + ahead/behind, vim mode, agent name, session id, plus zero-cost local readouts (clock, battery, memory, load average, hostname)
- looks great out of the box (11 presets, 21 themes, 12 progress-bar styles, truecolor support)
- is **trivial to install** — one bash file + `jq`, no Node, no Rust, no Python, no daemon
- stays customizable down to the smallest detail (per-token prefix, format, bar style, and separator-after overrides)

## Features

- **Single file**, ~3,000 lines of bash 3.2+. Drop it anywhere on `$PATH`.
- **Up to 4 lines** of statusline, each a freely-arranged token sequence.
- **42 tokens**: 29 from Claude Code's stdin JSON + 6 from `git` + 7 from local OS.
- **Many format variants** per token — bars, percents, countdowns, combined views, compact model names, hourly cost projections, token-count combos, short-form durations, etc. Each token advertises only the formats that make sense for its data.
- **11 presets**: `minimum`, `compact`, `focus`, `coder`, `default`, `modern`, `rates`, `claude`, `fancy`, `everything`, `maximum`.
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
git clone https://github.com/Dworf/statusline-bar.git ~/.local/share/statusline-bar
chmod +x ~/.local/share/statusline-bar/statusline-bar.sh
```

To upgrade later, `cd ~/.local/share/statusline-bar && git pull`.

### Wire it up in Claude Code

Claude Code reads its settings from **`~/.claude/settings.json`** (your user-level config). If the file doesn't exist yet, create it. If it already has other settings — model defaults, MCP servers, permissions, hooks, etc. — **don't overwrite it**: add the `statusLine` key alongside whatever's already there. The whole file is a single JSON object.

Minimal config (only `statusLine`, fresh install):

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/YOUR_USERNAME/.local/share/statusline-bar/statusline-bar.sh"
  }
}
```

Existing config with other top-level keys — add `statusLine` as a sibling:

```json
{
  "model": "claude-opus-4-7",
  "permissions": { ... },
  "statusLine": {
    "type": "command",
    "command": "/Users/YOUR_USERNAME/.local/share/statusline-bar/statusline-bar.sh"
  }
}
```

The `command` path must be **absolute** — `~` and `$HOME` aren't expanded. Replace `YOUR_USERNAME` (or paste the full path from `realpath ~/.local/share/statusline-bar/statusline-bar.sh`). On Windows: use the WSL or Git Bash path.

Restart Claude Code (or open a new session) and the statusline appears at the bottom. If it doesn't, run the script manually first to confirm it works:

```bash
echo '{}' | ~/.local/share/statusline-bar/statusline-bar.sh
```

You should see at least the model token render.

### Requirements

`bash` 3.2+ and `jq` — both ship with macOS and every mainstream Linux. Optional: `git` (for git tokens), `fc-list` (for Nerd Font detection), `pmset` / `/sys/class/power_supply` (for the battery token).

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
statusline-bar.sh -e                  # full catalog
statusline-bar.sh -e tokens           # just the tokens section
statusline-bar.sh -e themes           # just themes
statusline-bar.sh -e bars             # just bar styles
                  # presets | themes | prefixes | separators | bars | tokens
```

Prints a catalog with one row per option, rendered live against synthetic data. Uses your real terminal's color depth, so themes visibly differ — what you see is what you'd get if you picked it. Pipe through `less -R` if you want pagination with ANSI. See the [Showcase](#showcase) below for the full output.

## Reference

- **42 tokens** — 29 from Claude stdin (model, context, cost, rate limits, token counts, vim mode, agent name, session id, …) + 6 git + 7 OS (clock, battery, memory, load, …)
- **11 presets** — 1-line: `minimum`, `compact`, `focus`, `coder` · 2-line: `default`, `modern`, `rates`, `claude` · 3-line: `fancy` · 4-line: `everything`, `maximum`
- **21 themes** — Auto / adaptive: `default`, `solarized`, `graphite` · Light: `light`, `solarized-light`, `catppuccin-latte`, `tokyo-day`, `ayu-light`, `garden` · Dark: `dark`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `catppuccin`, `one-dark`, `rose-pine`, `monokai`, `mocha`, `silver`, `ocean`
- **8 prefix styles** — `none`, `label`, `emoji`, `nerd`, `ascii` + `emoji+label`, `label+emoji`, `nerd+label`
- **19 separators** — ASCII (3), Unicode (10), Decorative (3), Powerline (3)
- **12 bar styles** — solid: `blocks`, `heavy`, `line`, `braille`, `dots`, `arrows`, `ascii` · sub-character precision: `gradient`, `gradient_dots`, `gradient_fade`, `gradient_shade`, `gradient_braille`
- **Token-specific formats** — base set (`value`, `percent`, `progressbar`, `progressbar+percent`, `countdown`, `remaining`, `combined`, `flag`) plus richer per-token formats: model `compact`/`short`/`id`/`id_short`, context `tokens` / `tokens+size` / `percent+tokens` / `progressbar+percent+tokens`, cost `per_hour` / `with_rate`, lines `count`, duration / api_duration `short`, rate-limit `countdown_short` / `remaining_short` and combined `progressbar+percent+countdown_short` / `progressbar+percent+remaining_short`.

Globals can be overridden per-token via `tokens.<id>.prefix`, `.format`, `.bar_style`, `.separator_after`.

## Showcase

The output of `statusline-bar.sh --examples` (your terminal will show this in color):

<details>
<summary><b>Click to expand the full catalog</b> — 11 presets · 21 themes · 8 prefix styles · 19 separators · 12 bar styles · 42 tokens</summary>

```
## Presets  (factory layouts; switch via --preset NAME)

[ minimum    ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40

[ compact    ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40 | 🌿 feat/wizard | ⏳ 3m 50s | 🕔 5h 50%

[ focus      ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💭 true | 💪 xhigh | 💰 $0.40

[ coder      ] 🤖 Opus 4.7 (1M context) | 🌿 feat/wizard | 📊 +3 ~5 ?2 | ➕ +128 | ➖ -42 | ⏳ 3m 50s

[ default    ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40 | 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s
[ default    ] 💭 true | 💪 xhigh | 📁 example_dir | 🌳 main | 🌿 feat/wizard | 📊 +3 ~5 ?2 | 🔀 ↑2 ↓1 | ➕ +128 | ➖ -42 | ⏳ 3m 50s

[ modern     ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 🌿 feat/wizard | ➕ 3 | ✏️ 5 | 💰 $0.40
[ modern     ] 🕔 5h █████░░░░░ 50% | 🕖 7d █████░░░░░ 50% | ⏳ 3m 50s

[ rates      ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40
[ rates      ] 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s | 💾 ██████████ 97% | 📡 39s

[ claude     ] 🤖 Opus 4.7 (1M context) | 📝 Browse | 🧠 50% (49k/100k) | 💰 $0.40 | ⏳ 3m 50s
[ claude     ] 💭 true | 💪 xhigh | 🎨 default | ⚡️ | 🏷️ 2.1.139

[ fancy      ] 🤖 Opus 4.7 (1M context) | 🧠 █████░░░░░ 50% | 💰 $0.40 | ⏳ 3m 50s
[ fancy      ] 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s
[ fancy      ] 📁 example_dir | 🌿 feat/wizard | 📊 +3 ~5 ?2 | 💭 true | 💪 xhigh | 🔋 █████████░ 92% | 🕒 18:03

[ everything ] 🤖 Opus 4.7 (1M context) | 📝 Browse | 🔖 browse00 | 🧠 50% (49k/100k) | 📥 49k | 📤 50 | 🪟 100k | 🆓 50%
[ everything ] 💾 97% | 💰 $0.40 | 📡 39s | 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s | 💭 true | 💪 xhigh | 🎨 default | 🏷️ 2.1.139 | 🤝 Explore | ⌨️ INSERT | ⚡️ | 📈
[ everything ] 📁 example_dir | 🌳 main | 📂 0 | 🌲 /tmp/example_dir/feature | 📜 browse001.jsonl | 🌿 feat/wizard | 📊 +3 ~5 ?2 | ➕ 3 | ✏️ 5 | ❓ 2 | 🔀 ↑2 ↓1 | ➕ +128 | ➖ -42
[ everything ] ⏳ 3m 50s | 🕒 18:03 | 📅 2026-05-11 | 🖥️ mac | 👤 alice | 🔋 92% | 🧬 45% | 📊 1.2

[ maximum    ] 🤖 Opus 4.7 (1M context) | 📝 Browse | 🔖 browse00 | 🧠 █████░░░░░ 50% (49k/100k) | 📥 49k | 📤 50 | 🪟 100k | 🆓 █████░░░░░ 50%
[ maximum    ] 💾 ██████████ 97% | 💰 $0.40 | 📡 39s | 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s | 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s | 💭 true | 💪 xhigh | 🎨 default | 🏷️ 2.1.139 | 🤝 Explore | ⌨️ INSERT | ⚡️ | 📈
[ maximum    ] 📁 example_dir | 🌳 main | 📂 0 | 🌲 /tmp/example_dir/feature | 📜 browse001.jsonl | 🌿 feat/wizard | 📊 +3 ~5 ?2 | ➕ 3 | ✏️ 5 | ❓ 2 | 🔀 ↑2 ↓1 | ➕ +128 | ➖ -42
[ maximum    ] ⏳ 3m 50s | 🕒 18:03 | 📅 2026-05-11 | 🖥️ mac | 👤 alice | 🔋 █████████░ 92% | 🧬 █████░░░░░ 45% | 📊 1.2

## Themes  (color palettes; switch via --theme NAME — accent color on model + good/warn/crit bars)
                       good warn crit text
[ default          ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ solarized        ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%
[ graphite         ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ###....... 25%   ########.. 75%   ########## 95%
[ light            ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ solarized-light  ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%
[ catppuccin-latte ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ tokyo-day        ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ ayu-light        ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ garden           ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ dark             ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ dracula          ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ nord             ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%
[ gruvbox          ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%
[ tokyo-night      ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ catppuccin       ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ one-dark         ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ rose-pine        ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ monokai          ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ mocha            ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%
[ silver           ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ━━━─────── 25%   ━━━━━━━━── 75%   ━━━━━━━━━━ 95%
[ ocean            ] ● ● ● Aa   🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k)   ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%

## Prefix styles  (how each token is labeled; tokens.<id>.prefix to override per token)
[ none         ] Opus 4.7 (1M context) | 50% (49k/100k) | $0.40
[ label        ] Model: Opus 4.7 (1M context) | Ctx: 50% (49k/100k) | Cost: $0.40
[ emoji        ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40
[ nerd         ] Opus 4.7 (1M context) | 50% (49k/100k) | $0.40
[ ascii        ] [M] Opus 4.7 (1M context) | [C] 50% (49k/100k) | [$] $0.40
[ emoji+label  ] 🤖 Model: Opus 4.7 (1M context) | 🧠 Ctx: 50% (49k/100k) | 💰 Cost: $0.40
[ label+emoji  ] Model 🤖 Opus 4.7 (1M context) | Ctx 🧠 50% (49k/100k) | Cost 💰 $0.40
[ nerd+label   ]  Model: Opus 4.7 (1M context) |  Ctx: 50% (49k/100k) |  Cost: $0.40

## Separators  (string between tokens on the same line)
[ space        ] 🤖 Opus 4.7 (1M context)  🧠 50% (49k/100k)  💰 $0.40
[ pipe         ] 🤖 Opus 4.7 (1M context) | 🧠 50% (49k/100k) | 💰 $0.40
[ slash        ] 🤖 Opus 4.7 (1M context) / 🧠 50% (49k/100k) / 💰 $0.40
[ dot          ] 🤖 Opus 4.7 (1M context) · 🧠 50% (49k/100k) · 💰 $0.40
[ vbar         ] 🤖 Opus 4.7 (1M context) │ 🧠 50% (49k/100k) │ 💰 $0.40
[ dash         ] 🤖 Opus 4.7 (1M context) ─ 🧠 50% (49k/100k) ─ 💰 $0.40
[ bullet       ] 🤖 Opus 4.7 (1M context) • 🧠 50% (49k/100k) • 💰 $0.40
[ diamond      ] 🤖 Opus 4.7 (1M context) ◆ 🧠 50% (49k/100k) ◆ 💰 $0.40
[ arrow        ] 🤖 Opus 4.7 (1M context) ▸ 🧠 50% (49k/100k) ▸ 💰 $0.40
[ tri          ] 🤖 Opus 4.7 (1M context) ▶ 🧠 50% (49k/100k) ▶ 💰 $0.40
[ star         ] 🤖 Opus 4.7 (1M context) ★ 🧠 50% (49k/100k) ★ 💰 $0.40
[ sparkle      ] 🤖 Opus 4.7 (1M context) ✦ 🧠 50% (49k/100k) ✦ 💰 $0.40
[ gear         ] 🤖 Opus 4.7 (1M context) ⚙ 🧠 50% (49k/100k) ⚙ 💰 $0.40
[ check        ] 🤖 Opus 4.7 (1M context) ✓ 🧠 50% (49k/100k) ✓ 💰 $0.40
[ heart        ] 🤖 Opus 4.7 (1M context) ♥ 🧠 50% (49k/100k) ♥ 💰 $0.40
[ music        ] 🤖 Opus 4.7 (1M context) ♪ 🧠 50% (49k/100k) ♪ 💰 $0.40
[ chevron      ] 🤖 Opus 4.7 (1M context)  🧠 50% (49k/100k)  💰 $0.40
[ slant        ] 🤖 Opus 4.7 (1M context)  🧠 50% (49k/100k)  💰 $0.40
[ chevron_thin ] 🤖 Opus 4.7 (1M context)  🧠 50% (49k/100k)  💰 $0.40

## Bar styles  (each row: same bar at 25 / 75 / 95% — green good, yellow warn, red crit)
[ blocks           ] ███░░░░░░░ 25%   ████████░░ 75%   ██████████ 95%
[ heavy            ] ▰▰▰▱▱▱▱▱▱▱ 25%   ▰▰▰▰▰▰▰▰▱▱ 75%   ▰▰▰▰▰▰▰▰▰▰ 95%
[ line             ] ━━━─────── 25%   ━━━━━━━━── 75%   ━━━━━━━━━━ 95%
[ braille          ] ⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀ 25%   ⣿⣿⣿⣿⣿⣿⣿⣿⣀⣀ 75%   ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ 95%
[ dots             ] ●●●○○○○○○○ 25%   ●●●●●●●●○○ 75%   ●●●●●●●●●● 95%
[ arrows           ] ▶▶▶▷▷▷▷▷▷▷ 25%   ▶▶▶▶▶▶▶▶▷▷ 75%   ▶▶▶▶▶▶▶▶▶▶ 95%
[ ascii            ] ###....... 25%   ########.. 75%   ########## 95%
[ gradient         ] ██▌        25%   ███████▌   75%   █████████▌ 95%
[ gradient_dots    ] ██▌······· 25%   ███████▌·· 75%   █████████▌ 95%
[ gradient_fade    ] ██▒┄┄┄┄┄┄┄ 25%   ███████▒┄┄ 75%   █████████▒ 95%
[ gradient_shade   ] ██▓░░░░░░░ 25%   ███████▓░░ 75%   █████████▓ 95%
[ gradient_braille ] ██⡇······· 25%   ███████⡇·· 75%   █████████⡇ 95%

## Tokens  (42 total — pick any combination via Tokens & lines wizard)

### Claude session (29 tokens, read from stdin JSON)
[ model              ] 🤖 Opus 4.7 (1M context)           ⓘ Current Claude model display name
[ session_name       ] 📝 Browse                          ⓘ Custom session name set via --name or /rename
[ session_id         ] 🔖 browse00                        ⓘ Session UUID (first 8 chars)
[ context            ] 🧠 50% (49k/100k)                  ⓘ % of context window used; rich formats include tokens used and window size
[ tokens_input       ] 📥 49k                             ⓘ Total input tokens this session (e.g. 202k)
[ tokens_output      ] 📤 50                              ⓘ Total output tokens this session (e.g. 265)
[ context_size       ] 🪟 100k                            ⓘ Configured context window size (e.g. 1M)
[ context_remaining  ] 🆓 50%                             ⓘ % of context window still available
[ cache_hit          ] 💾 97%                             ⓘ % of input tokens served from cache
[ cost               ] 💰 $0.40                           ⓘ Session cost in USD (formatted $0.40)
[ duration           ] ⏳ 3m 50s                           ⓘ Total wall-clock time since session start
[ api_duration       ] 📡 39s                             ⓘ Time spent waiting for API responses
[ lines_added        ] ➕ +128                             ⓘ Lines of code added in this session (+128)
[ lines_removed      ] ➖ -42                              ⓘ Lines of code removed in this session (-42)
[ rl_5h              ] 🕔 5h █████░░░░░ 50% 🔄 3h 25m 13s    ⓘ 5-hour rate limit % + reset countdown
[ rl_7d              ] 🕖 7d █████░░░░░ 50% 🔄 5d 2h 17m 0s    ⓘ 7-day rate limit % + reset countdown
[ thinking           ] 💭 true                            ⓘ Whether extended thinking is enabled
[ effort             ] 💪 xhigh                           ⓘ Current reasoning effort (low/medium/high/xhigh/max)
[ output_style       ] 🎨 default                         ⓘ Active output style name
[ version            ] 🏷️ 2.1.139                      ⓘ Claude Code version
[ fast_mode          ] ⚡️                               ⓘ Fast mode flag (shows only when true)
[ exceeds_200k       ] 📈                                 ⓘ Token-count-over-200k flag (shows only when true)
[ dir                ] 📁 example_dir                     ⓘ Workspace directory basename
[ worktree           ] 🌳 main                            ⓘ Worktree name (--worktree sessions only)
[ vim_mode           ] ⌨️ INSERT                        ⓘ Current vim mode (NORMAL/INSERT/VISUAL)
[ agent_name         ] 🤝 Explore                         ⓘ Name of the running --agent
[ added_dirs         ] 📂 0                               ⓘ Count of dirs added via /add-dir
[ git_worktree       ] 🌲 /tmp/example_dir/feature        ⓘ Git worktree name (set for any linked worktree)
[ transcript         ] 📜 browse001.jsonl                 ⓘ Basename of the transcript file

### Git (6 tokens, populated when cwd is inside a git repo)
[ git_branch         ] 🌿 feat/wizard                     ⓘ Current git branch name
[ git_status         ] 📊 +3 ~5 ?2                        ⓘ Combined +staged ~modified ?untracked counts
[ git_staged         ] ➕ 3                                ⓘ Count of staged files
[ git_modified       ] ✏️ 5                             ⓘ Count of modified-but-unstaged files
[ git_untracked      ] ❓ 2                                ⓘ Count of untracked files
[ git_ahead_behind   ] 🔀 ↑2 ↓1                       ⓘ Ahead/behind count vs upstream

### Local OS (7 tokens, from the machine running the statusline)
[ clock              ] 🕒 18:03                           ⓘ Current time (HH:MM)
[ date               ] 📅 2026-05-11                      ⓘ Current date (YYYY-MM-DD)
[ hostname           ] 🖥️ mac                          ⓘ Short hostname
[ user               ] 👤 alice                           ⓘ Current user ($USER)
[ battery            ] 🔋 92%                             ⓘ Battery % (low % = critical color)
[ memory             ] 🧬 45%                             ⓘ Memory used % (relaxed thresholds; 80% is normal)
[ load               ] 📊 1.2                             ⓘ 1-minute load average

```

</details>

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

### 0.4.0 — 2026-05-12

A big content + UX pass: more variety in every catalog dimension, smarter defaults, and a redesigned `--examples` showcase.

**More choices**

- **+4 presets** (focus, coder, rates, claude) bringing the total to 11. New 1-liners cover "activity glance" and "git focus"; new 2-liners cover "usage / rate limits" and "Claude session state". Presets are now grouped by line count in the picker.
- **+11 themes** to 21 total, segmented in the picker by terminal compatibility (Auto / Light / Dark). Light additions: `solarized-light`, `catppuccin-latte`, `tokyo-day`, `ayu-light`, `garden`. Dark additions: `one-dark`, `rose-pine`, `monokai`, `mocha`, `silver`, `ocean`. Accent colors diversified — 12 of the 21 themes used to be some shade of blue; the new spread covers cyan / purple / pink / magenta / peach / orange / silver / brown / monochrome too.
- **+4 bar styles** (`gradient_dots`, `gradient_fade`, `gradient_shade`, `gradient_braille`) joining `gradient` as the sub-character-precision family — each takes a different approach to showing the empty track + the partially-filled cell.

**Tokens**

- **Context tokens consolidated and expanded.** `context_pct` + `context_bar` merge into a single `context` token; four companion tokens added — `tokens_input` (📥), `tokens_output` (📤), `context_size` (🪟), `context_remaining` (🆓). New combined formats on `context`: `tokens`, `tokens+size`, `percent+tokens`, `progressbar+percent+tokens`.
- **Model** gains `compact` (drops " context" from inside the parens), `short` (drops the whole paren group), `id` (raw model id), and `id_short` formats.
- **Cost** gains `per_hour` ("$6.20/hr") and `with_rate` ("$0.40 ($6.20/hr)") — projected burn rate from session duration.
- **Lines added / removed** gain `count` format (drops the leading +/-); now colored from the theme palette (good / crit).
- **Rate-limit** `rl_5h` / `rl_7d` gain `progressbar+percent+remaining`, plus `*_short` variants of every countdown / remaining format (top-2-unit precision — "3h 25m" instead of "3h 25m 13s").
- **Duration / api_duration** gain a `short` format.

**Wizard polish**

- `s save` no longer exits the wizard — it flashes a `✓ Saved to <path>` confirmation and leaves you where you were. Use `q` to leave once saved.
- `r reset` is now scoped to the current screen: per-field on token_field, per-token on token_detail, lines + per-token overrides on Tokens & lines, full reset elsewhere.
- Save and reset hints surfaced in every submenu's keybinding footer.
- Default empty_behavior changed from `hide` to `placeholder` so first-time users see `—` instead of tokens silently dropping out.
- Default context format upgraded to `percent+tokens` so the new combined view shows by default.
- `context_remaining` colored with inverse thresholds (high % = good, low % = crit) so it reads consistent with its `context` sibling.
- Pressing `↑` on a Tokens & lines line tab now jumps to the last token of that line — symmetric with `↓` returning to the tab row at the bottom.

**`--examples` catalog redesign**

- Each section focuses on the dimension it advertises: Themes shows accent + threshold bars (no cost), Bar styles shows the same bar at 25 / 75 / 95% with threshold colors, Tokens shows every token alone with an inline `ⓘ description`. Presets prints every line of multi-line layouts with the preset name as the row prefix.
- New `--examples MODE` argument accepts `presets` / `themes` / `prefixes` / `separators` / `bars` / `tokens` to print just one section.
- Sample data refreshed — rate-limit countdowns now show meaningful values (3h 25m 13s / 5d 2h 17m 0s) instead of `0s`, all the optional Claude fields (vim mode, agent name, fast mode, exceeds-200k, git worktree, transcript path) are filled in with realistic examples, anchor date moved from year 2286 to 2026-05-11.

**Other**

- **Nerd Font glyph mapping complete.** Every token now has a Font Awesome glyph for the `nerd` / `nerd+label` prefix styles — model `` (laptop/cpu), branch `` (code-fork), folder ``, clock ``, etc. Stored as `\uXXXX` JSON escapes inside `TOKENS_JSON` so they survive copy-paste and are easy to find. This was listed as a known v0.3.0 follow-up.
- New `MOCK_GIT_STATE=in_repo` for catalog rendering so git tokens show realistic values in presets too.
- Theme `default`'s accent inherits the terminal foreground color (no explicit color), so terminal-themed users keep their custom text color while semantic threshold colors still apply.
- Tests: 118 e2e cases passing.

### 0.3.0 — 2026-05-12

**Tokens & lines** — a full TUI for managing your statusline layout, plus a lot of preview-pane polish.

- **New "Tokens & lines" screen** replaces the old `Lines` / `Tokens` placeholders on the main menu. Manage every line and every token from one place:
  - Horizontal **line tabs** (`[1] [2] [3] +`) at the top — `←`/`→` switches the active line, `↓` enters the token list, Enter on `+` adds a new line (up to 4), `d` deletes a line with confirmation if non-empty.
  - Token rows + **inline separator rows** (always visible, labeled `↓ pipe (global)` or `↓ star (override)`).
  - `a` add a token, `c` change the token at cursor, `d` delete, `m` mark for cross-line move, `p` paste, `Shift+↑↓` move within a line, Enter on a token opens its detail screen, Enter on a separator row opens a separator picker scoped to that one position (with a `(use global)` row that clears the override).
  - `←`/`→` from inside the tokens zone also cycle through lines + the `+` tab (no need to climb back up).
- **Token picker**: 42 tokens grouped by source (Claude stdin / git / OS), each row showing a live `emoji+label` sample rendered with synthetic data (e.g. `🤖 Model: Opus 4.7 (1M context)`, `🕔 5h █████░░░░░ 50% 🔄 0s`). `✓` marks tokens already used somewhere. Cursor on a row tooltips its one-line description. Used by both `a add` and `c change`.
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