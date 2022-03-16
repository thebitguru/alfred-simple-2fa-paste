#!/usr/bin/env bash

# Tests the get_codes.sh script.

response=`./get_codes.sh --test --newline`
# echo $response

# Convert the response to an array.
IFS=$'\n'
received_responses=($response)

valid_results=`cat test_messages_results.txt`
valid_responses=($valid_results)

valid_response_index=0
received_response_index=1  # Ignore first line ("Running in test mode.")

ARG_REGEX='"arg"\: "([^"]+)"'
failed=0
while [[ $valid_response_index -lt ${#valid_responses[@]} ]]; do
    valid_response=${valid_responses[$valid_response_index]}
    received_response=${received_responses[$received_response_index]}

    if [[ $received_response =~ $ARG_REGEX ]]; then
        received_code=${BASH_REMATCH[1]}
        
        if [[ $valid_response != $received_code ]]; then
            printf "$valid_response_index: \xE2\x9D\x8C $valid_response != $received_code for $received_response\n"
            failed=1
        else
            printf "$valid_response_index: \xE2\x9C\x85 $valid_response = $received_code\n"
        fi
    else
        printf "$valid_response_index: \xE2\x9D\x8C Could not find 'arg' field in item: '$received_response'\n"
        failed=1
    fi
    
    valid_response_index=$((valid_response_index + 1))
    received_response_index=$((received_response_index + 1))
done

if [[ $failed -eq 0 ]]; then
    printf "\033[0;32mTest completed successfully.\n"
else
    printf "\033[0;31mSome tests failed.\n"
fi
