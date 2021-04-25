#!/bin/bash

# äüö UTF8-FTW
# https://github.com/patti2/twitch-follower-tracker / original PHP script by CommanderRoot

convert_time_to_pacific () {
	echo "ConvertTime Argument: ${1}"
	DATE=$( date --date="TZ=\"America/Los_Angeles\" ${1}" +"%Y-%m-%d %r %z" )
}

#Fail if no argument is given
if [ -z "$1" ]
	then
		echo "No username provided. Usage: get_follower_as_list.sh USERNAME"
		exit 1
fi

get_user_id () {

twitchname=$(echo ${1} | tr '[:upper:]' '[:lower:]')
local STATUS_CODE=$(curl --connect-timeout 5 --write-out %{http_code} --max-time 15 -H "Expect:" -H "Accept: application/vnd.twitchtv.v5+json" -H "Client-ID: 1rr2wks0n53qby34wanxhirvlo50359" --output /tmp/twitchcurl "https://api.twitch.tv/kraken/users?login=${twitchname}")

if [[ "$STATUS_CODE" -ne 200 ]]
	then
		echo "Error while getting ID for user: ${STATUS_CODE}"
		exit 1
fi

twitchid=$(jq -r ".users[] | select(.name == \"$twitchname\")._id" /tmp/twitchcurl)
}

get_follower_data () {
local followername=nothing
local STATUS_CODE=$(curl --connect-timeout 5 --write-out %{http_code} --max-time 15 -H "Expect:" -H "Accept: application/vnd.twitchtv.v5+json" -H "Client-ID: 1rr2wks0n53qby34wanxhirvlo50359" --output /tmp/twitchcurldata "https://api.twitch.tv/kraken/channels/${twitchid}/follows?direction=desc&limit=100&cursor=${cursor}")

if [ "$STATUS_CODE" -ne 200 ] && [ "$STATUS_CODE" -ne 500 ]
	then
		echo "Error while getting Follower Data: ${STATUS_CODE}"
		exit 1
fi

process_list ${1}
}

process_list () {

if [[ "$STATUS_CODE" = 500 ]]
        then
                #dirty(!!) workaround
		cursor=""
	else
		jq -r ".follows[].user | .name" /tmp/twitchcurldata | xargs -I {} -d '\n' sh -c "echo '{}' >> ${1}.txt"
		cursor=$(jq -r "._cursor" /tmp/twitchcurldata)
fi

}


get_followers () {
local twitchid=nothing
local cursor=""
get_user_id ${1}
get_follower_data ${1} ${cursor}

until [ -z "$cursor" ]
do
	get_follower_data ${1} ${cursor}
done
echo "Done!"
exit 0
}

get_followers ${1}
