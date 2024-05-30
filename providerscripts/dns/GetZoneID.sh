#!/bin/sh
#######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This will get the zone id  when we are using cloudflare as our DNS
# provider
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
#####################################################################################
#####################################################################################
#set -x

zonename="${1}"
email="${2}"
authkey="${3}"
dns="${4}"

if ( [ "${dns}" = "cloudflare" ] )
then    
	#Storing it in a file stops us hitting cloudflare rate limits
	if ( [ -f ${HOME}/runtime/zoneid.dat ] )
	then
		zoneid="`/bin/cat ${HOME}/runtime/zoneid.dat`"
	else
		zoneid="`/usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}&status=active&page=1&per_page=20&order=status&direction=desc&match=all" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" | /usr/bin/jq '.result[].id' | /bin/sed 's/"//g'`"
	
		if ( [ "${zoneid}" != "" ] )
		then
			/bin/echo "${zoneid}" > ${HOME}/runtime/zoneid.dat
		fi
	fi

	/bin/echo ${zoneid}

fi


