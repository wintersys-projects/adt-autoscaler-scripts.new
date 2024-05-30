#!/bin/sh
###################################################################################################
# Description: This will organise an autoscaled deployment making use of a pre provided full 
# machine backup. Its kinda like using a snapshot but rather using tar, this has some advantages
# in terms of the way I have done things which is that with snapshots you have to generate the snapshots
# and then redeploy a second time using the snapshots from the first build which makes it a two deploy process
# Using the tar archives, you can get to autoscale using the backups in a single build and in fact
# the backups you are using will be regenerated with every new build.
# The diadvantage is that backups aren't being used for autoscaler and databases machine classes
# which means that snapshot style builds can be used for autoscaler, webserver and database machine types
# where as the tar method can only be used for webservers
# euthor: Peter Winter
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

/bin/echo "${0} `/bin/date`: Building a new machine using the from backup method ${webserver_name}" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
  
snapshot_build="0"
	
#If we are here, then we are not building from a snapshot
webserver_name="${server_instance_name}"
	
#Test to see if our server can be accessed using our build key
count="0"
connected="0"

while ( [ "${count}" -lt "10" ] && [ "${connected}" = "0" ] )
do
	count="`/usr/bin/expr ${count} + 1`"
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS1} -o "PasswordAuthentication no" ${DEFAULT_USER}@${private_ip} "/bin/touch /tmp/alive.$$"

	if ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS1} ${DEFAULT_USER}@${private_ip} "/bin/ls /tmp/alive.$$ 2>/dev/null"`" != "" ] )
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
			/bin/echo "${0} `/bin/date`: Perfoming an sshpass style machine setup during a webserver build from backup" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

			connected="1"
			/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${DEFAULT_USER}@${private_ip} "/bin/mkdir -p /root/.ssh ; /bin/mkdir -p /home/${SERVER_USER}/.ssh"
			#Set up our ssh keys
			/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/ssh ${OPTIONS} ${CLOUDHOST_USERNAME}@${private_ip} "/bin/mkdir -p /home/${SERVER_USER}/.ssh ; /bin/chmod 700 /home/${SERVER_USER}/.ssh ;  /bin/chmod 700 /root/.ssh" 
			/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp ${OPTIONS} ${BUILD_KEY}.pub ${CLOUDHOST_USERNAME}@${private_ip}:/root/.ssh/authorized_keys 
			/usr/bin/sshpass -p ${CLOUDHOST_PASSWORD} /usr/bin/scp ${OPTIONS} ${BUILD_KEY}.pub ${CLOUDHOST_USERNAME}@${private_ip}:/home/${SERVER_USER}/.ssh/authorized_keys
		fi
	elif ( [ "${connected}" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: ${webserver_name} Perfoming an regular (non sshpass) style connection machine setup during a webserver build from backup" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

		/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /bin/mkdir -p /home/${SERVER_USER}/.ssh"
		/bin/cat ${BUILD_KEY}.pub | /usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /bin/chmod 777 /home/${SERVER_USER}/.ssh ; /bin/cat - >> /home/${SERVER_USER}/.ssh/authorized_keys ; ${SUDO} /bin/chmod  700 /home/${SERVER_USER}/.ssh"
		
		if ( [ "${DEFAULT_USER}" = "root" ] )
		then
			/bin/cat ${BUILD_KEY}.pub | /usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /bin/chmod 777 /root/.ssh ; /bin/cat - >> /root/.ssh/authorized_keys ; ${SUDO} /bin/chmod 700 /root/.ssh"
		else
			/bin/cat ${BUILD_KEY}.pub | /usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${SUDO} /bin/chmod 777 /home/${DEFAULT_USER}/.ssh ; /bin/cat - >> /home/${DEFAULT_USER}/.ssh/authorized_keys ; ${SUDO} /bin/chmod 700 /home/${DEFAULT_USER}/.ssh"
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
	/bin/echo "${0} `/bin/date`: Failed to contact newly provisioned webserver machine with ip address ${ip} will be destroyed and released" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	exit    
fi

if ( [ ! -d ${HOME}/runtime/webserverbackup ] )
then
	/bin/mkdir ${HOME}/runtime/webserverbackup
fi

validbackup="0"
count="0"
while ( [ "${validbackup}" = "0" ] && [ "${count}" -lt "5" ] )
do
	if ( [ ! -f ${HOME}/runtime/webserverbackup/backup.tgz ] || [ -f ${HOME}/runtime/webserverbackup/BACKUP_DOWNLOADING ] )
	then
		if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh webserverbackup/backup.tgz`" = "" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "FAILED TO FIND BACKUP ARCHIVE" "Couldn't find the entire machine backup archive in the config datastore" "ERROR"
			/bin/echo "${0} `/bin/date`: Failed to find a valid machine backup archive in config datastore" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
			${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
			exit
		else
			if ( [ ! -f ${HOME}/runtime/webserverbackup/BACKUP_DOWNLOADING ] )
			then
				/bin/echo "${0} `/bin/date`: Downloading backup image to restore from datastore for this machine" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
				/bin/touch ${HOME}/runtime/webserverbackup/BACKUP_DOWNLOADING
				${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh webserverbackup/backup.tgz ${HOME}/runtime/webserverbackup/backup.tgz
				/bin/rm ${HOME}/runtime/webserverbackup/BACKUP_DOWNLOADING
			else
			   count="0"
			   while ( [ -f ${HOME}/runtime/webserverbackup/BACKUP_DOWNLOADING ] && [ "${count}" -lt "30" ] )
			   do
				   count="`/usr/bin/expr ${count} + 1`"
				   /bin/sleep 10
			   done
			   if ( [ "${count}" -eq "30" ] )
			   then
				   ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO GET BACKUP FILE" "Couldn't find the backup file on the file system" "ERROR"
				   /bin/echo "${0} `/bin/date`: Failed to find a valid backup in config datastore during a build from backup attempt" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
				   ${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
				   exit
			   fi
			fi
		fi
	fi
	count="0"
	/bin/echo "${0} `/bin/date`: Performing checksum on downloaded backup" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	if ( [ ! -f ${HOME}/runtime/webserverbackup/checksum.dat ] )
	then
		if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh webserverbackup/checksum.dat`" = "" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "FAILED TO FIND CHECKSUM FILE" "Couldn't find the checksum file of the entire machine backup archive in the config datastore" "ERROR"
		fi
		${HOME}/providerscripts/datastore/configwrapper/GetFromConfigDatastore.sh webserverbackup/checksum.dat ${HOME}/runtime/webserverbackup/checksum.dat
	fi

	if ( [ -f ${HOME}/runtime/webserverbackup/backup.tgz ] && [ -f ${HOME}/runtime/webserverbackup/checksum.dat ] )
	then
		if ( [ ! -f ${HOME}/runtime/webserverbackup/newchecksum.dat ] || [ ! -f ${HOME}/runtime/webserverbackup/GENERATING_SHA_SUM ] )
		then
			/bin/touch ${HOME}/runtime/webserverbackup/GENERATING_SHA_SUM
			/usr/bin/sha512sum ${HOME}/runtime/webserverbackup/backup.tgz | /usr/bin/tee ${HOME}/runtime/webserverbackup/newchecksum.dat
			/bin/rm ${HOME}/runtime/webserverbackup/GENERATING_SHA_SUM
		elif ( [ -f ${HOME}/runtime/webserverbackup/GENERATING_SHA_SUM ] )
		then
			loop="0"
			while ( [ -f ${HOME}/runtime/webserverbackup/GENERATING_SHA_SUM ] && [ "${loop}" -lt "20" ] )
			do
				/bin/sleep 10
				loop="`/usr/bin/expr ${loop} + 1`"
			done
			if ( [ "${loop}" -eq "20" ] )
			then
				${HOME}/providerscripts/email/SendEmail.sh "FAILED TO OBTAIN SHA SUM" "Couldn't obtain the SHA sum of the backup file obtained from the config datastore" "ERROR"
				/bin/echo "${0} `/bin/date`: Failed to calculate SHA Sum for the backup file obtain from the config datastore" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
				${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
				exit
			fi
		fi

		if ( [ ! -f ${HOME}/runtime/webserverbackup/checksum.dat ] || [ ! -f ${HOME}/runtime/webserverbackup/newchecksum.dat ] )
		then
			validbackup="0"
		elif ( [ "`/usr/bin/awk '{print $1}' ${HOME}/runtime/webserverbackup/checksum.dat`" = "`/usr/bin/awk '{print $1}' ${HOME}/runtime/webserverbackup/newchecksum.dat`" ] )
		then
		  /bin/echo "${0} `/bin/date`: Found a valid backup during a build from backup attempt of machine" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		   validbackup="1"
		else 
		   /bin/echo "${0} `/bin/date`: Havent found a valid backup (attempt ${count}) during a build from backup attempt" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		   validbackup="0"
		fi
		count="`/usr/bin/expr ${count} + 1`"  
	fi
done

if ( [ "${validbackup}" = "0" ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "COULDN'T DOWNLOAD BACKUP" "Couldn't download backup on autoscaler ${autoscaler_name}" "ERROR"
	${HOME}/providerscripts/email/SendEmail.sh "FAILED TO BUILD/PROVISION A WEBSERVER" "Webserver with ip ${ip} failed to provision" "ERROR"
	/bin/echo "${0} `/bin/date`: Failed to find a valid backup during a build from backup attempt will have to destroy machine with ip address ${ip} and exit" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	exit
fi

/bin/echo "${0} `/bin/date`: It looks good so far, will down copy our machine backup to the candidate webserver machine, verify its checksum and extract it" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/runtime/webserverbackup/backup.tgz ${DEFAULT_USER}@${private_ip}:/tmp/backup.tgz
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/runtime/webserverbackup/checksum.dat ${DEFAULT_USER}@${private_ip}:/tmp/checksum.dat 
/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/autoscaler/buildmethods/CheckSumValidator.sh ${DEFAULT_USER}@${private_ip}:/tmp/CheckSumValidator.sh
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/mkdir -p ${HOME}/runtime ; ${CUSTOM_USER_SUDO} /bin/touch ${HOME}/runtime/BUILD_IN_PROGRESS"
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /usr/bin/sha512sum /tmp/backup.tgz | /usr/bin/tee /tmp/newchecksum.dat"

count="0"
while ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/sh /tmp/CheckSumValidator.sh"`" != "1" ] && [ "${count}" -lt "5" ] )
do
	/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/runtime/webserverbackup/backup.tgz ${DEFAULT_USER}@${private_ip}:/tmp/backup.tgz
	/usr/bin/scp -i ${BUILD_KEY} ${OPTIONS} ${HOME}/runtime/webserverbackup/checksum.dat ${DEFAULT_USER}@${private_ip}:/tmp/checksum.dat 
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /usr/bin/sha512sum /tmp/backup.tgz | /usr/bin/tee /tmp/newchecksum.dat"
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /usr/bin/awk '{print $1}' /tmp/newchecksum.dat | /usr/bin/tee /tmp/checksumtoken.dat"
	count="`/usr/bin/expr ${count} + 1`"
	/bin/sleep 20
done

if ( [ "${count}" = "5" ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "FAILED TO EXTRACT BACKUP ACRHIVE" "The backup acrhive failed its checksum verification checks" "ERROR"
	/bin/echo "${0} `/bin/date`: Failed to build webserver from backup because of failed checksum verification checks" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	exit
else
   /bin/echo "${0} `/bin/date`: All checksum tests passed by the candidate webserver during a 'build from backup' attempt" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
fi
	
count="0"
/bin/echo "${0} `/bin/date`: Now extracting or verfied backup on webserver with private ip address (${private_ip}), please wait" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
command="${CUSTOM_USER_SUDO} /bin/tar xvfz /tmp/backup.tgz -C / --exclude='root/.ssh/authorized_keys' 2>/dev/null"
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${command}"
while ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/ls /extractionmarker/extractedsuccessfully 2>/dev/null"`" = "" ] && [ "${count}" -lt "5" ] )
do 
	count="`/usr/bin/expr ${count} + 1`"
	/bin/sleep 20
	/bin/echo "${0} `/bin/date`: Trying another time (extraction attempt no ${count} to extract backup archive on candidate webserver because of a previously failed attempt with private ip address  (${private_ip}). This is attempt (${count})" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${command}"
done
	
if ( [ "`/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/ls /extractionmarker/extractedsuccessfully 2>/dev/null"`" = "" ] || [ "${count}" -eq "5" ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "FAILED TO EXTRACT BACKUP ACRHIVE" "The backup archive failed its verification checks" "ERROR"
	/bin/echo "${0} `/bin/date`: Failed to build webserver from backup because of failed verification that the backup really did extract correctly onto candidate webserver machine" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/bin/echo "${0} `/bin/date`: Destroying machine with ip address ${ip} and exiting to maybe try again another day" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	exit
fi

/bin/echo "${0} `/bin/date`: Fiddling about with candidate webserver to bring it up fully live" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/rm -r /extractionmarker ; ${CUSTOM_USER_SUDO} /bin/mkdir /run/php"
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/providerscripts/utilities/InitialiseHostname.sh 2>/dev/null"
/usr/bin/ssh -i ${BUILD_KEY} ${OPTIONS} ${DEFAULT_USER}@${private_ip} "${CUSTOM_USER_SUDO} DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get  -o DPkg::Lock::Timeout=-1 -qq -y install ssh ; ${CUSTOM_USER_SUDO} /bin/rm /home/${SERVER_USER}/runtime/FIREWALL-ACTIVE ; ${CUSTOM_USER_SUDO} /home/${SERVER_USER}/security/SetupFirewall.sh  ; ${CUSTOM_USER_SUDO} /etc/init.d/cron start ; ${CUSTOM_USER_SUDO} /usr/sbin/shutdown -r now"

#/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /usr/sbin/shutdown -r now"

/bin/echo "${0} `/bin/date`: ssh port has now changed from 22 to ${SSH_PORT} for private ip address ${private_ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
/bin/echo "${0} `/bin/date`: attempting to contact machine with private ${private_ip} on new port ${SSH_PORT}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log


/bin/echo "${0} `/bin/date`: Waiting for candidate webserver to become responsive on its newly allocated SSH port" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

count="0"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS1} ${SERVER_USER}@${private_ip} "/bin/touch /tmp/alive.$$"

while ( [ "`/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS1} ${SERVER_USER}@${private_ip} "/bin/ls /tmp/alive.$$ 2>/dev/null"`" = "" ] && [ "${count}" -lt "10" ] )
do
	/bin/sleep 20
	count="`/usr/bin/expr ${count} + 1`"
	/bin/echo "${0} `/bin/date`: still attempting to contact machine with private ${private_ip} on new port ${SSH_PORT}, this is attempt ${count}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS1} ${SERVER_USER}@${private_ip} "/bin/touch /tmp/alive.$$"
done

if ( [ "${count}" = "10" ] )
then
	${HOME}/providerscripts/email/SendEmail.sh "COULDN'T CONNECT TO A VERIFY WEBSERVER" "For some reason, autoscaler ${autoscaler_name} couldn't verify the completed build of webserver ${webserver_name}" "ERROR"
	/bin/echo "${0} `/bin/date`: Couldn't connect with machine with private ip address ${private_ip} after SSH port change" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	exit
fi

/bin/echo "${0} `/bin/date`: Checking that php and ${WEBSERVER_CHOICE} can be started correctly post installation on machine with private ip address ${private_ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /home/${SERVER_USER}/providerscripts/webserver/CheckWebserverIsUp.sh ${WEBSERVER_CHOICE}"

/bin/echo "${0} `/bin/date`:  Updating some configuration values locally (the autoscaler) and remotely (the webserver) - ${private_ip})" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

#Mark this as an autoscaled machine as distinct from one built during the initial build
${HOME}/providerscripts/utilities/StoreConfigValueWebserver.sh "AUTOSCALED" "1"
	
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh MYPUBLICIP ${WS_PUBLIC_IP}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh MYIP ${WSIP}"
/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/StoreConfigValue.sh SNAPPED '0'"

/bin/echo "${0} `/bin/date`: Syncing the latest application sourcecode (a backup image might be weeks old and our application has likely moved on) on machine with private ip address (${private_ip})" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/usr/bin/ssh -i ${BUILD_KEY} -p ${SSH_PORT} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/application/SyncLatestApplication.sh" 1>&2 >/dev/null

/bin/echo "${0} `/bin/date`: Rebooting the machine because, frankly, who doesn't love a reboot from time to time" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
