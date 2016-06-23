#!/bin/bash
BIN_DIR=/usr/bin
STARTEMUP=startweaved.sh

# see if there is an entry to start the listener service daemon schannel.x already
checkStartSchannel=$(cat "$BIN_DIR"/$STARTEMUP | grep "weavedschannel" | wc -l)
# if not, add it
if [ $checkStartSchannel = 0 ]; then
    sh -c "echo '"/usr/bin/weavedschannel" start' >> $BIN_DIR/$STARTEMUP"
fi

/usr/bin/weavedschannel start
