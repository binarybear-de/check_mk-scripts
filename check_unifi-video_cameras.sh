#!/bin/bash
# originally Written by Brayden Santo for Nagios to check the last recording time of videos cameras.
# https://github.com/chooko/Nagios-Plugins/tree/master/Unifi_Video
# enhanced by BinaryBear to
# - work with Check_MK as local agent extension
# - handle multiple cameras at once
# - also check if cam is connected right now
# - cache the curl response instead of CURLing each value

# This script uses JSON parsing to pull a single variable from the Unifi Video system through the Admin API.
# It depends on the small 'jq' parsing package, so you'll need to install that first.

ADDRESS=127.0.0.1 #address of your UniFi Video Server, default 127.0.0.1
PORT=7443 #port of your UniFi Video Server, default 7443
MAC_LIST=( F09FC2C0FE2B B4FBE4FF4665 ) #space-separated list of all MAC addresses without separation characters, e.g. 012345678910
API_KEY="lkGksS3KktDATB8gelgcRG3RP6acltFQ" #the API key - get one in UniFi Video UI User management
PATH_JQ="/usr/bin/jq" #path to jq
WARN_HOURS=12 #threshold for WARNING STATE
CRIT_HOURS=24 #threshold for CRITICAL STATE

####

WARN_HOURS_IN_SECONDS=$(date -d "-$WARN_HOURS hours" '+%s') #Translate WARN_HOURS to seconds
CRIT_HOURS_IN_SECONDS=$(date -d "-$CRIT_HOURS hours" '+%s') #Translate CRIT_HOURS to seconds
STATE=3 #set UNKNOWN STATE if script is interrupted for some reason

# Loop over all mac addresses
for mac in "${MAC_LIST[@]}"; do #do a for-loop for all MAC addresses

# clear up some variables
CAMERA_NAME=$()
CAMERA_LAST_RECORD_STARTTIME=$()
CAMERA_STATE=$()
##

# get some infos from api via jq
CURL_RESPONSE=$(curl -k -s "https://${ADDRESS}:${PORT}/api/2.0/camera?apiKey=${API_KEY}&mac=${mac}") #send request to API
CAMERA_NAME=$(echo $CURL_RESPONSE | ${PATH_JQ} '.data[].name') #extract the name given in UniFi Video
CAMERA_LAST_RECORD_STARTTIME=$(echo $CURL_RESPONSE | ${PATH_JQ} '.data[].lastRecordingStartTime') #extract the time stamp of the last record
CAMERA_STATE=$(echo $CURL_RESPONSE | ${PATH_JQ} '.data[].state') #extract the connection STATE
CAMERA_LAST_RECORD_IN_SECONDS=$(expr $CAMERA_LAST_RECORD_STARTTIME / 1000) #Divide the time data by 1000 to get accurate human time
##

if [ $CAMERA_LAST_RECORD_IN_SECONDS > 600 ]; then humanTime=$(date -d @"$CAMERA_LAST_RECORD_IN_SECONDS"); fi #convert to timestamp if more than 600 seconds / 10 minutes

# Longer ago than CRIT
if [ "$CAMERA_LAST_RECORD_IN_SECONDS" -lt "$CRIT_HOURS_IN_SECONDS" ]; then
DESCRIPTION="Last Recording: $humanTime on $CAMERA_NAME is more than 12 hours ago!"
STATE=2

# Longer ago then WARN but less ago then CRIT
elif [ "$CAMERA_LAST_RECORD_IN_SECONDS" -lt "$WARN_HOURS_IN_SECONDS" -a "$CAMERA_LAST_RECORD_IN_SECONDS" -gt "$CRIT_HOURS_IN_SECONDS" ]; then
DESCRIPTION="Last Recording: $humanTime on $CAMERA_NAME is more then 12 hours ago!"
STATE=1

# Less ago than WARN
elif [ "$CAMERA_LAST_RECORD_IN_SECONDS" -gt "$WARN_HOURS_IN_SECONDS" ]; then
DESCRIPTION="Last Recording: $humanTime"
STATE=0

# Exit as Unknown if something else happens...
else
DESCRIPTION="Something else happened, script failed."
STATE=3
fi

# Check if camera is connected
if [ "$CAMERA_STATE" == '"CONNECTED"' ]
then
DESCRIPTION="Connected, $DESCRIPTION"
else
DESCRIPTION="$CAMERA_STATE, $DESCRIPTION"
if [ $STATE -ne 3 ];then STATE=2; fi
fi

echo "$STATE Camera-${CAMERA_NAME//\"} - $DESCRIPTION"
done
