#!/bin/zsh -f
# Purpose: make Printopia load only on certain networks
#
#	NOTE: 	You MUST edit the list of networks down around line 150
#			Scroll down, you'll see the comment where you need to edit.
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-10-30

NAME="$0:t:r"

PLIST="$HOME/Library/LaunchAgents/com.ecamm.printopia.plist"

LOG="/tmp/$NAME.log"

zmodload zsh/datetime

TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

echo "\n\n$NAME started at $TIME" >>| "$LOG"

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

	# If we just want to log a message
function msg { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

function die
{
	echo "$NAME [`timestamp`]: $@ [die]" | tee -a "$LOG"

	exit 0
}

	# If the file doesn't exist, there's no reason to continie
[[ ! -e "$PLIST" ]] && die "No PLIST found at $PLIST"

	# check the current status of the launchd job
function get_status {

	/bin/launchctl list | fgrep -q com.ecamm.printopia

		# 0 = is loaded
		# 1 = is not loaded
	STATUS="$?"

}

function unload_printopia {

	get_status

	if [ "$STATUS" = "1" ]
	then
		msg "Already unloaded"
		exit 0
	elif [ "$STATUS" = "0" ]
	then
			# it's unloaded
		msg "Trying to unload $PLIST"

		/bin/launchctl unload "$PLIST" | tee -a "$LOG"

		get_status

		if [ "$STATUS" = "1" ]
		then
			msg "Successfully unloaded $PLIST"
			exit 0
		else
			msg "Failed to unload $PLIST: STATUS = $STATUS"
			exit 0
		fi

	else
		msg "Unknown Status: $STATUS"
		exit 0
	fi
}


function load_printopia {

	get_status

	if [ "$STATUS" = "0" ]
	then

		msg "Already loaded"
		exit 0
	elif [ "$STATUS" = "1" ]
	then
			# it's unloaded
		msg "Trying to load $PLIST"

		/bin/launchctl load "$PLIST" | tee -a "$LOG"

		get_status

		if [ "$STATUS" = "0" ]
		then
			msg "Successfully loaded $PLIST"
			exit 0
		else
			msg "Failed to load $PLIST: STATUS = $STATUS"
			exit 0
		fi

	else
		msg "Unknown Status: $STATUS"
		exit 0
	fi

}

	# This will tell the script to try get the current SSID that you are connected to.
	# It will try 6 times and wait 10 seconds between attempts (so, try for a minute, more or less)

MAX_ATTEMPTS="6"
SECONDS_BETWEEN_ATTEMPTS="10"

	# initialize the counter
COUNT=0

SSID=""

	# NOTE this 'while' loop can be changed to something else
while [ "$SSID" = "" ]
do

		# increment counter (this is why we init to 0 not 1)
	((COUNT++))

		# check to see if we have exceeded maximum attempts
	if [ "$COUNT" -gt "$MAX_ATTEMPTS" ]
	then
			msg "Exceeded $MAX_ATTEMPTS to find SSID. Giving up"
			exit 0
	fi

		# don't sleep the first time through the loop
	[[ "$COUNT" != "1" ]] && sleep ${SECONDS_BETWEEN_ATTEMPTS}

		# this is where we try to get the actual SSID and save it to a variable
	SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk -F': ' '/ SSID/{print $NF}')

done

msg "SSID is: $SSID"



####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		This is the part you MUST edit for it to work for you!
#
# Change the "Work Network"|"Home Network"|"Another Network" to whatever SSIDs you want to match
# You can make as many as you like, just make sure there is a "|" between them
# You can use '*' to match anything, for example: "luoma*" would match any SSID that starts with "luoma"
#
# By default you are defining networks that you want to use Printopia
# and any other network will not use it. But if you want to reverse that logic,
# and define SSIDs that you want to disable Printopia, just change "unload_printopia" and "load_printopia"

case "$SSID" in
	"Work Network"|"Home Network"|"Another Network")
		load_printopia
	;;

	*)
		# Any network which doesn't match the earlier ones will match this one
		unload_printopia
	;;

esac


exit 0
#
#EOF
