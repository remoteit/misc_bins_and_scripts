#!/bin/bash
# r3_header, -s (Enter DropBox API token)
TOOL_DIR="/usr/bin"

# clear status column A in remot3.it portal
ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "")
#=================================================
logfilename="$0".log
. /usr/bin/remot3_script_lib

cd /home/pi
git clone https://github.com/andreafabrizi/Dropbox-Uploader.git
dropbox_api_token=""

###############################
# Main program starts here    #
###############################
#
# Must have 3 parameters
#
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    usage
    exit 1
fi

jobid=$1
shift
api_server=$1
shift
short_code=$1

#
if [ $DEBUG_ON -gt 0 ]; then
    echo "$0 called with jobid $jobid api_server $api_server and shortcode $short_code" >> ${DEBUG_DIR}/$0
fi

command=$(translate $short_code)

if [ "$?" -gt 0 ]; then
    echo "[Fail] translate short code $short_code failed"
    exit 1
fi    

if [ $DEBUG_ON -gt 0 ]; then
    echo "Translated short code to $command" >> ${DEBUG_DIR}/$0
fi

#
# Must use eval to correctly expand command
#
eval set -- ${command}


################################################
# parse the flag options (and their arguments) #
################################################
while getopts f:m:p:l:s: OPT; do
    case "$OPT" in
        f)
            nul=$(wget --no-check-certificate $OPTARG 2>&1 )
            ;;
        m)
            # get file (part of multi file), this should be in the format "file -O output file"
            # you should be in the directory you want here
            nul=$(wget --no-check-certificate $OPTARG 2>&1 )
            ;;
        p)
            echo "-p"
            echo "(p) $OPTARG"
            ;;
        l)  
            # Location example as shown above in r3-header
            echo "-l"
            echo "(l) $OPTARG"
            ;;
        s)
            # echo "-s"
            # echo "(s) $OPTARG"
	    Status_A "Set SSID..."
	    log "Dropbox token: $OPTARG "
	    Status_A "SSID set."
            dropbox_api_token="$OPTARG"
            ;;
        esac
    done

cd /home/pi/Dropbox-Uploader
echo "$dropbox_api_token" > db_installer.tmp
echo "y" >> db_installer.tmp

./dropbox_uploader.sh < db_installer.tmp
# rm db_installer.tmp

ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "Done.")
ret=$(${TOOL_DIR}/task_notify.sh b $1 $2 "$dropbox_api_token")
ret=$(${TOOL_DIR}/task_notify.sh 1 $1 $2 "Done.")
