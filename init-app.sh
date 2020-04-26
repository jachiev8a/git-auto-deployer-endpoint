#!/bin/bash

LOGS_FILE=./logs/git-auto-deploy.log

# create logs folder (if not exists)
if [ ! -d "./logs" ] ; then
    echo " > [DOCKER]: Creating logs folder..."
    mkdir logs
fi

# run flask app
export FLASK_APP=app
echo -e " > [DOCKER]: Running Flask App in Background..."
flask run --host=0.0.0.0 >> "$LOGS_FILE" 2>&1 &
# get PID from current flask app
PID="$!"
echo -e " > [DOCKER]: Flask App PID: $PID\n"