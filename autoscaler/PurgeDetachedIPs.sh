#!/bin/sh
############################################################################################
# Description:  If a webserver is inadvertently destroyed from the gui or from a command line
# command, then its IP address will be left registered with the DNS provider which means that
# it will be included in the round robin sequence but with no webserver to fulfill any requests
# This script will monitor for ip addresses that do not have a corresponding server running
# and remove the ip addresses that are not required from the DNS provider thus making sure
# that all registered ip addresses have an associated webserver to fulfil them.
# This script is called every minute from cron and so is quite "on it" if a machine has been
# destroyed by a 3rd party
# Author: Peter Winter
# Date: 12/01/2017
###########################################################################################
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
#######################################################################################################
#######################################################################################################
#set -x

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
	exit
fi

dnsips="`${HOME}/autoscaler/GetDNSIPs.sh`"
ips="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST}`"

if ( [ "${dnsips}" = "" ] )
then
	exit
fi

for dnsip in ${dnsips}
do
	if ( [ "`/bin/echo ${ips} | /bin/grep ${dnsip}`" = "" ] )
	then
		/bin/echo "${0} `/bin/date`: Purging detached IP address: ${dnsip}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		${HOME}/autoscaler/RemoveIPFromDNS.sh ${dnsip}
	fi
done
