#!/bin/sh
#set -x

CUTOFF_DATE=""
CONFIRM=""

while getopts d:y FLAG
do	case "$FLAG" in
	d)	CUTOFF_DATE="$OPTARG";;
	y)	CONFIRM="yes";;
	[?])	print >&2 "Usage: $0 [-s] [-d seplist] file ..."
		exit 1;;
	esac
done

# Figure out if the user has BSD or GNU date
DATE_COMMAND_TYPE=""
if command -v date &> /dev/null
then
    if [ -z $(date --version 2>/dev/null || echo "" | grep GNU) ]; then
        DATE_COMMAND_TYPE="BSD"
    else
        DATE_COMMAND_TYPE="GNU"
    fi
else
    # No `date` command found. Check for gdate.
    if command -v gdate &> /dev/null
    then
        DATE_COMMAND_TYPE="GNU"
    else
        echo "Error: A date could not be found"
        exit
    fi
fi


if [ ! -z "CUTOFF_DATE" ]; then
    IN_FORMAT="%Y-%m-%d"
    OUT_FORMAT="+$IN_FORMAT"
    gdate  $OUT_FORMAT -d "$CUTOFF_DATE"
    date -jf "$IN_FORMAT" "$OUT_FORMAT" "$CUTOFF_DATE"
fi

# Grab Heroku apps except those on which we are a collaborator
HEROKU_APPS=$(heroku apps | sed -n '/=== Collaborated Apps/q;p' |grep -v '^$'|grep -v '^===')


for APP in $HEROKU_APPS; do
    APP_INFO=$(heroku apps:info --json $APP)
    WEB_URL=$(echo "$APP_INFO"|grep '^  *"web_url"')
    echo "$WEB_URL"
    exit
done
