#!/usr/bin/env bash

if [ -f /etc/systemd/system/auto-suspend.service ]; then
  systemctl stop auto-suspend.service
  rm -f /etc/systemd/system/auto-suspend.service
  rm -f /lib/systemd/system-sleep/epgstation.sh
  rm -f /lib/systemd/system-sleep/px4_drv.sh
  systemctl daemon-reload
fi

if [ -f /usr/local/bin/auto-suspend.sh ]; then
  rm -f /usr/local/bin/auto-suspend.sh
fi
