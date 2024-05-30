#!/bin/sh
########################################################################################
# Description: This script is called repeatedly from cron and performs the autoscaling
# calculations. The end result of calling this script might be a newly spawned webserver(s)
# and a subsequent reboot
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

if ( [ "`/bin/ps -ef | /bin/grep PerformScaling | /bin/grep -v Cron | /bin/grep -v grep | /usr/bin/wc -l`" != "0" ] )
then
	exit
fi

lockfile=${HOME}/runtime/autoscalelock.file

if ( [ ! -f ${lockfile} ] )
then
	/usr/bin/touch ${lockfile}
	${HOME}/autoscaler/PerformScaling.sh
	/bin/rm ${lockfile}
fi



