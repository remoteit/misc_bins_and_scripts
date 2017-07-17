#!/bin/bash
TOOL_DIR="/usr/bin"

#if you need to update status in log running process use the following (not more than once every 30 seconds)
#task_notify.sh 1 $1 "Job at stage x"

# Clear all status columns A-E in remot3.it portal

ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "")
#===========================================================
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
    ret=$(${TOOL_DIR}/task_notify.sh 2 $1 $2 "Upload failed.")
else
    echo "Success uploading logfile" >> "$logfile"
    ret=$(${TOOL_DIR}/task_notify.sh 1 $1 $2 "Upload succeeded.")
    ./dropbox_uploader.sh  list "/$da"  >> "$logfile"
fi


