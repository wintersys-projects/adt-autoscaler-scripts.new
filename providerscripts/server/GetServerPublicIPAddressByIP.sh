#!/bin/sh
############################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets a machine's public ip based on its private ip
#############################################################################
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
####################################################################################
####################################################################################
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

ip="${1}"
cloudhost="${2}"

if ( [ "`/bin/echo ${ip} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`" = "" ] )
then
	exit
fi

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute droplet list | /bin/grep ${ip} | /usr/bin/awk '{print $3}'
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	zone="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
	private_network_id="`/usr/bin/exo -O text compute private-network list  | /bin/grep "adt_private_net_${zone}" | /usr/bin/awk '{print $1}'`"
	server_name="`/usr/bin/exo compute private-network show ${private_network_id} | grep ${ip} |    /bin/grep -o "webserver-.* " | /usr/bin/awk '{print $1}'`"
	if ( [ "${server_name}" != "" ] )
	then
		/usr/bin/exo compute instance list | /bin/grep ${server_name} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'
	fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	/usr/local/bin/linode-cli --text linodes list | /bin/grep "${ip}" | /usr/bin/awk '{print $(NF-1)}'
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/bin/sleep 1
	vpc_id="`/usr/bin/vultr vpc2 list | /bin/grep "192.168.0.0" | /usr/bin/awk '{print $1}'`"
	machine_id="`/usr/bin/vultr vpc2 nodes list ${vpc_id} | /bin/grep ${ip} | /usr/bin/awk '{print $1}'`"
	/usr/bin/vultr instance list ${machine_id} | /bin/grep ${machine_id} | /usr/bin/awk '{print $2}'
fi

