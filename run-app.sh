#!/bin/bash

LOGS_FILE=./logs/git-auto-deploy.log
RUN_IN_BACKGROUND=false
NEED_HELP=false

echo " > Running app as user: $(whoami)"
usage() {
  echo -e "--- run-app.sh ---\n"
  echo -e "Usage: $0 [ -b ]   (run in background)"
  echo -e "Usage: $0          (run in current shell as process)\n"
  exit 0
}

# validate arguments
while getopts "hb" option; do
  case "$option" in
    b) RUN_IN_BACKGROUND=true ;;
    h) usage ;;
  esac
done

# create logs folder (if not exists)
if [ ! -d "./logs" ]
  mkdir logs
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
    echo " > Running Flask App..."
    flask run --host=0.0.0.0
fi