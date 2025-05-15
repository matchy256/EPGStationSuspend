#!/bin/bash

case "$1/$2" in
  pre/*)
    # suspend前
    modprobe -r px4_drv
    ;;
  post/*)
    # suspendからの復帰後
    modprobe px4_drv
    ;;
esac
