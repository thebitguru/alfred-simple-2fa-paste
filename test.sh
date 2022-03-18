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

test_results=""
failures=0

ARG_REGEX='"arg"\: "([^"]+)"'
while [[ $valid_response_index -lt ${#valid_responses[@]} ]]; do
    valid_response=${valid_responses[$valid_response_index]}
    received_response=${received_responses[$received_response_index]}

    if [[ $received_response =~ $ARG_REGEX ]]; then
        received_code=${BASH_REMATCH[1]}
        
        if [[ $valid_response != $received_code ]]; then
            test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\">
                <failure message=\"Expected '$valid_response', but received '$received_code'\" type=\"\"/>\n</testcase>\n"
            printf "$valid_response_index: \xE2\x9D\x8C $valid_response != $received_code for $received_response\n"
            let "failures+=1"
        else
            test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\" />\n"
            printf "$valid_response_index: \xE2\x9C\x85 $valid_response = $received_code\n"
        fi
    else
        test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\">
            <failure message=\"Could not find 'arg' in item: '$received_response'\" type=\"\"/></testcase>\n"
        printf "$valid_response_index: \xE2\x9D\x8C Could not find 'arg' field in item: '$received_response'\n"
        let "failures+=1"
    fi
    
    valid_response_index=$((valid_response_index + 1))
    received_response_index=$((received_response_index + 1))
done

if [[ $failures -eq 0 ]]; then
    printf "\033[0;32mTest completed successfully.\n"
else
    printf "\033[0;31mSome tests failed.\n"
fi

printf "<testsuite tests=\"${#valid_responses[@]}\" failures=\"$failures\">\n$test_results</testsuite>" > "test_results.xml"