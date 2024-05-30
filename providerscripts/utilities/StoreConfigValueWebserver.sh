#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : Store a configuration value in the .dat file
############################################################################################
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
#############################################################################################
#############################################################################################

export HOME="`/bin/cat /home/homedir.dat`"

if ( [ ! -f ${HOME}/.ssh/webserver_configuration_settings.dat ] )
then
   exit
fi

/bin/sed -i '/:/!d' ${HOME}/.ssh/webserver_configuration_settings.dat

if ( [ "${1}" != "" ] && [ "${2}" != "" ] )
then
	/bin/sed -i "/^${1}:/d" ${HOME}/.ssh/webserver_configuration_settings.dat
	/bin/echo "${1}:${2}" >> ${HOME}/.ssh/webserver_configuration_settings.dat
elif ( [ "${1}" != "" ] && [ "${2}" = "" ] )
then
	/bin/sed -i "/^{1}$/d" ${HOME}/.ssh/webserver_configuration_settings.dat
	/bin/echo "${1}" >> ${HOME}/.ssh/webserver_configuration_settings.dat
fi
