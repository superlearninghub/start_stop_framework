## change process to check with process argument

PROC=$(ps uxxww | awk "/ [process to check/ {print \$2}")
if [ -z "$PROC" ]; then
   exit 100
else
        exit 110
fi
