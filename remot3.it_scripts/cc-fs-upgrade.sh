#!/bin/bash
# script to upgrade armel 1.3-06 to 1.3-07u, adding rmt3 bulk service, schannel, and HWID to existing
cd /root

dpkg --status weavedconnectd | grep armel
if [ $? == 1 ]; then
     echo "Not armel architecture.  Exiting..."
     exit
fi

VERSION=$(dpkg --status weavedconnectd | grep Version | awk '{ print $2 }')
if [ "$VERSION" != "1.3-06" ]; then
     echo "Detected $VERSION is unexpected.  Exiting..."
     exit
fi

NAME=$1
AUTH=$2

# back up the OEM enablement files for isntalled services
cd /root
mkdir enablements
cp /etc/weaved/services/*.conf enablements

# remove any existing file, download from github
if [ -f weavedconnectd_1.3-07u_armel.deb ]; then
    rm weavedconnectd_1.3-07u_armel.deb
fi

wget https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-07/weavedconnectd_1.3-07u_armel.deb
dpkg -i weavedconnectd_1.3-07u_armel.deb

# now install rmt3 service
cp /usr/bin/remot3it_register /root
sed s/USERNAME=\"\"/USERNAME=\"$NAME\"/g < /usr/bin/remot3it_register > /tmp/rr.sh
sed s/REPLACE_AUTHHASH/$AUTH/g < /tmp/rr.sh > /tmp/rr2.sh
sed 's/"$mac"/"Clarehome-$mac"/g' < /tmp/rr2.sh > /tmp/rr3.sh
sed s/"# convertExistingUIDs"/convertExistingUIDs/g < /tmp/rr3.sh > /usr/bin/remot3it_register
wget https://github.com/weaved/installer/raw/master/weaved_software/enablements/rmt3.pi
# move the downloaded file to where the installer remot3it_register will find it
mv rmt3.pi /usr/share/weavedconnectd/conf
# restore the installed enablement files
cp /root/enablements/*.conf /etc/weaved/services

remot3it_register
# finally, start everything up
weavedstart.sh
# restore and clean up
mv /root/remot3it_register /usr/bin
rm /tmp/rr.sh /tmp/rr2.sh /tmp/rr3.sh
rm $0
