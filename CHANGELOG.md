# Changelog

Release history for [statusline-bar](README.md). Newest first.

## 0.6.1 — 2026-09-19

- **New `cache_read` token** — the tokens the last API call read back out of the prompt cache, as a raw count (`📖 201k`). `cache_hit` gives the ratio and `cache_write` the writes; on a warm turn the read count is most of what was sent, and nothing showed it. Formats `value` and `short`, `short` by default. It renders nothing at zero, and nothing on a payload with no `context_window.current_usage` — but it does not need the `prompt_cache` object the other cache counters read, so it works on Claude Code versions older than 2.1.251 too.
- **`cache_read` counts one API call, not the session.** `cache_write` and `cache_misses` are session totals and `cache_hit` a session ratio; `cache_read` is the most recent request alone. The two names are parallel, they sit next to each other, and nothing in the ids says they count over different spans — so `cache_read`'s description names its window, and [REFERENCE.md](REFERENCE.md#tokens) states the split above the token table.
- **`cache_read` joins three presets.** `cache` goes from 9 tokens to 10, beside `cache_write`; `everything` and `maximum` from 48 to 49. A config that already carries its own `lines` array keeps the layout it has — the stored lines outrank the preset.

Tests: 179 e2e cases passing.

## 0.6.0 — 2026-09-14

- **Six new prompt-cache tokens.** Claude Code 2.1.251+ ships a `prompt_cache` object in the statusline payload; `cache_warm`, `cache_expires`, `cache_ttl`, `cache_misses`, `cache_rebuild` and `cache_write` surface it. `cache_misses` shows the latest diagnosed cause alongside the count (`2 (tools_changed)`) via the new `cause` and `count+cause` formats. All six render nothing on older Claude Code versions, where the object is absent.
- **The `default` preset now shows cache state** — 15 tokens to 18. `cache_expires` joins the end of line 1; `cache_hit` and `cache_ttl` sit before `duration` on line 2. A config that already carries its own `lines` array keeps the layout it has: the stored lines outrank the preset, so the new default arrives when you re-pick `default` in the wizard, or on a fresh install.
- **New `cache` preset** — 2 lines, 9 tokens, focused on cache health. `rates` gains `cache_expires`; `everything` and `maximum` carry all six new tokens.
- **`cache_hit` reports the session-wide hit ratio** from `prompt_cache.hit_ratio`, rather than a ratio derived from the last API call alone, which collapsed toward zero after any cache write. Payloads without `prompt_cache` still fall back to the derived value.
- **`cache_hit` colors a high hit rate green.** It previously shared a threshold rule with `context` and the rate limits, where a high number means "running out", so a healthy cache rendered red.
- **`cache_warm`'s prefix follows its value** — 🔥 warm / 🧊 cold under `emoji`, fa-fire / fa-snowflake-o under `nerd`, and the composite styles (`emoji+label`, `label+emoji`, `nerd+label`) follow. Its `label` reads `State:` rather than `Cache:`, which `cache_hit` already uses — on the `cache` preset the two sit side by side. The mechanism is general: a registry entry declares a variant as `<style>_cold` beside `<style>`, and styles or tokens without one are unaffected.
- **`context_size`'s icon is now 📦**, a capacity box. It used to be 🪟, which now belongs to `cache_ttl` — a window is the better read for a cache lifetime, and two tokens cannot share a glyph.
- **An unknown token id in `lines` now renders nothing.** It used to emit the literal `null —` into the statusline and a `tok_<id>: command not found` line onto stderr for every refresh.
- **Fixed a crash on stock macOS bash 3.2.** `set -- "${_args[@]}"` aborts under `set -u` when the array is empty — bash 3.2 treats the expansion as an unbound variable — so the script exited 1 and rendered nothing, with or without `--config`. Present since before 0.5.0 and invisible to CI, because `#!/usr/bin/env bash` resolves to a newer bash on most development machines. The guarded form `${_args[@]+"${_args[@]}"}` is byte-identical for non-empty arguments. The test runner carried the same hazard and is fixed too; the zero-argument invocation Claude Code actually uses now has end-to-end coverage.
- **Every token's `nerd` prefix is now genuinely stored as a `\uXXXX` escape.** The 0.4.0 notes below claimed this, but 42 of the 49 `nerd`/`nerd_cold` fields in the token registry actually held literal UTF-8 Private Use Area bytes — invisible in most editors, unsearchable, and easy to corrupt on a copy-paste. All 49 now use lowercase `\uXXXX` escape text derived from the codepoints already in the file, so the registry's icon fields are plain ASCII and greppable as intended. `jq` decodes the escapes when it loads the registry, so rendering is byte-for-byte unchanged — no golden file moved.
- **`schema.json` brought back in line with the script.** The bundled JSON Schema — referenced as `$schema` by every generated config, so editors validate against it — had drifted since 0.4.0: its preset enum listed 7 of 12, its theme enum 10 of 21, its bar-style enums 8 of 12, and its format enum 9 of 27. The per-token key pattern `^[a-z_]+$` also silently skipped `rl_5h`, `rl_7d` and `exceeds_200k`. All enums are now generated from the script's embedded tables.
- **Token descriptions state the rule instead of an example value.** `tokens_input`, `tokens_output`, `context_size`, `cost`, `lines_added` and `lines_removed` carried a sample in parentheses — "Session cost in USD (formatted $0.40)" — which read as a promise about a specific number. Descriptions that enumerate real options, like `effort`'s `(low/medium/high/xhigh/max)`, keep theirs.
- **New `STATUSLINE_BAR_TUI_COLOR` environment variable.** A scripted wizard run (`--tui-script`) renders without color so its output stays diffable; setting this opts one back into the real palette. Interactive runs are unaffected.
- **The test suite runs anywhere.** No golden contains the maintainer's username, `$HOME` is normalised in captured output before comparison, and the `--help` case no longer depends on which config the running machine happens to resolve — so a fresh clone passes, wherever it sits and whoever owns it.
- **Screenshots are generated, not captured.** `tools/shots.sh` builds every image under `screenshots/` from real script output under the environment the e2e suite pins, so two runs produce byte-identical files and a catalog image cannot quietly fall behind the catalog.
- **Documentation split three ways** — `README.md` covers the pitch, install and the wizard; `REFERENCE.md` holds the full catalogs, config schema and CLI; `CHANGELOG.md` is this file.

Tests: 175 e2e cases passing.

## 0.5.2 — 2026-09-05

- **Test suite is now location-independent.** Five cases (`check_bad_json`, `config_loader_project_local`, and three wizard cases) had this repo's absolute checkout path baked into `test/cases.sh` and one expected-output file, so the suite failed for anyone whose clone lived elsewhere — including after simply renaming the containing folder. Config paths in `test/cases.sh` now go through the runner's `$CONFIGS_DIR`, and `test/run-tests.sh` rewrites the repo path to `<REPO>` in captured output before comparing, so goldens no longer depend on where the repo sits. Verified by running the full suite from a second checkout at a different path.

No changes to the script's runtime behavior.

Tests: 118 e2e cases passing.

## 0.5.1 — 2026-08-18

- Every render now mirrors the raw stdin JSON to `/tmp/statusline-bar-input.json` (atomic overwrite, `0600` perms, best-effort — a failed write never breaks the render) so the latest Claude Code payload is always available for inspection. Override the path with `$STATUSLINE_BAR_DEBUG_INPUT`, or set it to `off` to disable. See **Inspecting the input JSON** under [CLI](REFERENCE.md#cli).

Tests: 118 e2e cases passing.

## 0.5.0 — 2026-05-13

**First public release.** Rolls up the v0.4.0 + v0.4.1 changes into a single tagged drop, with documentation tuned for new users.

**Install / docs:**
- Switched from `curl …/vX.Y.Z/statusline-bar.sh` to `git clone` — clones to `~/.local/share/statusline-bar`, upgrade via `git pull`, no version pinning to maintain.
- Rewrote the **Wire it up in Claude Code** section to spell out the part new users trip on most: `~/.claude/settings.json` is one JSON object — *add* the `statusLine` key alongside `model` / `permissions` / `hooks` / etc., don't overwrite the file. Includes minimal-config example, merged-with-existing example, the trailing-comma reminder, and a sanity-check command that pipes `test/sample-input.json` into the script so you see a real two-line render before fiddling with Claude.
- New **Tune it live alongside Claude Code** subsection documenting the workflow: leave the wizard open in one terminal, run a real CC session in another, save in the wizard, type any `/` slash command in CC to force a statusline tick — see the new config rendered against your live data.
- Full **screenshots** throughout the README: hero, wizard pickers, Tokens & lines editor, token-detail screens, plus a **Showcase** section with light/dark `<picture>` switching for every catalog dimension (presets, themes, prefix styles, separators, bar styles, tokens). 33 screenshots organized into tables + showrooms.

**Nerd Font glyph mapping** (was the v0.1.0-era follow-up):
- Every one of the 42 tokens now has a Font Awesome glyph in its `nerd` prefix field, stored as `\uXXXX` JSON escapes so the source stays plain ASCII and grep-friendly. The `nerd` / `nerd+label` prefix styles render real icons in any Nerd-Font-patched terminal.

**Carrying forward from v0.4.0** (see the entry below for the full list): +4 presets (focus, coder, rates, claude → 11 total), +11 themes (segmented by terminal compat → 21 total), +4 bar styles (gradient_dots / gradient_fade / gradient_shade / gradient_braille → 12 total), context-token consolidation + 4 new companion tokens, ~15 new format variants (model compact/short/id/id_short, cost per_hour/with_rate, duration short, rate-limit countdown_short / remaining_short and combined, context tokens / tokens+size / percent+tokens / progressbar+percent+tokens, lines count), default empty_behavior → placeholder, save-no-exit + per-screen reset, themes-picker segmentation, catalog redesign, sample-data refresh.

Tests: 118 e2e cases passing.

## 0.4.0 — 2026-05-12

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

## 0.3.0 — 2026-05-12

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

## 0.2.0 — 2026-05-11

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

## 0.1.0 — 2026-05-11

- Initial release. 39 tokens, 7 presets, 10 themes, 8 prefix styles, 19 separators, 8 bar styles, 9 formats, per-token overrides.
- Interactive TUI wizard for preset / theme / prefix / separator / bar / empty / color-depth.
- `--examples catalog` and `--examples all` modes.
- Project-level config (`./.statusline-bar.json`) and `schema.json` for editor autocomplete.
- 114 end-to-end test cases.
- Known follow-ups for v0.1.1: TUI line-editor (add / reorder / remove lines), TUI per-token overrides (prefix/format/bar/separator-after), `--examples interactive` mode, full Nerd-font glyph mapping for the `nerd` prefix style.
