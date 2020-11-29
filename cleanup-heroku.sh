#!/bin/sh
#set -x

SHOW_COLUMNS=""
AUTO_CONFIRM=""

usage() {
	print >&2 "Usage: $0 [-s] [-d seplist] file ..."
}

while getopts cy FLAG
do	case "$FLAG" in
	c)	SHOW_COLUMNS="yes";;
	y)	AUTO_CONFIRM="yes";;
	[?])
        usage
		exit 1;;
	esac
done

HEROKU_APPS=$(heroku apps | sed -n '/=== Collaborated Apps/q;p' |grep -v '^$'|grep -v '^===')

get_json_field_value() {
    # Returns a value given a JSON string and a key name.
    # Assumes the JSON is pretty-printed and the key and
    # value are alone on the same line. The grep removing
    # addons is there because addons have a "web_url".
    printf '%s' "$1"| sed -n -e "/\"$2\"/p;"| grep -v '/addons/'| sed 's/^  *//;s/.*":  *"*//;s/"*,* *$//' 
}

if [ ! -z "$SHOW_COLUMNS" ]; then
    echo "app|buildpack|release_date|last_log_date|web_url"
fi

for APP in $HEROKU_APPS; do
    APP_INFO=$(heroku apps:info --json $APP 2>/dev/null)
    WEB_URL=$(get_json_field_value "$APP_INFO" "web_url")
    RELEASE_DATE=$(get_json_field_value "$APP_INFO" "released_at" | sed 's/T.*//')
    BUILDPACK=$(get_json_field_value "$APP_INFO" "buildpack_provided_description")
    LAST_LOG_DATE=$(heroku logs -n1 -a "$APP"|sed -n '/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T/s/T.*//;p')
    if [ -z "$LAST_LOG_DATE" ]; then
        LAST_LOG_DATE="null"
    fi
    echo "$APP|$BUILDPACK|$RELEASE_DATE|$LAST_LOG_DATE|$WEB_URL"
done
