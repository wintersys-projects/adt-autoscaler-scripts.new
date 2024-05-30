#!/bin/sh
#####################################################################################
# Description: This script is called from cron and sets up the UFW firewall. It is called
# repeatedly as a way of aggressively ensuring that the firewall is enabled, but, once
# the firewall is enabled a flag is set and checked each time this is called meaning
# this effectively does nothing once the firewall is configured.
# Author: Peter Winter
# Date: 12/01/2017
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
#######################################################################################################
#######################################################################################################
#set -x


trap cleanup 0 1 2 3 6 9 14 15

cleanup()
{
	/bin/rm ${HOME}/runtime/firewalllock.file
	exit
}

lockfile=${HOME}/runtime/firewalllock.file

if ( [ ! -f ${lockfile} ] )
then
	/usr/bin/touch ${lockfile}
	${HOME}/security/SetupFirewall.sh
	/bin/rm ${lockfile}
else
	/bin/echo "script already running"
fi
