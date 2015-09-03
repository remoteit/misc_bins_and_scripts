#!/bin/bash  
#
#  sshw_fast.sh: SSH wrapper for Weaved connections
#
#  uses UID for faster connection
#
#  sshw <-v> <-v> <username> <password> <UID>
#
#  <optional>  -v = verbose -v -v =maximum verbosity
#
#  will store info in ~/.weavedc/
#
#  License See : https://github.com/weaved/ssh_client
#

# include shell script lib, must be in path or specify path here
source lib.sh

#### Settings #####
VERSION=0.0.6
MODIFIED="Sept 4, 2015"
#
# Global Vars if set will not ask for these
# if using these fill all 4 out
#
USERNAME=""
PASSWD=""
DEVICE_ADDRESS=""
SSH_NAME=""
#
# Other Globals
#
DEVICE_STATE=""
LIST_ONLY=0
VERBOSE=0
PID=0;
#
# Config Dir
#
WEAVED_DIR="$HOME/.weaved"
LAST_LOGIN="$WEAVED_DIR/lastlogin"
USER="$WEAVED_DIR/user"
ENDPOINTS="$WEAVED_DIR/endpoints"
SAVE_AUTH="$WEAVED_DIR/auth"
CONNECTION_LOG="$WEAVED_DIR/log.$$.txt"
#
#
#
BIN_DIR=/usr/local/bin
EXE=weavedConnectd
#
# use/store authhash instead of password
#
USE_AUTH=0
#
#
#
startPort=33000
#
##### End Settings #####


#
# Config directory creation if not exist
#
create_config()
{
    umask 0077
    # create weaved directory
    if [ ! -d "$WEAVED_DIR" ]; then
        mkdir "$WEAVED_DIR" 
    fi
    # create files if they do not exist
    if [ ! -e "$ENDPOINTS" ] ; then
        touch "$ENDPOINTS"
    fi
    # create files if they do not exist
    if [ ! -e "$SAVE_AUTH" ] ; then
        touch "$SAVE_AUTH"
    fi
}
#
# Cleanup
#
cleanup()
{
    if [ $VERBOSE -gt 0 ]; then
        printf "Kill connection pid $PID\n"
        printf "Remove Connection Log\n"
    fi    

    rm $CONNECTION_LOG

    if [ $PID > 0 ]; then
            kill $PID
    fi
}

#
# Control C trap
#
ctrap()
{
    if [ $VERBOSE -gt 0 ]; then
        echo "ctrl-c trap"
    fi

    cleanup
    exit 0;
}

#
# Find next unused port
#
next_port()
{
    port=$startPort
    while [  1 ]; do
        # check if used
        grep "TPORT${port}" $ENDPOINTS > /dev/null 2>&1
        
        if [ $? = 1 ]; then
            # not found use this port
            break
        fi 

        let port=port+1
    done

#    echo "$port"
}

######### Wait for log event ########
#
# log_event file string
#
log_event()
{
    ret=0

    # create subshell and parse the logfile
    (echo $$; tail -f $1) | while read LINE ; do
        if [ -z $TPID ]; then
            TPID=$LINE # the first line is used to store the previous subshell PID
        else
            if [ $VERBOSE -gt 1 ]; then
                echo "log>>$LINE"
            fi

            case "$LINE" in
                *Cannot\ Bind*)
                    kill -3 $TPID            
                    echo "Port $port in use already cannot bind"
                    return 1
                    ;;
                *Starting\ Proxy*)
                    kill -3 $TPID
                    echo "Connection Started!"
                    exit 0 
                    #return 0
                ;;
                *usage:*)
                    kill -3 $TPID
                    echo "Error Starting weavedConnect"
                    return 2
                    ;;
                *command\ not\ found*)
                    kill -3 $TPID
                    echo "weavedConnectd Not Found In Path"
                    return 3
            esac
        fi
    done

    ret=$?
    return $ret 
}

usage()
{
       echo "Usage: $0 [-v (verbose)] [-v (maximum verbosity)] [-h (this message)] [<username> <password> <UID> <ssh login name>]" >&2
}

###############################
# Main program starts here    #
###############################
#
# Create the config directory if not there
#
create_config

################################################
# parse the flag options (and their arguments) #
################################################
while getopts vh OPT; do
    case "$OPT" in
      v)
        VERBOSE=$((VERBOSE+1)) ;;
      h | [?])
        # got invalid option
	usage
        exit 1 ;;
    esac
done

# get rid of the just-finished flag arguments
shift $(($OPTIND-1))

# echo $1
# in=$1

# If username not specified in this script, get from command line
if [ "$1" == "" ]; then
    if [ "$USERNAME" == "" ]; then
	usage
	exit
    else
    	username=$USERNAME
    fi
else
    username=$1
fi

if [ "$2" == "" ]; then
    if [ "$PASSWD" == "" ]; then
	usage
	exit
    else
	password=$PASSWD
    fi
else
    password=$2
fi

if [ "$3" == "" ]; then
    if [ "$DEVICE_ADDRESS" == "" ]; then
	usage
	exit
    else
        address=$DEVICE_ADDRESS
    fi
else
    address="$3"
fi

if [ "$4" == "" ]; then
    if [ "$SSH_NAME" == "" ]; then
	usage
	exit
    else
        ssh_name=$SSH_NAME
    fi
else
    ssh_name=$4
fi

base_username=$(echo -n "$username" | base64)
base_password=$(echo -n "$password" | base64)

next_port

if [ $VERBOSE -gt 0 ]; then
    echo "Device address is $address"
    echo "base64 username is $base_username"
    echo "base64 password is $base_password"
    echo "Connection will be to 127.0.0.1:$port"
fi


    touch "$CONNECTION_LOG"    
    rm $CONNECTION_LOG
    umask 0077

    # catch ctrl C now so we can cleanup
    trap ctrap SIGINT

    if [ $VERBOSE -gt 0 ]; then
        echo "Using connection log : $CONNECTION_LOG"
    fi

echo "Starting Weaved client daemon...."
#
# We can use a password or an Auth Hash (auth hash is a salted hashed value )
#
if [ "$USE_AUTH" == "1" ]; then
    # make the connection
    #$EXE -p "$base_username" "$ahash" "$address" "T$port" 2 127.0.0.1 0.0.0.0 15 0 0 > $CONNECTION_LOG &
    if [ $VERBOSE -gt 1 ]; then
        echo "issuing command: $EXE -p $base_username $ahash $DEVICE_ADDRESS T$port 2 127.0.0.1 0.0.0.0 15 0 0 > $CONNECTION_LOG &"
    fi
    pid=$!
else
    #
    # -c base64(yoicsid) base64(password) UID_to_connect TPort_to_bind encryption bind_to_address maxoutstanding
    #
    if [ $VERBOSE -gt 1 ]; then
        echo "issuing command: $EXE -c $base_username $base_password $address T$port 2 127.0.0.1 15 > $CONNECTION_LOG &"
    fi   
    $EXE -s -c $base_username $base_password $address T$port 2 127.0.0.1 15 > $CONNECTION_LOG 2>&1 &
    pid=$!
fi

if [ $VERBOSE -gt 1 ]; then
    echo "running pid $pid"
fi


# Wait for connectd to startup and connect
log_event $CONNECTION_LOG

retval=$?
if [ "$retval" != 0 ]
then
    kill $pid
    echo "Error in starting weavedConnectd or connecting to $device ($retval)"
    cleanup
    exit 255
fi


#
#
#
if [ $VERBOSE -gt 0 ]; then
    echo "running command>> ssh -l $ssh_name 127.0.0.1 -p$port"
fi
ssh -l "$ssh_name" 127.0.0.1 -p$port


echo "done"

cleanup

exit 0

