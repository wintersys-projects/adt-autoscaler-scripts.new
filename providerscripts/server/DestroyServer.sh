#!/bin/sh
############################################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script destroys a machine based on ip address
########################################################################################################################
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

OUT_FILE="firewall-remove-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/firewall/${OUT_FILE}
ERR_FILE="firewall-remove-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/firewall/${ERR_FILE}

export HOME="`/bin/cat /home/homedir.dat`"

server_ip="${1}"
cloudhost="${2}"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
algorithm="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"

if ( [ "${3}" = "" ] )
then
	private_server_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${server_ip} ${cloudhost}`"
else 
	private_server_ip="${3}"
fi
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPORT'`"


if ( [ "`/bin/echo ${server_ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
	exit
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	#This will destroy a server with the given ip address and cleanup all the associated configuration settings
	if ( [ "${server_ip}" != "" ] )
	then
		server_id="`/usr/local/bin/doctl compute droplet list | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"

		count="0"
		while ( [ "${count}" -lt "10" ] )
		do
			/usr/local/bin/doctl -force compute droplet delete ${server_id}
			if ( [ "$?" != "0" ] )
			then
				count="`/usr/bin/expr ${count} + 1`"
				/bin/sleep 5
			else
				break
			fi
		done
 
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}" 
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beenonline/${server_ip}" 
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_server_ip}"

		if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip} ] )
		then
		   /bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip}
		fi
	fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	if ( [ "${server_ip}" != "" ] )
	then
		zone="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
		server_name="`/usr/bin/exo compute instance list --zone ${zone} -O text | /bin/grep ${server_ip} | /usr/bin/awk '{print $2}'`"
		/bin/echo "Y" | /usr/bin/exo compute instance delete ${server_name} --zone ${zone} 

		/bin/echo "${0} `/bin/date`: Destroyed a server with name ${server_name}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beenonline/${server_ip}" 
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_server_ip}"

		if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip} ] )
		then
		   /bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip}
		fi
	fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	if ( [ "${server_ip}" != "" ] )
	then
		server_to_delete=""
		server_to_delete="`${HOME}/providerscripts/server/GetServerName.sh ${server_ip} 'linode'`"
		server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_to_delete} | /bin/grep -v "id" | /usr/bin/awk '{print $1}'`"
		/usr/local/bin/linode-cli linodes shutdown ${server_id}
		/usr/local/bin/linode-cli linodes delete ${server_id}
		/bin/echo "${0} `/bin/date`: Destroyed a server with name ${server_to_delete}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beenonline/${server_ip}" 
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_server_ip}"

		if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip} ] )
		then
		   /bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip}
		fi
	fi
fi

#This will destroy a server by ip address and cleanup all associated configuration settings

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"

	if ( [ "${server_ip}" != "" ] )
	then

		server_id="`/usr/bin/vultr instance list | /bin/grep ${server_ip} | /usr/bin/awk '{print $1}'`"
		/usr/bin/vultr instance delete ${server_id}

		/bin/echo "${0} `/bin/date`: Destroyed a server with id ${server_id}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverips/${private_server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "webserverpublicips/${server_ip}"
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beenonline/${server_ip}" 
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${private_server_ip}"


		if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip} ] )
		then
		   /bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_server_ip}
		fi
	fi
fi

