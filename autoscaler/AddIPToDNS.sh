#!/bin/sh
###################################################################################################
# Description: This script will take an ip address as a parameter and using the AddRecord.sh script
# from the providerscripts adds the ip address to the DNS service provider.
# It checks that the record doesn't already exist with the DNS provider before it is added and also
# removes any possibility of the machine to which the IP address belongs being a potentially stalled 
# build - it can't be, because we are satisdfied that the IP address needs to be added 
# Author: Peter Winter
# Date: 12/01/2017
######################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Fou.logion, either version 3 of the License, or
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

WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
DNS_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSCHOICE'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh 'DNSSECURITYKEY' stripped | /bin/sed 's/ /:/g'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSUSERNAME'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
	exit
fi

#Get the ip address which has been passed as a parameter

ip="${1}"
ipcheck="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${ip} ${CLOUDHOST}`"

if ( [ "`/bin/ls ${HOME}/runtime/beingbuiltips | /bin/grep ${ipcheck}`" = "" ] && [ ! -f  ${HOME}/runtime/IPREMOVED:${ip} ] )
then
	#Add the ip address to the DNS provider. Once this is done, the webserver should be online then.
	zonename="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
	zoneid="`${HOME}/providerscripts/dns/GetZoneID.sh "${zonename}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`"
	if ( [ "`${HOME}/providerscripts/dns/GetRecordID.sh "${zoneid}" "${WEBSITE_URL}" "${ip}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${DNS_CHOICE}"`" = "" ] )
	then    
		${HOME}/providerscripts/dns/AddRecord.sh "${zoneid}" "${DNS_USERNAME}" "${DNS_SECURITY_KEY}" "${WEBSITE_URL}" "${ip}" "${DNS_CHOICE}" 
		if ( [ "$?" = "0" ] )
		then
			private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddressByIP.sh ${ip} ${CLOUDHOST}`"
			if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip} ] )
			then
				/bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}
			fi
			/bin/touch /tmp/${private_ip}
			${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh /tmp/${private_ip} beenonline/${private_ip}
		fi

	fi
fi

