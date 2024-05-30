#!/bin/sh
######################################################################################
# Author: Peter Winter
# Date :  07/07/2016
# Description: This will install additional software for your current cloudhost (if available)
# to enhance the monitoring capabilities of your system. You might be able to set alerts
# and so on to tell you if a machine is getting saturated for some reason
#####################################################################################
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
#######################################################################################
#######################################################################################
#set -x

BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"

apt=""
if ( [ "`${HOME}/providerscripts/utilities/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt" ] )
then
	apt="/usr/bin/apt-get"
elif ( [ "`${HOME}/providerscripts/utilities/ExtractBuildStyleValues.sh "PACKAGEMANAGER" | /usr/bin/awk -F':' '{print $NF}'`" = "apt-fast" ] )
then
	apt="/usr/sbin/apt-fast"
fi

if ( [ "${apt}" != "" ] )
then
	if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh INSTALLMONITORINGGEAR:1`" = "1" ] )
	then
		CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

		if ( [ "${CLOUDHOST}" = "digitalocean" ] )
		then
			if ( [ "${BUILDOS}" = "ubuntu" ] )
			then
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				then
					DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				then
					DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				then
					DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				then
					/usr/bin/curl -sSL https://repos.insights.digitalocean.com/install.sh | /usr/bin/sudo bash    
				fi
			fi
			if ( [ "${BUILDOS}" = "debian" ] )
			then
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				 then
					  DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				 then
					 /usr/bin/curl -sSL https://repos.insights.digitalocean.com/install.sh | /usr/bin/sudo bash    
				 fi
			fi
		fi
		if ( [ "${CLOUDHOST}" = "linode" ] )
		then
			if ( [ "${BUILDOS}" = "ubuntu" ] )
			then
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				then
					DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				then
					DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				then
					DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				then
					:
				fi
			fi
			if ( [ "${BUILDOS}" = "debian" ] )
			then
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				 then
					  :
				 fi         
			fi    
		fi
		if ( [ "${CLOUDHOST}" = "exoscale" ] )
		then
			 if ( [ "${BUILDOS}" = "ubuntu" ] )
			 then
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				 then
					 :
				 fi
			 fi
			 if ( [ "${BUILDOS}" = "debian" ] )
			 then
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				 then
					 :
				 fi         
			fi
		fi
		if ( [ "${CLOUDHOST}" = "vultr" ] )
		then
			 if ( [ "${BUILDOS}" = "ubuntu" ] )
			 then
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				 then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				 fi
				 if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				 then
					 :
				 fi         
			fi
			if ( [ "${BUILDOS}" = "debian" ] )
			then
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "glances" ] )
				then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install glances 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "nmon" ] )
				then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install nmon 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "atop" ] )
				then
					 DEBIAN_FRONTEND=noninteractive ${apt} -o DPkg::Lock::Timeout=-1  -qq -y install atop 
				fi
				if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INSTALLMONITORINGGEAR' | /usr/bin/awk -F'|' '{print $NF}'`" = "native" ] )
				then
					 :
				fi        
			fi   
		fi
	fi
fi
