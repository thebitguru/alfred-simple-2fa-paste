Check for new codes even when there are not results.

# [1.2] - 2025-04-27

Fix shell script issues and improve readability

In get_codes.sh:

- Add quotes to prevent globbing and word splitting:
  - Line 16: >&2 echo "$1"
  - Line 162: echo -e "$output"
- Use modern command substitution syntax:
  - Line 57: response=$(cat test_messages.txt)
- Add -r option to read to prevent backslash mangling:
  - Line 112: while read -r line; do
- Quote expansions inside ${..} for pattern matching:
  - Line 154: remaining_message=${remaining_message##*"${BASH_REMATCH[0]}"}

In test.sh:

- Quote variables to prevent word splitting/globbing:
  - Line 10, 13: Use mapfile or read -a for array creation
  - Line 30: Use [[ "$var" != "value" ]] for string comparison
- Improve printf usage:
  - Lines 38, 42, 53, 64, 68-71: Use printf with separate format and arguments
- Use (( expr )) instead of let expr for arithmetic operations:
  - Line 39: (( i++ ))
  - Line 54: (( i++ ))
