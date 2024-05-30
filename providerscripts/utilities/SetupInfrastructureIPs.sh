#!/bin/sh
################################################################################################################
# Author: Peter Winter
# Date:   05/07/2016
# Description : Loads some environment variables into memory from the file system
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

export DATABASE_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBIP'`"
export BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCLIENTIP'`"
export WEBSERVER_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WSIP'`"
export AUTOSCALER_IP="`${HOME}/providerscripts/utilities/GetIP.sh`"



