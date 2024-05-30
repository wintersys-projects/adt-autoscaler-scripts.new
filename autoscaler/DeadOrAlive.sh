#!/bin/sh
############################################################################################
# Author: Peter Winter
# Date  : 04/07/2016
# Description : This will review the status and resposiveness of our fleet of webservers
# Any webservers that are found to not be alive and active by one of the checks are kept
# in a list of webservers that might need to be shutdown
# If we get into a situation where we have fewer webservers than our scaling mechanism demands
# then the scaling mechanism will start up new machines accordingly
# Every webserver has to pass a series of tighter and tighter checks before it is considered "online"
# 1: Is the machine calling itself "webserver" in its name, if not its not an online webserver
# 2: Is the machine labelled as "being built" if it is then its not an online webserver
# 3: Is this machine a potetially stalled build if it is its not an online webserver
# 4: Can the machine be probed by SSH, if it can't its not an online webserver
# 5: Does the machine respond to being probed by curl, if not its not an online webserver
# If the candidate machine passes all these checks it is considered an online webserver
# and its public IP address is added to the DNS system
# A machine is given a few chances and if it fails these checks repeatedly, it is ended
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
#set -x

logdate="`/usr/bin/date | /usr/bin/awk '{print $1,$2,$3}' | /bin/sed 's/ //g'`"
logdir="scaling-events-`/usr/bin/date | /usr/bin/awk '{print $1,$2,$3}' | /bin/sed 's/ //g'`"

#You can uncomment these if you want to see what is going on with the status monitoring of your webservers
if ( [ ! -d ${HOME}/logs/deadoralive-${logdate} ] )
then
	/bin/mkdir -p ${HOME}/logs/deadoralive-${logdate} 
fi

#OUT_FILE="dead-or-alive.out"
#exec 1>>${HOME}/logs/deadoralive-${logdate}/${OUT_FILE}
#ERR_FILE="dead-or-alive.err"
#exec 2>>${HOME}/logs/deadoralive-${logdate}/${ERR_FILE}

/bin/echo "#######################`/usr/bin/date`##################################"

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

autoscalerip="`${HOME}/providerscripts/utilities/GetPublicIP.sh`"
autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscalerip} ${CLOUDHOST}`"
if ( [ "${autoscaler_name}" != "" ] )
then
	autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $2}'`"
	wait_period="`/usr/bin/expr ${autoscaler_no} \* 30`"
	/bin/sleep ${wait_period}
else
	/bin/sleep 10
fi

endit ()
{
   down_ip="${1}"
   reason="${2}"

   #We don't want to go down below 2 webservers
   
	if ( [ "`/bin/ls -l ${HOME}/runtime/INITIALLY_PROVISIONING* 2>/dev/null`" = "" ] )
	then  
		autoscalerip="`${HOME}/providerscripts/utilities/GetPublicIP.sh`"
		if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh "beingbuiltips/*" | /bin/grep ${down_ip}`" = "" ] || [ "`/usr/bin/find ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip} -mmin +30`" != "" ] )
		then
			/bin/echo "Ending server with ip address ${down_ip}"
			/bin/echo "${0} `/bin/date`: Webserver with ip address: ${down_ip} is having it's ip address removed from the DNS system" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
			public_ip_address="`${HOME}/providerscripts/server/GetServerPublicIPAddressByIP.sh ${down_ip} ${CLOUDHOST}`"
			${HOME}/autoscaler/RemoveIPFromDNS.sh ${public_ip_address}
			#Be aware that the time to live is 120 seconds and so we have removed a DNS record now, but, it will still be served for up to 120 seconds after we remove it
			#So, we don't want it to not resolve to a server machine during that time period so we need to sleep for 120 seconds to make sure that the TTL has expired 
			#before we destroy the server machine that that IP address still might be resolving to and giving us timeouts and so on
			/bin/sleep 120
			${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER IS BEING SHUTDOWN ${down_ip}" "${reason}" "INFO"
			${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beenonline/${down_ip}"                
			/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY_${BUILD_IDENTIFIER} -o ConnectTimeout=10 -o ConnectionAttempts=3 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${down_ip} "${SUDO} ${HOME}/providerscripts/utilities/ShutdownThisWebserver.sh"
			/bin/echo "${0} `/bin/date`: Webserver with ip address: ${down_ip}  has been shutdown" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
			${HOME}/providerscripts/server/DestroyServer.sh ${public_ip_address} ${CLOUDHOST} ${down_ip}
			/bin/echo "${0} `/bin/date`: Webserver with ip address: ${down_ip}  has been destroyed and its resources released" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
			if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip} ] )
			then
				/bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip}
			fi
		fi
	fi
}

probe_by_ssh ()
{
		connectable="0"
		probecount="0"
	
		while ( [ "${connectable}" = "0" ] && [ "${probecount}" -lt "2" ] )
		do
			if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY -o ConnectTimeout=10 -o ConnectionAttempts=2 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/ls ${HOME}/runtime/AUTOSCALED_WEBSERVER_ONLINE" 2>/dev/null`" != "" ] ||  [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY -o ConnectTimeout=10 -o ConnectionAttempts=2 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/bin/ls ${HOME}/runtime/INITIAL_BUILD_WEBSERVER" 2>/dev/null`" != "" ] )
			then
				connectable="1"
			else 
				connectable="0"
			fi
			probecount="`/usr/bin/expr ${probecount} + 1`"
	   done

	   /bin/echo "${ip}" >> ${HOME}/runtime/probed_ips/processed_ips.dat
	   
	   if ( [ "${connectable}" = "0" ] )
	   then
			/bin/echo "${0} `/bin/date`: Webserver ${ip} was found to be offline because it couldn't be contacted over SSH" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
			/bin/echo "${ip}" >> ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat
		fi
}

probe_by_curl()
{
	probecount="0"
	status="down"
	while ( [ "${probecount}" -le "3" ] && [ "${status}" = "down" ] )
	do
		if ( [ "`/usr/bin/curl -m 20 --insecure -I "https://${ip}:443/${file}" 2>&1 | /bin/grep \"HTTP\" | /bin/grep -w \"200\|301\|302\|303\"`" != "" ] ) 
		then
			status="up"
		else
			status="down"
		fi
		probecount="`/usr/bin/expr ${probecount} + 1`"
	 done

	 /bin/echo "${ip}" >> ${HOME}/runtime/probed_ips/processed_ips.dat

	 if ( [ "${status}" = "down" ] )
	 then
			/bin/echo "${0} `/bin/date`: Webserver ${ip} was found to be offline because it couldn't be contacted using curl" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
			/bin/echo "${ip}" >> ${HOME}/runtime/probed_ips/failed_probe_curl_ips.dat
	  fi
}

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh "MAINTENANCE_MODE"`" != "" ] )
then
	NO_WEBSERVERS="1"
else
	. ${HOME}/autoscaler/CalculateNumberOfWebserversNeeded.sh
fi

noactivewebservers="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"

#Kill webservers in batches of up to 5 at a time
count="0"
while ( [ "${noactivewebservers}" -gt "${NO_WEBSERVERS}" ] && [ "${count}" -lt "5" ] )
do
   endit "`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/head -1`" "Because the machine was excess to requirements according to the scaling policy"
   /bin/sleep 30
   noactivewebservers="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"  
   count="`/usr/bin/expr ${count} + 1`"
done

all_ips="`${HOME}/providerscripts/server/GetServerPrivateIPAddresses.sh webserver ${CLOUDHOST}`"
online_ips="${all_ips}"

for ip in ${online_ips}
do
	if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh "beenonline/${ip}"`" != "" ] )
	then
		${HOME}/providerscripts/datastore/configwrapper/DeleteFromConfigDatastore.sh "beingbuiltips/${ip}"
	fi
done

/bin/echo "Performing checks to see which webservers are online and active"
/bin/echo "1: Current webserver online webserver list is : `/bin/echo ${online_ips} | /bin/sed 's/\n//g'`"

for ip in ${online_ips}
do
	if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh beingbuiltips/ recursive | /bin/grep ${ip}`" != "" ] )
	then
	   online_ips="`/bin/echo ${online_ips} | /bin/sed "s/${ip}//g"`"
	fi
done

/bin/echo "2: Current webserver online webserver list is : `/bin/echo ${online_ips} | /bin/sed 's/\n/ /g'`"

for ip in ${online_ips}
do
	if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip} ] && [ "`/usr/bin/find ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip} -mmin +30`" != "" ] )
	then
		/bin/echo "${0} `/bin/date`: Webserver ${ip} was found to be offline because it looked like a stalled build" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/bin/rm ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip}
		online_ips="`/bin/echo ${online_ips} | /bin/sed "s/${ip}//g"`"
	fi
done

/bin/echo "3: Current webserver online webserver list is : `/bin/echo ${online_ips} | /bin/sed 's/\n//g'`"

if ( [ ! -d ${HOME}/runtime/probed_ips/ ] )
then
	/bin/mkdir ${HOME}/runtime/probed_ips
fi

if ( [ -f ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat ] )
then
	/bin/rm ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat
fi

if ( [ -f ${HOME}/runtime/probed_ips/processed_ips.dat ] )
then
	/bin/rm ${HOME}/runtime/probed_ips/processed_ips.dat
	/bin/touch ${HOME}/runtime/probed_ips/processed_ips.dat
fi

no_online_ips="`/bin/echo "${online_ips}" | /usr/bin/wc -w`"

if ( [ -f ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat ] )
then
	/bin/cp /dev/null ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat
else
	/bin/touch ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat
fi

for ip in ${online_ips}
do
	probe_by_ssh &
done

no_processed_ips="`/bin/cat ${HOME}/runtime/probed_ips/processed_ips.dat | /usr/bin/wc -l`"

while ( [ "${no_processed_ips}" -lt "${no_online_ips}" ] )
do
	/bin/sleep 5
	no_processed_ips="`/bin/cat ${HOME}/runtime/probed_ips/processed_ips.dat | /usr/bin/wc -l`"
done

probed_ips="`/bin/cat ${HOME}/runtime/probed_ips/failed_probe_ssh_ips.dat`"
processed_ips="`/bin/cat ${HOME}/runtime/probed_ips/processed_ips.dat`"

for ip in ${processed_ips}
do
		if ( [ "`/bin/echo ${probed_ips} | /bin/grep ${ip}`" != "" ] )
		then
			online_ips="`/bin/echo ${online_ips} | /bin/sed "s/${ip}//g"`"
		fi
done

/bin/echo "4: Current webserver online webserver list is : `/bin/echo ${online_ips} | /bin/sed 's/\n//g'`"
		
if ( [ ! -d ${HOME}/runtime/probed_ips/ ] )
then
	/bin/mkdir ${HOME}/runtime/probed_ips
fi

if ( [ -f ${HOME}/runtime/probed_ips/failed_probe_curl_ips.dat ] )
then
	/bin/rm ${HOME}/runtime/probed_ips/failed_probe_curl_ips.dat
fi

if ( [ -f ${HOME}/runtime/probed_ips/processed_ips.dat ] )
then
	/bin/rm ${HOME}/runtime/probed_ips/processed_ips.dat
	/bin/touch ${HOME}/runtime/probed_ips/processed_ips.dat
fi

no_online_ips="`/bin/echo "${online_ips}" | /usr/bin/wc -w`"

if ( [ -f ${HOME}/runtime/probed_ips/failed_probe_curl_ips.dat ] )
then
	/bin/cp /dev/null ${HOME}/runtime/probed_ips/failed_probe_curl_ips.dat
else
	/bin/touch ${HOME}/runtime/probed_ips/failed_probe_curl_ips.dat
fi

/bin/echo "5: Current webserver online webserver list is : `/bin/echo ${online_ips} | /bin/sed 's/\n//g'`"

for ip in ${online_ips}
do
	probe_by_curl &
done

for ip in ${online_ips}
do
	if ( [ "`/usr/bin/ssh -p ${SSH_PORT} -i ${HOME}/.ssh/id_${ALGORITHM}_AGILE_DEPLOYMENT_BUILD_KEY -o ConnectTimeout=5 -o ConnectionAttempts=2 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SERVER_USER}@${ip} "/usr/bin/find ${HOME}/runtime/BUILD_IN_PROGRESS -mmin +30 2>/dev/null"`" != "" ] )
	then
	   /bin/echo "${0} `/bin/date`: Webserver ${ip} was found to be offline because it looks as if the build process failed to progress" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
	   online_ips="`/bin/echo ${online_ips} | /bin/sed "s/${ip}//g"`"
	fi
done

/bin/echo "Final: Webservers submitted for review IP addresses are: `/bin/echo ${all_ips} | /bin/sed 's/\n//g'`"
/bin/echo "Final: Webservers found to be online by the review are: `/bin/echo ${online_ips} | /bin/sed 's/\n//g'`"

offline_ips=""

if ( [ "${all_ips}" != "" ] && [ "${online_ips}" != "" ] )
then
	for ip in ${all_ips}
	do
		if ( [ "`/bin/echo ${online_ips} | /bin/grep ${ip}`" = "" ] )
		then
		   offline_ips="${offline_ips} ${ip}"
		 fi
	done
fi

if ( [ ! -d ${HOME}/runtime/potentialenders ] )
then
	/bin/mkdir ${HOME}/runtime/potentialenders
fi

if ( [ "${offline_ips}" != "" ] )
then
	for ip in ${offline_ips}
	do
		if ( [ -f ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip} ] && [ "`/usr/bin/find ${HOME}/runtime/POTENTIAL_STALLED_BUILD:${ip} -mmin +30`" != "" ] )
		then
			/bin/echo "${0} `/bin/date`: Ending webserver with ip:${ip} because it is considered a stalled build" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
			endit ${ip} "Webserver (${ip}) is being shutdown because it has been considered as a stalled build"
		elif ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh "beenonline/${ip}"`" != "" ] )
		then
			if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh "beingbuilt/${ip}"`" = "" ] )
			then
				/bin/echo "${ip}" >> ${HOME}/runtime/potentialenders/listofipstoend.dat
				/bin/echo "${0} `/bin/date`: Added IP ${ip} to list of ips to potentially get ended. This is its `/bin/grep ${ip} ${HOME}/runtime/potentialenders/listofipstoend.dat | /usr/bin/wc -l` chance gone out of 2 chances granted" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
				public_ip="`${HOME}/providerscripts/server/GetServerPublicIPAddressByIP.sh ${ip} ${CLOUDHOST}`"
				${HOME}/autoscaler/RemoveIPFromDNS.sh ${public_ip}
				if ( [ "`/bin/grep ${ip} ${HOME}/runtime/potentialenders/listofipstoend.dat | /usr/bin/wc -l`" -ge "2" ] )
				then
					 /bin/sed -i "s/${ip}//g" ${HOME}/runtime/potentialenders/listofipstoend.dat
					 endit ${ip} "Webserver was found to be offline please check your logs (${HOME}/logs/OPERATIONAL_MONITORING.log) and (${HOME}/logs/deadoralive${logdate}/*) for the more detailed reason"
				fi
			fi
		fi
	done
fi

for ip in ${online_ips}
do
	${HOME}/autoscaler/AddIPToDNS.sh "`${HOME}/providerscripts/server/GetServerPublicIPAddressByIP.sh ${ip} ${CLOUDHOST}`" &
	if ( [ -f ${HOME}/runtime/potentialenders/listofipstoend.dat ] )
	then
		/bin/sed -i "s/${ip}//g" ${HOME}/runtime/potentialenders/listofipstoend.dat
	fi
done

if ( [ -f ${HOME}/runtime/potentialenders/listofipstoend.dat ] )
then
	/bin/sed -i "/^$/d" ${HOME}/runtime/potentialenders/listofipstoend.dat
fi


#If things have really funged up then its possible that the processes could be hanging around in some undetermined state, so end them after 35 minutes

too_old="0"
pids="`/usr/bin/ps -ef | /bin/grep BuildWebserver.sh | /bin/grep -v grep | /usr/bin/awk '{print $2}'`"
for pid in ${pids}
do
	if ( [ "${pid}" != "" ] && [ "`/usr/bin/ps -o etime= -p "${pid}" | /usr/bin/awk -F':' '{print $1}' | /bin/sed 's/ //g'`" -ge "30" ] )
	then
		/bin/echo "${0} `/bin/date`: Killed BuildWebserver process ${pid} because it seemed to have stalled (been running for more than 30 minutes)" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
	   /bin/kill ${pid}
	   /bin/kill -KILL ${pid}
		too_old="1"
	   /bin/rm ${HOME}/runtime/autoscalelock.file
	fi
done

pids="`/usr/bin/ps -ef | /bin/grep PerformScaling.sh | /bin/grep -v grep | /usr/bin/awk '{print $2}'`"
for pid in ${pids}
do
	if ( [ "${pid}" != "" ] && [ "`/usr/bin/ps -o etime= -p "${pid}" | /usr/bin/awk -F':' '{print $1}' | /bin/sed 's/ //g'`" -ge "30" ] )
	then
		/bin/echo "${0} `/bin/date`: Killed PerformScaling process ${pid} because it seemed to have stalled (been running for more than 30 minutes)" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
		/bin/kill ${pid}
		/bin/kill -KILL ${pid}
		/bin/rm ${HOME}/runtime/autoscalelock.file
		too_old="1"
	fi
done

if ( [ "${too_old}" = "1" ] )
then
	/bin/echo "${0} `/bin/date`: This autoscaler has been rebooted for hygiene reasons because something seeemed to have gone stale" >> ${HOME}/logs/OPERATIONAL_MONITORING.log
	#This is necessary because if the processes above had a problem and might be hanging around indefinitely  we need to clean up and the shutdown process is the most comprehensive way to do that for us. 
	${HOME}/providerscripts/utilities/ShutdownThisAutoscaler.sh "reboot"  
fi
