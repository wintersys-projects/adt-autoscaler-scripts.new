#!/bin/sh
########################################################################################
# Description: This script is called regularly from cron and initiates the process of 
# determining the status of each webserver (is it dead or alive) and if it is found
# to be dead it will be terminated and if it is found to be alive, it will be allowed
# to live on
# Author: Peter Winter
# Date: 12/01/2017
########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
	exit
fi

if ( [ "`/bin/ps -ef | /bin/grep DeadOrAlive | /bin/grep -v Cron | /bin/grep -v grep | /usr/bin/wc -l`" != "0" ] )
then
	exit
fi

trap cleanup 0 1 2 3 6 9 14 15

cleanup()
{
	/bin/rm ${HOME}/runtime/deadoralivelock.file
	exit
}

lockfile=${HOME}/runtime/deadoralivelock.file

if ( [ ! -f ${lockfile} ] )
then
	/usr/bin/touch ${lockfile}
	${HOME}/autoscaler/DeadOrAlive.sh
	/bin/rm ${lockfile}
fi
