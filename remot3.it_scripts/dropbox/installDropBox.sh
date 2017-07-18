#!/bin/bash
# r3_header, -s (Enter DropBox API token)
# clear status column A in remot3.it portal

ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "")
#=================================================
logfilename="$0".log
. /usr/bin/remot3_script_lib

cd /home/pi
git clone https://github.com/andreafabrizi/Dropbox-Uploader.git
dropbox_api_token=""

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

cd Dropbox-Uploader
echo "$dropbox_api_token" > db_installer.tmp
echo "y" >> db_installer.tmp

./dropbox-uploader.sh < db_installer.tmp

ret=$(${TOOL_DIR}/task_notify.sh a $1 $2 "Done.")
ret=$(${TOOL_DIR}/task_notify.sh 1 $1 $2 "Done.")
