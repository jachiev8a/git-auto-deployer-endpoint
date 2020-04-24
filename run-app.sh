#!/bin/bash

LOGS_FILE=./shell-git-deploy-default.log
RUN_IN_BACKGROUND=false

echo "running app as user:"
whoami

# validate arguments
while getopts "h:b" option; do
  case "$option" in
    b) RUN_IN_BACKGROUND=true ;;
    h) echo "Usage: ./run-app.sh [-b] (to run in background)" ;;
  esac
done

# run flask app
export FLASK_APP=app
if [ "$RUN_IN_BACKGROUND" = true ] ; then
    echo "Running Flask App in Background..."
    flask run --host=0.0.0.0 > "$LOGS_FILE" 2>&1 &
else
    echo 'Running Flask App...'
    flask run --host=0.0.0.0
fi