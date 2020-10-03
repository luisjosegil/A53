#!/bin/bash
#	v9.10.0
#	Docker version 1.0

# CONTROL. GLOBAL VARIABLES ----------------

source config.control

#########################################################################################

source LIB/functions_HW.lib
source LIB/functions_DOCKER.lib

# MAIN CODE -----------------------
# LOCAL VARIABLES
LOW_TEMP_COUNTER=0
NUM_CORES=$( HW_retrieve_num_cores )
MAX_CPU_USE_INT=$(( "${MAX_CPU_USE}" * "${NUM_CORES}" ))

LABEL_CUR_CPU_USE_INT=$(( ${MAX_CPU_USE}*${NUM_CORES} ))
LABEL_CUR_CPU_USE=$(( "${LABEL_CUR_CPU_USE_INT}" / 100 ))

sleep_random_between_a_and_b "0" "${MAX_SECS_WAIT}"

docker_mine "${CONTAINER_LABEL}" 
docker_set_cpu_use "${LABEL_CUR_CPU_USE_INT}" "${CONTAINER_LABEL}" 

# Infinite loop
while true
do
	set -x
	sleep_x_secs "${SECS_2_SLEEP}"
	DATETIME=$(date)
	CPU_TEMP=$(HW_read_avg_cpu_temp)

	logger "${DATETIME}"
	logger "CPU Temp:${CPU_TEMP}"

	# This comparison is only for Integers
	if [ "${CPU_TEMP}" -gt "${MAX_CPU_TEMP}" ] 
	then
		LOW_TEMP_COUNTER="0"
		LABEL_CUR_CPU_USE_INT=$( docker_reduce_cpu_load "${CONTAINER_LABEL}" )
		#if (( ${DEBUG_LOGS}==${TRUE} ))
		logger "+CPU LOAD to:${LABEL_CUR_CPU_USE}."
	elif [ $( check_cpu_speedup "${CPU_TEMP}" ) -eq "${TRUE}" ] 
	then

		LOW_TEMP_COUNTER=$((LOW_TEMP_COUNTER++))	
		if [ ${LOW_TEMP_COUNTER} -ge "${MAX_TIMES_LOW_TEMP}" ]
		then
			LOW_TEMP_COUNTER="0"
			LABEL_CUR_CPU_USE_INT=$( docker_increase_cpu_load "${CONTAINER_LABEL}" )
			logger "+CPU LOAD to:${LABEL_CUR_CPU_USE}."
		fi

	else
		LOW_TEMP_COUNTER="0"
		logger "CPU temp in range"
	fi
done

exit 0
