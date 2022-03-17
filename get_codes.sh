#!/usr/bin/env bash

# Usage
#  get_codes.sh [--test] [--newline]
#     --test: Run the script in test mode.
#     --newline: Print a newline after the output.
#  To keep the script simple, the arguments are expected to be in these exact positions.

# TODO: Fix the case with double quotes in the "text" field.
ROW_REGEX='^\[?{"ROWID"\:([[:digit:]]+),"sender"\:"([^"]+)","service"\:"([^"]+)","message_date"\:"([^"]+)","text"\:"([^"]+)"}'

# NUMBER_MATCH_RE='^(.*[^[:digit:]]([[:digit:]]{3,})[^[:digit:]]).*$'
NUMBER_MATCH_REGEX='([G[:digit:]-]{3,})'

output=''
lookBackMinutes=${lookBackMinutes:-15}

if [[ "$1" == "--test" ]]; then
	echo "Running in test mode."
	response=`cat test_messages.txt`
else
	# >&2 echo "Lookback minutes: $lookBackMinutes"

	sqlQuery="select
		message.rowid,
		ifnull(handle.uncanonicalized_id, chat.chat_identifier) AS sender,
		message.service,
		datetime(message.date / 1000000000 + 978307200, 'unixepoch', 'localtime') AS message_date,
		message.text
	from
		message
			left join chat_message_join on chat_message_join.message_id = message.ROWID
			left join chat on chat.ROWID = chat_message_join.chat_id
			left join handle on message.handle_id = handle.ROWID
	where
		message.is_from_me = 0
		and message.text is not null
		and length(message.text) > 0
		and (
			message.text glob '*[0-9][0-9][0-9]*'
			or message.text glob '*[0-9][0-9][0-9][0-9]*'
			or message.text glob '*[0-9][0-9][0-9][0-9][0-9]*'
			or message.text glob '*[0-9][0-9][0-9][0-9][0-9][0-9]*'
			or message.text glob '*[0-9][0-9][0-9]-[0-9][0-9][0-9]*'
			or message.text glob '*[0-9][0-9][0-9][0-9][0-9][0-9][0-9]*'
			or message.text glob '*[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*'
		)
		-- and datetime(message.date / 1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime')
		--         >= datetime('now', '-$lookBackMinutes minutes', 'localtime')
	order by
		message.date desc
	limit 10;"
	# >&2 echo "SQL Query: $sqlQuery"

	response=$(sqlite3 ~/Library/Messages/chat.db -json "$sqlQuery")
	# >&2 echo "SQL Results: '$response'"
fi


if [[ -z "$response" ]]; then
	output+="{\"items\":[{\"type\":\"default\", \"icon\": {\"path\": \"icon.png\"}, \"arg\": \"\", \"subtitle\": \"Searched messages in the last $lookBackMinutes minutes.\", \"title\": \"No codes found\"}]}"
else
	while read line; do
		# echo "Line: $line"
		if [[ $line =~ $ROW_REGEX ]]; then
		 	sender=${BASH_REMATCH[2]}
			message_date=${BASH_REMATCH[4]}
			message=${BASH_REMATCH[5]}
			# echo " Found sender: $sender"
			# echo " Found message_date: $message_date"
			# echo " Found message: $message"

			remaining_message=$message
			message_quoted=${message//[\"]/\\\"}

			while [[ $remaining_message =~ $NUMBER_MATCH_REGEX ]]; do
				# echo " -- Message: $message"
				# echo " -- Found-1 ${BASH_REMATCH[1]}"
				code=${BASH_REMATCH[1]}

				if [[ -z "$output" ]]; then
					output='{"items":['
				else
					output+=','
					if [[ "$2" == "--newline" ]]; then
						output+="\n"
					fi
				fi
				#echo "Original $message"
				#echo "Quoted $message_quoted"
				#echo
				item="{\"type\":\"default\", \"icon\": {\"path\": \"icon.png\"}, \"arg\": \"$code\", \"subtitle\": \"${message_date}: ${message_quoted}\", \"title\": \"$code\"}"
				# echo $item
				output+=$item
				#echo "New output: $output"

				# Trim to the remaining message
				# echo "REMATCH: ${BASH_REMATCH[0]}"
				# echo "Before truncating message: $remaining_message"
				remaining_message=${remaining_message##*${BASH_REMATCH[0]}}
				# echo "Remaining message: $remaining_message"
			done
		else
			>&2 echo "No match for $line"
		fi

		continue
	done <<< "$response"
	output+=']}'
fi

# >&2 echo "Final Output: '$output'"
echo -e $output