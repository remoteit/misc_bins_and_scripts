#!/bin/bash
SOURCE=https://github.com/weaved/installer/raw/Version-1.3-06l/Raspbian%20deb/1.3-06/weavedconnectd_1.3-06l.deb
wget "$SOURCE" -O /tmp/weaved-l.deb
#nohup dpkg -i /tmp/weaved-l.deb
resp=$(nohup dpkg -i /tmp/weaved-l.deb 2>&1  &); echo
# weavedstart.sh
