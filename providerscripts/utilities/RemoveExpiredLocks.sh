#!/bin/sh
######################################################################################
# Author: Peter Winter
# Date :  07/07/2016
# Description: This will remove expired lock files from the runtime directory
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

if ( [ "${1}" = "reboot" ] )
then
	/usr/bin/find ${HOME}/runtime -name *lock* -type f -delete
else
	/usr/bin/find ${HOME}/runtime -name *lock* -type f -mmin +35 -delete
fi
#If its been 15 minutes since we updated the SSL certificate we can release the lock file we set
if ( [ -f ${HOME}/runtime/UPDATEDSSL ] )
then
	 /usr/bin/find ${HOME}/runtime/UPDATEDSSL -type f -mmin +15 -delete
fi
