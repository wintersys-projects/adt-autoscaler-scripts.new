#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This script will build a webserver from scratch in response to an autoscaling event
# It depends on the provider scripts and will build according to the provider it is configured for
# If we are configured to use snapshots, then the build will be completed using a snapshot (which
# must exist) otherwise, we perform a vanilla build of our webserver from scratch. A build can 
# also be made from a backup and all you have to do to use this option is set the value
# AUTOSCALE_FROM_BACKUP to "1" and the build process will generate an entire machine backup on 
# the first webserver that is built and all subsequent webseervers will not be directly installed
# but rather extracted from that backup which is a faster way to get your webservers online
# during autoscaling processes.
# With each of these three methods, there are advantages and disadvantages and it just depends
# what suits you
##############################################################################################
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
#############################################################################################
#############################################################################################
set -x

cleanup() {

	if ( [ -f ${HOME}/runtime/AUTOSCALINGMONITOR:${1} ] )
	then
		if ( [ "${2}" = "successfully" ] )
		then
			/bin/echo "${0} `/bin/date`: Build no ${1} has been completed ${2}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		else
			/bin/echo "${0} `/bin/date`: Build no ${1} has been completed unsuccessfully - due to a raised trap condition" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		fi
		/bin/rm ${HOME}/runtime/AUTOSCALINGMONITOR:${1}
	fi
 
}

#If we are trying to build a webserver before the toolkit has been fully installed, we don't want to do anything, so exit
if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "INSTALLEDSUCCESSFULLY"`" = "0" ] )
then
	exit
fi

buildno="${1}"
trap "cleanup ${buildno}" TERM
start=`/bin/date +%s`

ASIP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASIP'`"
if ( [ "${ASIP}" = "" ] )
then 
	if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerip/* | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`" = "1" ] )
	then
		ASIP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerip/*`"
	else
		ASIP="multiple"
	fi
fi

AS_PUBLIC_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASPUBLICIP'`"
if ( [ "${AS_PUBLIC_IP}" = "" ] )
then
	if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerpublicip/* | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`" = "1" ] )
	then
		AS_PUBLIC_IP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh autoscalerpublicip/*`"
	else
		AS_PUBLIC_IP="multiple"
	fi
fi

SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
DEFAULT_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DEFAULTUSER'`"

if ( [ "${DEFAULT_USER}" = "root" ] )
then
	SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
else
	SUDO="DEBIAN_FRONTEND=noninteractive /usr/bin/sudo -S -E "
fi
CUSTOM_USER_SUDO="DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "
OPTIONS=" -o ConnectTimeout=10 -o ConnectionAttempts=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
OPTIONS1=" -o ConnectTimeout=10 -o ConnectionAttempts=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "

#Check there is a directory for logging
logdate="`/usr/bin/date | /usr/bin/awk '{print $1 $2 $3 $NF}'`"
logdir="scaling-events-`/usr/bin/date | /usr/bin/awk '{print $1,$2,$3}' | /bin/sed 's/ //g'`"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
	/bin/mkdir -p ${HOME}/logs/${logdir}
fi

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
	/bin/mkdir -p ${HOME}/logs/${logdir}
fi

if ( [ ! -d ${HOME}/runtime/beingbuiltips ] )
then
	/bin/mkdir -p ${HOME}/runtime/beingbuiltips
fi

if ( [ ! -d ${HOME}/runtime/beingbuiltpublicips ] )
then
	/bin/mkdir -p ${HOME}/runtime/beingbuiltpublicips
fi

ip=""

#Pull the configuration into memory for easy access
KEY_ID="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'KEYID'`"
BUILD_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCHOICE'`"
BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
REGION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
SIZE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SIZE'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
DNS_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSCHOICE'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValues.sh 'DNSSECURITYKEY' stripped | /bin/sed 's/ /:/g'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSUSERNAME'`"
GIT_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITUSER'`"
GIT_EMAIL_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
APPLICATION_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPROVIDER'`"
APPLICATION_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYOWNER'`"
APPLICATION_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYUSERNAME'`"
APPLICATION_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYPASSWORD'`"
APPLICATION_REPOSITORY_TOKEN="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONREPOSITORYTOKEN'`"
CLOUDHOST_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOSTUSERNAME'`"
CLOUDHOST_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOSTPASSWORD'`"
BUILD_ARCHIVE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDARCHIVECHOICE'`"
DATASTORE_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DATASTORECHOICE'`"
WEBSERVER_CHOICE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSERVERCHOICE'`"
APPLICATION_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONIDENTIFIER'`"
APPLICATION_LANGUAGE="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONLANGUAGE'`"
SOURCECODE_REPOSITORY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'APPLICATIONBASELINESOURCECODEREPOSITORY'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
DB_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPORT'`"
BUILD_CLIENT_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDCLIENTIP'`"
PERSIST_ASSETS_TO_CLOUD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'PERSISTASSETSTOCLOUD'`"
DIRECTORIES_TO_MOUNT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DIRECTORIESTOMOUNT'`"

BUILD_KEY="${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER}"

DBIP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBIP'`"

if ( [ "${DBIP}" = "" ] )
then
	 DBIP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"databaseip/*\"`"
fi

DB_PUBLIC_IP="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DBPUBLICIP'`"

if ( [ "${DB_PUBLIC_IP}" = "" ] )
then
	 DB_PUBLIC_IP="`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"databasepublicip/*\"`"
fi

ASIPS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASIPS'`"

if ( [ "${ASIPS}" = "" ] )
then
	
	for ipaddress in "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"autoscalerpublicip/*\"`"
	do
		ASIPS=${ASIPS}:${ipaddress}
	done
	
	ASIPS="`/bin/echo ${ASIPS} | /bin/sed 's/^://g'`"
fi

ASIP_PRIVATES="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ASIP_PRIVATES'`"

if ( [ "${ASIP_PRIVATES}" = "" ] )
then
	for ipaddress in "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh \"autoscalerip/*\"`"
	do
		ASIP_PRIVATES=${ASIP_PRIVATES}:${ipaddress}
	done
	ASIP_PRIVATES="`/bin/echo ${ASIP_PRIVATES} | /bin/sed 's/^://g'`"
fi

z="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
name="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $1}'`"

# Set up the webservers properties, like its name and so on.
rnd="`/usr/bin/openssl rand -base64 32 | /usr/bin/tr -cd 'a-zA-Z0-9' | /usr/bin/cut -b 1-4`"
server_type="webserver"
autoscalerip="`/bin/hostname -I | /usr/bin/awk '{print $1}'`"
autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscalerip} ${CLOUDHOST}`"
autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $2}'`"
webserver_name="webserver-${autoscaler_no}-${rnd}-`/bin/echo ${BUILD_IDENTIFIER} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
server_instance_name="`/bin/echo ${webserver_name} | /usr/bin/cut -c -32 | /bin/sed 's/-$//g'`"

logdir="${logdir}/${webserver_name}"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
	/bin/mkdir -p ${HOME}/logs/${logdir}
fi

#The log files for the server build are written here...
log_file="webserver_out_`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${logdir}/${log_file}
err_file="webserver_err_`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${logdir}/${err_file}


#What type of machine are we building - this will determine the size and so on with the cloudhost
server_type_id="`${HOME}/providerscripts/server/GetServerTypeID.sh ${SIZE} "${server_type}" ${CLOUDHOST}`"

#Hell, what operating system are we running
ostype="`${HOME}/providerscripts/cloudhost/GetOperatingSystemVersion.sh ${SIZE} ${CLOUDHOST}`"

#Attempt to create a vanilla machine on which to build our webserver
#The build method tells us if we are using a snapshot or not

/bin/touch ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock

/bin/echo "${0} `/bin/date`: Spinning up a new webserver with name ${webserver_name}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

count="0"
buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${server_type_id}" "${server_instance_name}" "${KEY_ID}" ${CLOUDHOST} "${DEFAULT_USER}" ${CLOUDHOST_PASSWORD}`"

while ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
do
	/bin/sleep 5
	count="`/usr/bin/expr ${count} + 1`"
	buildmethod="`${HOME}/providerscripts/server/CreateServer.sh "${ostype}" "${REGION}" "${server_type_id}" "${server_instance_name}" "${KEY_ID}" ${CLOUDHOST} "${DEFAULT_USER}" ${CLOUDHOST_PASSWORD}`"
done

if ( [ "${count}" = "10" ] )
then
	/bin/echo "${0} `/bin/date`: Failed to build webserver with name ${server_instance_name} - this is most likely an issue with your provider (${CLOUDHOST}) check their status page" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/usr/bin/kill -TERM $$
fi

count="0"

# There is a delay between the server being created and started and it "coming online". The way we can tell it is online is when
# It returns an ip address, so try, several times to retrieve the ip address of the server
# We are prepared to wait a total of 300 seconds for the machine to come online
while ( [ "`/bin/echo ${ip} | /bin/grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`" = "" ] && [ "${count}" -lt "15" ] || [ "${ip}" = "0.0.0.0" ] )
do
	/bin/sleep 20
	ip="`${HOME}/providerscripts/server/GetServerIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
	WS_PUBLIC_IP="${ip}"
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${ip} webserverpublicips/${ip}
	private_ip="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh ${server_instance_name} ${CLOUDHOST}`"
	WSIP="${private_ip}"
	${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${private_ip} webserverips/${private_ip}
	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${ip}" = "" ] )
then
	#This should never happen, and I am not sure what to do about it if it does. If we don't have an ip address, how can
	#we destroy the machine? I simply exit, therefore.
	/bin/echo "${0} `/bin/date`: The weberver didn't come online" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/usr/bin/kill -TERM $$
else
	/bin/echo "${0} `/bin/date`: The webserver has been assigned public ip address ${ip} and private ip address ${private_ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/bin/echo "${0} `/bin/date`: The webserver is now provisioned and I am about to start building its software" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
fi

/bin/echo "${0} `/bin/date`: Ensuring that the server is attached to the VPC (if one is being used)" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
${HOME}/providerscripts/server/EnsureServerAttachToVPC.sh "${CLOUDHOST}" "${webserver_name}" "${private_ip}"

if ( [ ! -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip} ] )
then
	/bin/touch ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${private_ip}
fi

#We add our IP address to a list of machines in the 'being built' stage. We can check this flag elsewhere when we want to
#distinguish between ip address of webservers which have been built and are still being built.
#The autoscaler monitors for this when it is looking for slow builds. The being built part of things is cleared out when
#we reach the end of the build process so if this persists for an excessive amount of time, the "slow builds" script on the
#autoscaler knows that something is hanging or has gone wrong with the build and it clears things up.

if ( [ ! -d ${HOME}/runtime/beingbuiltips/${buildno} ] )
then
	/bin/mkdir -p ${HOME}/runtime/beingbuiltips/${buildno}
fi

if ( [ ! -d ${HOME}/runtime/beingbuiltpublicips/${buildno} ] )
then
	/bin/mkdir -p ${HOME}/runtime/beingbuiltpublicips/${buildno}
fi

/bin/touch ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}
/bin/touch ${HOME}/runtime/beingbuiltpublicips/${buildno}/${ip}

if ( [ -f ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock ] )
then
	 /bin/rm ${HOME}/runtime/INITIALLY_PROVISIONING-${buildno}.lock
fi

${HOME}/providerscripts/datastore/configwrapper/PutToConfigDatastore.sh ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip} beingbuiltips/

/bin/echo "${0} `/bin/date`: If you are using DBaaS then the DBaaS 'firewall' is being initialised" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

. ${HOME}/providerscripts/security/firewall/TightenDBaaSFirewall.sh

# Build our webserver
if ( [ "`/bin/echo ${buildmethod} | /bin/grep 'SNAPPED'`" = "" ] )
then   
	if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh AUTOSCALEFROMBACKUP:1`" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: Performing a backup style build for this webserver" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		. ${HOME}/autoscaler/buildmethods/BackupBuildMethod.sh
	else
		/bin/echo "${0} `/bin/date`: Performing a regular style build for this webserver" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		. ${HOME}/autoscaler/buildmethods/RegularBuildMethod.sh
	fi
else
	/bin/echo "${0} `/bin/date`: Performing a snapshot style build for this webserver" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	. ${HOME}/autoscaler/buildmethods/SnapshotBuildMethod.sh
fi

/bin/echo "${0} `/bin/date`: The main build has completed now just have to check that it's been dun right" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

#Do some checks to make sure the machine has come online and so on
count="0"
failedintegritycheck="0"
/bin/echo "${0} `/bin/date`: Performing build integrity checks for" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
while ( [ "${count}" -lt "10" ] && [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/CheckServerAlive.sh"`" != "ALIVE" ] )
do
	/bin/sleep 10
	count="`/usr/bin/expr ${count} + 1`"
	/bin/echo "${0} `/bin/date`: Doing build integrity checks for ${ip} attempt ${count}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
done

if ( [ "${count}" = "10" ] )
then
	failedintegritycheck="1"
	${HOME}/providerscripts/email/SendEmail.sh "FAILED INTEGRITY CHECKS" "A webserver (${webserver_name}) being built on autoscaler (${autoscaler_name}) has failed its integrity checks" "ERROR"
	/bin/echo "${0} `/bin/date`: Failed integrity checks for ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
fi

if ( [ "${failedintegritycheck}" = "0" ] )
then
	count="0"
	/bin/echo "${0} `/bin/date`:  Performing post processing for ip address ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/application/processing/PerformPostProcessingByApplication.sh ${SERVER_USER} autoscaled"
	if ( [ "$?" != "0" ] && [ "${count}" -lt "10" ] )
	then
		/bin/sleep 10
		count="`/usr/bin/expr ${count} + 1`"
		/bin/echo "${0} `/bin/date`: Performing post processing for  ${ip} attempt ${count}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/application/processing/PerformPostProcessingByApplication.sh ${SERVER_USER} autoscaled"
	fi

	if ( [ "${count}" = "10" ] )
	then
		${HOME}/providerscripts/email/SendEmail.sh "FAILED TO PERFORM POST PROCESSING" "Post Processing has failed to complete on autoscaler ${autoscaler_name} for webserver ${webserver_name}" "ERROR"
		/bin/echo "${0} `/bin/date`: Post Processing has failed to complete on autoscaler ${autoscaler_name} for webserver ${webserver_name}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	fi
		
	failedmountcheck="0"
	if ( [ "${snapshot_build}" = "0" ] )
	then
		count="0"
		/bin/echo "${0} `/bin/date`: Performing mount checks for ip address ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/datastore/SetupAssetsStore.sh"
		while ( [ "${count}" -lt "10" ] &&  [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/utilities/AreAssetsMounted.sh"`" != "MOUNTED" ] )
		do
			counts="`/usr/bin/expr ${count} + 1`"
			/bin/sleep 10
			/bin/echo "${0} `/bin/date`: Doing mount checks for ${ip} attempt ${count}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
			/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} ${HOME}/providerscripts/datastore/SetupAssetsStore.sh"
		done

		if ( [ "${count}" = "10" ] )
		then
			failedmountcheck="1"
			${HOME}/providerscripts/email/SendEmail.sh "MOUNT CHECKS HAVE BEEN FAILED" "Mount checks have been failed on autoscaler ${autoscaler_name} for webserver ${webserver_name}" "ERROR"
			/bin/echo "${0} `/bin/date`: Failed mount checks for ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log 
		fi
	fi
		
	failedonlinecheck="1"
	if ( [ "${failedmountcheck}" = "0" ] && [ "${failedintegritycheck}" = "0" ] )
	then
	   #Do a check, as best we can to make sure that the website application is actually running correctly
	   count="0"
	   while ( [ "${count}" -lt "10" ] && [ "${failedonlinecheck}" != "0" ] )
	   do
			. ${HOME}/autoscaler/SelectHeadFile.sh

			if ( [ "${failedonlinecheck}" = "1" ] )
			then
				/bin/echo "${0} `/bin/date`: Peforming online checks for ip address ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
				if ( [ "`/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently'`" = "" ] )
				then
					/bin/echo "/usr/bin/curl -I --max-time 60 --insecure https://${private_ip}:443/${headfile} | /bin/grep -E 'HTTP/2 200|HTTP/2 301|HTTP/2 302|HTTP/2 303|200 OK|302 Found|301 Moved Permanently"
					/bin/echo "${0} `/bin/date`: Expecting ${private_ip} to be online, but can't reach it with curl yet...." >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
					count="`/usr/bin/expr ${count} + 1`"
					/bin/echo "${0} `/bin/date`: Doing webserver/application online check for ${ip} attempt ${count}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
					/bin/sleep 20
				else
					/bin/echo "${0} `/bin/date`:  ${ip} is online that's wicked..." >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
					failedonlinecheck="0"
				fi
			fi
		done
		
		if ( [ "${count}" = "10" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "WEBSERVER FAILED TO COME ONLINE" "Online checks have been failed on autoscaler ${autoscaler_name} for webserver ${webserver_name}" "ERROR"
			/bin/echo "${0} `/bin/date`: ${ip} failed to come online" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
			failedonlinecheck="1"
		fi
	fi
fi

if ( [ "${failedintegritycheck}" = "1" ] || [ "${failedmountcheck}" = "1" ] || [ "${failedonlinecheck}" = "1" ] )
then 
	#If any of these are true, then somehow the machine/application didn't come online and so we need to destroy the machine
	if ( [ "${failedintegritycheck}" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: ${ip} failed its integrity check" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	fi
	if ( [ "${failedmountcheck}" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: ${ip} failed its mount check" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
		
	fi
	if ( [ "${failedonlinetcheck}" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: ${ip} failed its online check" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	fi

	/bin/echo "${0} `/bin/date`: ${ip} is being destroyed because it failed one or more validation checks" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	
	${HOME}/providerscripts/server/DestroyServer.sh ${ip} ${CLOUDHOST}
	
	/bin/echo "${0} `/bin/date`: The webserver ${ip} being built in response to a scaling event has failed to build and has had its resources released" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER HAS FAILED TO COME ONLINE" "For some reason, autoscaler provisioned webserver with ip ${ip} failed to provision. You will need to check your logs..." "ERROR"
	/usr/bin/kill -TERM $$
else
	/bin/echo "${0} `/bin/date`: All checks passed for ip address ${ip}" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	. ${HOME}/providerscripts/security/firewall/UpdateNativeFirewall.sh

	#If we got to here then we are a successful build as as best as we can tell, everything is online
	#So, we add the ip address of our new machine to our DNS provider and that machine is then ready
	#to start serving requests
	/bin/echo "${0} `/bin/date`: ${ip} is fully online and it's public ip is being added to the DNS provider" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/bin/echo "${0} `/bin/date`: Adding IP ${ip} to DNS system" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	
	${HOME}/autoscaler/AddIPToDNS.sh ${ip}
	
	/bin/echo "${0} `/bin/date`: The webserver ${ip} has had all its software built and its IP address added to the DNS system ready for use" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
	/bin/echo "${ip}"
fi

/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/touch ${HOME}/runtime/AUTOSCALED_WEBSERVER_ONLINE"
/usr/bin/ssh -p ${SSH_PORT} -i ${BUILD_KEY} ${OPTIONS} ${SERVER_USER}@${private_ip} "${CUSTOM_USER_SUDO} /bin/rm ${HOME}/runtime/BUILD_IN_PROGRESS"
/bin/echo "${0} `/bin/date`: Either way, successful or not the build process for machine with ip: ${ip} has completed" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/bin/echo "${0} `/bin/date`: Deleting the beingbuilt ip address ${private_ip} from the config datastore" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log
${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh  beingbuiltips/${private_ip}
/bin/rm ${HOME}/runtime/beingbuiltips/${buildno}/${private_ip}
/bin/rm ${HOME}/runtime/beingbuiltpublicips/${buildno}/${ip}
	
#Output how long the build took
end=`/bin/date +%s`
runtime="`/usr/bin/expr ${end} - ${start}`"
/bin/echo "${0} This script took `/bin/date -u -d @${runtime} +\"%T\"` to complete and completed at time: `/usr/bin/date`" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

/bin/echo "${0} `/bin/date`: Doing the final cleanup for this webserver's build context" >> ${HOME}/logs/${logdir}/MonitoringWebserverBuildLog.log

trap "cleanup ${buildno} successfully" TERM

/usr/bin/kill -TERM $$
