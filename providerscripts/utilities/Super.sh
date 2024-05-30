#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : Enable a genuine user to easily switch to root
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

/bin/grep SERVERUSERPASSWORD ${HOME}/.ssh/autoscaler_configuration_settings.dat | /usr/bin/awk -F':' '{print $NF}' | /usr/bin/sudo -S /bin/echo "Going Super hold on to your hat" 

/bin/echo
/bin/echo

/bin/echo "#####################################################################################"
/bin/echo "#####################ATTEMPTING TO RUN AS ROOT#######################################"
/bin/echo "#####################################################################################"

/usr/bin/sudo su

/bin/echo
/bin/echo

/bin/echo "#####################################################################################"
/bin/echo "#####################NO LONGER RUNNING AS ROOT#######################################"
/bin/echo "#####################################################################################"
