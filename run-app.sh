
LOGS_FILE=./sh-git-deploy-default.log
echo "running app as user:"
whoami

echo "Validating Log File..."
if [ -z "$1" ]
then
  echo "using default log file: $LOGS_FILE"
else
  echo "first arg (Log file): $1"
  LOGS_FILE=$1
fi

# run flask app
echo "Running Flask App in background..."
export FLASK_APP=app
flask run --host=0.0.0.0 > "$LOGS_FILE" 2>&1 &