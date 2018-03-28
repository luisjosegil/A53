#!/bin/bash
# GLOBAL VARIABLES ----------------
source ./config.control

# FUNCTIONS -----------------------

# External functions to kill a process
source ./functions_kill

function retrieve_HW_processor {
	local PROCESSOR=$(cat /proc/cpuinfo | grep Processor | head -n 1 | awk '{ print $3 }')
	echo "$PROCESSOR"
}

function retrieve_compiled_name {
        case $(retrieve_HW_processor) in
                "$MNR_CPU_HW_A7")
                        echo "$MNR_COMPILED_A7"
                        ;;
                "$MNR_CPU_HW_A53")
                        echo "$MNR_COMPILED_A53"
                        ;;
        esac
}

function update_config_file {
        #local NEW_CONFIG_LINE=$(echo '"'"$1"'"="'"$2"'"' )
        local OLD_CONFIG_LINE=$(echo "$1=")
        local NEW_CONFIG_LINE=$(echo "$1="'"'"$2"'"' )
        CUR_CONFIG_LINE=$(grep "$OLD_CONFIG_LINE" "$CONFIG_FILE_SCRIPTS" )
        # Update config file, if not updated yet
        if [[ "$CUR_CONFIG_LINE" != "$NEW_CONFIG_LINE" ]];
        then
                sed -i "/$OLD_CONFIG_LINE/c\\$NEW_CONFIG_LINE" "$CONFIG_FILE_SCRIPTS"
        fi
}

# MAIN CODE -----------------------
#set -x

MNR_NAME=$(retrieve_compiled_name)
# Update config file for the rest of scripts
update_config_file $MNR_LABEL_NAME_OF_MINER $MNR_NAME

kill_process_by_name $MNR_NAME

cd TEST
./$MNR_NAME -q -c ../cfg.json > $MNR_LOG_FILE 2>&1 &
cd ..

echo "new $MNR_NAME instance running with PID $(get_PID_by_name $MNR_NAME)"

exit 0
