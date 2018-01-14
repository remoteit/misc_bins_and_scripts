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
# download new deb pkg
wget https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-07/weavedconnectd_1.3-07c_armhf.deb

# get Clare version of rmt3 conf file
wget https://github.com/weaved/installer/raw/master/weaved_software/enablements/rmt3.pi
# check MD5 sums for any problem
echo "3e9b3fdd933400677c465d49032b7db1  weavedconnectd_1.3-07c_armhf.deb" > /tmp/wmd5.txt
echo "6799810c2e8846319c8c71ca0d041eaf rmt3.pi" >> /tmp/wmd5.txt
DLOK=$(md5sum -c /tmp/wmd5.txt)
# everthing checks out, so proceed
mv rmt3.pi /usr/share/weavedconnectd/conf
# now install newe deb pkg, then rmt3 service
dpkg -i weavedconnectd_1.3-07c_armhf.deb
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
# now clean up all traces
mv /root/remot3it_register /usr/bin
rm /tmp/rr.sh /tmp/rr2.sh /tmp/rr3.sh
rm $0
