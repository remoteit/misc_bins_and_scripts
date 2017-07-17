#!/bin/bash
logfile="/tmp/$0.log"
HOMEDIR="/home/pi"

da=$(date -I | sed s/"\s"/"_"/g)
dtm=$(date -R | sed s/"\s"/"_"/g)
echo "$da"_"$dtm" > "$logfile"

cd "$HOMEDIR/Dropbox-Uploader"

./dropbox_uploader.sh  list "/" | grep "$da"
if [ ! $? ]; then
echo "Creating directory for $da" >> "$logfile"
./dropbox_uploader.sh  mkdir "$da"
fi

./dropbox_uploader.sh  upload /var/log/messages  "$da"/"$dtm"_messages | grep "DONE"

if [ ! $? ]; then
echo "Error uploading logfile" >> "$logfile"
else
echo "Success uploading logfile" >> "$logfile"
fi

./dropbox_uploader.sh  list "/$da"  >> "$logfile"
