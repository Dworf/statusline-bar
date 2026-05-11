# Registry of test cases. Each call to run_case is one assertion.
# Cases get appended by later tasks. Format:
#   run_case <id> <fixture> <config> [extra-args...]

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
