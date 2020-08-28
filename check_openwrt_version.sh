#!/bin/ash
# Show the installed OpenWrt release version in Check_MK as a service
# This check will always be okay

. /etc/openwrt_release
echo "0 OpenWrt_Version - Installed: $DISTRIB_DESCRIPTION"
