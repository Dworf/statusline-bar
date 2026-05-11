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
