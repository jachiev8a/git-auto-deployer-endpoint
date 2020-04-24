#!/bin/bash

LOGS_FILE=./shell-git-deploy-default.log
RUN_IN_BACKGROUND=false

echo "running app as user:"
whoami

# validate arguments
while [ ! $# -eq 0 ]
do
	case "$1" in
		--help | -h)
			exit
			;;
		--background | -b)
			RUN_IN_BACKGROUND=true
			exit
			;;
	esac
	shift
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