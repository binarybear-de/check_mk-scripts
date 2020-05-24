#!/bin/bash
# small script to keep track of all apache2 vhosts's certificates without the need of specify them manually in monitoring...

#Set your limits here - currently defaults for till from Check_MK are used
WARN_DAYS=28
CRIT_DAYS=14

# Loop over all enabled Site-Files from Apache2 with .conf suffix and skip broken SYMLINKS. Get the Path to the Certificate-File
for TARGET in $(cat /etc/apache2/sites-enabled/*.conf | grep "SSLCertificateFile" | awk {'print $2'} | grep -v "No such file or directory")
do

# Parse the Certifiate's lifespan
EXPIRY_DATE=$(date -d "$(: | openssl x509 -in $TARGET -text -noout | grep 'Not After' |awk '{print $4,$5,$7}')" '+%s');
EXPIRY_DAYS=$(( ($EXPIRY_DATE-$(date +%s)) /86400))

# Get the Common name of the certificate
VHOST=$(openssl x509 -in $TARGET -text -noout | grep "Subject: CN" | awk {'print $4'})


# $(date +%s) - ( $EXPIRY_DATE

# Set the limits in the needed format
WARN_DAYS_DATE=$(($(date +%s) + (86400*$WARN_DAYS)));
CRIT_DAYS_DATE=$(($(date +%s) + (86400*$CRIT_DAYS)));

# Check if certificate is already expired
if [ $(date +%s) -gt $EXPIRY_DATE ]; then
STATE=2 #Check_MK's Critical-State
DESC="This certificate is expired since $(date -d @$EXPIRY_DATE '+%Y-%m-%d')!!"

elif [ $CRIT_DAYS_DATE -gt $EXPIRY_DATE ]; then
STATE=2 #Check_MK's Critical-State
DESC="Expiry in $EXPIRY_DAYS day(s) (valid until $(date -d @$EXPIRY_DATE '+%Y-%m-%d'))!"

elif [ $WARN_DAYS_DATE -gt $EXPIRY_DATE ] && [ $CRIT_DAYS_DATE -lt $EXPIRY_DATE ]; then
STATE=1 #Check_MK's Warning-State
DESC="Expiry in $EXPIRY_DAYS day(s) (valid until $(date -d @$EXPIRY_DATE '+%Y-%m-%d'))."

elif [ $WARN_DAYS_DATE -lt $EXPIRY_DATE ]; then
STATE=0 #Check_MK's OKAY-State
DESC="Certificate '$VHOST' will expire on $(date -d @$EXPIRY_DATE '+%Y-%m-%d')."

else #Set unknown if output is garbage
STATE=3 #Check_MK's  Unknown-State
fi;

# output for Check_MK, replace the * from wildcards with 'wildcard', to prevent them from not showing in Check_MK
echo "$STATE SSL-Cert_$VHOST - $DESC" | sed -r 's/[*]+/wildcard/g'
done
