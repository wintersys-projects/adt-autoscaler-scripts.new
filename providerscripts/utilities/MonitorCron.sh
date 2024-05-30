#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 11/08/2021
# Description:This will monitor whether cron is loading and loadable or not
#######################################################################################
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
########################################################################################
########################################################################################
#set -x

/usr/bin/crontab -l >/dev/null
if ( [ "$?" != "0" ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "CRON COULD NOT BE LOADED" "Something must br wrong, cron is not loading which is a big problem I will reboot" "ERROR"
	${HOME}/providerscripts/utilities/ShutdownThisAutoscaler.sh "reboot"
 fi
