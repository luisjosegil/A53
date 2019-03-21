#!/bin/bash
#	v9.3.0
#	Code formatted


cd /media/ramdisk/A53

# GLOBAL VARIABLES ----------------
source ./config.control

# External Libraries
source ./LIB/functions_JSON
source ./LIB/functions_HW

# LOCAL VARIABLES
LOW_TEMP_COUNTER=0

# LABELS
LABEL_CPU_EFFICIENCY="cpu-efficiency"

# FUNCTIONS -----------------------
function read_avg_cpu_temp {
	local TEMPERATURE=0
	for ((i=0; i<$AVG_NUM_TEMP_READS; i++)); do
		TEMPERATURE=$(( TEMPERATURE+$(read_instant_cpu_temp) ))
		sleep 1
	done
	echo "$((TEMPERATURE/AVG_NUM_TEMP_READS))"
}

function read_cur_cpu_use {
	local FILE=$(retrieve_cfg_file)
	read_from_JSON "${FILE}" "${LABEL_CPU_EFFICIENCY}" 
}

function retrieve_cfg_file {
	if (($TESTING == $FALSE ));
	then
		echo "${CONFIG_FILE}"
	else
		echo "tmp_cfg"
	fi
}

function set_cpu_use {
	local VALUE=$1
	if (($TESTING == $FALSE));
	then
		local FILE=$(retrieve_cfg_file)
		# We expect cpu percentage when function is called
		modify_JSON "${FILE}" "${LABEL_CPU_EFFICIENCY}" "${VALUE}"
	fi
}

function reduce_cpu_use {
	echo "reduce CPU usage"
	local FILE=$(retrieve_cfg_file)
	local CUR_CPU_USE=$(read_cur_cpu_use)
	NEW_CPU_USE=$(($CUR_CPU_USE-$CPU_USE_STEP))
	modify_JSON "${FILE}" "${LABEL_CPU_EFFICIENCY}" "${NEW_CPU_USE}"
}

function calc_increased_cpu_use {
	local FILE=$(retrieve_cfg_file)
	local CUR_CPU_USE=$(read_cur_cpu_use)
	local NEW_CPU_USE=$(($CUR_CPU_USE+$CPU_USE_STEP))
	echo "${NEW_CPU_USE}"
}

function kill_miner {
	/bin/bash ./kill_miner.sh
}

function mine {
        /bin/bash ./miner.sh 
}

function sleep_x_mins {
	if (($TESTING == $FALSE ));
	then
		/bin/sleep $(($1*60))
	else
		/bin/sleep $1
	fi
}
function check_cpu_speedup {
	if (( $1<(($MAX_CPU_TEMP-$CPU_TEMP_HISTERESYS)) ));
	then
		echo "${TRUE}"
	else
		echo "${FALSE}"
	fi

}

function sleep_random_between_a_and_b {
	SECONDS=$(/usr/bin/shuf -i${1}-${2} -n1)
	if (($DEBUG_LOGS==$TRUE));
	then
		echo "ENG. Sleep ${SECONDS} sec."
	fi
	/bin/sleep "${SECONDS}"
}
# MAIN CODE -----------------------
#set -x
sleep_random_between_a_and_b 0 $MAX_SECS_WAIT
# Infinite loop
if ((${TESTING}==${FALSE}));
then
	kill_miner
	mine
fi

while true
do
	sleep_x_mins "${MINS_TO_SLEEP}"
	DATETIME=$(date)
	CPU_TEMP=$(read_avg_cpu_temp)
	if ((${DEBUG_LOGS}==${TRUE}));
	then
		echo "${DATETIME}"
		echo "CPU Temp:${CPU_TEMP}"
	fi

	if ((${CPU_TEMP}>=${MAX_CPU_TEMP}));
	then
		LOW_TEMP_COUNTER="0"
		reduce_cpu_use
		if ((${DEBUG_LOGS}==${TRUE}));
		then
			echo "-CPU by ${CPU_USE_STEP}%. Reboot miner"
		fi
		if ((${TESTING}==${FALSE}));
		then
	       		kill_miner 
        		mine
		fi
	elif (  ( $( check_cpu_speedup "${CPU_TEMP}" )==${TRUE} )  ); 
	then

		((LOW_TEMP_COUNTER++))	
		if ((${LOW_TEMP_COUNTER}>=${MAX_TIMES_LOW_TEMP}));
		then
			LOW_TEMP_COUNTER="0"
			NEW_CPU_USE=$(calc_increased_cpu_use)
			if ((${NEW_CPU_USE}<=100));
			then		
				if ((${DEBUG_LOGS}==${TRUE}));
				then
					echo "+CPU to:${NEW_CPU_USE}. Reboot miner"
				fi
				set_cpu_use "${NEW_CPU_USE}"
				if ( (${TESTING}==${FALSE}) );
				then
		       			kill_miner 
	        			mine
				fi
			else
				if ((${DEBUG_LOGS}==${TRUE}));
				then
					echo "CPU already set to MAX"
				fi
			fi
		#else
		#	echo "ENG. Counter didn reach the limit"
		fi

	else
		LOW_TEMP_COUNTER="0"
		if ((${DEBUG_LOGS}==${TRUE}));
		then
			echo "CPU temp in range"
		fi
	fi
done

exit 0
