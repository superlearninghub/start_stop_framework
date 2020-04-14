# replace start command 
# replace process_name with process to kill
#!/bin/bash
. $HOME/.bash_profile
DATE=`date +%y%m%d%H%M`

cmd="/app/kibana-7.6.2-linux-x86_64/bin/kibana"
case $1 in
    start)
        #
        nohup $cmd &
sleep 10
    ;;

    stop)
	 kill -9 $(ps -ef |grep -i "kibana-7.6.2" | grep -v grep | awk '{ print $2 }')
;;
esac

