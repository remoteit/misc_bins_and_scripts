#!/bin/bash
#
#  web connection wrapper and working example for remot3.it Direct Connections
#
#  webw.sh <-v> <-v> <user@>remot3.it_webdevicename
#
#  <optional>  -v = verbose -v -v =maximum verbosity
#
#  will store info in ~/.remot3it/
#
#  License See : https://github.com/weaved/ssh_client
#
#  remot3.it Inc : https://remot3.it
#
#  Author : https://github.com/lowerpower
#

# include shell script lib, must be in path or specify path here
source lib.sh

#set -x

#### Settings #####
VERSION=0.0.9
MODIFIED="Jan 23, 2018"
#
# Config Dir
#
REMOT3IT_DIR="$HOME/.remot3it"
USER="$REMOT3IT_DIR/user"
ENDPOINTS="$REMOT3IT_DIR/endpoints"
AUTH="$REMOT3IT_DIR/auth"
CONNECTION_LOG="$REMOT3IT_DIR/log.$$.txt"
#
#
#
# connectd daemon name expected on the client
EXE=connectd
#
# Save Auth in homedir
#
SAVE_AUTH=1
#
# use/store authhash instead of password (recommended)
#
USE_AUTHHASH=1
authtype=0 
#
#
apiMethod="https://"
apiVersion="/apv/v23.5"
apiServer="api.remot3.it"
developerkey=""
pemkey=""
startPort=33000
#
# Global Vars if set will not ask for these
#
USERNAME=""
PASSWD=""
AHASH=""
#
# Other Globals
#
SERVICE_ADDRESS=""
SERVICE_STATE=""
LIST_ONLY=0
VERBOSE=0
DEBUG=0
PID=0;
TIMEIT=0
FAILTIME=10
#
# API URL's
#
loginURLpw="${apiMethod}${apiServer}${apiVersion}/user/login"
loginURLhash="${apiMethod}${apiServer}${apiVersion}/user/login/authhash"
logoutURL="${apiMethod}${apiServer}${apiVersion}/user/logout"
deviceListURL="${apiMethod}${apiServer}${apiVersion}/device/list/all"
##### End Settings #####

#
# Built in manpage
#
manpage()
{
#
# Put manpage text here
#
read -d '' man_text << EOF

webw.sh - A web connection wrapper for remot3.it showing use of the client-side daemon for a P2P connection.
------------------------------------------
This software allows you to make https connections to your remot3.it enabled http or https servers.

Your username and password will be stored in ~/.remot3it/auth.  In the event of a "102] login failure" error, delete this file and try again.

To get a list of all services associated with your account, use:

./webw.sh -l

To make an web connection to any given service, use:

./webw.sh service-name

servicename is the remot3.it name you gave to this device's web connection.

If your service name has spaces in it, surround "service name" with quotes.

Verbose output

To get more information about the internal operation of the script, use one or two -v switches, e.g.

./webw.sh -v device-name

./webw.sh -v -v device-name

Clearing the cache

To clear out all cached data (port assignments, service list)

./webw.sh -r

Connection times may be a little slower and you may get connection security warnings after doing this until all services have been conneced to once.

To cleanup (reset login authorization and active port assignments)

./webw.sh -c

After running this, you will need to log in again.

How the script works

The script starts by logging into the remot3.it server to obtain a login token.  All API calls are documented here:

https://remot3it.readme.io/v23.5/reference

The user token is sent to the Service List API call in order to retrieve the full device list associated with this account.

From there we parse the JSON output of the device list and find the entry corresponding to the device name you gave.  We find the UID (JSON ["deviceaddress"]) for this entry and use this in conjunction with the remot3.it daemon (connectd) in client mode to initiate a peer to peer connection.

/usr/bin/connectd -c <base64 of username> <base64 of password> <UID> T<portnum> <Encryption mode> <localhost address> <maxoutstanding>

-c = client mode
<base64 of username> = remot3.it user name, base64 encoded
<base64 of password> = remot3.it password, base64 encoded
<UID> = remot3.it UID for this device connections
<portnum> = port to use on localhost address
<Encryption mode> = 1 or 2
<localhost address> = 127.0.0.1
<maxoutstanding> = 12

Example:
/usr/bin/connectd -c ZmF1bHReaX5lMTk9OUB5YWhvby5jb20= d5VhdmVkFjAxWg== 80:00:00:0F:96:00:01:D3 T33000 1 127.0.0.1 12

Now you have a listener at 127.0.0.1:33000 that is a connection through remot3.it to your remote device's web service.

EOF
#
printf "\n%s\n\n\n" "$man_text"
}

#
# Print Usage
#
usage()
{
        echo "Usage: $0 [-v (verbose)] [-v (maximum verbosity)] [-l(ist services only)] [-c(leanup)] [-r(eset to default)] [-m(an page)] [-h (this message)] <devicename> " >&2
        echo "     [optional] must specify device name." >&2
        echo "Version $VERSION Build $MODIFIED" >&2
        exit 1 
}


#
# cleanup files that could affect normal operation if things went wrong
#
cleanup_files()
{
    if [ $VERBOSE -gt 0 ]; then
        printf "Cleaning up remot3.it runtime files.  Removing auth file and active files.\n"
    fi   
    # reset auth
    rm -f $AUTH
    # reset active files
    rm -f ${REMOT3IT_DIR}/*.active
}
#
# Delete all the stuff in ~\.remot3it to reset to default.  You may have to clean up your .ssh/known_hosts
# to get rid of ssh connection errors if your connections land on different ports
#
resetToDefault()
{
    if [ $VERBOSE -gt 0 ]; then
        printf "Resetting remot3.it settings to default.\n"
    fi   
    rm -f ${REMOT3IT_DIR}/*
}


#
# Config directory creation if not exist and setup file permissions
#
create_config()
{
    umask 0077
    # create remot3it directory
    if [ ! -d "$REMOT3IT_DIR" ]; then
        mkdir "$REMOT3IT_DIR" 
    fi
    # create files if they do not exist
    if [ ! -f "$ENDPOINTS" ] ; then
        touch "$ENDPOINTS"
    fi
    # cleanup old log files
    rm -f $REMOT3IT_DIR/*.txt
}
#
# Cleanup, this cleans up the files for the connection, and kills the P2P session if necessary
#
cleanup()
{
    if [ $DEBUG -eq 0 ]; then

        if [ $VERBOSE -gt 0 ]; then
            printf "Removing connection log.\n"
        fi    

        rm $CONNECTION_LOG
    else
        if [ $VERBOSE -gt 0 ]; then
            printf "Debug Mode, connection log is in $CONNECTION_LOG.\n"
        fi
    fi

    if [ $pid > 0 ]; then
        if [ $VERBOSE -gt 0 ]; then
            printf "Kill connection pid $pid.\n"
        fi
        kill $pid
    fi
    # cleanup port active file
    if [ -f "$REMOT3IT_DIR/${port}.active" ] ; then
        if [ $VERBOSE -gt 0 ]; then
            printf "Remove active flag file $REMOT3IT_DIR/${port}.active.\n"
        fi
        rm $REMOT3IT_DIR/${port}.active
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
# Find next unused port, returns the port to use, searches the $ENDPOINT cache
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

    echo "$port"

}
#
# check_auth_cache, one line auth file, type is set to 0 for password and 1 for authash
# 
# Returns $username $password $type on success
#
check_auth_cache()
{
    # check for auth file
    if [ -e "$AUTH" ] ; then
        # Auth file exists, lets get it
        read -r line < "$AUTH"
        # Parse
#        username=${line%%"|"*}
        username=$(echo $line | awk -F"|" '{print $1 }')
# echo "username: $username"
#        password=${line##*"|"}
        password=$(echo $line | awk -F"|" '{print $3 }')
# echo "password: $password"
#        t=${line#*"|"}
#echo "t: $t"
        authtype=$(echo $line | awk -F"|" '{print $2 }')
#        authtype=${t%%"|"*}
# echo "authtype: $authtype"
        developerkey=$(echo $line | awk -F"|" '{print $4 }')
# echo "developerkey: $developerkey"
        if [ $authtype -eq 1 ]; then
            ahash=$password
        fi
        return 1
    fi
    return 0
}

#
# Check Service Cache, return 1 if found and $port set
#
checkServiceCache()
{
    port=0

    # check if device exists, if so get port
    dev_info=$(grep "|$device|" $ENDPOINTS)

    if [ $? = 0 ]; then
        #found grab port
        p=${dev_info%%"|"*}
        port=${p##*"TPORT"}
        #Get address SERVICE_ADDRESS
        SERVICE_ADDRESS=${dev_info##*"|"}
        return 1
    fi
    return 0
}

#
#parse services
#
# fills service_array on return
#
parse_device()
{
    #parse services data into lines, this old code is not MacOS mach compatible
    #lines=$(echo "$1" | sed  's/},{/}\n{/g' )
    #lines=$(echo "$in" | sed  's/},{/}\'$'\n''{/g' )
    #lines=$(echo "$1" | sed  's/},{/}|{/g' )
    #parse lines into array 
    #readarray -t service_array < <( echo "$lines" )
    # mac friendly replacement
    #service_array=( $(echo $lines | cut -d $'\n' -f1) )

    # New optimized code that works with MacOS
    lines=$(echo "$1" | sed  's/},{/}|{/g' )
    IFS='|'
    service_array=(  $lines )
}

#
# match_device 
#   match the passed device name to the array and return the index if found or 0 if not
#   if found service_state and service_address are set
#
match_device()
{
    # loop through the device array and match the device name
    for i in "${service_array[@]}"
    do
        # do whatever on $i
        #service_name=$(jsonval "$(echo -n "$i")" "devicealias") 
        service_name=$(jsonval "$i" "devicealias") 
   
        if [ "$service_name" = "$1" ]; then
            # Match echo out the UID/address
            #service_address=$(jsonval "$(echo -n "$i")" "deviceaddress")
            SERVICE_ADDRESS=$(jsonval "$i" "deviceaddress")
            SERVICE_STATE=$(jsonval "$i" "devicestate")
            #echo -n "$SERVICE_ADDRESS"
            return 1
        fi
    done

    #fail
    #echo -n "Not found"
    return 0
}

#
# Service List
#
display_services()
{
    printf "%-30s | %-15s |  %-10s \n" "Service Name" "Service Type" "Service State"
    echo "--------------------------------------------------------------"
    # loop through the device array and match the device name
    for i in "${service_array[@]}"
    do
        # do whatever on $i
        service_name=$(jsonval "$i" "devicealias")
        service_state=$(jsonval "$i" "devicestate")
        service_service=$(jsonval "$i" "servicetitle")
        if [ "$service_service" == "HTTP" ]; then
            printf "%-30s | %-15s |  %-10s \n" $service_name $service_service $service_state
        fi
        #echo "$service_name : $service_service : $service_state"
    done
    echo
}


######### Begin Portal Login #########

getUserAndPassword() #get remot3it user and password interactively from user
{
    if [ "$USERNAME" != "" ]; then 
        username="$USERNAME"
    else
        printf "\n\n\n"
        printf "Please enter your remot3.it account username (email address): \n"
        read username
    fi

    if [ "$AHASH" != "" ]; then
        authtype=1
        ahash="$AHASH"
    else    

        if [ "$PASSWD" != "" ]; then
            password="$PASSWD"
        else
            printf "\nPlease enter your password: \n"
            read  -s password
        fi
    fi
    if [ "$DEVELOPERKEY" != "" ]; then
        developerkey="$DEVELOPERKEY"
    else
       printf "\nPlease enter your Developer API key: \n"
       read developerkey
    fi
}


# userLogin
# returns 1 if logged in, token is set
# returns 0 if not logged in login error is set
userLogin () #Portal login function
{
    printf "Logging in...\n"
#    echo "loginURLpw=$loginURLpw"
#    echo "username=$username"
#    echo "password=$password"
#    echo "developerkey=$developerkey"
#    echo 
    
    if [ $authtype -eq 1 ]; then
        resp=$(curl -s -S -X GET -H "content-type:application/json" -H "developerkey:${developerkey}" "$loginURLhash/$username/$ahash")
    else
        resp=$(curl -s -S -X POST -H "developerkey: ${developerkey}" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d "{ \"username\" : \"$username\", \"password\" : \"$password\" }" "$loginURLpw")
    fi

#    echo "resp=$resp"

    status=$(jsonval "$(echo -n "$resp")" "status")

    login404=$(echo "$resp" | grep "404 Not Found" | sed 's/"//g')

    if [ "$login404" ]; then
        # 404 error
        loginerror="[404] API not found"
        return 0
    fi

    if [ "$status" == "true" ]; then
        # good, get token
        #token=$(jsonval "$(echo -n "$resp")" "token")
        token=$(jsonval "$resp" "token")
        date +"%s" > ~/.remot3it_lastlogin
        # get atoken
        ahash=$(jsonval "$resp" "service_authhash")
        #echo "Got authhash >>$ahash"
        ret=1
    else
        loginerror=$(jsonval "$(echo -n "$resp")" "reason") 
        ret=0
    fi

    return "$ret"
}
 
######### End Portal Login #########

######### Service List ########
deviceList()
{
    resp=$(curl -s -S -X GET -H "content-type:application/json" -H "developerkey:$developerkey" -H "token:${token}" "$deviceListURL")
    echo $resp
}



######### Wait for log event ########
#
# log_event, this funcion is the P2P connection manager for the session, it monitors the P2P engine for connection and
#   Failure Status.  Once a connection has been established, this script terminates
#
log_event()
{
    ret=0

    # create subshell and parse the logfile, modified to work around mac osx old bash
    # ( echo $BASHPID; tail -f $1) | while read LINE ; do
    (echo $(sh -c 'echo $PPID'); tail -f $1) | while read LINE ; do
        if [ -z $TPID ]; then
            TPID=$LINE # the first line is used to store the previous subshell PID
        else
            if [ $VERBOSE -gt 1 ]; then
                echo "log>>$LINE"
            fi

            case "$LINE" in
                *auto\ connect\ failed*)
                    kill -3 $TPID
                    echo "Cannot create a connection to device $service_name"
                    return 4
                    ;;
                *proxy\ startup\ failed*)
                    kill -3 $TPID            
                    echo "Port $port in use already, cannot bind to port"
                    return 1
                    ;;
                *Proxy\ started.*)
                    kill -3 $TPID 
                    echo
                    echo "P2P tunnel connected on port $port" 
                    return 0
                ;;
                *usage:*)
                    kill -3 $TPID
                    echo "Error starting connectd daemon"
                    return 2
                    ;;
                *command\ not\ found*)
                    kill -3 $TPID
                    echo "connectd daemon not found In path"
                    return 3
                    ;;
                *state\ 5*)
                    printf "."
                    if [ $VERBOSE -gt 0 ]; then
                        echo
                        echo "Connected to service, starting P2P tunnel"
                    fi
                    ;;
                *connection\ to\ peer\ closed\ or\ timed\ out*)
                    echo "Connection closed or timed out."
                    exit
                    ;;
                *!!status*)
                    printf "."
                    ;; 
            esac
        fi
    done

    ret=$?
    #echo "exited"
    return $ret 
}


###############################
# Main program starts here    #
###############################
#
# Create the config directory if not there
#
echo "remot3.it webw.sh Version $VERSION $MODIFIED"
create_config

################################################
# parse the flag options (and their arguments) #
################################################
while getopts lvhmcr OPT; do
    case "$OPT" in
      c)
        cleanup_files
        exit 0
        ;;
      r)
        resetToDefault
        exit 0
        ;;
      m)
        manpage
        exit 0
        ;;
      l)
        LIST_ONLY=1 ;;
      v)
        VERBOSE=$((VERBOSE+1)) ;;
      h | [?])
        # got invalid option
echo "invalid"
        usage
        ;;
    esac
done

# get rid of the just-finished flag arguments
shift $(($OPTIND-1))

# make sure we have somthing to connect to
if [ $# -eq 0 -a "$LIST_ONLY" -ne 1 ]; then
    usage
fi

in=$1

# Parse off user
if [[ $1 == *"@"* ]]; then
    #user is specified, parse off host
    user=${1%%"@"*}"@"
    device=${1##*"@"}
else
    device=$1
fi

#shift opps out
shift

#check cache to see if we have auth 
check_auth_cache
retval=$?
if [ "$retval" != 0 ]; then
    # Lets Login
    if [ $VERBOSE -gt 0 ]; then
        echo "Use stored remot3.it credentials for user $username"
    fi
else
    getUserAndPassword
fi

#check device cache to see if we have device in cache
checkServiceCache
if [ $? = 1 ] && [ "$LIST_ONLY" -eq 0 ]; then
    # device found in cache, 
    if [ $VERBOSE -gt 0 ]; then
        printf "Found ${device} in cache with UID of ${SERVICE_ADDRESS} and port ${port}.  Trying fast connect, assuming credentials are valid and device is active.\n"
        #force device state as active, this may cause problems if not active
    fi
    SERVICE_STATE="active"
else

    # Login the User (future check if already logged in with token or user exists in saved form)
    userLogin
    
    # check return value and exit if error
    retval=$?
    if [ "$retval" == 0 ]
    then
        echo $loginerror
        exit 255
    fi 

    if [ $VERBOSE -gt 0 ]; then
        echo "Logged in - get device list"
    fi

    #save auth
    if [ $SAVE_AUTH -gt 0 ]; then
        if [ ! -e "$AUTH" ] ; then
            if [ $VERBOSE -gt 0 ]; then
                echo "Saving remot3.it credentials for $username"
            fi
            # Save either pw or hash depending on settings
            if [ $USE_AUTHHASH -eq 1 ]; then
                echo "${username}|1|${ahash}|${developerkey}" > $AUTH 
            else
                echo "${username}|0|${[password}|${developerkey}" > $AUTH 
            fi
        fi      
    fi

    # get device list
    dl_data=$(deviceList)

    # parse device list
    parse_device "$dl_data"

    if [ "$LIST_ONLY" -eq 1 ]; then
        # just display list only
        echo "Available HTTP services"
        echo
        display_services
        exit 0
    fi

    # Match Service passed to device list
    #address=$(match_device $device)
    match_device $device 

    retval=$?
    if [ "$retval" == 0 ]
    then
        echo "Service $device not found"
        exit 255
    fi

    # check if device exists, if so get port
    dev_info=$(grep "|$device|" $ENDPOINTS)

    if [ $? = 0 ]; then
        #found grab port
        p=${dev_info%%"|"*}
        port=${p##*"TPORT"}
    else
        # else get next port
        port=$(next_port)
        #append to file
        echo "TPORT${port}|${device}|${SERVICE_ADDRESS}" >> $ENDPOINTS
    fi
fi

#if [ $VERBOSE -gt 0 ]; then
#    echo "Service-- $device address is $address"
#fi

base_username=$(echo -n "$username" | base64)

if [ $VERBOSE -gt 0 ]; then
    echo "Service $device address is $SERVICE_ADDRESS"
    echo "Service is $SERVICE_STATE"
    echo "base64 username is $base_username"
    echo "Connection will be to 127.0.0.1:$port"
    if [  -e "$REMOT3IT_DIR/${port}.active" ]; then
        echo "A connection is already active, we will reuse the existing connection on port ${port}.";
    fi
fi

#
# IF device is not active we should warn user and not attach
#
if [ "$SERVICE_STATE" != "active" ]; then
    echo "Service is not active on the remot3.it Network, aborting connection attempt."
    exit 1
fi


#
# now check if port is already active, we do this by checking port running file
#
if [  -e $REMOT3IT_DIR/$port.active ]; then
    # port is active, lets just connect to it
    echo "102"
    if [ $VERBOSE -gt 0 ]; then
        printf "Port ${port} is already active, connecting to existing tunnel.\n"
    fi
    echo "Enter 127.0.0.1:$port into your browser's URL field."
    echo "Press a key to close this connection when you are done."
    #
    read anykey
    echo "done"

else
    #
    # need to setup a full connection
    #
    touch "$CONNECTION_LOG"    
    rm $CONNECTION_LOG
    umask 0077

    # catch ctrl C now so we can cleanup
    trap ctrap SIGINT

    if [ $VERBOSE -gt 0 ]; then
        echo "Using connection log : $CONNECTION_LOG"
    fi


    #
    # We can use a password or an Auth Hash (auth hash is a salted hashed value )
    # Auth Hash not yet tested
    #
    if [ $authtype -eq 1 ]; then
        # make the connection
        #$EXE -p "$base_username" "$ahash" "$address" "T$port" 2 127.0.0.1 0.0.0.0 15 0 0 > $CONNECTION_LOG &
        if [ $VERBOSE -gt 1 ]; then
            echo "Issuing command: $EXE -p $base_username $ahash $SERVICE_ADDRESS T$port 2 127.0.0.1 0.0.0.0 15 0 0 > $CONNECTION_LOG &"
        fi
        $EXE -s -p $base_username $ahash $SERVICE_ADDRESS T$port 2 127.0.0.1 0.0.0.0 15 0 0 > $CONNECTION_LOG 2>&1 &
        pid=$!
    else
        base_password=$(echo -n "$password" | base64)
        #
        # -c base64(yoicsid) base64(password) UID_to_connect TPort_to_bind encryption bind_to_address maxoutstanding
        #
        if [ $VERBOSE -gt 1 ]; then
            echo "Issuing command: $EXE -c $base_username $base_password $SERVICE_ADDRESS T$port 2 127.0.0.1 15 > $CONNECTION_LOG &"
        fi   
        $EXE -s -c $base_username $base_password $SERVICE_ADDRESS T$port 2 127.0.0.1 15 > $CONNECTION_LOG 2>&1 &
        pid=$!
    fi

    if [ $VERBOSE -gt 1 ]; then
        echo "Running pid $pid"
    fi


    # Wait for connectd to startup and connect
    log_event $CONNECTION_LOG

    retval=$?
    if [ "$retval" != 0 ]
    then        
        echo "Error in starting connectd daemon or connecting to $device ($retval)"
        cleanup
        exit 255
    fi
    #
    # Touch port active file
    #
    touch "$REMOT3IT_DIR/${port}.active"

    #
    #
    #

    echo "Enter 127.0.0.1:$port into your browser's URL field."
    echo "Press a key to close this connection when you are done."
    #
    read anykey
    echo "done"

    cleanup
fi

exit 0
