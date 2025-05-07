#!/usr/bin/env bash

# Tests the get_codes.sh script.

response=$(./get_codes.sh --ignore-full-disk-check --test --newline)

# Convert the response to an array, properly handling JSON format
IFS=$'\n'
received_responses=()
while IFS= read -r line; do
    if [[ $line =~ \"arg\"\:\ \"([^\"]+)\" ]]; then
        received_responses+=("${BASH_REMATCH[1]}")
    fi
done <<< "$response"

valid_results=$(cat test_messages_results.txt)
valid_responses=()
while IFS= read -r line; do
    valid_responses+=("$line")
done <<< "$valid_results"

test_results=""
failures=0
errors=0

# Sort both arrays to ensure consistent ordering
mapfile -t sorted_received < <(printf '%s\n' "${received_responses[@]}" | sort)
mapfile -t sorted_valid < <(printf '%s\n' "${valid_responses[@]}" | sort)

# Compare sorted arrays
for i in "${!sorted_valid[@]}"; do
    valid_response=${sorted_valid[$i]}
    received_response=${sorted_received[$i]:-""}

    if [[ -z "$received_response" ]]; then
        message="Could not find response for expected code: '$valid_response'"
        escaped=${message//</&lt;}
        escaped=${escaped//&/&amp;}
        escaped=${escaped//>/&gt;}
        escaped=${escaped//\"/&quot;}
        test_results+="<testcase classname=\"get_codes.sh\" name=\"line$i\" time=\"0\">
            <failure message=\"missing response\" type=\"missingResponse\">$escaped</failure>
            </testcase>\n"
        printf "%d: \xE2\x9D\x8C %s\n" "$i" "$message"
        ((errors++))
    elif [[ "$valid_response" != "$received_response" ]]; then
        escaped=${received_response//</&lt;}
        escaped=${escaped//&/&amp;}
        escaped=${escaped//>/&gt;}
        escaped=${escaped//\"/&quot;}
        test_results+="<testcase classname=\"get_codes.sh\" name=\"line$i\" time=\"0\">
            <failure message=\"invalid code\" type=\"invalidCode\">Expected '$valid_response', but received '$received_response'</failure>
            </testcase>\n"
        printf "%d: \xE2\x9D\x8C %s != %s\n" "$i" "$valid_response" "$received_response"
        ((failures++))
    else
        test_results+="<testcase classname=\"get_codes.sh\" name=\"line$i\" time=\"0\" />\n"
        printf "%d: \xE2\x9C\x85 %s = %s\n" "$i" "$valid_response" "$received_response"
    fi
done

if [[ ($failures -eq 0) && ($errors -eq 0) ]]; then
    printf "\033[0;32mTests completed successfully.\n"
else
    printf "\033[0;31m%d failures, %d errors.\n" "$failures" "$errors"
fi

iso8601date=$(date -u +%Y-%m-%dT%H:%M:%S)
printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testsuite name=\"get_codes.sh\" hostname=\"%s\" time=\"0\" timestamp=\"%s\"
    tests=\"%d\" errors=\"%d\" failures=\"%d\" skipped=\"0\">\n%s
</testsuite>" "$HOSTNAME" "$iso8601date" "${#valid_responses[@]}" "$errors" "$failures" "$test_results" > "test_results.xml"
