#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 23/08/2020
# Description: This will give us a time since the machine was installed
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

file_name="/etc/ssh/ssh_host_dsa_key.pub"

old=`/usr/bin/stat -c %Z $file_name` 
now=`/usr/bin/date +%s` 
age="`/usr/bin/expr ${now} - ${old}`"
age_in_mins="`/usr/bin/expr ${age} \/ 60`"

/bin/echo ${age_in_mins}
