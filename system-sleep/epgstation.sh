#!/bin/bash

HEREDIR="$( dirname -- $( realpath -- "${BASH_SOURCE[0]}" ) )"
BASEDIR="$(dirname $HEREDIR)"
source $BASEDIR/conf/epgstation_conf.inc

case "$1/$2" in
  pre/*)
    # suspend前
    $BASEDIR/set_next_wakeup.sh
    sync; sync; sync # 念の為
    ;;
  post/*)
    # suspendからの復帰後
    sleep 10s # 念の為
    curl -X POST "${EPGSTATION_API}/recording/resettimer"
    ;;
esac
