#!/bin/bash

logfilename="/tmp/$0".log
. /usr/bin/remot3_script_lib

deviceNameURL="api.remot3.it/apv/v22.12/device/validate/"
uid=$(grep ^UID /etc/weaved/services/Weavedrmt365535.* | awk '{ print $2 }')
secret=$(grep ^password /etc/weaved/services/Weavedrmt365535.* | awk '{ print $2 }')
echo "$uid" > "$logfilename"
echo "$secret" >> "$logfilename"

resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:WeavedDeveloperToolsWy98ayxR" "$deviceNameURL$uid"/"$secret")
# echo $resp
name=$(jsonval "$resp" "name")
echo "Name is: $name" >> "$logfilename"

if [ ! -d /home/pi/.remot3.it ]; then
    echo "Creating remot3.it settings folder" >> "$logfilename"
    mkdir /home/pi/.remot3.it
fi

echo "$name" > /home/pi/.remot3.it/devicename
