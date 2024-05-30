#!/bin/sh
############################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets the number of servers of a particular type which are running
#############################################################################################
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
######################################################################################
######################################################################################
#set -x

server_type="${1}"
cloudhost="${2}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	numberofservers="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_type} | /usr/bin/wc -l`"
	/bin/echo ${numberofservers}
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	server_type="`/bin/echo "${server_type}" | /bin/sed 's/\*//g'`"
	zone="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
	/usr/bin/exo compute instance list --zone ${zone} -O text | /bin/grep "${server_type}" | /usr/bin/wc -l
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	/usr/local/bin/linode-cli linodes list --text | /bin/grep "${server_type}" | /usr/bin/wc -l 2>/dev/null
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/bin/sleep 1
	server_type="`/bin/echo ${server_type} | /usr/bin/cut -c -25`"
	/usr/bin/vultr instance list | /bin/grep ${server_type} | /usr/bin/awk '{print $2}' | /usr/bin/wc -l
fi






