#!/usr/bin/env bash
# 録画中の確認
BASEDIR="$( dirname -- $( realpath -- "${BASH_SOURCE[0]}" ) )"
source $BASEDIR/conf/epgstation_conf.inc

recording_data=$(curl -s "${EPGSTATION_API}/recording?offset=0&limit=24&isHalfWidth=true")
total_recording=$(echo "$recording_data" | jq .total)
total_recording=${total_recording:-0}

if [ "$total_recording" -ne 0 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): 現在録画中です"
  exit 0
fi
exit 1
