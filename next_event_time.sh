#!/bin/bash

BASEDIR="$( dirname -- $( realpath -- "${BASH_SOURCE[0]}" ) )"
source $BASEDIR/conf/epgstation_conf.inc

# 時刻の配列（HH:MM形式）
times=("05:50" "17:50")

# 現在時刻のUNIX時間
now_epoch=$(date +%s)

# -------------------------------
# 1. EPGStationから次の録画予約開始時刻（UNIX時間）を取得
# -------------------------------
# JSONから最も近い future 録画の "startAt" を抽出
reserves=$(curl -s "${EPGSTATION_API}/reserves?offset=0&limit=24&isHalfWidth=true")
recording_epoch=$(echo ${reserves} | jq '[.reserves[] | select(.startAt > (now * 1000))] | sort_by(.startAt) | .[0].startAt // empty' --argjson now "$(date +%s)" )

# `recording_epoch` はミリ秒なので、秒に変換
if [ -n "$recording_epoch" ]; then
    recording_epoch=$((recording_epoch / 1000))
fi

# 候補の時刻を格納
candidate_epochs=()

# -------------------------------
# 2. 配列で指定された時刻群を候補に追加
# -------------------------------
for time_str in "${times[@]}"; do
    hour=${time_str%%:*}
    minute=${time_str##*:}

    candidate_epoch=$(date -d "today $hour:$minute" +%s)

    if [ "$candidate_epoch" -le "$now_epoch" ]; then
        candidate_epoch=$(date -d "tomorrow $hour:$minute" +%s)
    fi

    candidate_epochs+=("$candidate_epoch")
done

# -------------------------------
# 3. 録画予約の開始時刻も候補に追加（存在する場合）
# -------------------------------
if [ -n "$recording_epoch" ]; then
    candidate_epochs+=("$recording_epoch")
fi

# -------------------------------
# 4. 最も早く来る時刻を選ぶ
# -------------------------------
closest_time=""
closest_diff=9999999999

for epoch in "${candidate_epochs[@]}"; do
    diff=$((epoch - now_epoch))
    if [ "$diff" -lt "$closest_diff" ]; then
        closest_diff=$diff
        closest_time=$epoch
    fi
done

# -------------------------------
# 5. 出力（YYYYMMDDHHMM）
# -------------------------------
date -d "@$closest_time" +%Y%m%d%H%M
