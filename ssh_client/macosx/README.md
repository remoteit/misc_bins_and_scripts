# Direct Connect Client for MacOSX

This is a client created for MacOSX.  Several different flavors of the launcher are included to connect to a device 
and launch the proper OSX client for the desired device.

The flavors available in this version are:
- sshw  -  Connect to an SSH server device and automatically launch ssh client.
- sftpw -  Connect to a SFTP server device and automatically launch sftp client.
- smbw  -  Connect to a Samba server device and automatically launch Samba Client.
- wweb  -  Connect to a web (http) device and automatically lauch Safari.

## Installing

Clone this directory and run

```
./install.sh
```
This should install the files in ```/usr/local/bin``` if this is in your path you should be able to use sshw, 

## Modifications over basic ssh_client
  sftpw, smbw and wweb are slight variations over the sshw script.   The modifications are related to the client laucher the script uses.
  With the sshw script the client laucher is the following line:
```bash
  ssh "${user}127.0.0.1" -p$port
```
  This calls the standard ssh client on the system with the specified username and the port for the connection at 127.0.0.1.
  the wweb script client laucher code is as follows:
```
open -a "Safari" "http://127.0.0.1:$port"
```
  Changing this line to another method would allow a user to build a script to launch any type of client to a direct Remote.it/weaved connection.


