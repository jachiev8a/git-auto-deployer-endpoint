#!/bin/bash

LOGS_FILE=./logs/git-auto-deploy.log
RUN_IN_BACKGROUND=false

usage() {
    echo -e "\n--- run-app.sh ---\n"
    echo -e "Usage:\n"
    echo -e "  $0 [ -b ]   (run in background)"
    echo -e "  $0          (run in current shell)\n"
    exit 0
}

activate_venv() {
    if [ -f ./venv/bin/activate ]; then
        echo " > Activate venv..."
        source ./venv/bin/activate
    else
        echo " > ERROR: venv does not exists! Exiting..."
        exit 1
    fi
}

# validate arguments
while getopts "hb" option; do
    case "$option" in
        b) RUN_IN_BACKGROUND=true ;;
        h) usage ;;
    esac
done

echo ""
echo " > Running app as user: $(whoami)"

# create logs folder (if not exists)
if [ ! -d "./logs" ] ; then
    echo " > Creating logs folder..."
    mkdir logs
fi

# validate python venv environment
echo " > Validating Python Virtualenv..."
if [[ "$VIRTUAL_ENV" != "" ]]
then
    echo " > Virtualenv is Active. Nothing to do!"
else
    activate_venv
fi

# run flask app
export FLASK_APP=app
if [ "$RUN_IN_BACKGROUND" = true ] ; then
    echo " > Running Flask App in Background..."
    flask run --host=0.0.0.0 > "$LOGS_FILE" 2>&1 &
    # get PID from current flask app
    PID="$!"
    echo " > Flask App PID: $PID"
    echo "$PID" > "pid-flask-app"
else
    echo " > Running Flask App...\n"
    flask run --host=0.0.0.0
fi