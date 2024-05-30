#!/bin/sh
####################################################################################################
# Author : Peter Winter
# Date   : 04/07/2016
# Description : This script will build the "autoscaler" from scratch
####################################################################################################
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
#######################################################################################################
#######################################################################################################
#set -x

#Get ourselves oriented and prepared
USER_HOME="`/usr/bin/awk -F: '{ print $1}' /etc/passwd | /bin/grep "X*X"`"
export HOME="/home/${USER_HOME}" | /usr/bin/tee -a ~/.bashrc

#Set the permissions as we want for all the autoscaler infrastructure scripts that we are using
/usr/bin/find ${HOME} -not -path '*/\.*' -type d -print0 | xargs -0 chmod 0755 # for directories
/usr/bin/find ${HOME} -not -path '*/\.*' -type f -print0 | xargs -0 chmod 0500 # for files
/bin/chown ${SERVER_USER}:root ${HOME}/.ssh
/bin/chmod 750 ${HOME}/.ssh

export HOMEDIR=${HOME}
/bin/echo "${HOMEDIR}" > /home/homedir.dat
/bin/echo "export HOME=`/bin/cat /home/homedir.dat` && \"\${1}\" \"\${2}\" \"\${3}\" \"\${4}\" \"\${5}\" \"\${6}\"" > /usr/bin/run
/bin/chmod 755 /usr/bin/run

if ( [ ! -d ${HOME}/logs/initialbuild ] )
then
	/bin/mkdir -p ${HOME}/logs/initialbuild
fi

if ( [ ! -d ${HOME}/super ] )
then
	/bin/mkdir ${HOME}/super
fi

/bin/mv ${HOME}/providerscripts/utilities/Super.sh ${HOME}/super
/bin/chmod 400 ${HOME}/super/Super.sh

if ( [ -f ${HOME}/InstallGit.sh ] )
then
	/bin/rm ${HOME}/InstallGit.sh
fi

out_file="initialbuild/autoscaler-build-out-`/bin/date | /bin/sed 's/ //g'`"
exec 1>>${HOME}/logs/${out_file}
err_file="initialbuild/autoscaler-build-err-`/bin/date | /bin/sed 's/ //g'`"
exec 2>>${HOME}/logs/${err_file}

#Check our params
if ( [ "$1" = "" ] )
then
	/bin/echo "${0} Usage: ./as.sh <server user>" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
	exit
fi

SERVER_USER="${1}"

/bin/echo "${0} `/bin/date`: Beginning the build of the autoscaler" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} `/bin/date`: Building a new webserver" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} `/bin/date`: Setting up the build parameters" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Load the parts of the configuration that we need into memory
WEBSITE_URL="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'WEBSITEURL'`"
CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
INFRASTRUCTURE_REPOSITORY_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYUSERNAME'`"
INFRASTRUCTURE_REPOSITORY_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPASSWORD'`"
INFRASTRUCTURE_REPOSITORY_PROVIDER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYPROVIDER'`"
INFRASTRUCTURE_REPOSITORY_OWNER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'INFRASTRUCTUREREPOSITORYOWNER'`"
GIT_EMAIL_ADDRESS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITEMAILADDRESS'`"
DNS_USERNAME="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSUSERNAME'`"
DNS_SECURITY_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DNSSECURITYKEY'`"
SERVER_TIMEZONE_CONTINENT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECONTINENT'`"
SERVER_TIMEZONE_CITY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERTIMEZONECITY'`"
BUILDOS="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDOS'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"

#Non standard variable assignments
ROOT_DOMAIN="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{$1=""}1' | /bin/sed 's/^ //g' | /bin/sed 's/ /./g'`"
GIT_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'GITUSER'  | /bin/sed 's/#/ /g'` "
WEBSITE_NAME="`/bin/echo ${WEBSITE_URL} | /usr/bin/awk -F'.' '{print $2}'`"

#Record what everything has actually been set to in case there is a problem...
/bin/echo "##################BUILD ENVIRONMENT SETTINGS#######################" > ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "CLOUDHOST:${CLOUDHOST}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "WEBSITE_URL:${WEBSITE_URL}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "INFRASTRUCTURE_REPOSITORY_PROVIDER:${INFRASTRUCTURE_REPOSITORY_PROVIDER}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "INFRASTRUCTURE_REPOSITORY_USERNAME:${INFRASTRUCTURE_REPOSITORY_USERNAME}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "INFRASTRUCTURE_REPOSITORY_PASSWORD:${INFRASTRUCTURE_REPOSITORY_PASSWORD}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "INFRASTRUCTURE_REPOSITORY_OWNER:${INFRASTRUCTURE_REPOSITORY_OWNER}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "GIT_EMAIL_ADDRESS:${GIT_EMAIL_ADDRESS}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "SERVER_TIMEZONE_CONTINENT:${SERVER_TIMEZONE_CONTINENT}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "SERVER_TIMEZONE_CITY:${SERVER_TIMEZONE_CITY}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "SSH_PORT:${SSH_PORT}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "GIT_USER:${GIT_USER}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "WEBSITE_NAME:${WEBSITE_NAME}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "ROOT_DOMAIN:${ROOT_DOMAIN}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "BUILDOS:${BUILDOS}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "DNS_USERNAME:${DNS_USERNAME}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "DNS_SECURITY_KEY:${DNS_SECURITY_KEY}" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "##################BUILD ENVIRONMENT SETTINGS#######################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Create the config directories, these will be mounted from the autoscaler to the other server types - DB, WS and Images Servers
if ( [ ! -d ${HOME}/.ssh ] )
then
	/bin/mkdir ${HOME}/.ssh
	/bin/chmod 700 ${HOME}/.ssh
fi

if ( [ ! -d ${HOME}/runtime ] )
then
	/bin/mkdir -p ${HOME}/runtime
	/bin/chown ${SERVER_USER}:${SERVER_USER} ${HOME}/runtime
	/bin/chmod 755 ${HOME}/runtime
fi

#Initialise Git
/usr/bin/git config --global user.name "${GIT_USER}"
/usr/bin/git config --global user.email ${GIT_EMAIL_ADDRESS}
/usr/bin/git config --global init.defaultBranch main
/usr/bin/git config --global pull.rebase false 

#Set the hostname of this machine
. ${HOME}/providerscripts/utilities/InitialiseHostname.sh

#Some kernel safeguards
/bin/echo "vm.panic_on_oom=1
kernel.panic=10" >> /etc/sysctl.conf

#Install the programs that we need to use when building the autoscaler

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Installing software packages "
/bin/echo "${0} `/bin/date`: Installing Software packages" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

>&2 /bin/echo "${0} Update.sh"
${HOME}/installscripts/Update.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallUFW.sh"
${HOME}/installscripts/InstallUFW.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallCurl.sh"
${HOME}/installscripts/InstallCurl.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallSSHPass.sh"
${HOME}/installscripts/InstallSSHPass.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallBC.sh"
${HOME}/installscripts/InstallBC.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallJQ.sh"
${HOME}/installscripts/InstallJQ.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallSendEmail.sh"
${HOME}/installscripts/InstallSendEmail.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallLibioSocket.sh"
${HOME}/installscripts/InstallLibioSocket.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallLibnetSsleay.sh"
${HOME}/installscripts/InstallLibnetSsleay.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallSysStat.sh"
${HOME}/installscripts/InstallSysStat.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallRsync.sh"
${HOME}/installscripts/InstallRsync.sh ${BUILDOS}
>&2 /bin/echo "${0} InstallCron.sh"
${HOME}/installscripts/InstallCron.sh ${BUILDOS}
>&2 /bin/echo "${0} Install Monitoring Gear"
${HOME}/installscripts/InstallMonitoringGear.sh

#Configure the timezone we are in
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Setting up timezone"
/bin/echo "${0} `/bin/date`: Setting timezone" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Set the time on the machine
if ( [ "`/usr/bin/timedatectl list-timezones | /bin/grep ${SERVER_TIMEZONE_CONTINENT} | /bin/grep ${SERVER_TIMEZONE_CITY}`" != "" ] )
then
	/usr/bin/timedatectl set-timezone ${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}
	${HOME}/providerscripts/utilities/StoreConfigValue.sh "SERVERTIMEZONECONTINENT" "${SERVER_TIMEZONE_CONTINENT}"
	${HOME}/providerscripts/utilities/StoreConfigValue.sh "SERVERTIMEZONECITY" "${SERVER_TIMEZONE_CITY}"
	export TZ=":${SERVER_TIMEZONE_CONTINENT}/${SERVER_TIMEZONE_CITY}"
fi

#Redimentary check to make sure all the software we require installed
if ( [ -f /usr/bin/curl ] && [ -f /usr/sbin/ufw ] && [ -f /usr/bin/sshpass ] && [ -f /usr/bin/bc ] && [ -f /usr/bin/jq ] )
then
	/bin/echo "${0} `/bin/date` : It seems like all the required software has been installed correctly" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
else
	/bin/echo "${0} `/bin/date` : It seems like the required software hasn't been installed correctly" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
	exit
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Installing cloudtools"
/bin/echo "${0} `/bin/date`: Installing cloudtools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Install the tools for our particular cloudhost provider
${HOME}/installscripts/InstallCloudhostTools.sh
${HOME}/providerscripts/cloudhost/InitialiseCloudhostConfig.sh

cd ${HOME}

/bin/echo "ServerAliveInterval 15" | /usr/bin/tee ${HOME}/.ssh/config  /root/.ssh/config 
/bin/echo "ServerAliveCountMax 6" | /usr/bin/tee -a ${HOME}/.ssh/config  /root/.ssh/config 

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Setting up the script which allows us to root"
/bin/echo "${0} `/bin/date`: Setting up the script which allows us to root" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Installing Datastore tools"
/bin/echo "${0} `/bin/date`: Installing Datastore tools" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
#Install the S3 compatible service we are using
. ${HOME}/installscripts/InstallDatastoreTools.sh
. ${HOME}/providerscripts/datastore/InitialiseDatastoreConfig.sh

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Disabling password authentication"
/bin/echo "${0} `/bin/date`: Disabling password authentication" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

/bin/sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
/bin/sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Changing our preferred SSH port"
/bin/echo "${0} `/bin/date`: Changing to our preferred SSH port" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

if ( [ -f /etc/systemd/system/ssh.service.d/00-socket.conf ] )
then
	/bin/rm /etc/systemd/system/ssh.service.d/00-socket.conf
	/bin/systemctl daemon-restart
fi

/bin/systemctl disable --now ssh.socket
/bin/systemctl enable --now ssh.service

if ( [ "`/bin/grep '^#Port' /etc/ssh/sshd_config`" != "" ] || [ "`/bin/grep '^Port' /etc/ssh/sshd_config`" != "" ] )
then
	/bin/sed -i "s/^Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
	/bin/sed -i "s/^#Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
else
	/bin/echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Preventing root logins"
/bin/echo "${0} `/bin/date`: Preventing root logins" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Double down on preventing logins as root. We already tried, but, make absolutely sure because we can't guarantee format of /etc/ssh/sshd_config
if ( [ "`/bin/grep '^#PermitRootLogin' /etc/ssh/sshd_config`" != "" ] || [ "`/bin/grep '^PermitRootLogin' /etc/ssh/sshd_config`" != "" ] )
then
	/bin/sed -i "s/^PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config
	/bin/sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config
else
	/bin/echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Ensuring SSH connections are long lasting"
/bin/echo "${0} `/bin/date`: Ensuring SSH connections are long lasting" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Make sure that client connections to sshd are long lasting
if ( [ "`/bin/grep 'ClientAliveInterval 200' /etc/ssh/sshd_config 2>/dev/null`" = "" ] )
then
	/bin/echo "
ClientAliveInterval 200
ClientAliveCountMax 10" >> /etc/ssh/sshd_config
fi

/usr/sbin/service sshd restart

DEVELOPMENT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'DEVELOPMENT'`"
PRODUCTION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'PRODUCTION'`"

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Initialising Cron"
/bin/echo "${0} `/bin/date`: Initialising cron" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

#Initialise the cron scripts. If you want to add cron jobs, modify this script to include them
. ${HOME}/cron/InitialiseCron.sh

#/bin/chown -R ${SERVER_USER}:${SERVER_USER} ${HOME}

/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
>&2 /bin/echo "${0} Setting up the firewall and then rebooting for hygiene"
/bin/echo "${0} `/bin/date`: Rebooting the autoscaler post installation" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
/bin/echo "${0} #######################################################################################" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

${HOME}/security/SetupFirewall.sh

${HOME}/providerscripts/email/SendEmail.sh "A NEW AUTOSCALER HAS BEEN SUCCESSFULLY BUILT" "A new autoscaler machine has been built and is now going to reboot before coming available" "INFO"

/bin/touch ${HOME}/runtime/DONT_MESS_WITH_THESE_FILES-SYSTEM_BREAK

/bin/touch ${HOME}/runtime/AUTOSCALER_READY

/usr/sbin/shutdown -r now
