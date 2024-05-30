#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/02/2024
# Description : This just keeps a record of how many webservers are running so we can look back
# over time and see how many webservers have been active at any given moment in time
# This might be useful if you have had some network outage and machines are considered
# offline through no fault of their own and you want to look back and see what the profile
# of machines being destroyed and rebuilt was
##############################################################################################
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
#############################################################################################
#############################################################################################
#set -x


if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh INSTALLMONITORINGGEAR:1`" = "1" ] )
then

	CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

	noprovisioned="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"
	noactive="`${HOME}/autoscaler/GetDNSIPs.sh | /usr/bin/wc -w`"

	if ( [ "${no_active}" = "" ] )
	then
		no_active="0"
	fi

	if ( [ ! -d ${HOME}/logs/monitoring ] )
	then
		/bin/mkdir -p ${HOME}/logs/monitoring
	fi

	/bin/echo "###############################`/usr/bin/date`##################################################################" >> ${HOME}/logs/monitoring/WebserverHistory.log
	/bin/echo "The number of webserver IP addresses registered with the DNS system at this time is ${no_active} online machines" >> ${HOME}/logs/monitoring/WebserverHistory.log
	/bin/echo "The number of webserver machines that have been provisioned at this time is: ${noprovisioned} allocated machines" >> ${HOME}/logs/monitoring/WebserverHistory.log
 fi
