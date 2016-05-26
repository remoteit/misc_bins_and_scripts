#!/bin/bash
# The above line should be for your system.
#
# remot3.it Bulk Management Skeleton Script 
#
# $1 parameter is the jobID used for completion status
#
# Put your scripts here, can be anything this example get the kernal version and arch 
#
TOOL_DIR="/usr/bin"

# first param is os ID
kv=$(cat /etc/os-release | grep -w ID | awk -F "=" '{print $2 }')
# second one is free disk space in %
sys=$(ps ax | grep weavedconnect | grep -v grep | wc -l)

#need to notify back based on below

#if you need to update status in log running process use the following (not more than once every 30 seconds)
#task_notify.sh 1 $1 "Job at stage x"

# send to status a
ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 " ")
ret=$(${TOOL_DIR}/task_notify.sh b $1 $2 " ")
ret=$(${TOOL_DIR}/task_notify.sh c $1 $2 " ")
ret=$(${TOOL_DIR}/task_notify.sh d $1 $2 " ")
ret=$(${TOOL_DIR}/task_notify.sh e $1 $2 " ")


# Lastly finalize job, no updates allowed after this
ret=$(${TOOL_DIR}/task_notify.sh 1 $1 $2 "Job complete $kv")

# Use this for error, and message
#/usr/bin/weaved_plugin.sh 2 $1 $2 "Job Failed"

