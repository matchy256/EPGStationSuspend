#!/bin/bash

BASEDIR="$( dirname -- $( realpath -- "${BASH_SOURCE[0]}" ) )"

# === 設定値 ===
INTERFACE="enp3s0"
INTERVAL=30
MONITOR_TIME=600
THRESHOLD=70000
PROCESSES_TO_CHECK=("ffmpeg" "Caption2Ass" "logwatch" "yt-dlp" "mkvmerge" "comskip")

LAST_TRAFFIC=$(date +%s)
echo "LAST_TRAFFIC:" `date -d @$LAST_TRAFFIC "+%H:%M:%S"`

read_rx_tx_bytes() {
  ip -s link show "$INTERFACE" | awk '/RX:/{getline; rx=$1} /TX:/{getline; tx=$1} END{print rx, tx}'
}

read prev_rx_bytes prev_tx_bytes < <(read_rx_tx_bytes)

# コンソールログインしているユーザーがいるか
is_console_user_present() {
  if who | grep -q '^\w'; then
    echo "[`date`] ${0}: Someone is logging in to the shell." 1>&2
    return 0
  fi
  return 1
}

# SMB共有にアクセスしているユーザーがいるか
is_smb_accessing() {
  if type smbstatus >/dev/null 2>&1; then
    declare SmbUsers=`smbstatus -p | grep "^[0-9]" | wc -l`
    if (( SmbUsers > 0 )); then
      echo "[`date`] ${0}: Someone is accessing this server via Samba." 1>&2
      return 0
    fi
  fi
  return 1
}

# 指定されたプロセスが動作中か
is_target_process_running() {
  for pname in "${PROCESSES_TO_CHECK[@]}"; do
    pgrep -f "$pname" &>/dev/null
    if [ $? -eq 0 ]; then
      echo "[`date`] ${0}: ${pname} process is running" 1>&2
      return 0
    fi
  done
  return 1
}

# EPGStationが録画中か
is_now_recording() {
  $BASEDIR/is_recording.sh >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "[`date`] ${0}: EPGStaton is recording." 1>&2
    return 0
  fi
  return 1
}

# 20分以内に次のイベント発生か?
check_next_event() {
  next_time=$($BASEDIR/next_event_time.sh)
  if ! [[ "$next_time" =~ ^[0-9]{12}$ ]]; then
    return 1
  fi
  target_epoch=$(date -d "${next_time:0:4}-${next_time:4:2}-${next_time:6:2} ${next_time:8:2}:${next_time:10:2}" +%s)
  now_epoch=$(date +%s)
  # 差分を計算（秒）
  diff=$((target_epoch - now_epoch))
  if [ "$diff" -ge 0 ] && [ "$diff" -le 1200 ]; then
    echo "[`date`] ${0}: Next event is within 20 minutes of current time ($diff sec. after)" 1>&2
    return 0
  fi
  return 1
}

should_prevent_sleep() {
  is_console_user_present && return 0
  is_smb_accessing && return 0
  is_target_process_running && return 0
  is_now_recording && return 0
  check_next_event && return 0
  return 1
}

check_traffic() {
  read cur_rx_bytes cur_tx_bytes < <(read_rx_tx_bytes)
  rx_diff=$((cur_rx_bytes - prev_rx_bytes))
  tx_diff=$((cur_tx_bytes - prev_tx_bytes))
  echo "[`date`] rx_diff: $rx_diff / tx_diff: $tx_diff"

  if [ "$rx_diff" -ge "$THRESHOLD" ] || [ "$tx_diff" -ge "$THRESHOLD" ]; then
    LAST_TRAFFIC=$(date +%s)
    echo "LAST_TRAFFIC:" `date -d @$LAST_TRAFFIC "+%H:%M:%S"`
  fi

  prev_rx_bytes=$cur_rx_bytes
  prev_tx_bytes=$cur_tx_bytes
}

while true; do
  check_traffic
  current_time=$(date +%s)
  idle_time=$((current_time - LAST_TRAFFIC))

  if [ "$idle_time" -ge "$MONITOR_TIME" ]; then
    echo "idle_time: $idle_time"
    if should_prevent_sleep; then
      echo "[`date`] Suspend is being suppressed under some conditions."
    else
      echo "[`date`] To be suspend..."
      systemctl suspend
      break
    fi
  fi

  sleep "$INTERVAL"
done
