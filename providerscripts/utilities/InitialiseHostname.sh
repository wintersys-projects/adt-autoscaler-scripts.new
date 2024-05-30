
#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2021
# Description : This will set the hostname for our current machine
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

export HOME="`/bin/cat /home/homedir.dat`"

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} `/bin/date`: Setting the autoscaler hostname" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log


if ( [ "${WEBSITE_NAME}" = "" ] )
then
	WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
	WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"
fi
if ( [ "${BUILDOS}" = "" ] )
then
	BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
fi

# Set the hostname for the machine
/bin/echo "${WEBSITE_NAME}AS" > /etc/hostname
/bin/hostname -F /etc/hostname

#Set the hostname the method varies by operating system
if ( [ "${BUILDOS}" = "debian" ] )
then
	/bin/sed -i "/127.0.0.1/ s/$/ ${WEBSITE_NAME}AS/" /etc/cloud/templates/hosts.debian.tmpl
	/bin/sed -i '1 i\127.0.0.1        localhost' /etc/cloud/templates/hosts.debian.tmpl

	if ( [ "`/bin/grep 127.0.0.1 /etc/hosts | /bin/grep "${WEBSITE_NAME}"`" = "" ] )
	then
		/bin/sed -i "s/127.0.1.1/127.0.1.1 ${WEBSITE_NAME}ASX/g" /etc/hosts
		/bin/sed -i "s/X.*//" /etc/hosts
	fi
	/bin/sed -i "0,/127.0.0.1/s/127.0.0.1/127.0.0.1 ${WEBSITE_NAME}AS/" /etc/hosts
else
	/usr/bin/hostnamectl set-hostname ${WEBSITE_NAME}AS
fi
