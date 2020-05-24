#!/bin/bash
# check all certificates one or more FOLDERs for is validity, similar to the check_http certificate check.
# nice-to-have for openvpn certificate monitoring, FOLDERs with certs in general (e.g. easy-rsa)
# there will be a separated check for each FOLDER summarizing all certs while showing certs in WARN / CRIT STATE as well as the one closest to its expiry date

WARN_DAYS=28 #threshold for WARNING STATE
CRIT_DAYS=14 #threshold for CRITICAL STATE

# Configure the FOLDERs at the very bottom!
####

function check_certs_in_FOLDER {

# Reset these variables to be clear to run this multiple times without the data from last function call
leastexpirationdate=0
leastexpirationcert=""
DESCRIPTION=""
STATE=0
##

FOLDER=$(basename -- $1) # get folder path from complete path (used as name for the service in Check_MK)
for TARGET in $1/*.crt; do

FILENAME=$(basename -- $TARGET)
# Parse the Certifiate
expirationdate=$(date -d "$(: | openssl x509 -in $TARGET -text -noout | grep 'Not After' |awk '{print $4,$5,$7}')" '+%s');

inwarndays=$(($(date +%s) + (86400*$WARN_DAYS)));
incritdays=$(($(date +%s) + (86400*$CRIT_DAYS)));


if [ $leastexpirationdate -gt $expirationdate ] || [ $leastexpirationdate -eq 0 ]; then
leastexpirationdate=$expirationdate
leastexpirationcert=$FILENAME
fi

expirydays=$(( ($expirationdate-$(date +%s)) /86400))
if [ $(date +%s) -gt $expirationdate ]; then
STATE=2
DESCRIPTION="$DESCRIPTION $FILENAME has already expired!"

elif [ $incritdays -gt $expirationdate ]; then
STATE=2
DESCRIPTION="$DESCRIPTION $FILENAME expires in $expirydays Days,"

elif [ $inwarndays -gt $expirationdate ]; then
if [ $STATE -eq 0 ]; then STATE=1 fi #Set WARN state only if it was OKAY before to prevent overriding CRITICAL with WARNING
DESCRIPTION="$DESCRIPTION $FILENAME expires in $expirydays Days,"

elif [ $inwarndays -lt $expirationdate ]; then
: #Do nothing to preserve a 

else #Set unknown and exit if output is garbage
STATE=3
exit
fi;
done

if [ $STATE -eq 0 ]; then
DESCRIPTION="All certs in FOLDER $1 are valid, $leastexpirationcert will expire next in $expirydays days ($(date -d @$expirationdate '+%Y-%m-%d'))"
fi

# Finally Check_MK output
echo "$STATE SSL-Certs_$FOLDER - $DESCRIPTION"
}

# define you FOLDERs here - currently .crt-files only to exclude private keys
#check_certs_in_FOLDER "/some/path"
#check_certs_in_FOLDER "/some/other/path"
