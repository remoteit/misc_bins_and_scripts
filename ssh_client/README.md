# ssh_client
SSH/WEB client example on how to use remot3.it connectd daemon on your Linux client to directly connect to a remote service.

You'll need to install the correct daemon on your client computer and then change the name of the EXE= variable in sshw.sh or webw.sh to match the daemon name.  For existing released weavedconnectd packages, that should be changed to:

Raspberry Pi installer 1.3-07z1
EXE=weavedconnectd.pi 

Ubuntu/Debian 64-bit installer 1.3-07k:
EXE=weavedconnectd.i686 

A file called "endpoints" is created in ~/.remot3.it which holds the ports associated with a given UID.
"auth" is created in ~/.remot3.it to cache your login credentials.  Set the variable SAVE_AUTH to 0 to prevent caching credentials.
