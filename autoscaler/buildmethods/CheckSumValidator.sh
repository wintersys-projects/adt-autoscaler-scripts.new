#!/bin/sh
###################################################################################################
# Description: This is just a small utility script for use in doing the check sum of the backup archive
# once is it scp'd to the new webserver.It gets copied to the new webserver when it is built from a backup
# and run there to check that the backup is considered valid and hasn't been paritally scp'd because of
# a network glitch or anything
# Author: Peter Winter
# Date: 12/01/2017
######################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Fou.logion, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################################
#######################################################################################################

checksumtoken="`/usr/bin/awk '{print $1}' /tmp/newchecksum.dat`"


if ( [ "`/bin/grep ${checksumtoken} /tmp/checksum.dat`" != "" ] )
then
   /bin/echo "1"
else
   /bin/echo "0"
fi
