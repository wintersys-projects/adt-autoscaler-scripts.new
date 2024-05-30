#!/bin/sh
####################################################################################################################
# Author: Peter Winter
# Date:   07/06/2016
# Description : This script is used to shutdown the autoscaler. You can do any cleanup you want in this script
# but to ensure system consistency all shutdowns shoud done through this script rather than through the provider's GUI interface
########################################################################################################################
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

/bin/echo ""
/bin/echo "#######################################################################"
/bin/echo "Shutting down an autoscaler instance. Please wait whilst I clean the place first."
/bin/echo "#######################################################################"
/bin/echo ""
/bin/echo "${0} `/bin/date`: Shutting down the autoscaler" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

if ( [ -f ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE ] )
then
	/bin/rm ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE
fi

/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE

if ( [ "`/bin/ls ${HOME}/runtime/AUTO*MON 2>/dev/null`" != "" ] )
then
	 /bin/rm ${HOME}/runtime/AUTO*MON* 2>/dev/null
fi

if ( [ -f ${HOME}/runtime/autoscalelock.file ] )
then
	/bin/rm ${HOME}/runtime/autoscalelock.file
fi

if ( [ "`/bin/ls ${HOME}/runtime/beingbuiltips/* 2>/dev/null`" != "" ] )
then
	/bin/rm -r ${HOME}/runtime/beingbuiltips/*
fi

if ( [ "`/bin/ls ${HOME}/runtime/beingbuiltpublicips/* 2>/dev/null`" != "" ] )
then
	/bin/rm -r ${HOME}/runtime/beingbuiltpublicips/*
fi

if ( [ "${1}" = "halt" ] )
then
	/usr/sbin/shutdown -h now
elif ( [ "${1}" = "reboot" ] )
then
	/usr/sbin/shutdown -r now
fi
