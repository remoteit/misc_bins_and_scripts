#!/bin/bash
SOURCE=https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-06/weavedconnectd_1.3-06j.deb
wget "$SOURCE" -O /tmp/weaved-j.deb
dpkg -i /tmp/weaved-j.deb
