#!/bin/bash

BASEDIR="$( dirname -- $( realpath -- "${BASH_SOURCE[0]}" ) )"

# スクリプト出力（YYYYMMDDHHMM形式）
output_time=$("$BASEDIR/next_event_time.sh")

# フォーマット確認
if ! [[ "$output_time" =~ ^[0-9]{12}$ ]]; then
    echo "エラー: スクリプトの出力が想定形式(YYYYMMDDHHMM)ではありません: $output_time"
    exit 1
fi

# 出力をUNIXタイム（秒）に変換
event_epoch=$(date -d "${output_time:0:4}-${output_time:4:2}-${output_time:6:2} ${output_time:8:2}:${output_time:10:2}" +%s)

# 10分（600秒）前の時刻を計算
wake_epoch=$((event_epoch - 600))

# 現在の時刻と比較して過去ならエラー
now_epoch=$(date +%s)
if [ "$wake_epoch" -le "$now_epoch" ]; then
    echo " 警告: 計算された起床時刻がすでに過去です（$wake_epoch）"
    exit 1
fi

# 既存の wakealarm をクリア（必要に応じて）
echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm > /dev/null

# 新しい wakealarm をセット
echo "$wake_epoch" | sudo tee /sys/class/rtc/rtc0/wakealarm > /dev/null

echo " RTC wakealarm を設定しました（$(date -d "@$wake_epoch")）"

# 確認方法:
# cat /proc/driver/rtc
