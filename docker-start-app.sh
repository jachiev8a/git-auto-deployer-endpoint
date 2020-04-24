#!/bin/bash

LOGS_FILE=./logs/git-auto-deploy.log
RUN_IN_BACKGROUND=false

PID_FILE="./pid-flask-app"

usage() {
    echo -e "\n--- [DOCKER]: run-app.sh ---\n"
    echo -e "Usage:\n"
    echo -e "  $0 [ -b ]   (run in background)"
    echo -e "  $0          (run in current shell)\n"
    exit 0
}

# validate arguments
while getopts "hb" option; do
    case "$option" in
        b) RUN_IN_BACKGROUND=true ;;
        h) usage ;;
        *) usage ;;
    esac
done
echo "" # new line

# validate if Flask app is not already running in the OS
PS_PARSED_PID=$(pgrep -l flask | awk '{print $1}')
if [ -n "$PS_PARSED_PID" ]; then
    echo -e " > [DOCKER]: There is a Flask process currently running in the OS..."
    echo -e " > [DOCKER]: OS Flask process PID: '$PS_PARSED_PID'\n"
    exit 0
fi

echo " > [DOCKER]: Running app as user: $(whoami)"

# create logs folder (if not exists)
if [ ! -d "./logs" ] ; then
    echo " > [DOCKER]: Creating logs folder..."
    mkdir logs
fi

# run flask app
export FLASK_APP=app
if [ "$RUN_IN_BACKGROUND" = true ] ; then
    echo -e " > [DOCKER]: Running Flask App in Background..."
    flask run --host=0.0.0.0 > "$LOGS_FILE" 2>&1 &
    # get PID from current flask app
    PID="$!"
    echo -e " > [DOCKER]: Flask App PID: $PID\n"
    echo -e "$PID" > "$PID_FILE"
else
    echo -e " > [DOCKER]: Running Flask App...\n"
    flask run --host=0.0.0.0
fi