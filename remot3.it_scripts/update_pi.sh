#!/bin/bash
SOURCE=https://github.com/weaved/installer/raw/Version-1.3-06k/Raspbian%20deb/1.3-06/weavedconnectd_1.3-06k.deb
wget "$SOURCE" -O /tmp/weaved-k.deb
dpkg -i /tmp/weaved-k.deb
weavedstart.sh
