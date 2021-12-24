#!/usr/bin/env bash

re1='^.*[^[:digit:]]([[:digit:]]{3,})[^[:digit:]].*$'

output=''
lookBackMinutes=${lookBackMinutes:-15}
>&2 echo "Lookback minutes: $lookBackMinutes"

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
    and datetime(message.date / 1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime')
            >= datetime('now', '-$lookBackMinutes minutes', 'localtime')
order by
    message.date desc
limit 10;"
>&2 echo "SQL Query: $sqlQuery"

response=$(sqlite3 ~/Library/Messages/chat.db -json "$sqlQuery")
>&2 echo "Response: '$response'"

if [[ -z "$response" ]]; then
	output+="{\"items\":[{\"type\":\"default\", \"icon\": {\"path\": \"icon.png\"}, \"arg\": \"\", \"subtitle\": \"Searched messages in the last $lookBackMinutes minutes.\", \"title\": \"No codes found\"}]}"
	echo $output
else
	while read line; do
		#echo "LINE: $line"
		message=${line##*text\":\"}
		#echo "EXTRACTED: $message"
		if [[ $message =~ $re1 ]]; then
			#echo "Matches: ${BASH_REMATCH[*]}"
			#echo "Found ${BASH_REMATCH[1]}"

			if [[ -z "$output" ]]; then
				output='{"items":['
			else
				output+=','
			fi
			message=${message%*\"\},}
			message=${message%*\"\}]}
			message_quoted=${message//[\"]/\\\"}
			#echo "Original $message"
			#echo "Quoted $message_quoted"
			#echo
			item="{\"type\":\"default\", \"icon\": {\"path\": \"icon.png\"}, \"arg\": \"${BASH_REMATCH[1]}\", \"subtitle\": \"${message_quoted}\", \"title\": \"Code ${BASH_REMATCH[1]}\"}"
			#echo $item
			output+=$item
			#echo "New output: $output"
		fi
	done <<< "$response"
	output+=']}'
fi

echo $output

