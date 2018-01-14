#!/bin/bash
#
# remot3.it Shell Script Lib - Just a simple library of handy shell script functions
#
# mike@remot3.it
#
#
# Notes
#
#${var#*SubStr}  # will drop begin of string upto first occur of `SubStr`
#${var##*SubStr} # will drop begin of string upto last occur of `SubStr`
#${var%SubStr*}  # will drop part of string from last occur of `SubStr` to the end
#${var%%SubStr*} # will drop part of string from first occur of `SubStr` to the end


#produces a unix timestamp to the output                                                                                           
utime()                                                                                                                            
{                                                                                                                                  
    echo $(date +%s)                                                                                                               
} 
#
# Produce a sortable timestamp that is year/month/day/timeofday
#
timestamp()
{
    echo $(date +%Y%m%d%H%M%S)
}


#
# Simple Long Random
#
srand()
{
    echo "$RANDOM$RANDOM" 
}

#
# dev_random() - produces a crypto secure random number string ($1 digits) to the output (supports upto 50 digits for now)
#
# ret=dev_random(10)
#
dev_random()                                                                                                                        
{                                                                                                                                  
    local count=$1                                                                                                                 
    if [ "$count" -lt 1 ] || [ "$count" -ge 50 ]; then                           
        count=50;                                                                  
    fi                                                                             
    ret=$(cat /dev/urandom | tr -cd '0-9' | dd bs=$count count= 2>/dev/null)
    echo -n "$ret"                                 
} 

# XML parse,: get the value from key $2 in buffer $1, this is simple no nesting allowed
#
xmlval()
{
   temp=`echo $1 | awk '!/<.*>/' RS="<"$2">|</"$2">"`
   echo ${temp##*|}
}

#                                                                                                                                  
# JSON parse (very simplistic):  get value frome key $2 in buffer $1,  values or keys must not have the characters {}[", 
#   and the key must not have : in it
#
#  Example:
#   value=$(jsonval "$json_buffer" "$key") 
#                                                   
jsonval()                                              
{
    temp=`echo "$1" | sed -e 's/[{}\"]//g' | sed -e 's/,/\'$'\n''/g' | grep -w $2 | cut -d"[" -f2- | cut -d":" -f2-`
    #echo ${temp##*|}         
    echo ${temp}                                                
}                                                   

jsonvalx()
{
    temp=`echo $1 | sed -e 's/[{}"]//g' -e "s/,/\\$liblf/g" | grep -w $2 | cut -d":" -f2-`
    #echo ${temp##*|}
    echo ${temp}    
}



#                                                                                                
# rem_spaces $1  - replace space with underscore (_)                                                  
#
rem_spaces()                                                                  
{
    echo "$@" | sed -e 's/ /_/g'                                                         
}      

#                                                                                                
# rem_spaces $1  - replace space with underscore (^)                                                  
#
spaces2pipe()                                                                  
{
    echo "$@" | sed -e 's/ /^/g'                                                         
}   

#                                                                                                
# rem_spaces $1  - replace ^ with space ( )                                                  
#
pipe2space()                                                                  
{
    echo "$@" | sed -e 's/^/ /g'                                                         
}                
                                               
#                   
# urlencode $1
#                                      
urlencode()                                                                           
{
#STR="$1"
STR="$@"          
[ "${STR}x" == "x" ] && { STR="$(cat -)"; }
                     
echo ${STR} | sed -e 's| |%20|g' \
-e 's|!|%21|g' \
-e 's|#|%23|g' \
-e 's|\$|%24|g' \
-e 's|%|%25|g' \
-e 's|&|%26|g' \
-e "s|'|%27|g" \
-e 's|(|%28|g' \
-e 's|)|%29|g' \
-e 's|*|%2A|g' \
-e 's|+|%2B|g' \
-e 's|,|%2C|g' \
-e 's|/|%2F|g' \
-e 's|:|%3A|g' \
-e 's|;|%3B|g' \
-e 's|=|%3D|g' \
-e 's|?|%3F|g' \
-e 's|@|%40|g' \
-e 's|\[|%5B|g' \
-e 's|]|%5D|g'

}    





