#!/usr/bin/env bash

BASEDIR="$( dirname -- $( realpath -- "${BASH_SOURCE[0]}" ) )"

chmod 755 *.sh
chmod 755 system-sleep/*.sh
install -m 644 systemd/auto-suspend.service /etc/systemd/system/

ln -s ${BASEDIR}/auto-suspend.sh /usr/local/bin/
ln -s ${BASEDIR}/system-sleep/epgstation.sh /lib/systemd/system-sleep/
ln -s ${BASEDIR}/system-sleep/px4_drv.sh /lib/systemd/system-sleep/

systemctl daemon-reload
systemctl start auto-suspend.service
