#!/bin/bash

# GLOBAL VARIABLES ----------------
source ./config.control

# FUNCTIONS -----------------------
function read_cpu_temp {
	local TEMP=$(sudo cat /sys/devices/virtual/thermal/thermal_zone0/temp)
	if (( $TEMP > 1000 ));
	then
		echo "$(($TEMP/1000))"
	else
		echo "$TEMP"
	fi
}

function read_cur_cpu_use {
	local FILE=$(retrieve_cfg_file)
	local CUR_CPU_USE=$(cat $FILE | grep cpu-efficiency | sed 's/,//g' | sed 's/"//g' | awk '{ print $3 }')
	echo "$CUR_CPU_USE"
}

function retrieve_cfg_file {
	if (($TESTING == $FALSE ));
	then
		echo "$CONFIG_FILE"
	else
		echo "tmp_cfg"
	fi
}

function set_cpu_use {
	local FILE=$(retrieve_cfg_file)
	# We expect cpu percentage when function is called
	local NEW_JSON_VAL=$(echo '"'"cpu-efficiency"'" : "'"$1"'",' )
	sed -i "/cpu-efficiency/c\ \t$NEW_JSON_VAL" "$FILE"	
}

function reduce_cpu_use {
	echo "reduce CPU usage"
	local FILE=$(retrieve_cfg_file)
	local CUR_CPU_USE=$(read_cur_cpu_use)
	NEW_CPU_USE=$(($CUR_CPU_USE-$CPU_USE_STEP))
	set_cpu_use $NEW_CPU_USE
}

function calc_increased_cpu_use {
	local FILE=$(retrieve_cfg_file)
	local CUR_CPU_USE=$(read_cur_cpu_use)
	local NEW_CPU_USE=$(($CUR_CPU_USE+$CPU_USE_STEP))
	echo "$NEW_CPU_USE"
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

# MAIN CODE -----------------------
#set -x
# Infinite loop

if (($TESTING==$FALSE));
then
	kill_miner
	mine
fi

while true
do
	sleep_x_mins $MINS_TO_SLEEP
	DATETIME=$(date)
	CPU_TEMP=$(read_cpu_temp)
	if (($DEBUG_LOGS==$TRUE));
	then
		echo "$DATETIME"
		echo "CPU Temp:$CPU_TEMP"
	fi

	if (($CPU_TEMP>=$MAX_CPU_TEMP));
	then
		reduce_cpu_use
		if (($DEBUG_LOGS==$TRUE));
		then
			echo "-CPU by $CPU_USE_STEP%. Reboot miner"
		fi
		if (($TESTING==$FALSE));
		then
	       		kill_miner 
        		mine
		fi
	elif (( $CPU_TEMP<(($MAX_CPU_TEMP-$CPU_TEMP_HISTERESYS)) ));
	then
		NEW_CPU_USE=$(calc_increased_cpu_use)
		if (($NEW_CPU_USE<=100));
		then		
			if (($DEBUG_LOGS==$TRUE));
			then
				echo "+CPU to:$NEW_CPU_USE. Reboot miner"
			fi
			set_cpu_use $NEW_CPU_USE
			if (($TESTING==$FALSE));
			then
	       			kill_miner 
        			mine
			fi
		else
			if (($DEBUG_LOGS==$TRUE));
			then
				echo "CPU already set to MAX"
			fi
		fi
	else
		if (($DEBUG_LOGS==$TRUE));
		then
			echo "CPU temp in range"
		fi
	fi
done

exit 0
