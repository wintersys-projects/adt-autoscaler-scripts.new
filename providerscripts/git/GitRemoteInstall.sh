#!/bin/sh
########################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This will install the git tool and is is called over SSH from the build
# machine in so that we can bootstrap our building an autoscaler. I chose not to use cloud-init
# to do this.
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
###########################################################################################
###########################################################################################
#set -x

if ( [ ! -f /usr/bin/git ] )
then
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y update
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y install git
fi

count="0"
while ( [ ! -f /usr/bin/git ] && [ "${count}" -lt "5" ] )
do
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y update
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y install git
	/bin/sleep 10
	count="`/usr/bin/expr ${count} + 1`"
done
