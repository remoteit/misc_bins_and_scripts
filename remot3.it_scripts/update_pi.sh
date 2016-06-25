#!/bin/bash
SOURCE=https://github.com/weaved/installer/raw/master/Raspbian%20deb/1.3-06/weavedconnectd-1.3-06g.deb
wget "$SOURCE" -O /tmp/weaved-g.deb
dpkg -i /tmp/weaved-g.deb
