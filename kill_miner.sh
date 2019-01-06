#!/bin/bash
# GLOBAL VARIABLES ----------------
source ./config.control

# Import common functions to kill processes
source ./functions_kill

# Activate debugging
#set -x

# MINER_NAME is kept in config file
kill_process_by_name $MINER_NAME

# Stop debugging
#set +x

exit 0
