#!/bin/sh

usage() {
    printf "%s\n" "Usage: $0 (list|destroy) [OPTIONS] [APPLICATIONS...]"
}

get_json_field_value() {
    # Returns a value given a JSON string and a key name.
    # Assumes the JSON is pretty-printed and the key and
    # value are alone on the same line. The grep removing
    # addons is there because addons have a "web_url".
    printf '%s' "$1"| sed -n -e "/\"$2\"/p;"| grep -v '/addons/'| sed 's/^  *//;s/.*":  *"*//;s/"*,* *$//' 
}

list_apps () {
    SHOW_COLUMNS=""
    while getopts ":ch" FLAG
    do case "$FLAG" in
        c)
            SHOW_COLUMNS="yes"
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage
            exit 2
            ;;
        esac
    done
    shift "$((OPTIND-1))"


    # If the user did not supply a list of Heroku apps, grab them from the Heroku CLI
    if [ -n "$*" ]; then
        HEROKU_APPS="$*"
    else
        HEROKU_APPS=$(heroku apps | sed -n '/=== Collaborated Apps/q;p' |grep -v '^$'|grep -v '^===')
    fi

    if [ -n "$SHOW_COLUMNS" ]; then
        printf "%s\n" "app|buildpack|release_date|last_log_date|web_url"
    fi

    for APP in $HEROKU_APPS; do
        APP_INFO=$(heroku apps:info --json "$APP" 2>/dev/null || printf "%s" "error")
        if [ "$APP_INFO" = "error" ]; then
            printf "Error fetching info for app %s" "$APP"
            exit 1
        fi
        WEB_URL=$(get_json_field_value "$APP_INFO" "web_url")
        RELEASE_DATE=$(get_json_field_value "$APP_INFO" "released_at" | sed 's/T.*//')
        BUILDPACK=$(get_json_field_value "$APP_INFO" "buildpack_provided_description")
        LAST_LOG_DATE=$(heroku logs -n1 -a "$APP"|sed -n '/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T/s/T.*//;p')
        if [ -z "$LAST_LOG_DATE" ]; then
            LAST_LOG_DATE="null"
        fi
        printf "%s\n" "$APP|$BUILDPACK|$RELEASE_DATE|$LAST_LOG_DATE|$WEB_URL"
    done
}

destroy_apps(){
    AUTO_CONFIRM=""
    while getopts yh FLAG
    do	case "$FLAG" in
        y)
            AUTO_CONFIRM="yes"
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage
            exit 2
            ;;
        esac
    done
    shift "$((OPTIND-1))"

    HEROKU_APPS="$*"
    for APP in $HEROKU_APPS; do
        echo "going to delete $APP"
        if [ -n "$AUTO_CONFIRM" ]; then
            heroku apps:destroy "--confirm=$APP" "$APP"
        else
            heroku apps:destroy "$APP"
        fi
    done
    
}

main (){
    if [ "$1" = "list" ]; then
        shift "1"
        list_apps "$@"
    elif [ "$1" = "destroy" ]; then
        shift "1"
        destroy_apps "$@"
    else
        usage
        exit 2
    fi
}

# Ensure we're logged into Heroku
if ! heroku auth:whoami 1>/dev/null 2>&1; then
    printf "%s\n" "Error: you must be do \"heroku login\" before running this script"
    exit 1
fi

# Run main
main "$@"

