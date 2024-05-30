#!/bin/sh
#####################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : Commits specified file and pushes it to origin
######################################################################################
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

if ( [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ] )
then
	/bin/echo "Usage : ${0} : <files> <commit message> <repository provider> "
	exit
fi

repository_provider="${3}"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"


if ( [ "${INFRASTRUCTURE_REPOSITORY_USERNAME}" = "" ] || [ "${INFRASTRUCTURE_REPOSITORY_PASSWORD}" = "" ] )
then
	/bin/echo "Please enter your repository username"
	read REPOSITORY_USERNAME
	/bin/echo "Please enter your repository password"
	read REPOSITORY_PASSWORD
	INFRASTRUCTURE_REPOSITORY_PASSWORD="${REPOSITORY_PASSWORD}"
fi

/usr/bin/git add ${1}
/usr/bin/git commit -m "${2}"
/usr/bin/git branch -M main

if ( [ "${repository_provider}" = "bitbucket" ] )
then
	if ( [ "${INFRASTRUCTURE_REPOSITORY_PASSWORD}" = "" ] )
	then
		/usr/bin/git remote add origin https://${INFRASTRUCTURE_REPOSITORY_USERNAME}@bitbucket.org/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-autoscaler-scripts.git
	else
		/usr/bin/git remote add origin https://${INFRASTRUCTURE_REPOSITORY_USERNAME}:${INFRASTRUCTURE_REPOSITORY_PASSWORD}@bitbucket.org/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-autoscaler-scripts.git
	fi
fi
if ( [ "${repository_provider}" = "github" ] )
then
	if ( [ "${INFRASTRUCTURE_REPOSITORY_PASSWORD}" = "" ] )
	then
		/usr/bin/git remote add origin https://${INFRASTRUCTURE_REPOSITORY_USERNAME}@github.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-autoscaler-scripts.git
	else
		/usr/bin/git remote add origin https://${INFRASTRUCTURE_REPOSITORY_USERNAME}:${INFRASTRUCTURE_REPOSITORY_PASSWORD}@github.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-autoscaler-scripts.git
	fi
fi
if ( [ "${repository_provider}" = "gitlab" ] )
then
	if ( [ "${INFRASTRUCTURE_REPOSITORY_PASSWORD}" = "" ] )
	then
		/usr/bin/git remote add origin https://${INFRASTRUCTURE_REPOSITORY_USERNAME}@gitlab.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-autoscaler-scripts.git
	else
		/usr/bin/git remote add origin https://${INFRASTRUCTURE_REPOSITORY_USERNAME}:${INFRASTRUCTURE_REPOSITORY_PASSWORD}@gitlab.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-autoscaler-scripts.git
	fi
fi

/usr/bin/git push -u origin main

