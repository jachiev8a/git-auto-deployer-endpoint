#!/bin/bash

# ----------------------------------------------------------------------
# Script definitions
# ----------------------------------------------------------------------

# default one used as repo path to deploy
DEFAULT_REPO_PATH=/opt/jira/git-jira
USE_DEFAULT_REPO_PATH=false
REPO_PATH_TO_DEPLOY=""

# default one used as ssh id_rsa
DEFAULT_SSH_FILE_ID=id_rsa
DEFAULT_SSH_FILE=/usr/local/share/data/ssh-jira-groovy-scripts/$DEFAULT_SSH_FILE_ID
USE_DEFAULT_SSH_FILE=false
GIT_SSH_FILE=""

# usage help use
# ----------------------------------------------------------------------
usage() {
    echo -e "\n--- [DOCKER]: docker-start-app.sh ---\n"
    echo -e "Usage:\n"
    echo -e "  $0 [ -d ]   (use default repo path: '$DEFAULT_REPO_PATH')"
    echo -e "  $0 [ -i ]   (use default id_rsa: '$DEFAULT_SSH_FILE')"
    echo -e "  $0          (run normal. Type the repo path to be used.)\n"
    exit 0
}

# script error handler
# ----------------------------------------------------------------------
handle_error() {
    error_msg=$1
    echo -e ""
    echo -e "==================================================================="
    echo -e " > [DOCKER]: ERROR:"
    echo -e " > $error_msg"
    echo -e "==================================================================="
    echo -e "\n > Exiting...\n"
    exit 1
}

# validate arguments parsing
# ----------------------------------------------------------------------
while getopts "hdi" option; do
    case "$option" in
        d) USE_DEFAULT_REPO_PATH=true ;;
        i) USE_DEFAULT_SSH_FILE=true ;;
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
    echo -e " > [DOCKER]: Setting up Repo Path...\n"
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

# Validate ssh argument
# ----------------------------------------------------------------------
if [ "$USE_DEFAULT_SSH_FILE" = true ] ; then
    echo -e " > [DOCKER]: Using Default SSH id_rsa: '$DEFAULT_SSH_FILE'\n"
    GIT_SSH_FILE=$DEFAULT_SSH_FILE
else
    echo -e " > [DOCKER]: Setting up SSH id_rsa...\n"
    read -r -p " > Enter the SSH id_rsa Path Value: " input_ssh_path

    # validate that ssh path exists
    if [ ! -d "$input_ssh_path" ] ; then
        handle_error "Given SSH id_rsa Path does not exists! -> '$input_ssh_path'"
    else
        echo -e ""
        echo -e " > [DOCKER]: Valid SSH id_rsa Value -> '$input_ssh_path'"
        echo -e " > [DOCKER]: [OK]\n"
    fi
    GIT_SSH_FILE="$input_ssh_path"
fi

# Validate ssh argument
# ----------------------------------------------------------------------
current_working_dir=$(pwd)
this_root_ssh_file="$current_working_dir/$DEFAULT_SSH_FILE_ID"

# validate that ssh path exists
echo -e " > [DOCKER]: Validate SSH $DEFAULT_SSH_FILE_ID is located in root..."
echo -e " > SSH File -> '$this_root_ssh_file'"
if [ ! -d "$this_root_ssh_file" ] ; then
    echo -e " > [DOCKER]: SSH $DEFAULT_SSH_FILE_ID not located in root."
    echo -e " > [DOCKER]: start copying file from source..."
    echo -e " > Source File: '$GIT_SSH_FILE'"
    echo -e " > Destination: '$current_working_dir'"
    echo -e ""
    cp "$GIT_SSH_FILE" "$current_working_dir"
    echo -e " > [DOCKER]: Successfully Copied [OK]"
else
    echo -e " > [DOCKER]: SSH $DEFAULT_SSH_FILE_ID already located in root."
    echo -e " > [DOCKER]: Nothing to do! [OK]"
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
