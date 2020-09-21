#!/bin/bash

source /config/shell_secrets.txt

function file_exists_web() {
  if [[ `wget --max-redirect=0 -S --spider "$1"  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
    return 0
  else
    return 1
  fi
}

# DUCKDNS
duckdns_update() {
  curl "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAINS&token=$DUCKDNS_TOKEN&ip="
}

# SCREEN FUNCTIONS
screen_toggle() {
  ssh $TOUCHPANEL_SSH xset -display :0.0 dpms force $1
}

screen_suspend () {
#  PID=$$
#  ssh $TOUCHPANEL_SSH "echo $SUDO_PASSWORD | sudo -S systemctl suspend"
  ssh $TOUCHPANEL_SSH "echo $SUDO_PASSWORD | sudo -S pm-suspend"
#  sleep 2
#  kill $PID
}

shell_test() {
  which ffmpeg > ffmpeg
}

# SELECT
select_set_options() {
  _set_input $1 $BASE_URL$API_PATH$INPUT_SELECT
}

text_set_values() {
  _set_input $1 $BASE_URL$API_PATH$INPUT_TEXT

}

var_set_values() {
  _set_variable $1 $BASE_URL$API_PATH$VAR_SET
}

_set_input() {
  ls $1/*.txt | while read d; do

    query="{\"entity_id\":\"$(head -n 1 $d)\",\"options\":[\"$(sed -n 2p $d)\""

    cnt=0
    while read l; do
      cnt=$((cnt+1))
      if [[ "$cnt" -gt 2 ]]; then
        query="$query,\"$l\""
      fi
    done < "$d"
    query="$query]}"

    _send_data "$query" "$2"
  done
}

_set_variable() {
  ls $1/*.txt | while read d; do

    query="{\"entity_id\":\"$(head -n 1 $d)\",\"value\":\"$(sed -n 2p $d)\""

    cnt=0
    while read l; do
      cnt=$((cnt+1))
      if [[ "$cnt" -gt 2 ]]; then
        query="$query,\"$l\""
      fi
    done < "$d"
    query="$query}"

    _send_data "$query" "$2"
  done
}

# $1 = query
# $2 = URL
_send_data() {
  curl -X POST \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $APITOKEN" \
  -H "Content-Type: application/json" \
  -d "$1" \
  $2
}

_get_states() {
  curl -X GET \
  -H "Authorization: Bearer $APITOKEN" \
  -H "Content-Type: application/json" \
  $BASE_URL$API_STATES_PATH/input_select.vacuum_room
}

# Start a Parsehub Scraper
# 1: Start URL for scraper
# 2: Project ID
# 3: Start values aka login credentials
_parsehub_start_scrape() {
  curl -X POST \
    -d "api_key=$PARSEHUB_API_TOKEN" \
    -d "start_url=$1" \
    -d "start_value_override=$3" \
    -d "send_email=0" \
    "https://www.parsehub.com/api/v2/projects/$2/run"
}

# PARSEHUB_API_TOKEN
# $PARSEHUB_LIBRARY_TOKEN
# File
_parsehub_get_data() {
  rm -f "$2"

  curl -X GET "https://www.parsehub.com/api/v2/projects/$1/last_ready_run/data?api_key=$PARSEHUB_API_TOKEN" | gunzip > "$2"
}