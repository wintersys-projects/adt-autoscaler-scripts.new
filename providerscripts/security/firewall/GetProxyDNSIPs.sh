
  
#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2021
# Description : This will get the DNS IP addresses that need to be granted access through
# the firewall from a specific provider when we use a proxy service such as cloudflare
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

alldnsproxyips=""
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
DNS_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSCHOICE'`"

autoscalerips=""

autoscalerips="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"autoscalerip/*\" | /usr/bin/tr '\n' ' '`"
autoscalerpublicips="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"autoscalerpublicip/*\" | /usr/bin/tr '\n' ' '`"
autoscalerips=${autoscalerips}${autoscalerpublicips}

preparedautoscalerips=""

for autoscalerip in ${autoscalerips}
do
	autoscalerip="\"${autoscalerip}/32\","
	preparedautoscalerips=${preparedautoscalerips}${autoscalerip}
done

autoscalerips="`/bin/echo ${preparedautoscalerips} | /bin/sed 's/,$//g'`"

if ( [ "${DNS_CHOICE}" = "cloudflare" ] )
then

	if ( [ "${CLOUDHOST}" = "digitalocean" ] )
	then
		#dynamic
		alldnsproxyips="`/usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/ips" | /usr/bin/jq '.result.ipv4_cidrs' | /bin/grep '"' | /bin/sed 's/.* "//g' | /bin/sed 's/".*//g' | /usr/bin/tr '\n' ' ' | /bin/sed 's/ $//g'`"

		if ( [ "${alldnsproxyips}" = "" ] || [ "${alldnsproxyips}" = "null" ] )
		then
			#hardcoded
			alldnsproxyips="103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 104.16.0.0/13 104.24.0.0/14 108.162.192.0/18 141.101.64.0/18 162.158.0.0/15 172.64.0.0/13 173.245.48.0/20 188.114.96.0/20 190.93.240.0/20 197.234.240.0/22 198.41.128.0/17 131.0.72.0/22 199.27.128.0/21"
		fi
		
		autoscalerips="`/bin/echo ${autoscalerips} | /bin/sed 's/,/ /g'`"
		alldnsproxyips="${autoscalerips} ${alldnsproxyips}"
		alldnsproxyips="`/bin/echo ${alldnsproxyips} | /bin/sed 's/"//g'`"
	fi

	if ( [ "${CLOUDHOST}" = "exoscale" ] )
	then
		#dynamic
		alldnsproxyips="\"`/usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/ips" | /usr/bin/jq '.result.ipv4_cidrs' | /bin/grep '"' | /bin/sed 's/.* "//g' | /bin/sed 's/".*//g' | /usr/bin/tr '\n' ' ' | /bin/sed 's/ /,/g'  | /bin/sed 's/,$//g'| /bin/sed 's/ $//g'`\""
	   
		if ( [ "${alldnsproxyips}" = "" ] || [ "${alldnsproxyips}" = "null" ] )
		then
			#hardcoded
			alldnsproxyips="103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 104.16.0.0/13 104.24.0.0/14 108.162.192.0/18 141.101.64.0/18 162.158.0.0/15 172.64.0.0/13 173.245.48.0/20 188.114.96.0/20 190.93.240.0/20 197.234.240.0/22 198.41.128.0/17 131.0.72.0/22 199.27.128.0/21"
		fi
		autoscalerips="`/bin/echo ${autoscalerips} | /bin/sed 's/,/ /g'`"
		alldnsproxyips="${autoscalerips} ${alldnsproxyips}"
		alldnsproxyips="`/bin/echo ${alldnsproxyips} | /bin/sed 's/"//g'`"
	fi

	if ( [ "${CLOUDHOST}" = "linode" ] )
	then
		#dynamic
		alldnsproxyips="`/usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/ips" | /usr/bin/jq '.result.ipv4_cidrs'  | /usr/bin/tr '\n' ' ' | /bin/sed 's/ \+/ /g' | /bin/sed 's/\[//g' | /bin/sed 's/\]//g' | /bin/sed 's/ //g'`"        

		 #hardcoded
		 if ( [ "${alldnsproxyips}" = "" ] || [ "${alldnsproxyips}" = "null" ] )
		 then
			 alldnsproxyips="\"103.21.244.0/22\",\"103.22.200.0/22\",\"103.31.4.0/22\",\"104.16.0.0/13\",\"104.24.0.0/14\",\"108.162.192.0/18\",\"141.101.64.0/18\",\"162.158.0.0/15\",\"172.64.0.0/13\",\"173.245.48.0/20\",\"188.114.96.0/20\",\"190.93.240.0/20\",\"197.234.240.0/22\",\"198.41.128.0/17\",\"131.0.72.0/22\",\"199.27.128.0/21\""
		fi
		alldnsproxyips="${autoscalerips},${alldnsproxyips}"
	fi

	if ( [ "${CLOUDHOST}" = "vultr" ] )
	then
		#dynamic
		alldnsproxyips="\"`/usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/ips" | /usr/bin/jq '.result.ipv4_cidrs' | /bin/grep '"' | /bin/sed 's/.* "//g' | /bin/sed 's/".*//g' | /usr/bin/tr '\n' ' ' | /bin/sed 's/ $//g'`\""
	   
		if ( [ "${alldnsproxyips}" = "" ] || [ "${alldnsproxyips}" = "null" ] )
		then
			#hardcoded
			alldnsproxyips="103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 104.16.0.0/13 104.24.0.0/14 108.162.192.0/18 141.101.64.0/18 162.158.0.0/15 172.64.0.0/13 173.245.48.0/20 188.114.96.0/20 190.93.240.0/20 197.234.240.0/22 198.41.128.0/17 131.0.72.0/22 199.27.128.0/21"
		fi
		autoscalerips="`/bin/echo ${autoscalerips} | /bin/sed 's/,/ /g'`"
		alldnsproxyips="${autoscalerips} ${alldnsproxyips}"
		alldnsproxyips="`/bin/echo ${alldnsproxyips} | /bin/sed 's/"//g'`"
	fi
fi

alldnsproxyips="`/bin/echo ${alldnsproxyips} | /bin/sed 's/,$//g'`"
