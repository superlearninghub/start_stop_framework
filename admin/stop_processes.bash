#!/bin/bash

. $HOME/.bash_profile

APP_HOST_FILE=/app/cluster/APP_HOSTS
LIST_FILE=$ADMINDIR/start_stop_processes.list
SITE=$(cat $APP_HOST_FILE | grep $(hostname -s) | grep -v "^#" | awk '{ print $3 }')

case $(uname) in
Linux)
  CAT_REVERSE="tac"
  ;;
SunOS)
  CAT_REVERSE="tail -r"
  ;;
esac

IFS='
'

usage ()
{
        echo "Usage: stop_processes server_name group_name"
        echo "1 - server_name to choose:"
        echo
        echo "$(cat $APP_HOST_FILE | grep -v "^#" | grep "$SITE" | awk ' { print $1 }')"
        echo
        echo "2 - group_name to choose:"
        echo
        for line in $(cat $LIST_FILE.template | grep -v "^#" | awk ' { print $3 }'  | sort -u)
        do
                echo $(eval echo $line)
        done
        echo
        exit
}

eval_cfg ()
{
        cat ${1}.template | while read line ; do

        if echo $line | grep "#GLOBAL_VAR" | grep -v "^#" >/dev/null
        then
                RESNAME=$(echo $(eval echo $line) | awk '{print $1}')
                resComment=$(echo $(eval echo $line) | awk '{print $2}')
                resGroup=$(echo $(eval echo $line) | awk '{print $3}')
                printf  "%-20s\t%-20s\t%-20s\n"  ${RESNAME} ${resComment} ${resGroup}
        else
                if echo $line | grep -v "^#" >/dev/null
                then
                        echo $line
                fi
        fi

        done > $1
}

getResStatus () {
        RESNAME=$1
        HOST=$2

        case "$CLUSTERMODE" in
        "VCS")
                sudo /opt/VRTS/bin/hares -probe $RESNAME -sys $HOST
                sleep 5

                RES=$(sudo /opt/VRTS/bin/hares -state $RESNAME -sys $HOST)
                if [ "$RES" == "OFFLINE" ]; then
                        echo 0
                else
                        echo 1
                fi
                ;;
        "MON")
                RES=$(sudo /usr/bin/monit status $RESNAME | grep "status" | grep -v "monitoring status" | awk '{ print $2 " " $3 }')
                if [ "$RES" == "Not monitored" ]; then
                        echo 0
                else
                        echo 1
                fi
                ;;
        "OFF")
                $CLUSTERDIR/check_${RESNAME}.bash
                if [ $(echo $?) -eq 100 ]; then
                        echo 0
                else
                        echo 1
                fi
                ;;
        esac

}

changeResStatus() {
        RESNAME=$1
        HOST=$2
        ACTION=$3

        case "$CLUSTERMODE" in
        "VCS")
                sudo /opt/VRTS/bin/hares -$ACTION $RESNAME -sys $HOST
                ;;
        "MON")
                if [ "$ACTION" == "online" ]; then
                        ACTION2="start"
                else
                        ACTION2="stop"
                fi

                sudo /usr/bin/monit $ACTION2 $RESNAME
                ;;
        "OFF")
                if [ "$ACTION" == "online" ]; then
                        ACTION2="start"
                        RES=110
                else
                        ACTION2="stop"
                        RES=100
                fi

                $CLUSTERDIR/check_${RESNAME}.bash
                if [ $(echo $?) -ne $RES ]; then
                        $CLUSTERDIR/start_stop_${RESNAME}.bash $ACTION2
                fi
                ;;
        esac

}

checkResStatus ()
{      
        LIMIT=18
        COUNT=0
        SALEEPTIME=5
        let TOTALTIME=$LIMIT*$SLEEPTIME*2
        RESNAME=$1
        HOST=$2
        RESCOMM=$3
        RESNAMESHORT=$4
        while [ $COUNT -lt $LIMIT ]
        do
                RES=$(getResStatus $RESNAME $HOST)
                if [ $RES -eq 0 ]; then
                        echo "--------------------------------------------------------------------"
                        echo "$(date) END   STOP $RESCOMM "
                        echo "--------------------------------------------------------------------"
                        return 0
                fi
                let COUNT=$COUNT+1
                sleep $SLEEPTIME
        done

        echo "-------------------------------------------------------------------------------------------"
        echo "$(date) ERROR : Resource $RESCOMM did not go OFFLINE after $TOTALTIME seconds"
        echo "-------------------------------------------------------------------------------------------"
        echo "-------------------------------------------------------------------------------------------"
        echo "$(date) Running the clean action for $RESCOMM: $CLUSTERDIR/start_stop_$RESNAMESHORT.bash clean"
        echo "-------------------------------------------------------------------------------------------"
        $CLUSTERDIR/start_stop_$RESNAMESHORT.bash clean
        sleep 10
        if [ $(getResStatus $RESNAME $HOST) -eq 0 ]; then
                echo "--------------------------------------------------------------------"
                echo "$(date) END   STOP $RESCOMM "
                echo "--------------------------------------------------------------------"
        fi

}

eval_cfg ${LIST_FILE}

if [ "$1" == "" ] || [ "$2" == "" ]; then
        usage "$1" "$2"
fi

SERVERNAME="$1"
GROUPNAME="$2"
FOUND="notok"

for CURR_SERVER in $(cat $APP_HOST_FILE | grep -v "^#" | grep "$SITE" | awk ' { print $1 }')
do
        if [ ${CURR_SERVER} == ${SERVERNAME} ]; then
                FOUND="ok"
        fi
done

if [ ${FOUND} == "notok" ]; then
        usage $SERVERNAME $GROUPNAME
fi

FOUND="notok"

for CURR_GROUP in $(cat $LIST_FILE | grep -v "^#" | awk ' { print $3 }')
do
        if [ ${CURR_GROUP} == ${GROUPNAME} ]; then
                FOUND="ok"
        fi
done

if [ ${FOUND} == "notok" ] ; then
        usage $SERVERNAME $GROUPNAME
fi



echo "--------------------------------------------------------------------"
echo `date` BEGIN STOP Processes
echo "--------------------------------------------------------------------"

for line in $(eval $(echo $CAT_REVERSE) $LIST_FILE | grep -v "^#" | grep "${GROUPNAME}")
do
        RESCOMMENT=$(echo $line | awk '{ print $2 }')
        echo "--------------------------------------------------------------------"
        echo "$(date) BEGIN STOP $RESCOMMENT "
        echo "--------------------------------------------------------------------"
        RESNAMESHORT=$(echo $line | awk '{ print $1 }')
        if [ $CLUSTERMODE == "OFF" ]; then
                RESNAME=$RESNAMESHORT
        else
                RESNAME=${GROUPNAME}_${RESNAMESHORT}
        fi

        changeResStatus $RESNAME $SERVERNAME "offline"
        checkResStatus $RESNAME $SERVERNAME $RESCOMMENT $RESNAMESHORT
done

echo "--------------------------------------------------------------------"
echo `date` END STOP Processes
echo "--------------------------------------------------------------------"
echo

