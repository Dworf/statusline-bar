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
