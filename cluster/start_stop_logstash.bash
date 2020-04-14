# replace start command 
# replace process_name with process to kill
#!/bin/bash
. $HOME/.bash_profile
DATE=`date +%y%m%d%H%M`

cmd="/app/logstash-7.6.2/bin/logstash -f /app/logstash-7.6.2/config/logstash-simple.conf"
case $1 in
    start)
        #
        nohup $cmd &
sleep 10
    ;;

    stop)
      kill -9 $(ps -ef |grep -i "logstash-simple.conf" | grep -v grep | awk '{ print $2 }')   
;;
esac

