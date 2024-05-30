#!/bin/sh
######################################################################################################
# Author: Peter Winter
# Date :  9/4/2016
# Description: Update the OS software
#######################################################################################################
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
#######################################################################################################
#######################################################################################################
BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"

if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh BUILDOS:ubuntu`" = "1" ] || [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh BUILDOS:debian`" = "1" ] )
then
	 ${HOME}/installscripts/UpdateAndUpgrade.sh ${BUILDOS}   
	 
	 if ( [ -f ${HOME}/DROPLET ] )
	 then
		 ${HOME}/installscripts/InstallDoctl.sh ${BUILDOS} #This will update the Doctl tool if we are on Digital Ocean
	 fi
	 
	 if ( [ -f ${HOME}/EXOSCALE ] )
	 then
		 ${HOME}/installscripts/InstallExo.sh ${BUILDOS} #This will update the Exo cli tool if we are on Exoscale
	 fi
	 
	 if ( [ -f ${HOME}/LINODE ] )
	 then
		 ${HOME}/installscripts/InstallLinodeCLI.sh ${BUILDOS} #This will update the Linode cli tool if we are on Linode
	 fi
	 
	 if ( [ -f ${HOME}/VULTR ] )
	 then
		 ${HOME}/installscripts/InstallVultr.sh ${BUILDOS} #This will update the Vultr Cli tool if we are on Vultr
	 fi
	 
fi
