#!/bin/bash

[ -f /var/run/reboot-required ] && echo 'System needs to be rebooted' || echo 'No pending reboot'

exit 1