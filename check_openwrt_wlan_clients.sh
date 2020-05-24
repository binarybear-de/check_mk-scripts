#!/bin/sh
# to keep track of the amount of clients associated to an OpenWrt AccessPoint
# dependency is the iw package
# it automatically finds all wifi adapter-names by parsing them from ifconfig's output
# you can also define the states for disabled wifi and some client thresholds
# output is containing wifi state, transmit power and number of clients and the mac addresses of those
# for dual band you may need to run this twice for each band to keep those client numbers separated...

FILTER="wlan" #search-filter for autodetection, e.g. 'wlan' or 'ath' depending on your hardware
NAME="wlan" #the check's name in Check_MK
WARN_CLIENTS=6 #threshold for WARNING state
CRIT_CLIENTS=8 #threshold for CRITIAL state
STATE_DISABLED=0 #state if wifi is detected as disabled, 0 = OK, 1 = WARN, 2 = CRIT, 3 = UNKNOWN

####

CLIENTS=$(ifconfig | grep $FILTER | awk {'print $1'} | while read line ; do iw dev $line station dump | grep "Station" ; done | wc -l)
if [ $CLIENTS -lt $WARN_CLIENTS ]; then STATE=0
elif [ $CLIENTS -ge $WARN_CLIENTS ] && [ $CLIENTS -lt CRIT_CLIENTS ]; then STATE=1
elif [ $CLIENTS -ge $CRIT_CLIENTS ]; then STATE=2
else STATE=3
fi
if [ $(uci get wireless.radio0.disabled) == 1 ] ; then
DESCRIPTION="WLAN is disabled!"
STATE=$STATE_DISABLED
else
DESCRIPTION="$(uci get wireless.radio0.txpower) dBm, $CLIENTS Clients: $(wlan l | awk {'print $2'} | tr '\n' ' ')"
fi
echo "$STATE $NAME clients=$CLIENTS $DESCRIPTION"
