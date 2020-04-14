#!/bin/bash

IFS='
'
RETCOD=0
export bold=`tput bold`
export offall=`tput sgr0`
export blink=`tput blink`

printRes ()
{
        if [ $2 = 110 ]; then
                echo "************************************"
                echo "***** $3 : ok"
                echo "************************************"
        else
                echo "************************************"
                echo "***** $3 : ${bold}${blink}NOT ok${offall}"
                echo "************************************"
                RETCOD=1
        fi
}

for line in $(cat $ADMINDIR/start_stop_processes.list | grep -v "^#")
do
        #echo $line
        resName=$(echo $line | awk ' { print $1 } ')
        resComment=$(echo $line | awk ' { print $2 } ')
        $CLUSTERDIR/check_${resName}.bash
        printRes ${resName} $? ${resComment}
done

exit $RETCOD

