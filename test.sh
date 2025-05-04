#!/usr/bin/env bash

# Tests the get_codes.sh script.

response=`./get_codes.sh --ignore-full-disk-check --test --newline`
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
errors=0

ARG_REGEX='"arg"\: "([^"]+)"'
while [[ $valid_response_index -lt ${#valid_responses[@]} ]]; do
    valid_response=${valid_responses[$valid_response_index]}
    received_response=${received_responses[$received_response_index]}

    if [[ $received_response =~ $ARG_REGEX ]]; then
        received_code=${BASH_REMATCH[1]}
        
        if [[ $valid_response != $received_code ]]; then
            escaped=${received_response//</&lt;}
            escaped=${escaped//&/&amp;}
            escaped=${escaped//>/&gt;}
            escaped=${escaped//\"/&quot;}
            test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\" time=\"0\">
                <failure message=\"invalid code\" type=\"invalidCode\">Expected '$valid_response', but received '$received_code' for $escaped</failure>
                </testcase>\n"
            printf "$valid_response_index: \xE2\x9D\x8C $valid_response != $received_code for $received_response\n"
            let "failures+=1"
        else
            test_results+="<testcase classname=\"get_codes.sh\" name=\"line$valid_response_index\" time=\"0\" />\n"
            printf "$valid_response_index: \xE2\x9C\x85 $valid_response = $received_code\n"
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
        printf "$valid_response_index: \xE2\x9D\x8C $message\n"
        let "errors+=1"
    fi
    
    valid_response_index=$((valid_response_index + 1))
    received_response_index=$((received_response_index + 1))
done

if [[ ($failures -eq 0) && ($errors -eq 0) ]]; then
    printf "\033[0;32mTests completed successfully.\n"
else
    printf "\033[0;31m$failures failures, $errors errors.\n"
fi

iso8601date=`date -u +%Y-%m-%dT%H:%M:%S`
printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testsuite name=\"get_codes.sh\" hostname=\"$HOSTNAME\" time=\"0\" timestamp=\"$iso8601date\"
    tests=\"${#valid_responses[@]}\" errors=\"$errors\" failures=\"$failures\" skipped=\"0\">\n$test_results
</testsuite>" > "test_results.xml"