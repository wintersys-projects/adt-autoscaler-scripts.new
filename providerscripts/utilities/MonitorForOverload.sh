#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description:This will monitor of the webserver is overloaded or not
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

if test "`/usr/bin/find ${HOME}/runtime/CPU_OVERLOAD_ACKNOWLEDGED -mmin +15`"
then
   /bin/rm ${HOME}/runtime/CPU_OVERLOAD_ACKNOWLEDGED
fi

if test "`/usr/bin/find ${HOME}/runtime/LOW_MEMORY_ACKNOWLEDGED -mmin +15`"
then
   /bin/rm ${HOME}/runtime/LOW_MEMORY_ACKNOWLEDGED
fi

if test "`/usr/bin/find ${HOME}/runtime/LOW_DISK_ACKNOWLEDGED -mmin +15`"
then
   /bin/rm ${HOME}/runtime/LOW_DISK_ACKNOWLEDGED
fi

ip="`${HOME}/providerscripts/utilities/GetPublicIP.sh`"

if ( [ ! -f ${HOME}/runtime/CPU_OVERLOAD_ACKNOWLEDGED ] )
then
	cpu_usage="`/usr/bin/sar -u 2 30 | /usr/bin/awk '{print $NF}' | /usr/bin/tail -1 | /usr/bin/awk -F'.' '{print $1}'`"

	if ( [ "${cpu_usage}" -lt "25" ] )
	then
		${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} overloadedips/${ip}
	else
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh overloadedips/${ip}
	fi

	if ( [ "${cpu_usage}" -lt "5" ] )
	then 
		/bin/touch ${HOME}/runtime/CPU_OVERLOAD_ACKNOWLEDGED
		${HOME}/providerscripts/email/SendEmail.sh "POTENTIAL OVERLOAD CONDITION" "Potential overload on machine with ip ${ip} CPU is only ${cpu_usage}% free" "ERROR"
	fi
fi

if ( [ ! -f ${HOME}/runtime/LOW_MEMORY_ACKNOWLEDGED ] )
then
	free_memory="`/usr/bin/free | /bin/grep Mem | /usr/bin/awk '{print $4/$2 * 100.0}'`"

	if ( [ "${free_memory}" -lt "10" ] )
	then
		/bin/touch ${HOME}/runtime/LOW_MEMORY_ACKNOWLEDGED
		${HOME}/providerscripts/email/SendEmail.sh "POTENTIAL LOW MEMORY CONDITION" "Potential low memory on machine with ip ${ip} memory is only ${free_memory}% free" "ERROR"
	fi
fi

if ( [ ! -f ${HOME}/runtime/LOW_DISK_ACKNOWLEDGED ] )
then
	disk_usage="`/usr/bin/df | /bin/grep -w "/" | /usr/bin/awk '{print $5}' | /bin/sed 's/%//'`"

	if ( [ "${disk_usage}" -gt "90" ] )
	then
		/bin/touch ${HOME}/runtime/LOW_DISK_ACKNOWLEDGED
		${HOME}/providerscripts/email/SendEmail.sh "POTENTIAL LOW DISK SPACE CONDITION" "Potential low disk space on machine with ip ${ip} disk space is  ${disk_usage}% full" "ERROR"
	fi
fi
