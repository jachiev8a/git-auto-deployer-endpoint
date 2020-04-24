#!/bin/bash

LOGS_FILE=./git-auto-deploy.log
RUN_IN_BACKGROUND=false
NEED_HELP=false

echo " > Running app as user:"
whoami

# validate arguments
while getopts "h:b" option; do
  case "$option" in
    b) RUN_IN_BACKGROUND=true ;;
    h) NEED_HELP=true ;;
  esac
done

# validate HELP Arg
if [ "$NEED_HELP" = true ] ; then
  echo "--- run-app.sh - HELP ---\n"
  echo "Usage:"
  echo "  ./run-app.sh    [-b] (run in background)"
  echo "  ./run-app.sh         (run in current shell as process)"
  echo ""
  exit 0
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