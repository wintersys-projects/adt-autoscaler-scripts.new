#!/bin/sh
##########################################################################################
# Description : We can use this script to send emails from within our scripts
# These will generally be sysem emails or status emails
# Date : 10-11-2016
# Author : Peter Winter
##########################################################################################
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

subject="$1"
message="$2"
level="$3"
to_address="$4"

message="MESSSAGE TIMESTAMP: `/usr/bin/date` \n ${message}"

FROM_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SYSTEMFROMEMAILADDRESS'`"
TO_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SYSTEMTOEMAILADDRESS'`"

if ( [ "${to_address}" != "" ] )
then
	TO_ADDRESS="${to_address}"
fi

USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'EMAILUSERNAME'`"
PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'EMAILPASSWORD'`"
EMAIL_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'EMAILPROVIDER'`"

if ( [ "${level}" != "MANDATORY" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh EMAILNOTIFICATIONLEVEL:ERROR`" = "1" ] && [ "${level}" != "ERROR" ] )
then
   exit
fi

if ( [ "${FROM_ADDRESS}" != "" ] && [ "${TO_ADDRESS}" != "" ] && [ "${USERNAME}" != "" ] && [ "${PASSWORD}" != "" ] && [ "${subject}" != "" ] && [ "${message}" != "" ] )
then
	if ( [ "${EMAIL_PROVIDER}" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: Email sent via sendpulse, subject : ${subject} to: ${TO_ADDRESS}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s smtp-pulse.com:2525 -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
	fi
	if ( [ "${EMAIL_PROVIDER}" = "2" ] )
	then
		/bin/echo "${0} `/bin/date`: Email sent via mailjet, subject : ${subject} to: ${TO_ADDRESS}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s in-v3.mailjet.com:587 -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}    
	fi
	if ( [ "${EMAIL_PROVIDER}" = "3" ] )
	then
		/bin/echo "${0} `/bin/date`: Email sent via AWS SES, subject : ${subject} to: ${TO_ADDRESS}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/usr/bin/sendemail -o tls=no -f ${FROM_ADDRESS} -t ${TO_ADDRESS} -s email-smtp.eu-west-1.amazonaws.com -xu ${USERNAME} -xp ${PASSWORD} -u "${subject} `/bin/date`" -m ${message}
	fi
else
	/bin/echo "${0} `/bin/date`:Email not sent because of missing parameter(s)" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
fi
