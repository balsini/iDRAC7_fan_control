#!/bin/bash
#
# https://github.com/brezlord/iDRAC7_fan_control
# A simple script to control fan speeds on Dell generation 12 PowerEdge servers. 
# If the inlet temperature is above 35deg C enable iDRAC dynamic control and exit program.
# If inlet temp is below 35deg C set fan control to manual and set fan speed to predetermined value.
# The tower servers T320, T420 & T620 inlet temperature sensor is after the HDDs so temperature will
# be higher than the ambient temperature.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo $SCRIPT_DIR
git -C $SCRIPT_DIR reset --hard HEAD
git -C $SCRIPT_DIR pull
chmod +x $SCRIPT_DIR/fan_control.sh

source .env

# Variables
#IDRAC_IP="IP address of iDRAC"
#IDRAC_USER="user"
#IDRAC_PASSWORD="passowrd"
# Fan speed in %
SPEED0="0x00"
SPEED5="0x05"
SPEED10="0x0a"
SPEED15="0x0f"
SPEED20="0x14"
SPEED25="0x19"
SPEED30="0x1e"
SPEED35="0x23"
TEMP_THRESHOLD="50" # iDRAC dynamic control enable thershold
TEMP_SENSOR="04h"   # Inlet Temp
#TEMP_SENSOR="01h"  # Exhaust Temp
#TEMP_SENSOR="0Eh"  # CPU 1 Temp
#TEMP_SENSOR="0Fh"  # CPU 2 Temp

# Get system date & time.
DATE=$(date +%d-%m-%Y\ %H:%M:%S)
echo "Date $DATE"

# Get temperature from iDARC.
T=$(ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD sdr type temperature | grep $TEMP_SENSOR | cut -d"|" -f5 | cut -d" " -f2)
echo "--> iDRAC IP Address: $IDRAC_IP"
echo "--> Current Inlet Temp: $T"

# If ambient temperature is above 35deg C enable dynamic control and exit, if below set manual control.
if [[ $T -ge $TEMP_THRESHOLD ]]
then
  echo "--> Temperature is above 35deg C"
  echo "--> Enabled dynamic fan control"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x01 0x01
  exit 1
else
  echo "--> Temperature is below 35deg C"
  echo "--> Disabled dynamic fan control"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x01 0x00
fi

MAX_SPEED=35
MIN_SPEED=5
MIN_TEMP=25

DYN_SPEED=0
[ "$T" -ge "$MIN_TEMP" ] && DYN_SPEED=$((MAX_SPEED * (T-MIN_TEMP) / (TEMP_THRESHOLD - MIN_TEMP)))

DYN_SPEED_HEX=$(printf "0x%x\n" $DYN_SPEED)

echo "--> Setting fan speed to $DYN_SPEED% ($DYN_SPEED_HEX)"
ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $DYN_SPEED_HEX


exit 0


# Set fan speed dependant on ambient temperature if inlet temperaturte is below 35deg C.
# If inlet temperature between 1 and 14deg C then set fans to 10%.
if [ "$T" -ge 1 ] && [ "$T" -le 14 ]
then
  echo "--> Setting fan speed to 10%"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $SPEED10

# If inlet temperature between 15 and 19deg C then set fans to 15%
elif [ "$T" -ge 15 ] && [ "$T" -le 19 ]
then
  echo "--> Setting fan speed to 15%"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $SPEED15

# If inlet temperature between 20 and 24deg C then set fans to 20%
elif [ "$T" -ge 20 ] && [ "$T" -le 24 ]
then
  echo "--> Setting fan speed to 20%"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $SPEED20

# If inlet temperature between 25 and 29deg C then set fans to 25%
elif [ "$T" -ge 25 ] && [ "$T" -le 29 ]
then
  echo "--> Setting fan speed to 25%"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $SPEED25

# If inlet temperature between 30 and 35deg C then set fans to 30%
elif [ "$T" -ge 30 ] && [ "$T" -le 34 ]
then
  echo "--> Setting fan speed to 30%"
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $SPEED30
fi
