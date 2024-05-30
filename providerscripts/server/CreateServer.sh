#!/bin/sh
######################################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script spins up a machine of the specified size, name and so on on our chosen provider
# There are two distinct ways that a machine can be built.
# 1) A regular build
# 2) From pre-existing snapshots.
# It depends on whether the provider supports snapshots as to whether we can use option 2 or not
#######################################################################################################
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

export HOME="`/bin/cat /home/homedir.dat`"

os_choice="${1}"
region="${2}"
server_size="${3}"
server_name="${4}"
key_id="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/DROPLET ] || [ "${cloudhost}" = "digitalocean" ] )
then
	snapshotid="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

	if ( [ "${snapshotid}" = "" ] )
	then
		${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
	fi

	vpc_id="`/usr/local/bin/doctl vpcs list  | /bin/grep "adt-vpc" | /bin/grep "${region}" | /usr/bin/awk '{print $1}'`"

	#Digital ocean supports snapshots so, we test to see if we want to use them
	if ( [ "S{snapshotid}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
		#If we get to here, then we are building from a snapshot and we pass the snapshotid in as the oschoice parameter
		snapshotid="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

		os_choice="${snapshotid}"
		key_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'KEYID'`"
		
		/bin/echo "${0} `/bin/date`: Building a new webserver using the snapshot build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

		/usr/local/bin/doctl compute droplet create "${server_name}" --size "${server_size}" --image "${os_choice}"  --region "${region}" --ssh-keys "${key_id}" --vpc-uuid "${vpc_id}"
		if ( [ "$?" != "0" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE DROPLET" "I tried to create a droplet called ${server_name} and failed. I don't know why, please investigate" "ERROR"
		fi
		
		#We pass back a string as a token to say that we built from a snapshot
		/bin/echo "SNAPPED"
elif ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "0" ] )
	then
		#If we are here, then it is a regular build process
		#We know that if this fails, it will be called again so no need for checks
		/bin/echo "${0} `/bin/date`: Building a new webserver using the standard build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/usr/local/bin/doctl compute droplet create "${server_name}" --size "${server_size}" --image "${os_choice}"  --region "${region}" --ssh-keys "${key_id}" --vpc-uuid "${vpc_id}"
		if ( [ "$?" != "0" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE DROPLET" "I tried to create a droplet called ${server_name} and failed. I don't know why, please investigate" "ERROR"
		fi
		#Pass back a token to say it was a standard build
		/bin/echo "STANDARD"
	else
		#If we get to here, then something was somehow wrong and we were unable to build the server
		/bin/echo "${0} `/bin/date`: There was a 'missed' attempt to build a webserver" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/bin/echo "MISSED"
	fi
fi

template_id="${1}"
zone_id="${2}"
server_size="${3}" 
server_name="${4}"
key_pair="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/EXOSCALE ] || [ "${cloudhost}" = "exoscale" ] )
then
	snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

	if ( [ "${snapshot_id}" = "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "0" ] )
	then
		template_id="`/bin/echo "${template_id}" | /bin/sed "s/'//g"`"
		/bin/echo "${0} `/bin/date`: Building a new webserver using the standard build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/bin/echo "STANDARD"
	else
		/bin/echo "${0} `/bin/date`: Building a new webserver using the snapshot build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		template_id="${snapshot_id}"
		/bin/echo "SNAPPED"
	fi
	
	/usr/bin/exo compute instance create "${server_name}" --instance-type standard.${server_size}  --security-group adt-webserver --template "${template_id}" --zone ${zone_id} --ssh-key ${key_pair} --cloud-init "${HOME}/providerscripts/server/cloud-init/exoscale.dat"
	if ( [ "$?" != "0" ] )
	then
		${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE VPS Server" "I tried to create VPS machine called ${server_name} and failed. I don't know why, please investigate" "ERROR"
	fi
	if ( [ "`/usr/bin/exo compute private-network list -O text | /bin/grep adt_private_net_${zone_id}`" = "" ] )
	then
		/usr/bin/exo compute private-network create adt_private_net_${zone_id} --zone ${zone_id} --start-ip 10.0.0.20 --end-ip 10.0.0.200 --netmask 255.255.255.0
		if ( [ "$?" != "0" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE PRIVATE NETWORKT" "I tried to create a droplet called adt_private_${zone_id} and failed. I don't know why, please investigate" "ERROR"
		fi
	fi
	
	/usr/bin/exo compute instance private-network attach  ${server_name} adt_private_net_${zone_id} --zone ${zone_id}
	if ( [ "$?" != "0" ] )
	then
		${HOME}/providerscripts/email/SendEmail.sh "MACHINE NOT ATTACHED TO Private Network" "A machine failed to add to the VPC network you might be able to manually add it with the cli or you may have to manually terrminate it because it won't come online" "ERROR"
	fi
fi

distribution="${1}"
location="${2}"
server_size="${3}"
server_name="`/bin/echo ${4} | /usr/bin/cut -c -32`"
key_id="${5}"
cloudhost="${6}"
username="${7}"

if ( [ -f ${HOME}/LINODE ] || [ "${cloudhost}" = "linode" ] )
then
	snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

	if ( [ "${snapshot_id}" = "" ] )
	then
		${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
	fi

	key="`/usr/local/bin/linode-cli --text sshkeys view ${key_id} | /usr/bin/awk '{print $3,$4,$5}' | /usr/bin/tail -n-1`"
	
	if ( [ -f ${HOME}/.ssh/EMERGENCY_PASSWORD ] )
	then
		emergency_password="`/bin/cat ${HOME}/.ssh/EMERGENCY_PASSWORD`"
	fi
	
	#Linode supports snapshots, so decide if we are building from a snapshot
	if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
		#If we are here, then we are building from a snapshot, so, get the snapshot id and pass it in to the server create command
		#Note 164 is a special os id to say that we are building from a snapshot and not a standard image
		snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"
		/bin/echo "${0} `/bin/date`: Building a new webserver using the snapshot build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${location} --image "private/${snapshot_id}" --type ${server_size} --label "${server_name}" --no-defaults
		server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
		/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		/bin/echo "SNAPPED"
	else
		/bin/echo "${0} `/bin/date`: Building a new webserver using the standard build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

		if ( [ "`/bin/echo ${distribution} | /bin/grep 'Ubuntu 20.04'`" != "" ] )
		then
			/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}"  --root_pass ${emergency_password} --region ${location} --image linode/ubuntu20.04 --type ${server_size} --label "${server_name}" --no-defaults
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE LINODE" "I tried to create a droplet called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
			server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
			/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Ubuntu 22.04'`" != "" ] )
		then
			/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${location} --image linode/ubuntu22.04 --type ${server_size} --label "${server_name}" --no-defaults
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE LINODE" "I tried to create a linode called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
			server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
			/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Ubuntu 24.04'`" != "" ] )
		then
			/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${location} --image linode/ubuntu24.04 --type ${server_size} --label "${server_name}" --no-defaults
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE LINODE" "I tried to create a linode called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
			server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
			/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Debian 10'`" != "" ] )
		then
			/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${location} --image linode/debian10 --type ${server_size} --label "${server_name}" --no-defaults
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE LINODE" "I tried to create a linode called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
			server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
			/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Debian 11'`" != "" ] )
		then
			/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${location} --image linode/debian11 --type ${server_size} --label "${server_name}" --no-defaults
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE LINODE" "I tried to create a linode called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
			server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
			/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		elif ( [ "`/bin/echo ${distribution} | /bin/grep 'Debian 12'`" != "" ] )
		then
			/usr/local/bin/linode-cli linodes create  --authorized_keys "${key}" --root_pass ${emergency_password} --region ${location} --image linode/debian12 --type ${server_size} --label "${server_name}" --no-defaults 
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE LINODE" "I tried to create a linode called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
			server_id="`/usr/local/bin/linode-cli linodes list --text --label ${server_name} | /bin/grep -v 'id' | /usr/bin/awk '{print $1}'`"
			/usr/local/bin/linode-cli linodes ip-add ${server_id} --type ipv4 --public false
		fi
	fi
fi

os_choice="${1}"
region="${2}"
server_plan="${3}"
server_name="${4}"
key_id="${5}"
cloudhost="${6}"

if ( [ -f ${HOME}/VULTR ] || [ "${cloudhost}" = "vultr" ] )
then
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"
				
	firewall_id="`/usr/bin/vultr firewall group list | /usr/bin/tail -n +2 | /bin/grep -w 'adt-webserver' | /usr/bin/awk '{print $1}'`"

	if ( [ "${firewall_id}" = "" ] )
	then
		 ${HOME}/providerscripts/email/SendEmail.sh "COULDN'T OBTAIN FIREWALL" "Failed to obtain firewall id when trying to create a new webserver" "ERROR"
		 /bin/echo "${0} `/bin/date`: Failed to obtain firewall id when creating a new webserver" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		 exit
	fi
	
	if ( [ "${snapshot_id}" = "" ] )
	then
		${HOME}/providerscripts/utilities/StoreConfigValue.sh 'SNAPAUTOSCALE' '0'
	fi

	if ( [ "`/usr/bin/vultr vpc2 list | grep adt-vpc`" = "" ] )
	then
		/usr/bin/vultr vpc2 create --region="${region}" --description="adt-vpc" --ip-type="v4" --ip-block="192.168.0.0" --prefix-length="16"
	fi
	
	vpc_id="`/usr/bin/vultr vpc2 list | grep adt-vpc | /usr/bin/awk '{print $1}'`"

	#Vultr supports snapshots, so decide if we are building from a snapshot
	if ( [ "${snapshot_id}" != "" ] && [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
	then
		/bin/echo "${0} `/bin/date`: Building a new webserver using the snapshot build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log

		#If we are here, then we are building from a snapshot, so, get the snapshot id and pass it in to the server create command
		#Note 164 is a special os id to say that we are building from a snapshot and not a standard image
		snapshot_id="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SNAPSHOTID'`"

		user_data=`/bin/cat ${HOME}/providerscripts/server/cloud-init/vultr.dat`
		
		if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ENABLEDDOSPROTECTION:1`" = "1" ] )
		then
		   /usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_plan}" --ipv6=false -s ${key_id} --snapshot="${snapshot_id}" --ddos=true --userdata="${user_data}" --firewall-group="${firewall_id}"
		   if ( [ "$?" != "0" ] )
		   then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE VPS Machine" "I tried to create a VPS Machine called ${server_name} and failed. I don't know why, please investigate" "ERROR"
		   fi
		else
		   /usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_plan}" --ipv6=false -s ${key_id} --snapshot="${snapshot_id}" --ddos=false --userdata="${user_data}" --firewall-group="${firewall_id}"
		   if ( [ "$?" != "0" ] )
		   then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE VPS Machine" "I tried to create a VPS Machine called ${server_name} and failed. I don't know why, please investigate" "ERROR"
		   fi
		fi

		#Pass back a token to say we built from a snapshot
		/bin/echo "SNAPPED"
	else
		#If we are here, then we are doing a regular build
		/bin/echo "${0} `/bin/date`: Building a new webserver using the standard build method" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/bin/sleep 1
		os_choice="`/usr/bin/vultr os list | /bin/grep "${os_choice}" | /usr/bin/awk '{print $1}'`"
		/bin/sleep 1

		user_data=`/bin/cat ${HOME}/providerscripts/server/cloud-init/vultr.dat`

		if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh ENABLEDDOSPROTECTION:1`" = "1" ] )
		then        
			/usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_plan}" --os="${os_choice}" --ipv6=false -s ${key_id} --ddos=true --userdata="${user_data}" --firewall-group="${firewall_id}"
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE VPS Machine" "I tried to create a VPS Machine called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
		else
			/usr/bin/vultr instance create --label="${server_name}" --region="${region}" --plan="${server_plan}" --os="${os_choice}" --ipv6=false -s ${key_id} --ddos=false --userdata="${user_data}" --firewall-group="${firewall_id}"
			if ( [ "$?" != "0" ] )
			then
				 ${HOME}/providerscripts/email/SendEmail.sh "FAILED TO CREATE VPS Machine" "I tried to create a VPS Machine called ${server_name} and failed. I don't know why, please investigate" "ERROR"
			fi
		fi
	fi
	
	machine_id="`/usr/bin/vultr instance list | /bin/grep "${server_name}" | /usr/bin/awk '{print $1}'`"
	
	while ( [ "${machine_id}" = "" ] )
	do
	   machine_id="`/usr/bin/vultr instance list | /bin/grep "${server_name}" | /usr/bin/awk '{print $1}'`"
	   /bin/sleep 5
	done
	
	if ( [ "${machine_id}" != "" ] )
	then
		count="0"
		/usr/bin/vultr vpc2 nodes attach ${vpc_id} --nodes="${machine_id}"

		while ( [ "$?" != "0" ] && [ "${count}" -lt "5" ] )
		do
			count="`/usr/bin/expr ${count} + 1`"
			/bin/sleep 30
			/usr/bin/vultr vpc2 nodes attach ${vpc_id} --nodes="${machine_id}"
		done 
		
		if ( [ "${count}" = "5" ] )
		then
			${HOME}/providerscripts/email/SendEmail.sh "MACHINE NOT ATTACHED TO Private Network" "A machine ${machine_id} failed to add to the VPC ${vpc_id} network you might be able to manually add it with the cli or you may have to manually terrminate it because it won't come online" "ERROR"
		fi
	fi
fi
