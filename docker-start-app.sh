#!/bin/bash

# ----------------------------------------------------------------------
# Script definitions
# ----------------------------------------------------------------------

# default one used as repo path to deploy
DEFAULT_REPO_PATH=/opt/jira/git-jira
USE_DEFAULT_REPO_PATH=false
REPO_PATH_TO_DEPLOY=null

# usage help use
# ----------------------------------------------------------------------
usage() {
    echo -e "\n--- [DOCKER]: docker-start-app.sh ---\n"
    echo -e "Usage:\n"
    echo -e "  $0 [ -d ]   (use default repo path: $DEFAULT_REPO_PATH)"
    echo -e "  $0          (run normal. Type the repo path to be used.)\n"
    exit 0
}

# script error handler
# ----------------------------------------------------------------------
handle_error() {
    error_msg=$1
    echo -e ""
    echo -e "=========================================================="
    echo -e " > [DOCKER]: ERROR: $error_msg"
    echo -e "=========================================================="
    echo -e "\n > Exiting...\n"
    exit 1
}

# validate arguments parsing
# ----------------------------------------------------------------------
while getopts "hd" option; do
    case "$option" in
        d) USE_DEFAULT_REPO_PATH=true ;;
        h) usage ;;
        *) usage ;;
    esac
done
echo "" # new line

echo " > [DOCKER]: Running Docker App as user: '$(whoami)'"

# create logs folder (if not exists)
# ----------------------------------------------------------------------
if [ ! -d "./logs" ] ; then
    echo " > [DOCKER]: Creating logs folder..."
    mkdir logs
fi

# Validate repo path argument
# ----------------------------------------------------------------------
if [ "$USE_DEFAULT_REPO_PATH" = true ] ; then
    echo -e " > [DOCKER]: Using Default repo path: '$DEFAULT_REPO_PATH'\n"
    REPO_PATH_TO_DEPLOY=$DEFAULT_REPO_PATH
else
    echo -e " > [DOCKER]: Setting up Repo Path:\n"
    read -r -p " > Enter the Repo Path Value: " input_repo_path

    # validate that repo path exists
    if [ ! -d "$input_repo_path" ] ; then
        handle_error "Given Repo Path does not exists! -> '$input_repo_path'"
    else
        echo -e ""
        echo -e " > [DOCKER]: Valid Repo Path Value -> '$input_repo_path'"
        echo -e " > [DOCKER]: [OK]\n"
    fi
    REPO_PATH_TO_DEPLOY="$input_repo_path"
fi

# set the repo path variable use at docker-compose file.
export REPO_TO_DEPLOY="$REPO_PATH_TO_DEPLOY"

echo -e " > [DOCKER]: Executing docker-compose..."

docker-compose -f docker-compose.yml up -d
docker_exit_status=$?

if [ $docker_exit_status -ne 0 ]; then
    handle_error "docker-compose command failed! Check the logs..."
fi

echo -e " > [DOCKER]: Docker App Executed [OK]"
