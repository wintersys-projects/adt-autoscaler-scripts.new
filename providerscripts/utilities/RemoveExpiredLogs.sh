#!/bin/sh
###############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This will remove log files and directories older than 7 days
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

/usr/bin/find ${HOME}/logs/* -mtime +7 -exec rm {} \;
/usr/bin/find ${HOME}/logs/* -mtime +7 -type d -exec rmdir {} \; 2>/dev/null
