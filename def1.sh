#!/bin/bash

Production=$( echo 1 )
#echo "$Production"

Debug=$( echo 0 )
#echo "$Debug"

path_to_log=$( echo "/srv/http/2110log/block.log" )
#echo "$path_to_log"

if [[ -f "$path_to_log" ]]
  then
	echo "Log started: $(date)" >> $path_to_log
  else
	#touch "$path_to_log"
	echo "Log created: $(date)" > $path_to_log
  fi

main() {

while [ : ]
do
  date_Time=$( date )
  check_EST=$( ss -np | grep "tcp   ESTAB" )
  #echo "$check_EST"

  check_TCP_connection
  sleep 5
done
}

check_TCP_connection () {

echo "$check_EST" | while read line
do
  if [[ $Production = 0 ]]
    then
	echo "===> $line"
    fi

  if [[ $line == "" ]]
    then
	if [[ $Production = 0 ]]; then echo "empty"; fi
	break
    fi

  filter_IP_PORT_SRC=$( echo $line | awk '{print $5}')
  filter_IP_PORT_DST=$( echo $line | awk '{print $6}')
  filter_PID=$( echo $line | awk '{print $7}' )
  #echo "$filter_IP_PORT_SRC"
  #echo "$filter_IP_PORT_DST"
  #echo "$filter_PID"
  if [[ $filter_IP_PORT_SRC =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]
    then
 	filter_IP_Address_SRC=$(echo ${BASH_REMATCH} ) 
  	if [ $Debug = 1 ]; then echo "$filter_IP_Address_SRC"; fi
    fi

  if [[ $filter_IP_PORT_DST =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]
    then
 	filter_IP_Address_DST=$(echo ${BASH_REMATCH} ) 
  	if [ $Debug = 1 ]; then echo "$filter_IP_Address_DST"; fi
    fi

  if [[ $filter_IP_PORT_SRC =~ ([^:]*)$ ]]
    then
 	filter_Port_SRC=$(echo ${BASH_REMATCH} ) 
  	if [ $Debug = 1 ]; then echo "$filter_Port_SRC"; fi
    fi

  if [[ $filter_IP_PORT_DST =~ ([^:]*)$ ]]
    then
 	filter_Port_DST=$(echo ${BASH_REMATCH} ) 
  	if [ $Debug = 1 ]; then echo "$filter_Port_DST"; fi
    fi

  if [[ $filter_PID =~ pid=*([[:digit:]]*) ]]
    then
 	filter_PID_Num=$(echo ${BASH_REMATCH[1]} ) 
  	if [ $Debug = 1 ]; then echo "$filter_PID_Num"; fi
    fi

  if [[ $filter_Port_SRC != "8080" ]] &&
     [[ $filter_Port_SRC != "80" ]]
    then
      echo $(
      echo -n "$date_Time";
      echo -n $'\t\t';
      echo -n "Blocking OUTPUT: $filter_IP_Address_DST, $filter_Port_DST and ";
      echo "PID Kill: $filter_PID_Num";
      ) | tee -a $path_to_log 

      #iptables -A INPUT -p tcp --destination-port $filter_Port_DST -j DROP
      iptables -A OUTPUT -p tcp --destination-port $filter_Port_DST -j DROP
      kill 9 $filter_PID_Num
    fi
done

}

#Main function is running.
main

