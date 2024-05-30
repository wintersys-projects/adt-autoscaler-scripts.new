#!/bin/sh
###################################################################################################
# Description: You can use the script ${BUILD_HOME}/helperscripts/AdjustScaling.sh to set how many 
# webservers you want to have active at any given point in time. You can also configure cron
# with scripts such as "DailyScaleUp" or "DailyScaleDown" or "LunchtimeScaleUp" and on such that
# you can have any level of control you want over how many webservers are running at any given point
# in time. The script "AdjustScaling.sh" will write the configuration you have set to the Datastore
# and then this script will read and action that configuration setting. This is not load responsive
# meaning it will not be suitable if you have sites with unpredictable sudden spikes although this 
# toolkit could be extended to suport the use of dynamic scaling with providers that have infrastructure
# to support that. 
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

# Wait for 5 minutes after first installation before we allow scaling to start  
if ( [ -f ${HOME}/runtime/INITIALBUILDCOMPLETED ] )
then
	if test "`/usr/bin/find ${HOME}/runtime/INITIALBUILDCOMPLETED -mmin -5`"
	then
		exit
	fi
fi

scaling_mode="static"
NO_WEBSERVERS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'NUMBERWS'`"

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "scalingprofile/profile.cnf"`" = "0" ] )
then
	/bin/echo  "SCALING_MODE=${scaling_mode}" > /tmp/profile.cnf
	/bin/echo  "NO_WEBSERVERS=${NO_WEBSERVERS}" >> /tmp/profile.cnf  
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh /tmp/profile.cnf "scalingprofile/profile.cnf"
fi

if ( [ -f /tmp/profile.cnf ] )
then
	/bin/rm /tmp/profile.cnf
fi

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
	exit
fi

# Get the scaling profile from the Datastore so we can see how many webservers we need to have online
${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh "scalingprofile/profile.cnf"

while ( [ ! -f /tmp/profile.cnf ] && [ "${count}" -lt "5" ] )
do
	/bin/sleep 5
	${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh "scalingprofile/profile.cnf"
	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" = "5" ] )
then
	/bin/echo "${0} `/bin/date`: Wasn't able to retrieve scaling config profile" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	${HOME}/providerscripts/email/SendEmail.sh "NO SCALING CONFIG PROFILE FOUND" "I haven't been able to retrieve a scaling config profile from the datastore" "ERROR"
fi

if ( [ -f /tmp/profile.cnf ] && [ "`/bin/cat /tmp/profile.cnf`" != "" ] )
then
	scaling_mode="`/bin/grep -a "SCALING_MODE" /tmp/profile.cnf | /usr/bin/awk -F'=' '{print $NF}'`"
	NO_WEBSERVERS="`/bin/grep -a "NO_WEBSERVERS" /tmp/profile.cnf | /usr/bin/awk -F'=' '{print $NF}'`"
else
	/bin/echo  "SCALING_MODE=${scaling_mode}" > /tmp/profile.cnf
	/bin/echo  "NO_WEBSERVERS=${NO_WEBSERVERS}" >> /tmp/profile.cnf
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh /tmp/profile.cnf "scalingprofile/profile.cnf"
fi

if ( [ "${scaling_mode}" = "static" ] && [ "${NO_WEBSERVERS}" != "" ] )
then
	${HOME}/providerscripts/utilities/StoreConfigValue.sh 'NUMBERWS' "${NO_WEBSERVERS}"
fi

if ( [ "${scaling_mode}" != "static" ] )
then
	exit
fi

#We don't want less than 2 webservers so, if somehow, webservers is set to less than 2 default it to 2 to be on the safe side. 
if ( [ "${NO_WEBSERVERS}" -lt "2" ] )
then
	NO_WEBSERVERS="2"
fi


