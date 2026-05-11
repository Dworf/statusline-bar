# Registry of test cases. Each call to run_case is one assertion.
# Cases get appended by later tasks. Format:
#   run_case <id> <fixture> <config> [extra-args...]
# Optional: prefix the call with CASE_ENV="K=V K2=V2" to override env.

# Phase 1: help/version
run_case help_basic       ""  ""  --help
run_case version_basic    ""  ""  --version

# Phase 2: data heredocs
run_case data_themes      ""  ""  --dump-data themes
run_case data_separators  ""  ""  --dump-data separators
run_case data_bar_styles  ""  ""  --dump-data bar_styles
run_case data_presets     ""  ""  --dump-data presets
run_case data_tokens      ""  ""  --dump-data tokens
run_case data_token_model ""  ""  --dump-data token:model

# Phase 3: capability detection
CASE_ENV="NO_COLOR=1"                                 run_case cap_depth_nocolor    "" "" --dump-cap color-depth
CASE_ENV="COLORTERM=truecolor"                        run_case cap_depth_truecolor  "" "" --dump-cap color-depth
CASE_ENV="TERM=xterm-256color COLORTERM= NO_COLOR="   run_case cap_depth_256        "" "" --dump-cap color-depth
CASE_ENV="TERM=dumb COLORTERM= NO_COLOR="             run_case cap_depth_none       "" "" --dump-cap color-depth
CASE_ENV="STATUSLINE_BAR_FORCE_NERD=unknown"          run_case cap_nerd_unknown     "" "" --dump-cap nerd-font
CASE_ENV="STATUSLINE_BAR_FORCE_NERD=yes"              run_case cap_nerd_cached_yes  "" "" --dump-cap nerd-font
CASE_ENV="NO_COLOR=1"                                 run_case color_off            "" "" --dump-color "#3fb950"
CASE_ENV="COLORTERM=truecolor"                        run_case color_fg_hex         "" "" --dump-color "#3fb950"
CASE_ENV="COLORTERM=truecolor"                        run_case color_fg_named       "" "" --dump-color "bold"

# Phase 4: duration
run_case dur_zero          "" "" --dump-format duration 0
run_case dur_seconds       "" "" --dump-format duration 45000
run_case dur_minutes       "" "" --dump-format duration 330000
run_case dur_hours         "" "" --dump-format duration 7230000
run_case dur_days          "" "" --dump-format duration 100800000
run_case dur_trailing_zero "" "" --dump-format duration 7200000

# Phase 4: percent
run_case pct_zero  "" "" --dump-format percent 0
run_case pct_int   "" "" --dump-format percent 87
run_case pct_float "" "" --dump-format percent 4.7

# Phase 4: progressbar
run_case bar_0pct          "" "" --dump-format bar 0    blocks   10
run_case bar_50pct         "" "" --dump-format bar 50   blocks   10
run_case bar_100pct        "" "" --dump-format bar 100  blocks   10
run_case bar_heavy_50      "" "" --dump-format bar 50   heavy    10
run_case bar_braille_50    "" "" --dump-format bar 50   braille  10
run_case bar_ascii_50      "" "" --dump-format bar 50   ascii    10
run_case bar_gradient_0    "" "" --dump-format bar 0    gradient 10
run_case bar_gradient_12_5 "" "" --dump-format bar 12.5 gradient 10
run_case bar_gradient_50   "" "" --dump-format bar 50   gradient 10
run_case bar_gradient_87_5 "" "" --dump-format bar 87.5 gradient 10
run_case bar_gradient_100  "" "" --dump-format bar 100  gradient 10

# Phase 4: prefix dispatcher
run_case prefix_emoji_model "" "" --dump-prefix model emoji       "Opus 4.7"
run_case prefix_label_model "" "" --dump-prefix model label       "Opus 4.7"
run_case prefix_combo_model "" "" --dump-prefix model emoji+label "Opus 4.7"
run_case prefix_none_model  "" "" --dump-prefix model none        "Opus 4.7"

# Phase 5: simple string tokens
run_case tok_model                sample-input.json   "" --dump-token model
run_case tok_session_name         sample-input.json   "" --dump-token session_name
run_case tok_effort               sample-input.json   "" --dump-token effort
run_case tok_output_style         sample-input.json   "" --dump-token output_style
run_case tok_version              sample-input.json   "" --dump-token version
run_case tok_dir                  sample-input.json   "" --dump-token dir
run_case tok_worktree             sample-input.json   "" --dump-token worktree
run_case tok_vim_mode_missing     sample-input.json   "" --dump-token vim_mode
run_case tok_agent_name_missing   sample-input.json   "" --dump-token agent_name
run_case tok_session_id           sample-input.json   "" --dump-token session_id
run_case tok_added_dirs_zero      sample-input.json   "" --dump-token added_dirs
run_case tok_git_worktree_missing sample-input.json   "" --dump-token git_worktree
run_case tok_transcript           sample-input.json   "" --dump-token transcript

# Phase 5: numeric & duration tokens
run_case tok_cost          sample-input.json "" --dump-token cost
run_case tok_lines_added   sample-input.json "" --dump-token lines_added
run_case tok_lines_removed sample-input.json "" --dump-token lines_removed
run_case tok_duration      sample-input.json "" --dump-token duration
run_case tok_api_duration  sample-input.json "" --dump-token api_duration

# Phase 5: percent tokens
run_case tok_context_pct sample-input.json "" --dump-token context_pct
run_case tok_context_bar sample-input.json "" --dump-token context_bar
run_case tok_cache_hit   sample-input.json "" --dump-token cache_hit

# Phase 5: rate-limit tokens
run_case tok_rl_5h sample-input.json "" --dump-token rl_5h
run_case tok_rl_7d sample-input.json "" --dump-token rl_7d

# Phase 5: flag tokens
run_case tok_thinking_on  sample-input.json   "" --dump-token thinking
run_case tok_thinking_off thinking-off.json   "" --dump-token thinking
run_case tok_fast_mode    thinking-off.json   "" --dump-token fast_mode
run_case tok_exceeds_200k sample-input.json   "" --dump-token exceeds_200k

# Phase 5: git tokens (via mock)
CASE_ENV="MOCK_GIT_STATE=in_repo"     run_case tok_git_branch_inrepo  sample-input.json "" --dump-token git_branch
CASE_ENV="MOCK_GIT_STATE=out_of_repo" run_case tok_git_branch_outside sample-input.json "" --dump-token git_branch
CASE_ENV="MOCK_GIT_STATE=in_repo"     run_case tok_git_staged         sample-input.json "" --dump-token git_staged
CASE_ENV="MOCK_GIT_STATE=in_repo"     run_case tok_git_modified       sample-input.json "" --dump-token git_modified
CASE_ENV="MOCK_GIT_STATE=in_repo"     run_case tok_git_untracked      sample-input.json "" --dump-token git_untracked
CASE_ENV="MOCK_GIT_STATE=in_repo"     run_case tok_git_status         sample-input.json "" --dump-token git_status
CASE_ENV="MOCK_GIT_STATE=in_repo"     run_case tok_git_ahead_behind   sample-input.json "" --dump-token git_ahead_behind

# Phase 5: OS tokens
CASE_ENV="HOSTNAME_OVERRIDE=mbp"                run_case tok_hostname sample-input.json "" --dump-token hostname
CASE_ENV="USER=david"                           run_case tok_user     sample-input.json "" --dump-token user
CASE_ENV="STATUSLINE_BAR_FAKE_NOW=1715450580"   run_case tok_clock    sample-input.json "" --dump-token clock
CASE_ENV="STATUSLINE_BAR_FAKE_NOW=1715450580"   run_case tok_date     sample-input.json "" --dump-token date
CASE_ENV="STATUSLINE_BAR_FAKE_BATTERY=87"       run_case tok_battery_fake     sample-input.json "" --dump-token battery
CASE_ENV="STATUSLINE_BAR_FORCE_NO_BATTERY=1"    run_case tok_battery_missing  sample-input.json "" --dump-token battery
CASE_ENV="STATUSLINE_BAR_FAKE_MEMORY=42"        run_case tok_memory_fake      sample-input.json "" --dump-token memory
CASE_ENV="STATUSLINE_BAR_FORCE_NO_MEMORY=1"     run_case tok_memory_missing   sample-input.json "" --dump-token memory
CASE_ENV="STATUSLINE_BAR_FAKE_LOAD=1.42"        run_case tok_load_fake        sample-input.json "" --dump-token load
CASE_ENV="STATUSLINE_BAR_FORCE_NO_LOAD=1"       run_case tok_load_missing     sample-input.json "" --dump-token load

# Phase 6: apply_format
run_case fmt_value             "" "" --apply-format model       value                            "Opus" blocks 10 0
run_case fmt_percent_apply     "" "" --apply-format context_pct percent                          "4"    blocks 10 0
run_case fmt_bar_apply         "" "" --apply-format context_pct progressbar                      "50"   blocks 10 0
run_case fmt_rl_combined_apply "" "" --apply-format rl_5h       progressbar+percent+countdown    "0|3600" blocks 10 0
run_case fmt_flag_true         "" "" --apply-format thinking    flag                             "true"  blocks 10 0
run_case fmt_flag_false        "" "" --apply-format thinking    flag                             "false" blocks 10 0
run_case fmt_combined_git      "" "" --apply-format git_status  combined                         "+3|~5|?2" blocks 10 0

# Phase 6: render_token
run_case render_token_model_default sample-input.json default-min.json --dump-render-token model
run_case render_token_context_bar   sample-input.json ctx-bar.json     --dump-render-token context_bar

# Phase 6: render_line / render_all
run_case render_line_default sample-input.json default-min.json --dump-render-line 0
CASE_ENV="MOCK_GIT_STATE=in_repo STATUSLINE_BAR_FAKE_NOW=9999999999" \
  run_case render_all_default sample-input.json default-preset.json --dump-render-all

# Phase 7: config builder & loader
run_case config_default_build "" "" --dump-default-config
run_case config_loader_explicit "" default-min.json --dump-loaded-config
CASE_ENV="STATUSLINE_BAR_CONFIG=test/configs/default-min.json XDG_CONFIG_HOME=/nonexistent HOME=/nonexistent" \
  run_case config_loader_env "" "" --dump-loaded-config
CASE_ENV="XDG_CONFIG_HOME=/nonexistent HOME=/nonexistent" \
  run_case config_loader_fallback "" "" --dump-loaded-config

# Project-level config lookup
pre_config_loader_project_local() {
  mkdir -p /tmp/sbar-project
  jq '.theme="dracula"' /Users/david/Documents/Projects/statusline_bar/statusline-bar/test/configs/default-min.json \
    > /tmp/sbar-project/.statusline-bar.json
}
CASE_ENV="XDG_CONFIG_HOME=/nonexistent HOME=/nonexistent" \
  run_case config_loader_project_local project-input.json "" --dump-loaded-config

# First-run auto-create
pre_config_auto_create() { rm -rf /tmp/sbar-autotest; }
CASE_ENV="XDG_CONFIG_HOME=/tmp/sbar-autotest HOME=/tmp/sbar-autotest" \
  run_case config_auto_create sample-input.json "" --check-auto-create

# Phase 7: --check validator
run_case check_ok            "" check-ok.json --check
expect_exit_check_bad_json=1
run_case check_bad_json      "" check-bad-json.json --check
expect_exit_check_bad_preset=1
run_case check_bad_preset    "" check-bad-preset.json --check
expect_exit_check_unknown_token=1
run_case check_unknown_token "" check-unknown-token.json --check

# Phase 8: e2e render via the main render path (no --dump-*)
CASE_ENV="MOCK_GIT_STATE=in_repo STATUSLINE_BAR_FAKE_NOW=9999999999 XDG_CONFIG_HOME=/tmp/sbar-noop HOME=/tmp/sbar-noop" \
  run_case e2e_default_preset sample-input.json default-preset.json

# Phase 8: --preset and --theme one-shot overrides
CASE_ENV="MOCK_GIT_STATE=in_repo STATUSLINE_BAR_FAKE_NOW=9999999999 XDG_CONFIG_HOME=/tmp/sbar-noop HOME=/tmp/sbar-noop" \
  run_case override_preset_minimum sample-input.json default-preset.json --preset minimum
CASE_ENV="MOCK_GIT_STATE=in_repo STATUSLINE_BAR_FAKE_NOW=9999999999 XDG_CONFIG_HOME=/tmp/sbar-noop HOME=/tmp/sbar-noop" \
  run_case override_theme_dracula  sample-input.json default-preset.json --theme dracula

# Phase 9: Examples mode
# (--examples all is too slow for the standard suite — 10,640 samples × ~30 jq
# calls each ≈ 25 min. Verify manually via:
#   ./statusline-bar.sh --examples-all-count
# Expected: 10640
# )
run_case examples_synthetic_load          "" "" --dump-data examples_input
run_case examples_catalog_section_themes  "" "" --examples catalog --only themes
run_case examples_catalog_full            "" "" --examples catalog

# Phase 10: Wizard smoke tests
pre_wizard_smoke_quit() {
  rm -f /tmp/sbar-wizard-test.json
  cp /Users/david/Documents/Projects/statusline_bar/statusline-bar/test/configs/default-min.json /tmp/sbar-wizard-test.json
}
post_wizard_smoke_quit() {
  if ! diff -u /tmp/sbar-wizard-test.json /Users/david/Documents/Projects/statusline_bar/statusline-bar/test/configs/default-min.json >/dev/null; then
    echo "FAIL wizard_smoke_quit (config modified despite quit)"
    return 1
  fi
}
CASE_ENV="STATUSLINE_BAR_CONFIG=/tmp/sbar-wizard-test.json TERM=xterm-256color STATUSLINE_BAR_FAKE_MEMORY=50 STATUSLINE_BAR_FAKE_LOAD=1.0 STATUSLINE_BAR_FAKE_BATTERY=92 HOSTNAME_OVERRIDE=Mac STATUSLINE_BAR_FORCE_NERD=no" \
  run_case wizard_smoke_quit "" "" --wizard --tui-script q

pre_wizard_save_theme() {
  rm -f /tmp/sbar-wsave.json
  cp /Users/david/Documents/Projects/statusline_bar/statusline-bar/test/configs/default-min.json /tmp/sbar-wsave.json
}
post_wizard_save_theme() {
  local got; got="$(jq -r '.theme' /tmp/sbar-wsave.json)"
  if [[ "$got" != "dracula" ]]; then
    echo "FAIL wizard_save_theme (theme=$got, expected dracula)"
    return 1
  fi
}
# Script: enter theme (down to row 1, enter), then down 5x to dracula, enter, save
# Main cursor starts at 0 (Preset). Down once → 1 (Theme). Enter → theme screen.
# Theme cursor starts at 0 (default). Down 5 times → dracula. Enter. Pop to main.
# Then 's' saves. Use $'\n' for enter.
CASE_ENV="STATUSLINE_BAR_CONFIG=/tmp/sbar-wsave.json TERM=xterm-256color STATUSLINE_BAR_FAKE_MEMORY=50 STATUSLINE_BAR_FAKE_LOAD=1.0 STATUSLINE_BAR_FAKE_BATTERY=92 HOSTNAME_OVERRIDE=Mac STATUSLINE_BAR_FORCE_NERD=no" \
  run_case wizard_save_theme "" "" --wizard --tui-script "$(printf 'D\nDDDDD\ns')"

# Tokens & lines: enter the screen, drop into tokens zone, navigate, quit.
# DDDDD\n  → main cursor 0→5 (T&L), enter → tabs zone
# D       → enter tokens zone
# DD      → step down two rows (token 1 → separator → token 2)
# q       → quit
pre_wizard_tokens_lines_nav() {
  rm -f /tmp/sbar-tl.json
  cp /Users/david/Documents/Projects/statusline_bar/statusline-bar/test/configs/default-preset.json /tmp/sbar-tl.json
}
CASE_ENV="STATUSLINE_BAR_CONFIG=/tmp/sbar-tl.json TERM=xterm-256color STATUSLINE_BAR_FAKE_MEMORY=50 STATUSLINE_BAR_FAKE_LOAD=1.0 STATUSLINE_BAR_FAKE_BATTERY=92 HOSTNAME_OVERRIDE=Mac STATUSLINE_BAR_FORCE_NERD=no MOCK_GIT_STATE=in_repo STATUSLINE_BAR_FAKE_NOW=9999999999" \
  run_case wizard_tokens_lines_nav "" "" --wizard --tui-script "$(printf 'DDDDD\nDDDq')"
