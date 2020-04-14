## change process to check with process argument

PROC=$(ps -ef |grep -i "logstash-simple.conf" | grep -v grep | awk '{ print $2 }')
if [ -z "$PROC" ]; then
   exit 100
else
   exit 110
fi
