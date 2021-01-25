#!/bin/bash
# script to monitor currently connected users of a OpenVPN AccessServer in CheckMK
# https://github.com/binarybear-de/check_mk-scripts
# BUILD 2021-01-24

#change these to a value to trigger WARN or CRIT. If not needed, just leave them blank
WARN_CLIENTS=50
CRIT_CLIENTS=300

###############################################################
# you should not need to edit anything below here!
###############################################################

USERS=$(/usr/local/openvpn_as/scripts/sacli VPNSummary | grep clients | awk {'print $2'})
echo "P OpenVPN_AS-Clients count=$USERS;$WARN_CLIENTS;CRIT_CLIENTS;0; $USERS are currently connected"
