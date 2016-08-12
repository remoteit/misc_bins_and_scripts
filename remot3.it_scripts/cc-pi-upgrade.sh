#!/bin/bash
# script to upgrade Clare 1.3-04 to weavedconnectd 1.3-07, adding rmt3 bulk service, schannel, and HWID to existing
cd ~

NAME=$1
AUTH=$2

mkdir enablements
cp /etc/weaved/services/*.conf enablements
dpkg --purge weavedconnectd-clare

# remove any existing file, download from github
if [ -f weavedconnectd_1.3-07c_armhf.deb ]; then
    rm weavedconnectd_1.3-07c_armhf.deb
fi

wget https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-07/weavedconnectd_1.3-07c_armhf.deb
dpkg -i weavedconnectd_1.3-07c_armhf.deb
# get Clare version of rmt3 conf file
wget https://github.com/weaved/installer/raw/master/weaved_software/enablements/rmt3.pi
mv rmt3.pi /usr/share/weavedconnectd/conf
# now install rmt3 service
cp /usr/bin/remot3it_register /root
sed s/USERNAME=\"\"/USERNAME=\"$NAME\"/g < /usr/bin/remot3it_register > /tmp/rr.sh
sed s/REPLACE_AUTHHASH/$AUTH/g < /tmp/rr.sh > /tmp/rr2.sh
sed 's/"$mac"/"Clarehome-$mac"/g' < /tmp/rr2.sh > /tmp/rr3.sh
sed s/"# convertExistingUIDs"/convertExistingUIDs/g < /tmp/rr3.sh > /usr/bin/remot3it_register
mv ~/enablements/*.conf /etc/weaved/services
remot3it_register
# recreate startup scripts from enablement files
# finally, start everything up
weavedstart.sh
mv /root/remot3it_register /usr/bin
rm $0
