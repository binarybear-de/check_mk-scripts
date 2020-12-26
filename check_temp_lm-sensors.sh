echo "<<<lnx_thermal:sep(124)>>>"
sensors -u | grep _input | awk {'print $2'} | while read -r temp; do
        s=$((s+1))
        echo "Zone 0$s|enabled|thermal|${temp//.}"
done
