#!/bin/bash
# small script to keep track of all apache2 vhosts's certificates without the need of specify them manually in monitoring...
# creates a service for each site / vhost
# only works with 'plain' config files - no macro module

WARN_DAYS=28 #threshold for WARNING state
CRIT_DAYS=14 #threshold for CRITICAL state

####

# Loop over all enabled Site-Files from Apache2 with .conf suffix and skip broken SYMLINKS. Get the Path to the Certificate-File
for TARGET in $(cat /etc/apache2/sites-enabled/*.conf | grep "SSLCertificateFile" | awk {'print $2'} | grep -v "No such file or directory")
do

# Parse the Certifiate's lifespan
EXPIRY_DATE=$(date -d "$(: | openssl x509 -in $TARGET -text -noout | grep 'Not After' |awk '{print $4,$5,$7}')" '+%s');
EXPIRY_DAYS=$(( ($EXPIRY_DATE-$(date +%s)) /86400))

# Get the Common name of the certificate
VHOST=$(openssl x509 -in $TARGET -text -noout | grep "Subject: CN" | awk {'print $4'})

# Set the limits in the needed format
WARN_DAYS_DATE=$(($(date +%s) + (86400*$WARN_DAYS)));
CRIT_DAYS_DATE=$(($(date +%s) + (86400*$CRIT_DAYS)));

# Check if certificate is already expired
if [ $(date +%s) -gt $EXPIRY_DATE ]; then
STATE=2
DESCRIPTION="This certificate is expired since $(date -d @$EXPIRY_DATE '+%Y-%m-%d')!!"

elif [ $CRIT_DAYS_DATE -gt $EXPIRY_DATE ]; then
STATE=2
DESCRIPTION="Expiry in $EXPIRY_DAYS day(s) (valid until $(date -d @$EXPIRY_DATE '+%Y-%m-%d'))!"

elif [ $WARN_DAYS_DATE -gt $EXPIRY_DATE ] && [ $CRIT_DAYS_DATE -lt $EXPIRY_DATE ]; then
STATE=1
DESCRIPTION="Expiry in $EXPIRY_DAYS day(s) (valid until $(date -d @$EXPIRY_DATE '+%Y-%m-%d'))."

elif [ $WARN_DAYS_DATE -lt $EXPIRY_DATE ]; then
STATE=0
DESCRIPTION="Certificate '$VHOST' will expire on $(date -d @$EXPIRY_DATE '+%Y-%m-%d')."

else #Set unknown if output is garbage
STATE=3
fi;

# output for Check_MK, replace the * from wildcards with 'wildcard', to prevent them from not showing in Check_MK
echo "$STATE SSL-Cert_$VHOST - $DESCRIPTION" | sed -r 's/[*]+/wildcard/g'
done
