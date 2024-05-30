#!/bin/sh
#################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: This will record the load on your servers for you to be able to review at your leisure
# Requires atop to be installed.
#################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#####################################################################################
#####################################################################################
#set -x

if ( [ "${1}" = "reboot" ] )
then
	if ( [ -f ${HOME}/runtime/ATOP_RUNNING ] )
	then
		/bin/rm ${HOME}/runtime/ATOP_RUNNING
	fi
fi

if ( [ -d ${HOME}/logs/atoplogrecords ] )
then
	/usr/bin/find ${HOME}/logs/atoplogrecords -type f -mtime +7 -delete
fi

if ( [ -f  ${HOME}/runtime/ATOP_RUNNING ] )
then
	exit
fi

if ( [ -f /usr/bin/atopsar ] )
then
	if ( [ ! -d ${HOME}/logs/atoplogrecords ] )
	then
		/bin/mkdir -p ${HOME}/logs/atoplogrecords
	fi

	LOG_FILE="atop_out_`/bin/date | /bin/sed 's/ //g'`"
	exec 1>>${HOME}/logs/atoplogrecords/${LOG_FILE}

	/bin/touch ${HOME}/runtime/ATOP_RUNNING

	/usr/bin/atopsar -c 10 360 

	total_records="`/usr/bin/tail -n +7 ${HOME}/logs/atoplogrecords/${LOG_FILE} | /usr/bin/wc -l`"
	idle_values="`/usr/bin/awk '{print $NF}' ${HOME}/logs/atoplogrecords/${LOG_FILE}`"

	no_low_values="0"

	for value in ${idle_values}
	do
		if ( [ "${value}" -eq "${value}" ] 2>/dev/null )
		then
			if ( [ "${value}" -le "10" ] )
			then
				no_low_values="`/usr/bin/expr ${no_low_values} + 1`" 
			fi
		fi
	done

	percentage_low_values=`/usr/bin/awk -v values=${no_low_values} -v total=${total_records} 'BEGIN { printf "%.0f\n", 100 * values / total }'`
	
	if ( [ "${percentage_low_values}" -gt "25" ] )
	then
		${HOME}/providerscripts/email/SendEmail.sh "HIGH PERCENTAGE LOAD" "More than a quarter of samples had more than 90% load over the past hour on machine with IP address `${HOME}/providerscripts/utilities/GetPublicIP.sh`" "ERROR"
	fi

	/bin/rm ${HOME}/runtime/ATOP_RUNNING

fi
