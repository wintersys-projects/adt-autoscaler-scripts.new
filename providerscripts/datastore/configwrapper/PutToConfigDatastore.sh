#!/bin/sh
####################################################################################
# Author: Peter Winter
# Date :  24/02/2022
# Description: This will put a particular file to the configuration datastore
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
######################################################################################
######################################################################################
#set -x

export HOME=`/bin/cat /home/homedir.dat`
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
configbucket="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{ for(i = 1; i <= NF; i++) { print $i; } }' | /usr/bin/cut -c1-3 | /usr/bin/tr '\n' '-' | /bin/sed 's/-//g'`"
configbucket="${configbucket}-config"

if ( [ "`${HOME}/providerscripts/utilities/CheckBuildStyle.sh 'DATASTORETOOL:s3cmd'`" = "1" ] )
then
	if ( [ "$3" = "recursive" ] )
	then
		/usr/bin/s3cmd --recursive put $1 s3://${configbucket}/$2
	else
		if ( [ -f ${1} ] )
		then
			/usr/bin/s3cmd put $1 s3://${configbucket}/$2
		elif ( [ -f ./${1} ] )
		then
			/usr/bin/s3cmd put ./$1 s3://${configbucket}/$2
			/bin/rm ./$1
		elif ( [ -f /tmp/${1} ] )
		then
			/usr/bin/s3cmd put /tmp/$1 s3://${configbucket}/$2
		else
			 directory="`/bin/echo ${1} | /usr/bin/awk -F'/' 'NF{NF-=1};1' | /bin/sed 's/ /\//g'`"
			/bin/mkdir -p /tmp/${directory}
			/bin/touch /tmp/$1
			/usr/bin/s3cmd put /tmp/$1 s3://${configbucket}/$2
			/bin/rm /tmp/$1
		fi
	fi
fi
