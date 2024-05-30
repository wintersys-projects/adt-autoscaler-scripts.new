#!/bin/sh
######################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This will setup the configuration file for the current cloudhost cli tool
# a template is held in the configfiles subdirectory if needed with placeholders that
# this script replaces with "live" values. If there is a change to the format that a
# later version of the current cli tool needs needs then the template in the "configfiles"
# subdirectory will have to be updated to reflect the needed changes. 
# I did some experimenting and this was the easiest and cleanest way I could come up
# with for generating these configuration files. 
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
###################################################################################
###################################################################################
#set -x

export HOME="`/bin/cat /home/homedir.dat`"

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"

if ( [ "${CLOUDHOST}" = "digitalocean" ] )
then
	TOKEN="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'TOKEN'`"
	
	if ( [ -f ${HOME}/.config/doctl/config.yaml ] )
	then
		/bin/rm ${HOME}/.config/doctl/config.yaml
	fi
	
	/bin/echo "${0} Configuring Digital Ocean CLI tool" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

	if ( [ ! -d ${HOME}/.config/doctl ] )
	then
		/bin/mkdir -p ${HOME}/.config/doctl
	fi
	
	/bin/cp ${HOME}/providerscripts/cloudhost/configfiles/digitalocean/digitalocean.tmpl ${HOME}/.config/doctl/config.yaml

	if ( [ "${TOKEN}" != "" ] )
	then
		/bin/sed -i "s/XXXXTOKENXXXX/${TOKEN}/" ${HOME}/.config/doctl/config.yaml
	else 
		/bin/echo "${0} Couldn't find your digital ocean account personal access token in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ ! -d /root/.config/doctl ] )
	then
		/bin/mkdir -p /root/.config/doctl
	fi
	
	/bin/cp ${HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml
	/bin/chown root:root ${HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml
	/bin/chmod 400 ${HOME}/.config/doctl/config.yaml /root/.config/doctl/config.yaml

fi

if ( [ "${CLOUDHOST}" = "exoscale" ] )
then
	CLOUDHOST_ACCOUNT_ID="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOSTACCOUNTID'`"
	REGION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"
	ACCESS_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ACCESSKEY'`"
	SECRET_KEY="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SECRETKEY'`"
	
	if ( [ -f ${HOME}/.config/exoscale/exoscale.toml ] )
	then
		/bin/rm ${HOME}/.config/exoscale/exoscale.toml
	fi

	/bin/echo "${0} Configuring Exoscale CLI tool" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

	if ( [ ! -d ${HOME}/.config/exoscale ] )
	then
		/bin/mkdir -p ${HOME}/.config/exoscale
	fi

	/bin/cp ${HOME}/providerscripts/cloudhost/configfiles/exoscale/exoscale.tmpl  ${HOME}/.config/exoscale/exoscale.toml

	if ( [ "${CLOUDHOST_ACCOUNT_ID}" != "" ] )
	then
		/bin/sed -i "s/XXXXCLOUDEMAILADDRESSXXXX/${CLOUDHOST_ACCOUNT_ID}/" ${HOME}/.config/exoscale/exoscale.toml
	else 
		/bin/echo "${0} Couldn't find your exoscale cloud email address in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ "${REGION}" != "" ] )
	then
		/bin/sed -i "s/XXXXREGIONXXXX/${REGION}/" ${HOME}/.config/exoscale/exoscale.toml
	else 
		/bin/echo "${0} Couldn't find your region in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ "${ACCESS_KEY}" != "" ] )
	then
		/bin/sed -i "s/XXXXACCESSKEYXXXX/${ACCESS_KEY}/" ${HOME}/.config/exoscale/exoscale.toml
	else 
		/bin/echo "${0} Couldn't find your access key in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ "${SECRET_KEY}" != "" ] )
	then
		/bin/sed -i "s/XXXXSECRETKEYXXXX/${SECRET_KEY}/" ${HOME}/.config/exoscale/exoscale.toml
	else 
		/bin/echo "${0} Couldn't find your secret key in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ ! -d /root/.config/exoscale ] )
	then
		/bin/mkdir -p /root/.config/exoscale
	fi
	
	/bin/cp ${HOME}/.config/exoscale/exoscale.toml /root/.config/exoscale/exoscale.toml
	/bin/chown root:root${HOME}/.config/exoscale/exoscale.toml /root/.config/exoscale/exoscale.toml
	/bin/chmod 400 ${HOME}/.config/exoscale/exoscale.toml /root/.config/exoscale/exoscale.toml

fi

if ( [ "${CLOUDHOST}" = "linode" ] )
then

	CLOUDHOST_ACCOUNT_ID="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOSTACCOUNTID'`"
	TOKEN="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'TOKEN'`"
	REGION="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'REGION'`"

	if ( [ -f ${HOME}/.config/linode-cli ] )
	then
		/bin/rm ${HOME}/.config/linode-cli
	fi
		
	if ( [ ! -d ${HOME}/.config ] )
	then
		/bin/mkdir ${HOME}/.config
	fi

	/bin/echo "${0} Configuring Linode CLI tool" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log

	/bin/cp ${HOME}/providerscripts/cloudhost/configfiles/linode/linode-cli.tmpl  ${HOME}/.config/linode-cli

	if ( [ "${CLOUDHOST_ACCOUNT_ID}" != "" ] )
	then
		/bin/sed -i "s/XXXXLINODEACCOUNTUSERNAMEXXXX/${CLOUDHOST_ACCOUNT_ID}/" ${HOME}/.config/linode-cli
	else 
		/bin/echo "${0} Couldn't find your linode account username in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ "${TOKEN}" != "" ] )
	then
		/bin/sed -i "s/XXXXTOKENXXXX/${TOKEN}/" ${HOME}/.config/linode-cli
	else 
		/bin/echo "${0} Couldn't find your linode account personal access token in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ "${REGION}" != "" ] )
	then
		/bin/sed -i "s/XXXXREGIONXXXX/${REGION}/" ${HOME}/.config/linode-cli
	else 
		/bin/echo "${0} Couldn't find your region id in your template, will have to exit" >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi

	if ( [ ! -d /root/.config ] )
	then
		/bin/mkdir /root/.config
	fi

	/bin/cp  ${HOME}/.config/linode-cli /root/.config/linode-cli
	/bin/chown root:root /root/.config/linode-cli ${HOME}/.config/linode-cli
	/bin/chmod 400 /root/.config/linode-cli ${HOME}/.config/linode-cli

fi

if ( [ "${CLOUDHOST}" = "vultr" ] )
then
	TOKEN="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'TOKEN'`"

	if ( [ "${TOKEN}" != "" ] )
	then
		export VULTR_API_KEY="${TOKEN}"
		if ( [ ! -d ${HOME}/.config ] )
		then
			/bin/mkdir ${HOME}/.config
		fi
		
		/usr/bin/touch ${HOME}/.config/VULTRAPIKEY:${VULTR_API_KEY}
		/bin/echo "api-key: ${VULTR_API_KEY}" > ${HOME}/.vultr-cli.yaml
		/bin/echo "api-key: ${VULTR_API_KEY}" > /root/.vultr-cli.yaml
		/bin/chown root:root ${HOME}/.vultr-cli.yaml /root/.vultr-cli.yaml
		/bin/chmod 400 ${HOME}/.vultr-cli.yaml /root/.vultr-cli.yaml
	else
		/bin/echo "${0} Couldn't find your vultr API key from your template - will have to exit...." >> ${HOME}/logs/initialbuild/BUILD_PROCESS_MONITORING.log
		exit
	fi
fi
