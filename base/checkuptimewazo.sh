#!/bin/bash
uptime=`uptime | sed -r '1 s/.*up *(.*),.*user.*/\1/g;q'`
echo "Uptime Wazo : $uptime"
exit 0
