#!/bin/bash
# The above line should be for your system.  Raspberry Pi supports bash shell
#
# remot3.it Bulk Management Script 
#
# $1 parameter is the jobID used for completion status
# $2 is API server
#
# This example script first clears all the status columns (StatusA-E) in the remot3.it portal.
# Next this script grabs the following Pi system values and returns them to the remot3.it portal.
#
#StatusA = os-release ID per /etc/os-release
#StatusB = Linux Kernel version
#StatusC = System uptime since last boot
#StatusD = counts and returns the number of TCP services on Pi that are available for remot3.it access
#StatusE = Free memory on the Pi

TOOL_DIR="/usr/bin"

#if you need to update status in log running process use the following (not more than once every 30 seconds)
#task_notify.sh 1 $1 "Job at stage x"

# Clear all status columns A-E in remot3.it portal

ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "")
ret=$(${TOOL_DIR}/task_notify.sh b $1 $2 "")
ret=$(${TOOL_DIR}/task_notify.sh c $1 $2 "")
ret=$(${TOOL_DIR}/task_notify.sh d $1 $2 "")
ret=$(${TOOL_DIR}/task_notify.sh e $1 $2 "")

# Update status column A (StatusA) in remot3.it portal
#-------------------------------------------------
# retrieve the os ID as reported by the command “cat /etc/os-release”
os=$(cat /etc/os-release | grep -w ID | awk -F "=" '{print $2 }')
# send to status column a in remot3.it portal
ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 $os)
#-------------------------------------------------

# Update status column B (StatusB) in remot3.it portal
#-------------------------------------------------
# retrieve the Linux kernel version
fwversion=$(uname -a | awk '{print $3 }')
# send to status column b in remot3.it portal
ret=$(${TOOL_DIR}/task_notify.sh b $1 $2 "$fwversion")
#-------------------------------------------------

# Update status column C (StatusC) in remot3.it portal
#-------------------------------------------------
# retrieve the system uptime 
uptime=$(uptime | sed 's/^.*up *//; s/, *[0-9]* user.*$/m/; s/day[^0-9]*/d, /;s/\([hm]\).*m$/\1/;s/:/h, /;s/^//')
# send to status column c in remot3.it portal
ret=$(${TOOL_DIR}/task_notify.sh c $1 $2 "$uptime")
#-------------------------------------------------

# Update status column D (StatusD) in remot3.it portal
#-------------------------------------------------
# retrieve the number of services with an active remot3.it attachment
sys=$(ps ax | grep weavedconnect | grep -v grep | wc -l)
# send to status d
ret=$(${TOOL_DIR}/task_notify.sh d $1 $2 "$sys")
#-------------------------------------------------

# Update status column E (StatusE) in remot3.it portal
#-------------------------------------------------
# use free command to retrieve free memory space value
memfree=$(free | grep Mem | awk '{print $4 }')
# send to status e
ret=$(${TOOL_DIR}/task_notify.sh e $1 $2 "$memfree")
#-------------------------------------------------

#=======================================================================
# ${TOOL_DIR}/task_notify.sh 1 $1 $2 "Job at stage 3"
#=======================================================================
# Lastly finalize job, no updates allowed after this
ret=$(${TOOL_DIR}/task_notify.sh 1 $1 $2 "Job complete")

# Use this for error, and message
#${TOOL_DIR}/task_notify.sh 2 $1 $2 "Job Failed"

