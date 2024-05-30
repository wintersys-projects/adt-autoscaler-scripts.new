#!/bin/sh
###############################################################################################
# Description: This script will set up your crontab for you
# Date: 28/01/2017
# Author: Peter Winter
###############################################################################################
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
#######################################################################################
#######################################################################################
#set -x

#Setup crontab

/bin/echo "MAILTO=''" > /var/spool/cron/crontabs/root

#These scripts are set to run every minute
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && /bin/sleep 30 && ${HOME}/providerscripts/utilities/UpdateIP.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/datastore/ObtainBuildClientIP.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/cron/SetupFirewallFromCron.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/autoscaler/PurgeDetachedIPs.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/RemoveExpiredLocks.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/1 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/MonitorForOverload.sh" >> /var/spool/cron/crontabs/root


#These scripts are set to run every 5 minutes
/bin/echo "*/5 * * * * export HOME="${HOMEDIR}" && ${HOME}/security/MonitorFirewall.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/5 * * * * export HOME="${HOMEDIR}" && ${HOME}/autoscaler/RecordNumberOfWebserversRunning.sh" >> /var/spool/cron/crontabs/root

#This script will run every 10 minutes
/bin/echo "*/10 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/EnforcePermissions.sh" >> /var/spool/cron/crontabs/root
/bin/echo "*/10 * * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/MonitorCron.sh" >> /var/spool/cron/crontabs/root

/bin/echo "@hourly export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/LoadMonitoring.sh" >> /var/spool/cron/crontabs/root

/bin/echo "@daily export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/PerformSoftwareUpdate.sh" >> /var/spool/cron/crontabs/root

SERVER_TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECONTINENT'`"
SERVER_TIMEZONE_CITY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECITY'`"

/bin/echo "@reboot export TZ=\":${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}\"" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/UpdateInfrastructure.sh" >>/var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/RemoveExpiredLocks.sh reboot" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/LoadMonitoring.sh 'reboot'" >> /var/spool/cron/crontabs/root
/bin/echo "@reboot export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/PerformSoftwareUpdate.sh" >> /var/spool/cron/crontabs/root


#If we are building for production, then these scripts are also installed in the crontab. If it's for development then they are not
#installed.
if ( [ "${PRODUCTION}" = "1" ] )
then
	/bin/echo "*/2 * * * * export HOME="${HOMEDIR}" && ${HOME}/cron/PerformScalingFromCron.sh" >> /var/spool/cron/crontabs/root
	/bin/echo "*/3 * * * * export HOME="${HOMEDIR}" && ${HOME}/cron/DeadOrAliveFromCron.sh" >> /var/spool/cron/crontabs/root
	/bin/echo "30 7 * * *  export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/DailyScaleup.sh 3" >> /var/spool/cron/crontabs/root
	/bin/echo "30 17 * * * export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/DailyScaledown.sh 2" >> /var/spool/cron/crontabs/root
fi

/bin/echo "30 3 * * *  export HOME="${HOMEDIR}" && ${HOME}/providerscripts/utilities/RemoveExpiredLogs.sh" >> /var/spool/cron/crontabs/root

#Install our new crontab
/usr/bin/crontab /var/spool/cron/crontabs/root
