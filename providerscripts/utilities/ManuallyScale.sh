#!/bin/sh
###############################################################################################
# Author: Peter Winter
# Date  : 04/07/2022
# Description : This script can be used to scale up or scale down the number of webservers manually
# You just call it from the command line whilst logged in to the autoscaler in order to configure
# how many webservers to scale up to or scale down to
################################################################################################
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
###########################################################################################
###########################################################################################
#set -x

if ( [ "$1" = "" ] )
then
	/bin/echo "Please enter the number of webservers you want to scale to, 2 or more, as an integer"
	read no_webservers
else
	no_webservers="${1}"
fi

while ( [ "${no_webservers}" -lt "2" ] )
do
	/bin/echo "Number of webservers has to be 2 or more. Please supply a different value"
	read no_webservers
done

${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh "scalingprofile/profile.cnf" 1>/dev/null 2>/dev/null
/bin/sed -i "/^NO_WEBSERVERS=/c\NO_WEBSERVERS=${no_webservers}" /tmp/profile.cnf 
${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh profile.cnf "scalingprofile/profile.cnf" 1>/dev/null 2>/dev/null

/bin/rm /tmp/profile.cnf

${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh "scalingprofile/profile.cnf" 1>/dev/null 2>/dev/null
no_webservers="`/bin/grep NO_WEBSERVERS /tmp/profile.cnf | /usr/bin/awk -F'=' '{print $NF}'`"

if ( [ "${no_webservers}" != "" ] )
then
	/bin/echo "Number of webservers is now successfully set to ${no_webservers}"
fi

/bin/rm /tmp/profile.cnf
