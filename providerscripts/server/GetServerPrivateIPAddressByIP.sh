#!/bin/sh
############################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script gets a machine's private ip based on its public ip
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
	ip="`/usr/local/bin/doctl compute droplet list | /bin/grep ${ip} | /usr/bin/awk '{print $4}'`"
	/bin/echo ${ip}
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	zone="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
	server_name="`/usr/bin/exo compute instance list --zone ${zone} -O text | /bin/grep ${ip} | /usr/bin/awk '{print $2}'`"
	/usr/bin/exo compute private-network show adt_private_net_${zone} --zone ${zone} -O text | /usr/bin/tr '{' '\n' | /bin/grep ${server_name} | /usr/bin/sed 's/}.*//g' | /usr/bin/awk '{print $2}'
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	#/usr/local/bin/linode-cli linodes list --text | /bin/grep ${ip} | /bin/grep -o "192.168[^[:space:]]*"
	linode_id="`/usr/local/bin/linode-cli --text linodes list | /bin/grep ${ip} | /usr/bin/awk '{print $1}'`"
	# /usr/local/bin/linode-cli --text linodes ips-list ${linode_id} | /bin/grep -A 3 'ipv4.private' | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'
	/usr/local/bin/linode-cli  --text linodes list | /bin/grep ${linode_id} | /bin/grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | /bin/grep  "192.168"
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/bin/sleep 1
   id="`/usr/bin/vultr instance list | /bin/grep ${ip} | /usr/bin/awk '{print $1}'`"
   /usr/bin/vultr instance get ${id} | /bin/grep "INTERNAL IP" | /usr/bin/awk '{print $NF}'
fi


