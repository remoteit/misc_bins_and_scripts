#!/bin/bash
# script to upgrade 1.3-06 to 1.3-07, adding rmt3 bulk service, schannel, and HWID to existing
cd ~

NAME=$1
AUTH=$2

# remove any existing file, download from github
if [ -f weavedconnectd_1.3-07c_armel.deb ]; then
    rm weavedconnectd_1.3-07c_armel.deb
fi

wget https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-07/weavedconnectd_1.3-07c_armel.deb
dpkg -i weavedconnectd_1.3-07c_armel.deb

# now install rmt3 service
cp /usr/bin/remot3it_register /root
sed s/USERNAME=\"\"/USERNAME=\"$NAME\"/g < /usr/bin/remot3it_register > /tmp/rr.sh
sed s/REPLACE_AUTHHASH/$AUTH/g < /tmp/rr.sh > /tmp/rr2.sh
sed 's/"$mac"/"Clarehome-$mac"/g' < /tmp/rr2.sh > /tmp/rr3.sh
sed s/"# convertExistingUIDs"/convertExistingUIDs/g < /tmp/rr3.sh > /usr/bin/remot3it_register
wget https://github.com/weaved/installer/raw/master/weaved_software/enablements/rmt3.pi
mv rmt3.pi /usr/share/weavedconnectd/conf
# mv ~/enablements/*.conf /etc/weaved/services
remot3it_register
# finally, start everything up
weavedstart.sh
# restore and clean up
mv /root/remot3it_register /usr/bin
rm $0
