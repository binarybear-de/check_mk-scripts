#!/bin/bash
# small script to keep track of all apache2 VHOSTs's certificates without the need of specify them manually in monitoring...
# https://github.com/binarybear-de/check_mk-scripts/blob/master/check_apache2_certs.sh
SCRIPTBUILD="BUILD 2021-03-27"

#Set your limits here - currently defaults for till from Check_MK are used
WARN_DAYS=28
CRIT_DAYS=14
WARN_DAYS_DATE=$(($(date +%s) + (86400*$WARN_DAYS)));
CRIT_DAYS_DATE=$(($(date +%s) + (86400*$CRIT_DAYS)));

###############################################################
# you should not need to edit anything below here
###############################################################

find /etc/apache2/sites-enabled/ -iname *.conf |
while read FILE ; do
	if [ -e "$FILE" ]; then
		cat "$FILE" | grep -v "^\s*#" | grep "SSLCertificateFile" | awk {'print $2'}
	fi
done | while read TARGET; do

	# Parse the Certifiate's lifespan
	EXPIRATIONDATE=$(date -d "$(: | openssl x509 -in $TARGET -text -noout | grep 'Not After' | awk '{print $4,$5,$7}')" '+%s');
	
	# Get the Common name of the certificate
	VHOST=$(openssl x509 -in $TARGET -text -noout | grep "Subject: CN" | awk {'print $4'})
	
	# Check if certificate is already expired
	if [ $(date +%s) -gt $EXPIRATIONDATE ]; then
		STATE=2 #Check_MK's Critical-STATE
		DESCRIPTION="This certificate is expired since $(date -d @$EXPIRATIONDATE '+%Y-%m-%d')!!"

	elif [ $CRIT_DAYS_DATE -gt $EXPIRATIONDATE ]; then
		STATE=2 #Check_MK's Critical-STATE
		DESCRIPTION="Expiry in less than $CRIT_DAYS Days (valid until $(date -d @$EXPIRATIONDATE '+%Y-%m-%d'))!"

	elif [ $WARN_DAYS_DATE -gt $EXPIRATIONDATE ] && [ $CRIT_DAYS_DATE -lt $EXPIRATIONDATE ]; then
		STATE=1 #Check_MK's Warning-STATE
		DESCRIPTION="Expiry in less than $WARN_DAYS but more than $CRIT_DAYS Days (valid until $(date -d @$EXPIRATIONDATE '+%Y-%m-%d'))."

	elif [ $WARN_DAYS_DATE -lt $EXPIRATIONDATE ]; then
		STATE=0 #Check_MK's OKAY-STATE
		DESCRIPTION="Certificate '$VHOST' will expire on $(date -d @$EXPIRATIONDATE '+%Y-%m-%d')."

	else #Set unknown if output is garbage
		STATE=3 #Check_MK's  Unknown-STATE
	fi

	echo "$STATE SSL-Cert_$VHOST - $DESCRIPTION" | sed -r 's/[*]+/wildcard/g'
done
