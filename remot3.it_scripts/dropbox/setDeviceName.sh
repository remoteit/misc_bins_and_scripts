#!/bin/bash
TOOL_DIR="/usr/bin"

#if you need to update status in log running process use the following (not more than once every 30 seconds)
#task_notify.sh 1 $1 "Job at stage x"

# Clear status column A in remot3.it portal

ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "")
#=================================================
logfilename="$0".log
. /usr/bin/remot3_script_lib

deviceNameURL="api.remot3.it/apv/v22.12/device/validate/"
uid=$(grep ^UID /etc/weaved/services/Weavedrmt365535.* | awk '{ print $2 }')
secret=$(grep ^password /etc/weaved/services/Weavedrmt365535.* | awk '{ print $2 }')
echo "UID: $uid" > "$logfilename"
echo "Secret: $secret" >> "$logfilename"

resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" "$deviceNameURL$uid"/"$secret")
# echo $resp
name=$(jsonval "$resp" "name")
echo "Name: $name" >> "$logfilename"

if [ ! -d /home/pi/.remot3.it ]; then
    echo "Creating remot3.it settings folder" >> "$logfilename"
    mkdir /home/pi/.remot3.it
fi

echo "$name" > /home/pi/.remot3.it/devicename
ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "$name")
ret=$(${TOOL_DIR}/task_notify.sh 1 $1 $2 "Set name succeeded.")
