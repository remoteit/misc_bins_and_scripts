#!/bin/sh /etc/rc.common
#
# Sample Starup Script for weaved services for openwrt
#
# Copyright (C) 2006 OpenWrt.org
#
#

# Start almost Last, stop almost first
START=98
STOP=20

# you should only have to edit the next line                       
# put your service name here, should be a provisioning file in /etc/weaved
service_name=weaved-ssh

# This is custom for just the SSH service, we track the SSH port and point to that, if your
# service does not need a port specification, remove the -x from below
DESC="Weaved Connectd Daemon for SSH"
SSH_PORT=`uci get dropbear.@dropbear[0].Port`

# You should not have to edit anything else, but the defaults are below
exe=connectd
exe_path=/usr/bin/$exe
pidfile=/var/run/$service_name.pid
config_path=/etc/weaved
log_file=/dev/null


#
# Function pidrunning, returns pid of running process or 0 if not running
#
pidrunning()
{
    pid=$1
    tpid=`ps | awk '$1 == '$pid' { print $1}'`
    # make sure we got reply
    if [ -z "$tpid" ]
    then
        tpid=0
    fi
    echo $tpid
}


start() {
  logger "[Weaved] Starting $DESC" 
  if [ -f $config_path/$service_name.conf ]; then
    if [ -f $pidfile ]; then
      pid=`cat $pidfile`;
      if [ -d /proc/$pid ]; then
        #echo -e "Warning: $exe is already running (pid=$pid).";
        return 
      else
        rm -f $pidfile;
        #echo -n "Starting $DESC..."
        # We set the target port here based on the dropbear config
        $exe_path -f $config_path/$service_name.conf -x T$SSH_PORT -d $pidfile > $log_file;
        sleep 2;
        if [ -f $pidfile ]; then
            t=1  
            #echo -e " [OK]"
        else
          return 1
          #echo -e " [FAIL]"
        fi
      fi
    else
      #echo -n "Starting $DESC..."
      $exe_path -f $config_path/$service_name.conf -d $pidfile > $log_file;
      sleep 2;
      if [ -f $pidfile ]; then
        t=1
        #echo -e " [OK]"
      else
        return 1
        #echo -e " [FAIL]"
      fi
    fi
  else
    #echo -e "Error: can not found $config_path/$service_name.conf";
    return 1 
  fi
}

stop() {
  logger "[Weaved] Stopping $DESC" 
  #echo -n "Stopping $DESC..."
    #if we don't have a PID file, just exit
            
    if [ ! -e $pidfile ]                                       
    then    
        logger "[Weaved] Shutdown no pid file, exiting"
        #echo -e " [FAIL]"                                                        
        return 1 
    fi 
    #
    # kill with pid, first get pid from file
    #
    tmp=`cat $pidfile`
                                                                         
    # kill pid if running
    if [ "$tmp" == `pidrunning $tmp`  ]               
    then                                            
        kill $tmp                                
    fi   

    #wait for pid to die 5 seconds
    count=0                   # Initialise a counter
    while [ $count -lt 5 ]  
    do
        if [ "$tmp" != `pidrunning $tmp`  ] 
        then
           break;
        fi
        # not dead yet
        count=`expr $count + 1`  # Increment the counter
        #echo "still running"
        sleep 1
    done

    if [ "$tmp" == `pidrunning $tmp`  ]                                           
    then
       # hard kill
       kill -9 $tmp
      if [ "0" -ne "$?" ]; then                                                                                                                                                              
            #echo -e " [FAIL]"       
            return 1                                         
      fi 
    fi 
                        
    # remove PID file      
    rm $pidfile

    #echo -e " [OK]" 
    return
}

