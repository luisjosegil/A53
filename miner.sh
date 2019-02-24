#!/bin/bash
# GLOBAL VARIABLES ----------------
source ./config.control

# functions_BASH_CFG  functions_HW  functions_JSON  functions_kill


# FUNCTIONS -----------------------

# External functions
source ./LIB/functions_kill
source ./LIB/functions_HW
source ./LIB/functions_BASH_CFG

function retrieve_compiled_name {
	# Depends on LIB/functions_HW
        case $(retrieve_HW_processor) in
                "${MNR_CPU_HW_A7}")
                        echo "${MNR_COMPILED_A7}"
                        ;;
                "${MNR_CPU_HW_A53}")
                        echo "${MNR_COMPILED_A53}"
                        ;;
        esac
}

# MAIN CODE -----------------------
#set -x

MNR_NAME=$(retrieve_compiled_name)
# Update config file for the rest of scripts
#update_config_file "${MNR_LABEL_NAME_OF_MINER}" "${MNR_NAME}"
modify_BASH_CONFIG "${CONFIG_FILE_SCRIPTS}" "${MNR_LABEL_NAME_OF_MINER}" "${MNR_NAME}"

kill_process_by_name "${MNR_NAME}"

./TEST/${MNR_NAME} -q -c cfg.json > ${MNR_LOG_FILE} 2>&1 &

id_PID=$(get_PID_by_name "${MNR_NAME}")
echo "new ${MNR_NAME} instance running with PID ${id_PID}"

exit 0

