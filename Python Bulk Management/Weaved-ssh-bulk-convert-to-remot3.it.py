import httplib2
import json
import time
import subprocess
import datetime
import base64
import paramiko
import sys
import os
import getpass
import errno
import re
import string

from socket import error as socket_error
import socket

homeFolder = "/home/gary"

authcache = True
authCacheFile="~/.remot3.it/auth"

portCache = True;
portCacheFile=homeFolder + "/.remot3.it/endpoints"

sshCache=True;
sshCacheFile = homeFolder + "/.remot3.it/ssh"

# deviceListFile = homeFolder + "/.remot3.it/devicelist"
# remoteScriptFile = homeFolder + "/.remot3.it/remotescript"
scriptPath=homeFolder + "/.remot3.it/"
logFilePath=scriptPath + "/logs/"

apiMethod="http://"
apiVersion="/v21"
apiServer="api.weaved.com"
apiKey="WeavedDemoKey$2015"

# for production, remove these and ask the user at the begnning of the session
userName = "faultline1989@yahoo.com"
password = "weaved$2012"
deviceName=""
# substitute the name of the actual daemon you are using.
# this will depend on CPU architecture and OS details
clientDaemon = "/usr/bin/weavedConnectd.linux"

#===============================================
def addName(deviceItem, name):
    # this file we are creating will be used as input to weavedinstaller to log in and add the Device Name
    f = open(scriptPath + "addname", "w+")
    f.write("1\n")
    f.write(userName + "\n")
    f.write(password + "\n")
    f.write(name + "\n")
    f.write("4\n")
    f.close()
    
    # this file will be the script that uses the previous file
    f = open(scriptPath + "addnamescript", "w+")
    f.write("@fileSend " + scriptPath + "addname /tmp/addname\n")
    f.write("sudo weavedinstaller < /tmp/addname? > /tmp/weavedlog.txt\n")
    f.write("@sleep 30\n")
    f.write("@fileGet /tmp/weavedlog.txt -addname.txt\n")
    f.close()
    
    runScript(deviceItem, "addnamescript")


#===============================================
def getPort(UID, name):
    if(portCache == True):
        startPort = 33000
        cacheHit = False
        if(os.path.isfile(portCacheFile)):
            with open(portCacheFile, 'r') as f:
                for line in f:
                    params = line.split("|")
                    port = params[0].split("TPORT")[1]
                    if(startPort < port):
                        startPort = port
#                        print startPort
                    if(UID in line):
                        assignedPort = port
                        cacheHit = True
                        break
        if(cacheHit == False):
            assignedPort = int(startPort) + 1
            print "Caching port for", UID
            with open(portCacheFile, 'a') as f:
                f.write("TPORT%d" % assignedPort + "|"  + name + "|"  + UID + "\n")
    return int(assignedPort)

#===============================================
def p2pConnect(startPortNum, startDaemon):
#   uncomment the following line to force proxy mode connections
    return (-1,0)
    portNum = getPort(deviceItem["deviceaddress"], deviceItem["devicealias"])                
    print "Device:", deviceItem["devicealias"]
    if(startDaemon == True):
        portParam = "T%d" % int(portNum)
        args = [clientDaemon, "-l", "5000", "hello", "-c", base64userName, base64password, deviceItem["deviceaddress"], portParam, "1", "127.0.0.1", "12"]
    #    print args
        try:
            proc = subprocess.Popen(args,shell=False)
        except:
            "Process launch exception!"
#    Listen to UDP port 5000 to get the ready status or error messages
    statusPort = 5000
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("", statusPort))
    while 1:    # debug status scan from daemon
        data, addr = s.recvfrom(128)
# uncomment the following statement to see all output from the daemon
#        print data
        if 'hello Proxy started.' in data:
            break
        if 'hello Cannot Bind Port' in data:
            print 'Cannot bind to port: ', portNum
            return (-1, -1)
        if 'hello weavedConnectd terminated' in data:
            print 'P2P connection timed out!', portNum
            return (-1, -1)
    ssh = trySSHConnect('127.0.0.1', portNum)
    return (ssh, proc)

#===============================================
from urllib2 import urlopen
from json import dumps
from json import load

def proxyConnect(UID, token):
#    print "Entering proxyConnect()"
    # my_ip = urlopen('http://ip.42.pl/raw').read()
    my_ip = load(urlopen('http://jsonip.com'))['ip']
#    print "my_ip =", my_ip

    proxyConnectURL = apiMethod + apiServer + apiVersion + "/api/device/connect"

    proxyHeaders = {
                'Content-Type': content_type_header,
                'apikey': apiKey,
                'token': token
            }

    proxyBody = {
                'deviceaddress': UID,
                'hostip': my_ip,
                'wait': "true"
            }

    response, content = http.request( proxyConnectURL,
                                          'POST',
                                          headers=proxyHeaders,
                                          body=dumps(proxyBody),
                                       )
#    print "Response = ", response
#    print "Content = ", content

    data = json.loads(content)["connection"]["proxy"]
    URI = data.split(":")[0] + ":" + data.split(":")[1]
    URI = URI.split("://")[1]
    portNum = data.split(":")[2]

    print "connecting to:", URI, portNum
    
    ssh = trySSHConnect(URI, int(portNum))
    return ssh

#===============================================
def trySSHConnect(host, portNum):
# initiate Paramiko SSH session Ex
    sshUserName, sshPassword = getSSHCredentials()
    paramiko.util.log_to_file ('paramiko.log') 

#and then check the response...
    try:
        ssh = paramiko.SSHClient()
#        print "1"
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
#        print "2"
# was trying to add banner_timeout because it seems to have that failure
# occasionally. Couldn't get it working.
#        ssh.connect(host, port=portNum, username=sshUserName,
#            password=sshPassword, pkey=None, key_filename=None,
#            timeout=3.0, allow_agent=True, look_for_keys=True,
#            compress=False, sock=None, gss_auth=False, gss_kex=False,
#            gss_deleg_creds=True, gss_host=None, banner_timeout=5.0)
#        print "hostname = ", host
#        print "port = ", portNum
#        print "sshUsername = ", sshUserName
#        print "sshPassword = ", sshPassword

        ssh.connect(hostname=host, port=portNum, username=sshUserName, password=sshPassword)
#        print "3"
        ssh.get_transport().window_size = 3 * 1024 * 1024
#        print "4"
    except paramiko.AuthenticationException:
        print "Authentication failed!"
        return -1
    except paramiko.BadHostKeyException:
        print "BadHostKey Exception!"
        return -1
    except paramiko.SSHException:
        print "SSH Exception!"
        ssh.close()
        return -2
    except socket.error as e:
        print "Socket error ", e
        return -1
    except:
        print "Could not SSH to %s, unhandled exception" % host
    print "Made connection to " + host + ":" + str(portNum)
    return (ssh)

#===============================================
def getSSHCredentials():
    cacheHit = False
    if(os.path.isfile(sshCacheFile)):
        with open(sshCacheFile, 'r') as f:
            alias = deviceItem["devicealias"]
#            print UID
            for line in f:
                if(alias in line):
                    params = line.split("|")
                    sshUserName = params[1]
                    sshPassword = params[2]
                    cacheHit = True
                    break
            if(cacheHit == False):
                sshUserName = raw_input("SSH user name:") 
                sshPassword = raw_input("SSH password:")
                with open(sshCacheFile, 'a') as f:
                    f.write(deviceItem["devicealias"] + "|" + sshUserName + "|" + sshPassword + "|\n")
    else:
        sshUserName = raw_input("SSH user name:") 
        sshPassword = raw_input("SSH password:")                  
        with open(sshCacheFile, 'a') as f:
            f.write(deviceItem["devicealias"] + "|" + sshUserName + "|" + sshPassword + "|\n")
    return (sshUserName, sshPassword)

#===============================================
def remoteScript(ssh, scriptName):
    scriptPathName = scriptPath + scriptName
    print scriptPathName
    logFile = ""
    if(os.path.isfile(scriptPathName)):
        channel = ssh.invoke_shell(term='vt100', width=80, height=24)
        
        fileHandle = open(scriptPathName, 'r')
        for line in fileHandle:
            lineBits = line.split(" ")
            # handle special file transfer command
            if("@fileSend" == lineBits[0]):
                source = lineBits[1]
                target = lineBits[2]
                sendFile(ssh, source, target)
            if("@fileGet" == lineBits[0]):
                source = lineBits[1]
                target = lineBits[2]
                logFile = logFilePath + deviceItem["devicealias"] + target
                getFile(ssh, source, logFile)
            if("@sleep" == lineBits[0]):
                sleeptime = float(lineBits[1])
                print "Sleeping for " + str(sleeptime) + " seconds..."
                time.sleep(sleeptime)
                
            else:
                print line
                bytesSent = channel.send(line)
#                print bytesSent
# this delay is used on slower devices to allow all commands to get to log file
            time.sleep(1)
#            output=channel.recv(8000)
#            print(output)
    else:
        print "Remote script file does not exist!"
        print "Please create a script file at:", scriptPathName
        return -1
    print "remoteScript completed"
    return logFile
        
#===============================================
   
def sendFile(ssh, source, target):
    try:
        ftp = ssh.open_sftp()
    except paramiko.ssh_exception.SSHException, e:
            print "SSH Exception on opening sftp connection\n", e
    else:
        #====== now retrieve the remote file and place on desktop
        print "Send", source, "to", target
        ftp.put(source, target)
        ftp.close() 

#===============================================

def getFile(ssh, source, target):
    try:
        ftp = ssh.open_sftp()
    except paramiko.ssh_exception.SSHException, e:
        print "SSH Exception on opening sftp connection\n", e
    else:
        #====== now retrieve the remote file and place on desktop
        print "Get", source, "to", target
        ftp.get(source, target)
        ftp.close()
        print "Getfile completed"


def searchForBulk(deviceList, ipAddress):
    # print "All services at IP address:", ipAddress
    bulkFound = 0
    for deviceItem in deviceList["devices"]:
        if(deviceItem["lastinternalip"] == ipAddress):
            if(deviceItem["servicetitle"] == "Bulk Service"):
                print "Bulk Service found at:", deviceItem["devicealias"]
                bulkFound = 1
                print "----------------------"
                return 0
    if (bulkFound == 0):
        print "Bulk Service not installed on device at", ipAddress
        print "----------------------"
        return 1
 
def runScript(deviceTable, scriptName):
   # attempt P2P connection after starting daemon
    portNum = 33000
#    print "is active"
    print "----------\n"
    ssh, proc = p2pConnect(portNum, True)
    # -2 indicates SSH Exception, commonly failure to retrieve banner
    if(ssh == -2):
        print "Retrying P2P..."
        # ssh.close()
        # attempt P2P without starting daemon (presumed started)
        ssh, proc = p2pConnect(portNum, False)                 
    if(ssh > 0):
        print "Executing script via P2P."
#                        remoteScript(ssh)
        ssh.close()
        proc.kill()
    else:
        print "Connecting to %s via proxy." % deviceTable["devicealias"]
        ssh = proxyConnect(deviceTable["deviceaddress"], token)
        if(ssh != -1):
            print "Executing script via proxy."
            logFile = remoteScript(ssh, scriptName)
            ssh.close()
        else:
            print "Proxy connection failed!"
    portNum = portNum + 1
    print "----------"
    return logFile
    
#===============================================
if __name__ == '__main__':

    httplib2.debuglevel     = 0
    http                    = httplib2.Http()
    content_type_header     = "application/json"

    loginURL = apiMethod + apiServer + apiVersion + "/api/user/login"

#    print "Login URL = " + loginURL

    loginHeaders = {
                'Content-Type': content_type_header,
                'apikey': apiKey
            }
    try:        
        response, content = http.request( loginURL + "/" + userName + "/" + password,
                                          'GET',
                                          headers=loginHeaders)
    except:
        print "Server not found.  Possible connection problem!", e
        exit()
                                          
#    print (response)
    print "============================================================"
#    print (content)
    print

    try: 
        data = json.loads(content)
        if(data["status"] != "true"):
            print "Can't connect to Weaved server!"
            print data["reason"]
            exit()

        token = data["token"]
    except KeyError:
        print "Comnnection failed!"
        exit()
#    except URLError:
#        print "Connection failed!"
#        exit()

    print "Token = " +  token

    deviceListURL = apiMethod + apiServer + apiVersion + "/api/device/list/all"

    deviceListHeaders = {
                'Content-Type': content_type_header,
                'apikey': apiKey,
                'token': token,
            }
            
    response, content = http.request( deviceListURL,
                                          'GET',
                                          headers=deviceListHeaders)
    print "----------------------------------" 

    deviceData = json.loads(content)
#    print deviceData["devices"]
    base64userName = base64.b64encode(userName)
    base64password = base64.b64encode(password)

    # check to see if script and log folder exist, error and quit if not
    # since you have to put scripts there
    
    

    foundDevice = False
    piFound = 0
    # now iterate over all devices in returned list
    # check to see if current service type is SSH
    # next check all devices to see if there is an RMT3 service at the same internal and external IP
    # if not, then send and execute the script which installs the rmt3 service and then adds the hardware ID
    # to the other registered services
    
    for deviceItem in deviceData["devices"]:
        if(deviceItem["servicetitle"] == "SSH"):
            foundDevice = True
            typeString = deviceItem["devicetype"] 
            length = len(typeString)
            # print "Length =" + str(length)

            if(length == 47):
                deviceBytes = typeString[24:29]
                # print typeString
                # print deviceBytes
                if(deviceBytes == "04:30"):
                    piFound = 1
                    # print "Raspberry Pi found."
            else:
                if (length == 35):
                    deviceBytes = typeString[24:29]
                # print typeString
                # print deviceBytes
                    if(deviceBytes == "04:30"):
                        piFound = 1
                        # print "Raspberry Pi found."
               
            
            if((piFound == 1) & (deviceItem["devicestate"] == "active")):
                 print "\n=========================================="               
                 print deviceItem["devicealias"]
                 print deviceItem["lastinternalip"]
                 if(searchForBulk(deviceData, deviceItem["lastinternalip"]) == 1):
                    logFile = runScript(deviceItem, "getinfo")
                    print logFile
                    regex = re.compile("^Version:\s+\d\.\d-\w+", re.I)
                    fileHandle2 = open(logFile, 'r')
                    for line in fileHandle2:
                        # print line
                        weavedconnectd = regex.search(line)
                        # print weavedconnectd
                        if (weavedconnectd != None):
                            version = string.split(weavedconnectd.group(0))[1]
                            # print version
                            print weavedconnectd.group(0)
                            if(version == "1.3-07v"):
                                print "Installed version of weavedconnectd is up to date"
                            else:
                                print "Downloading and installing new version"
                                logFile = runScript(deviceItem, "updateWeavedConnectd")
                                print logFile
                                # the previous script will kill the SSH connection when it runs
                                # dpkg. Wait a few seconds and then go get the dpkg log.
                                print "Pausing for 30 seconds for daemons to restart"
                                time.sleep(30)
                                logFile = runScript(deviceItem, "getDpkgLog")
                                print logFile
                                addName(deviceItem, "test-name")
                                
#            else:
#                print "is not active."
#                print "----------\n"


