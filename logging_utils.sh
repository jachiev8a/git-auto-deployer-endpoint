#!/bin/bash

ANSI_LOG_OFF="\033[0m"
ANSI_LOG_RED="\e[91m"
ANSI_LOG_GREEN="\e[92m"
ANSI_LOG_YELLOW="\e[93m"
ANSI_LOG_BLUE="\e[94m"

# log_debug
# ----------------------------------------------------------------------
log_debug() {
    log_msg=$1
    echo -e "$ANSI_LOG_BLUE$log_msg$ANSI_LOG_OFF"
}

# log_info
# ----------------------------------------------------------------------
log_info() {
    log_msg=$1
    echo -e "$ANSI_LOG_GREEN$log_msg$ANSI_LOG_OFF"
}

# log_warning
# ----------------------------------------------------------------------
log_warning() {
    log_msg=$1
    echo -e "$ANSI_LOG_YELLOW$log_msg$ANSI_LOG_OFF"
}

# log_error
# ----------------------------------------------------------------------
log_error() {
    log_msg=$1
    echo -e "$ANSI_LOG_RED$log_msg$ANSI_LOG_OFF"
}
