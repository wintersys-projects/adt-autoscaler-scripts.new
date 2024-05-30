#!/bin/sh
###################################################################################################
# Description: This is the regular build style which involves a full build of a webserver installing
# one software package after another from scratch until the machine is built
# I chose not to use cloud-init simply because I its not so easy to pass paramter values to cloud-init
# and doing it this way by bootstrapping git and working from there just seemed to be easier
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

/bin/echo "${0} `/bin/date`: Building a new machine using the regular build method ${webserver_name}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

snapshot_build="0"
#If we are here, then we are not building from a snapshot
webserver_name="${server_instance_name}"
#Test to see if our server can be accessed using our build key
count="0"
connected="0"
sshpass="0"

while ( [ "${count}" -lt "10" ] && [ "${connected}" = "0" ] )
do
	count="`/usr/bin/expr ${count} + 1`"
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS1} -o "PasswordAuthentication no" ${DEFAULT_USER}@${private_ip} "/bin/touch /tmp/alive.$$"

	if ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS1} ${DEFAULT_USER}@${private_ip} "/bin/ls /tmp/alive.$$"`" != "" ] )
	then
		connected="1"
	fi
		
	if ( [ "${connected}" = "0" ] && [ "${CLOUDHOST_PASSWORD}" != "" ] )
	then
		if ( [ ! -f /usr/bin/sshpass ] )
		then
			if ( [ "${BUILDOS}" = "ubuntu" ] || [ "${BUILDOS}" = "debian" ] )
			then
				DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=-1 -qq install sshpass
			fi
		fi
			
		/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${DEFAULT_USER}@${private_ip} "/bin/touch /tmp/alive1.$$"
			
		if ( [ "$?" = "0" ] )
		then
			/bin/echo "${0} `/bin/date`: Doing an sshpass style initiation of our new webserver (${server_instance_name}) with ip address ${private_ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
			sshpass="1"
			connected="1"
		fi
	
	fi
	if ( [ "${connected}" = "0" ] )
	then
		/bin/sleep 30
	fi
done

if ( [ "${connected}" = "0" ] && [ "${count}" = "10" ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "FAILED TO BUILD/PROVISION A WEBSERVER" "For some reason, autoscaler provisioned webserver with ip ${ip} failed to provision. At the very least, the clouhost_password wasn't set when it was needed" "ERROR"
	/bin/echo "${0} `/bin/date`: Failed to build initiate a new webserver I will have to destroy it and try again" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	exit    
fi

if ( [ "${sshpass}" = "1" ] )
then
	/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp ${OPTIONS} ${BUILD_KEY}.pub ${CLOUDHOST_USERNAME}@${private_ip}:/root/.ssh/authorized_keys
fi

/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /usr/sbin/useradd ${SERVER_USER} 2>&1 >/dev/null ; /bin/echo ${SERVER_USER}:${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E /usr/sbin/chpasswd ; ${SUDO} /usr/bin/gpasswd -a ${SERVER_USER} sudo"
/bin/cat ${BUILD_KEY}.pub | /usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /bin/mkdir -p /home/${SERVER_USER}/.ssh ; ${SUDO} /bin/chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${SERVER_USER}/.ssh ; /bin/cat - >> /home/${SERVER_USER}/.ssh/authorized_keys ; ${SUDO} /bin/sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config ; ${SUDO} /bin/sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config ; ${SUDO} /etc/init.d/ssh reload ; ${SUDO} /bin/chown -R ${SERVER_USER}:${SERVER_USER} /home/${SERVER_USER}"

/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${BUILD_KEY} ${SERVER_USER}@${private_ip}:/home/${SERVER_USER}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/providerscripts/git/GitRemoteInstall.sh ${SERVER_USER}@${private_ip}:/home/${SERVER_USER}

count="0"
while ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/ls /home/${SERVER_USER}/ws.sh" 2>/dev/null`" = "" ] && [ "${count}" -lt "5" ] )
do
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/GitRemoteInstall.sh ; cd /home/${SERVER_USER}; /usr/bin/git clone https://github.com/${INFRASTRUCTURE_REPOSITORY_OWNER}/adt-webserver-scripts.git; /bin/cp -r ./adt-webserver-scripts/* .; /bin/rm -r ./adt-webserver-scripts; /bin/chown -R ${SERVER_USER}:${SERVER_USER} /home/${SERVER_USER}/*; /bin/chmod 500 /home/${SERVER_USER}/ws.sh "
	/bin/sleep 5
	count="`/usr/bin/expr ${count} + 1`"
done

#Mark this as an autoscaled machine as distinct from one built during the initial build
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "AUTOSCALED" "1"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "SNAPPED" "0"

/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/.ssh/webserver_configuration_settings.dat ${HOME}/.ssh/buildstyles.dat ${SERVER_USER}@${private_ip}:${HOME}/.ssh/
 
#Configuration values
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "MYPUBLICIP" "${ip}"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "MYIP" "${private_ip}"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "BUILDCLIENTIP" "${BUILD_CLIENT_IP}"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "ASIP" "${ASIP}"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "ASPUBLICIP" "${AS_PUBLIC_IP}"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "DBIP" "${DBIP}"
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "DBPUBLICIP" "${DB_PUBLIC_IP}"
 
/bin/echo "${0} `/bin/date`: Initiating the main build on webserver ${webserver_name}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

#We have lots of backup choices to build from, hourly, daily and so on, so this will pick which backup we want to build from
if ( [ "${BUILD_CHOICE}" = "0" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/ws.sh 'virgin' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "1" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/ws.sh 'baseline' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "2" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'hourly' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "3" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'daily' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "4" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'weekly' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "5" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'monthly' ${SERVER_USER}"
elif ( [ "${BUILD_CHOICE}" = "6" ] )
then
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO}  ${HOME}/ws.sh 'bimonthly' ${SERVER_USER}"
fi

/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO}  /usr/sbin/shutdown -r now"

