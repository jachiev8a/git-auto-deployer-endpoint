#!/bin/bash

PID_FILE="./pid-flask-app"
CURRENT_APP_PID=""
PS_PARSED_PID=""

usage() {
    echo -e "\n--- stop-app.sh ---\n"
    echo -e "Usage:\n"
    echo -e "  $0          (stops the process if any)\n"
    exit 0
}

# validate arguments
while getopts "h" option; do
    case "$option" in
        h) usage ;;
        *) usage ;;
    esac
done

echo ""
echo " > Retrieving current Flask process PID from OS..."
PS_PARSED_PID=$(pgrep -l flask | awk '{print $1}')

if [ -z "$PS_PARSED_PID" ]; then
    echo " > There is no Flask process currently running in the OS..."
    echo " > Nothing to do!\n"
    exit 0
fi

# validate PID file exists
echo " > Validate current pid file exists..."
if [ ! -f "$PID_FILE" ]; then
    echo " > ERROR: '$PID_FILE' does not exists!"
    exit 1
else
    CURRENT_APP_PID=$(cat "$PID_FILE")
    echo " > Current Flask App PID: '$CURRENT_APP_PID'"
fi

# validate both PID
if [ "$CURRENT_APP_PID" == "$PS_PARSED_PID" ]; then
    echo " > OS PID and file PID are the same... [OK]"
    echo " > killing process with PID: $PS_PARSED_PID"
fi