#!/bin/sh
###################################################################################################
# Description: This will build a webserver off a preexisting snapshot This is the snapshot build
# method and it should be quicker than a regular build but with the disadvantage that the snapshot
# you are building might be a bit out of date if you took the original snapshot a month ago or so
# The actual application is synced to the latest version. 
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
#set -x
  
/bin/echo "${0} `/bin/date`: Building a new machine using the snapshot method ${webserver_name}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

snapshot_build="1"
attempts="0"
finished="0"
	
while ( [ "${finished}" = "0" ] && [ "${attempts}" -lt "10" ] )
do
	attempts="`/usr/bin/expr ${attempts} + 1`"
	/bin/sleep 30
	/bin/echo "${0} `/bin/date`: Attempting to connect with a new machine ip address ${private_ip} that has been spun up from a snapshot attempt ${attempts}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/usr/bin/ssh -i ${BUILD_KEY} -o ConnectTimeout=30 -o ConnectionAttempts=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SERVER_USER}@${private_ip} "/bin/touch /tmp/alive.$$" 
	if ( [ "$?" = "0" ] )
	then
		finished="1"
		/bin/echo "${0} `/bin/date`: Have been able to establish a connection to the newly provisioned shapshot generated machine ${webserver_name} which was provisioned as the result of a scaling event " >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	fi
done

if ( [ "${finished}" = "0" ] )
then
	if ( [ "${CLOUDHOST}" = "vultr" ] )
	then
		#This is untidy, lol,
		#because vultr cloudhost doesn't let you destroy machines until they have been running for 5 mins or more
		/bin/sleep 300
	fi
	
	${HOME}/providerscripts/email/SendEmail.sh "COULDN'T CONNECT TO A WEBSERVER BUILT FROM A SNAPSHOT" "For some reason, autoscaler ${autoscaler_name} couldn't provision webserver ${webserver_name}" "ERROR"
	/bin/echo "${0} `/bin/date` : ${private_ip} is being destroyed because it couldn't be connected to after spinning it up from a snapshot" >> ${HOME}/logs/${logdir}/MonitoringLog.log
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
fi

/bin/echo "${0} `/bin/date`: ${private_ip} reconfiguring the necessary initiation stuff for machine ${webserver_name}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

#Mark this as an autoscaled machine as distinct from one built during the initial build
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "AUTOSCALED" "1"

/bin/echo "${0} `/bin/date`: Copying the webserver config and buildstyles to the built from snapshot machine" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/rm /home/${SERVER_USER}/runtime/APPLICATION_DB_CONFIGURED /home/${SERVER_USER}/runtime/PROCESSED_INITIAL_CONFIG /home/${SERVER_USER}/.ssh/webserver_configuration_settings.dat /home/${SERVER_USER}/.ssh/buildstyles.dat"    
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} -P ${SSH_PORT} ${HOME}/.ssh/webserver_configuration_settings.dat ${SERVER_USER}@${private_ip}:${HOME}/.ssh/
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} -P ${SSH_PORT} ${HOME}/.ssh/buildstyles.dat ${SERVER_USER}@${private_ip}:${HOME}/.ssh/
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} -p ${SSH_PORT} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /usr/sbin/service sshd restart"

  
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} -P ${SSH_PORT} ${HOME}/.ssh/webserver_configuration_settings.dat ${SERVER_USER}@${private_ip}:${HOME}/.ssh/
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} -P ${SSH_PORT} ${HOME}/.ssh/buildstyles.dat ${SERVER_USER}@${private_ip}:${HOME}/.ssh/

/bin/echo "${0} `/bin/date`: Updating the configuration values that are specific to this build" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh MYPUBLICIP ${WS_PUBLIC_IP}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh MYIP ${WSIP}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh BUILDCLIENTIP ${BUILD_CLIENT_IP}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh ASIPS ${ASIPS}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh ASIP_PRIVATES ${ASIP_PRIVATES}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh ASIP ${ASIP}"    
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh ASPUBLICIP ${AS_PUBLIC_IP}"  
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh DBIP ${DBIP}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh DBPUBLICIP ${DB_PUBLIC_IP}" 
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh SNAPPED '1'"

/bin/echo "${0} `/bin/date`: Syncing the latest application sourcecode to webroot because a snapshot can be weeks old and no doubt the application itself has likely moved on" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/application/SyncLatestApplication.sh"  1>&2 >/dev/null

/bin/echo "${0} `/bin/date`: Everyone loves a good reboot so lets do one here" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /usr/sbin/shutdown -r now" 
