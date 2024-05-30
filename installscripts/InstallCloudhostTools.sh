#!/bin/sh
##############################################################################
# Description: This script will install the tools for the selected cloudhost.
# It is with these tools that servers can be manipulated.
# It also makes sure that the machine type is set which we might check for
# in various places in the code
# Author: Peter Winter
# Date: 12/01/2017
##############################################################################
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
#############################################################################
#############################################################################

#Configure the machine for the current provider. Each new provider that is added will need a config process like these to be added
#here

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	/bin/echo "${0} `/bin/date`: Building for the Digital Ocean provider" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
	${HOME}/installscripts/InstallDoctl.sh ${BUILDOS}
	/bin/chmod 400 {HOME}/.config/doctl/config.yaml
	/usr/bin/touch ${HOME}/DROPLET
fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
	/bin/echo "${0} `/bin/date`: Building for the Exoscale provider" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
	${HOME}/installscripts/InstallExo.sh ${BUILDOS}
	/bin/chmod 400 ${HOME}/.config/exoscale/exoscale.toml
	/usr/bin/touch ${HOME}/EXOSCALE
fi


if ( [ "${CLOUDHOST}" = "linode" ] )
then
	/bin/echo "${0} `/bin/date`: Building for the Linode provider" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
  #  ${HOME}/installscripts/Update.sh "${BUILDOS}"
	${HOME}/installscripts/InstallLinodeCLI.sh "${BUILDOS}"
	/bin/chmod 400 ${HOME}/.config/linode-cli
	/usr/bin/touch ${HOME}/LINODE
fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	/bin/echo "${0} `/bin/date`: Building for the Vultr provider" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
	${HOME}/installscripts/InstallGo.sh ${BUILDOS}
	${HOME}/installscripts/InstallVultr.sh ${BUILDOS}
	/usr/bin/touch ${HOME}/VULTR
fi
