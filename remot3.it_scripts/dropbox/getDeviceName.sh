#!/bin/bash
namefile="/home/pi/.remot3.it/devicename"

if [ ! -f "$namefile" ]; then
    echo "Device name is not set!"
else
    name=$(cat "$namefile")
    echo "$name"
fi
