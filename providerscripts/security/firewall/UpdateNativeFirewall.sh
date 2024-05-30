#!/bin/sh
########################################################################################
# Author: Peter Winter
# Date  : 12/07/2021
# Description : This will apply add newly built webserver machines to our webservers'
# native firewall
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ACTIVEFIREWALLS:2`" = "0" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ACTIVEFIREWALLS:3`" = "0" ] )
then
	exit
fi

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
   exit
fi

if ( [ -f ${HOME}/DROPLET ] )
then    
	firewall_id="`/usr/local/bin/doctl -o json compute firewall list | jq '.[] | select (.name == "adt-webserver" ).id' | /bin/sed 's/"//g'`"
	webserver_ids="`${HOME}/providerscripts/server/ListServerIDs.sh webserver ${CLOUDHOST}`"

	for webserver_id in ${webserver_ids}
	do
		if ( [ "`/usr/local/bin/doctl compute firewall  list | /bin/grep "adt-webserver" | /bin/grep ${webserver_id}`" = "" ] )
		then
			/usr/local/bin/doctl compute firewall add-droplets ${webserver_firewall_id} --droplet-ids ${webserver_id}
		fi
	done
fi

if ( [ -f ${HOME}/EXOSCALE ] )
then   
	 :
fi

if ( [ -f ${HOME}/LINODE ] )
then
	firewall_id="`/usr/local/bin/linode-cli --json firewalls list | jq '.[] | select (.label == "adt-webserver" ).id'`"
	webserver_ids="`${HOME}/providerscripts/server/ListServerIDs.sh webserver ${CLOUDHOST}`"

	for webserver_id in ${webserver_ids}
	do
		if ( [ "`/usr/local/bin/linode-cli --json firewalls devices-list ${firewall_id} | /bin/grep ${webserver_id}`" = ""  ] )
		then
			/usr/local/bin/linode-cli firewalls device-create --id ${webserver_id} --type linode ${firewall_id} 
		fi
	done
fi


if ( [ -f ${HOME}/VULTR ] )
then
   :
fi
