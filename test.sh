#!/usr/bin/env bash

# Tests the get_codes.sh script.

response=$(./get_codes.sh --ignore-full-disk-check --test --newline)
# echo $response

# Convert the response to an array.
IFS=$'\n'
read -r -d '' -a received_responses < <(printf '%s\0' "$response")

mapfile -t valid_responses < test_messages_results.txt

valid_response_index=0
received_response_index=1  # Ignore first line ("Running in test mode.")

test_results=""
failures=0
errors=0

ARG_REGEX='"arg"\: "([^"]+)"'
while [[ $valid_response_index -lt ${#valid_responses[@]} ]]; do
    valid_response=${valid_responses[$valid_response_index]}
    received_response=${received_responses[$received_response_index]}

    if [[ $received_response =~ $ARG_REGEX ]]; then
        received_code=${BASH_REMATCH[1]}

        if [[ "$valid_response" != "$received_code" ]]; then
            escaped=${received_response//</&lt;}
            escaped=${escaped//&/&amp;}
            escaped=${escaped//>/&gt;}
            escaped=${escaped//\"/&quot;}
            test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\" time=\"0\">
                <failure message=\"invalid code\" type=\"invalidCode\">Expected '$valid_response', but received '$received_code' for $escaped</failure>
                </testcase>\n"
            printf "%d: \xE2\x9D\x8C %s != %s for %s\n" "$valid_response_index" "$valid_response" "$received_code" "$received_response"
            ((failures+=1))
        else
            test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\" time=\"0\" />\n"
            printf "%d: \xE2\x9C\x85 %s = %s\n" "$valid_response_index" "$valid_response" "$received_code"
        fi
    else
        message="Could not find 'arg' field in item: '$received_response'"
        escaped=${message//</&lt;}
        escaped=${escaped//&/&amp;}
        escaped=${escaped//>/&gt;}
        escaped=${escaped//\"/&quot;}
        test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\" time=\"0\">
            <failure message=\"invalid message\" type=\"invalidMessage\">$escaped</failure>
            </testcase>\n"
        printf "%d: \xE2\x9D\x8C %s\n" "$valid_response_index" "$message"
        ((errors+=1))
    fi

    valid_response_index=$((valid_response_index + 1))
    received_response_index=$((received_response_index + 1))
done

if [[ ($failures -eq 0) && ($errors -eq 0) ]]; then
    printf "\033[0;32mTests completed successfully.\n"
else
    printf "\033[0;31m%d failures, %d errors.\n" "$failures" "$errors"
fi

iso8601date=$(date -u +%Y-%m-%dT%H:%M:%S)
printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<testsuite name=\"get_codes.sh\" hostname=\"%s\" time=\"0\" timestamp=\"%s\"\n    tests=\"%d\" errors=\"%d\" failures=\"%d\" skipped=\"0\">\n%s\n</testsuite>" "$HOSTNAME" "$iso8601date" "${#valid_responses[@]}" "$errors" "$failures" "$test_results" > "test_results.xml"
