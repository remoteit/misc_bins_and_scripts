#!/bin/sh
#
# Generic Weaved Startup script        
# mike@weaved  
#
# This assumes a startup script per service in /etc/init.d or similar
#
#        

# you should only have to edit the next line                       
# put your service name here, should be a provisioning file in /etc/weaved                   
service_name=web.linux

# You should not have to edit anything else, but the defaults are below
exe=weavedConnectd
# change the next line if you move the weaved daemon
exe_path=/usr/bin/$exe
# change the next line if your pid files are stored somewhere else
pidfile=/var/run/$service_name.pid
# default config file location for weaved provisioing files
config_path=/etc/weaved
# if you want to see the output of the daemon on startup, put a file here
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
    logger "[Weaved] Start Weaved service ${service_name}"                        
    echo "Start Weaved service ${service_name}"      
                                                          
    if [ -f $config_path/$service_name ]; then         
        if [ -f $pidfile ]; then                                         
            pid=`cat $pidfile`;
            # assumes /proc/$pid, if not use pidrunning                                          
            if [ -d /proc/$pid ]; then  
                # Pid file exists and running   
                echo -e "[FAIL]: ${service_name} is already running on pid ${pid}.";
                return 1                               
            else
                # pid file exists but not running, remove pidfile      
                rm -f $pidfile;
                sync    
                sleep 1;                              
            fi
        fi   
        # if we make it here we should be OK to start
        $exe_path -f ${config_path}/${service_name} -d $pidfile > $log_file;
        sleep 2;
        if [ -f $pidfile ]; then
            echo -e " [OK]"
            return 0
        else
            echo -e " [FAIL]: tried to start service, but no pidfile created"
            return 1
        fi
    else
        echo -e "[FAIL]: Provisioning File not Found (${config_path}/${service_name})";
        return 1;
    fi
                                                     
}  

stop() {
    logger "[Weaved] Stop Weaved service ${service_name}"                        
    echo "Start Weaved service ${service_name}"   
    #if we don't have a PID file, just exit
            
    if [ ! -e $pidfile ]                                       
    then    
        logger "[Weaved] Shutdown no pid file, exiting"
        echo -e " [FAIL]: No pid file found"                                                        
        return 1 
    fi 
    #
    # kill with pid, first get pid from file
    #
    pid=`cat $pidfile`
                                                                         
    # kill pid if running
    #if [ -d /proc/$pid ]; then
    if [ "$pid" == `pidrunning $pid`  ]               
    then                                            
        kill $pid                                
    fi   

    #wait for pid to die 5 seconds
    count=0                   # Initialise a counter
    while [ $count -lt 5 ]  
    do
        if [ "$pid" != `pidrunning $pid`  ] 
        then
           break;
        fi
        # not dead yet
        count=`expr $count + 1`  # Increment the counter
        #echo "still running"
        sleep 1
    done

    if [ "$pid" == `pidrunning $pid`  ]                                           
    then
       # hard kill
       kill -9 $pid
       sleep 1
      if [ "0" -ne "$?" ]; then                                                                                                                                                              
            echo -e " [FAIL]: could not kil process ${pid}"       
            return 1                                         
      fi 
    fi 
                        
    # remove PID file      
    rm $pidfile

    echo -e " [OK]" 
    return 0
}

status() {
 
    #if we don't have a PID file, just exit
            
    if [ ! -e $pidfile ]                                       
    then    
        echo -e "[Not Running]"                                                        
        return 1 
    fi 
    #
    # kill with pid, first get pid from file
    #
    pid=`cat $pidfile`
                                                                         
    # kill pid if running
    #if [ -d /proc/$pid ]; then
    if [ "$pid" == `pidrunning $pid`  ]               
    then                                            
        echo -e "[Running]"
        return 0                  
    else
        echo -e "[Not Running]: but pid file exists"
        return 1
    fi   
}


restart() {
    stop
    if [ "1" -ne "$?" ]; then     
        sleep 4
        start
    fi
    return $?
}

case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart|reload)
                restart
                ;;
        *)
                echo $"Usage: $0 {start|stop|restart}"
                exit 1
                ;;
esac

exit $?




