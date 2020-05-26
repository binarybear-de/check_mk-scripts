echo "<<<lnx_thermal:sep(124)>>>"
# if your system does not show temperature sensors as acpi devices, they are not listed in Check_MK
# I wrote a check to keep track of the CPU thermals of my GA-N3150-D3V mainboard in my server, board thermal reading is always 26,8 °C...
# Creates a single Service called "CPU-Core SUMMARY" in Check_MK. If you wish a separated service for each core, simple uncomment the echo-line in the for-loop

# UNSTABLE STATE! Just programmed in ~10 Minutes, so use it with care!
# Install lm-sensors first, e.g. apt install lm-sensors
# You can always check what lm-sensors finds on you system with the command "lm-sensors"!

# My Output looks like this

#acpitz-acpi-0
#Adapter: ACPI interface
#temp1:        +26.8°C  (crit = +95.0°C)

#coretemp-isa-0000
#Adapter: ISA adapter
#Core 0:       +29.0°C  (high = +90.0°C, crit = +90.0°C)
#Core 1:       +29.0°C  (high = +90.0°C, crit = +90.0°C)
#Core 2:       +29.0°C  (high = +90.0°C, crit = +90.0°C)
#Core 3:       +29.0°C  (high = +90.0°C, crit = +90.0°C)

#####

TEMP_CRIT=40 #threshold for CRITICAL state
AMOUNT_CORES=4 #Constant AMOUNT_CORESider

####
TEMP_SUMMARY=0 #Do not change, declaration to not fail the first addition operation.

#Check every core for its temperature - YES the cores are hardcoded ... -_-
for i in `seq 2 $[$AMOUNT_CORES + 1]`; do #start at second line because first is the thermal sensors of my board
        TEMPERATURE=$(sensors -u | grep "$i"_input | awk {'print $2'});
        echo "CPU-Core $i|enabled|cpu-thermal|${TEMPERATURE//.}|55000|critical|55000|warn|60000|passive|110000|active" # uncomment for EVERY core as a service
        TEMP_SUMMARY=$[${TEMPERATURE//.} + $TEMP_SUMMARY]
done


echo "CPU-Core SUMMARY|enabled|cpu-thermal|$[$TEMP_SUMMARY / $AMOUNT_CORES]|"$TEMP_CRIT"000|critical" # uncomment for a summary of every core in one service
