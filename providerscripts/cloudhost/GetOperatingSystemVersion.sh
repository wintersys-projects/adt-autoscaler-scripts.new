#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get the operating system version
######################################################################################
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
###################################################################################
###################################################################################
#set -x

instance_size="${1}"
cloudhost="${2}"

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
BUILDOSVERSION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOSVERSION'`"


if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	BUILDOSVERSION="`/bin/echo ${BUILDOSVERSION} | /bin/sed 's/\./-/g'`"
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/echo "ubuntu-${BUILDOSVERSION}-x64"
elif ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/echo "debian-${BUILDOSVERSION}-x64"
	fi
fi

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		if ( [ "${BUILDOSVERSION}" = "20.04" ] )
		then
			/bin/echo "Linux Ubuntu ${BUILDOSVERSION} LTS 64-bit"
		elif ( [ "${BUILDOSVERSION}" = "22.04" ] )
		then
			/bin/echo "Linux Ubuntu ${BUILDOSVERSION} LTS 64-bit"
		elif ( [ "${BUILDOSVERSION}" = "24.04" ] )
		then
			/bin/echo "Linux Ubuntu ${BUILDOSVERSION} LTS 64-bit"
		fi
	elif ( [ "${BUILDOS}" = "debian" ] )
	then
		if ( [ "${BUILDOSVERSION}" = "11" ] )
		then 
			/bin/echo "Linux Debian ${BUILDOSVERSION} (Bullseye) 64-bit"
		elif ( [ "${BUILDOSVERSION}" = "12" ] )
		then
			/bin/echo "Linux Debian ${BUILDOSVERSION} (Bookworm) 64-bit"
		fi
	fi
fi

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/echo "Ubuntu ${BUILDOSVERSION}"
elif ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/echo "Debian ${BUILDOSVERSION}"
	fi
fi

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	if ( [ "${BUILDOS}" = "ubuntu" ] )
	then
		/bin/echo "Ubuntu ${BUILDOSVERSION} LTS x64"
elif ( [ "${BUILDOS}" = "debian" ] )
	then
		/bin/echo "Debian ${BUILDOSVERSION} x64"
	fi
fi
