#!/bin/bash
# script to upgrade Clare 1.3-04 to weavedconnectd 1.3-07, adding rmt3 bulk service, schannel, and HWID to existing
# this will use any existing UIDs found in enablement files to enregister those services
# prior to purging the weavedconnectd-clare package
# we have to save all of Clare's template enablement files so that they can be replaced prior to running the remot3it_register after 1.3-07 installation
#================================================================
# ----------------------------------------
# web API URLs
version=v27
server=api
loginURL=https://$server.weaved.com/$version/api/user/login
loginAuthURL=https://$server.weaved.com/$version/api/user/login/authhash
unregdeviceURL=https://$server.weaved.com/$version/api/device/list/unregistered
preregdeviceURL=https://$server.weaved.com/$version/api/device/create
deleteURL=https://$server.weaved.com/$version/api/device/delete
connectURL=https://$server.weaved.com/$version/api/device/connect
deviceURL=https://$server.weaved.com/$version/api/device
deviceHWIDURL=https://$server.weaved.com/$version/api/developer/device/hardwareid
regdeviceURL=https://$server.weaved.com/$version/api/device/register
#===============================================================
TMP_DIR=/tmp
BIN_DIR=/usr/bin
WEAVED_DIR=/etc/weaved/services
PID_DIR=/var/run
APIKEY="WeavedDeveloperToolsWy98ayxR"
SERIALNUMBERFILE=/etc/weaved/serial.txt
STARTEMUP=weavedstart.sh

####### SignInAPI ###################
signInAPI()
{
#    echo $username $password $authhash
    if [ "$authhash" == "REPLACE_AUTHHASH" ]; then
        resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:$APIKEY" "$loginURL/$username/$password" 2> $TMP_DIR/.curlerr)
    else
        resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:$APIKEY" "$loginAuthURL/$username/$authhash" 2> $TMP_DIR/.curlerr)
    fi

#    debug $resp

    status=$(jsonval "$resp" "status")
#    debug $status

    if [ "$status" == "true" ]; then
	token=$(jsonval "$resp" "token")
    else
    	loginFailed=$(echo "$resp" | grep "The username or password are invalid" | sed 's/"//g')
    	slimError=$(echo "$resp" | grep "Slim Application Error" | sed 's/"//g')
    	login404=$(echo "$resp" | grep 404 | sed 's/"//g')
#	echo "Error" $loginFailed $slimError $login404
    fi

    # invalid cert can happen if system date is set to before current date
    invalidCert=$(cat $TMP_DIR/.curlerr  | grep "SSL certificate problem")
    date +"%s" > $TMP_DIR/.lastlogin
}
####### End SignInAPI ###################

######### Test Login #########
testLogin()
{
    while [ "$loginFailed" != "" ] || [ "$slimError" != "" ]; do
#	clear
	printf "You have entered either an incorrect username or password. Please try again.\n"

    done
    if [ "$invalidCert" != "" ]; then
 #       clear
        printf "The login security certificate is not valid.  This can be caused\n"
        printf "by your system date being incorrect.  Your system date is:\n\n $(date)\n\n"
        printf "Please correct the system date if needed and run the installer again.\n"
        printf "Run the command 'man date' for help resetting the date.\n\n"
        printf "If you are receiving this message and your system date is correct,\n"
        printf "please contact Weaved support at forum.weaved.com.\n"
        exit
    fi
}
######### End Test Login #########

######### Remove matching line from root crontab ######
cronRemoveLine()
{
    crontab -l | grep -v "$1" | cat > $TMP_DIR/.crontmp
    crontab $TMP_DIR/.crontmp
}

######### Disable Weaved services to start at reboot time ######
disableStartup()
{
    cronRemoveLine "@reboot $BIN_DIR/$STARTEMUP"
}
######### End Disable Weaved services to start at reboot time ######


##### Delete All Connections
deleteAllConnections()
{
    if [ 1 ]; then

    # now iterate through all enablement files to find it
    # stop all daemons.  

    	for file in $WEAVED_DIR/*.conf; do
	# get service name from UID
            uid="$(grep '^UID' $file | awk '{print $2}')"
	    resp=$(curl -s -S -X GET -H "content-type:application/json" -H "apikey:$APIKEY"  -H "token:$token" "$deviceURL/$uid")
            serviceName=$(jsonval "$resp" "name")

	    logger "weaved: upgrade Deleting $serviceName..."
	
	    result=$(curl -s $deleteURL -X 'POST' -d "{\"deviceaddress\":\"$uid\"}" -H “Content-Type:application/json” -H "apikey:$APIKEY" -H "token:$token" &> /dev/null)
	    deleteResult=$(jsonval "$result" "status")
#	    debug $deleteResult

	    fileNameRoot=$(echo $file |xargs basename | awk -F "." {'print $1'})
#		    echo $fileNameRoot
 	    # if daemon pid exists, stop daemon and remove start/stop script
 	    if [ -f $PID_DIR/$fileNameRoot.pid ]; then
 	        if [ -f $BIN_DIR/$fileNameRoot.sh ]; then
 		    $BIN_DIR/$fileNameRoot.sh stop -q
 		    rm $BIN_DIR/$fileNameRoot.sh
		fi
	    fi
	    if [ -f $file ]; then
		rm $file
	    fi
	    if [ -f $BIN_DIR/notify_$fileNameRoot.sh ]; then
		rm $BIN_DIR/notify_$fileNameRoot.sh
   	    fi
        done
        if [ -f $BIN_DIR/$STARTEMUP ]; then
	    rm $BIN_DIR/$STARTEMUP
   	fi
# also should clear out crontab at this point
	disableStartup
# remove serial.txt
        if [ -f $SERIALNUMBERFILE ]; then
	    rm $SERIALNUMBERFILE
   	fi
    fi
}

##### End of Delete All Connections

#----------------------------------------------------------
# JSON parse (very simplistic):  get value frome key $2 in buffer $1,  values or keys must not have the characters {}[", 
#   and the key must not have : in it
#
#  Example:
#   value=$(jsonval "$json_buffer" "$key") 
#                                                   
jsonval()                                              
{
#    echo "jsonval $1 $2"
    temp=`echo "$1" | sed -e 's/[{}\"]//g' | sed -e 's/,/\'$'\n''/g' | grep -w $2 | cut -d"[" -f2- | cut -d":" -f2-`
    #echo ${temp##*|}         
    echo ${temp}                                                
}  

#=============================================

# ---- main program starts here

cd ~

# get account credentials from cmd line
username=$1
authhash=$2

# copy existing customized enablement files
if [ ! -d enablements ]; then
    mkdir enablements
fi

cp /usr/share/weavedconnectd/conf/* enablements

# log in

signInAPI
logger "Weaved token=$token"

# now iterate through installed enablement files and remove any services with a UID and password already
deleteAllConnections

# next purge the weavedconnectd-clare package
dpkg --purge weavedconnectd-clare

# remove any existing file, download from github
if [ -f weavedconnectd_1.3-07c_armhf.deb ]; then
    rm weavedconnectd_1.3-07c_armhf.deb
fi
# download new deb pkg
wget https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-07/weavedconnectd_1.3-07c_armhf.deb

# get Clare version of rmt3 conf file
wget https://github.com/weaved/installer/raw/master/weaved_software/enablements/rmt3.pi
# check MD5 sums for any problem
echo "3e9b3fdd933400677c465d49032b7db1  weavedconnectd_1.3-07c_armhf.deb" > /tmp/wmd5.txt
echo "6799810c2e8846319c8c71ca0d041eaf rmt3.pi" >> /tmp/wmd5.txt
DLOK=$(md5sum -c /tmp/wmd5.txt)
logger "Weaved- $DLOK"

# everything checks out, so proceed
mv rmt3.pi /usr/share/weavedconnectd/conf
# restore previous enablement files
mv /root/enablements/* /usr/share/weavedconnectd/conf

# now install newe deb pkg, then rmt3 service
dpkg -i weavedconnectd_1.3-07c_armhf.deb
cp /usr/bin/remot3it_register /root
sed s/USERNAME=\"\"/USERNAME=\"$NAME\"/g < /usr/bin/remot3it_register > /tmp/rr.sh
sed s/REPLACE_AUTHHASH/$AUTH/g < /tmp/rr.sh > /tmp/rr2.sh
sed 's/"$mac"/"Clarehome-$mac"/g' < /tmp/rr2.sh > /tmp/rr3.sh
sed 's/#    makeConnection ssh/    makeConnection ssh/g' < /tmp/rr3.sh > /tmp/rr4.sh
sed 's/#    makeConnection web 80/    makeConnection web 8080/g' < /tmp/rr4.sh > /tmp/rr5.sh
sed 's/#    makeConnection tcp 3389 "$SERVICEBASENAME-tcp-3389"/    makeConnection tcp 7519 "$SERVICEBASENAME-tcp-7519"/g' < /tmp/rr5.sh > /usr/bin/remot3it_register

# mv ~/enablements/*.conf /etc/weaved/services
remot3it_register
# recreate startup scripts from enablement files
# finally, start everything up
weavedstart.sh
# now clean up all traces
mv /root/remot3it_register /usr/bin
rm /tmp/rr.sh /tmp/rr2.sh /tmp/rr3.sh
# rm $0
