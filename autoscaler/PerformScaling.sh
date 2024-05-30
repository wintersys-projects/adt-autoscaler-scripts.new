#!/bin/sh
############################################################################################
# Description:  This script will create Webservers up to the defined number of webservers
# required when there's not enough. You might be running multiple autoscalers in which case
# this script is set up to loadbalance the webservers to be built between the autoscalers.
# This is not partcularly heavy work for the autoscalers to do but you might want to have 
# multiple autoscalers for architectual resilience like you might like to have multiple
# webservers for the same reason. 
# Author: Peter Winter
# Date: 12/01/2017
###########################################################################################
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

logdate="`/usr/bin/date | /usr/bin/awk '{print $1 $2 $3 $NF}'`"
logdir="scaling-events-`/usr/bin/date | /usr/bin/awk '{print $1,$2,$3}' | /bin/sed 's/ //g'`"

if ( [ ! -d ${HOME}/logs/${logdir} ] )
then
	/bin/mkdir -p ${HOME}/logs/${logdir}
fi

if ( [ "`${HOME}/providerscripts/datastore/configwrapper/CheckConfigDatastore.sh "SWITCHOFFSCALING"`" = "1" ] )
then
	exit
fi

if ( [ "`${HOME}/providerscripts/utilities/ExtractConfigValue.sh SNAPAUTOSCALE`" = "1" ] && [ ! -f ${HOME}/runtime/INITIAL_SCALING_PROCESSED ] )
then
   /bin/echo "${0} `/bin/date`: Initial scaling process has completed and I am authorising scaling" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
   /bin/touch ${HOME}/runtime/INITIAL_SCALING_PROCESSED
   /bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE  
   if ( [ -f ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE ] )
   then
	   /bin/rm ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE
   fi
   exit
fi

if ( [ -f ${HOME}/runtime/INITIALBUILDCOMPLETED ] )
then
	if test "`/usr/bin/find ${HOME}/runtime/INITIALBUILDCOMPLETED -mmin -5`"
	then
		/bin/echo "${0} `/bin/date`: This autoscaler is still in its initial wait period and is authroised to scale as soon as possible" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		/bin/touch ${HOME}/runtime/INITIAL_SCALING_PROCESSED
		/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE  
		if ( [ -f ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE ] )
		then
			/bin/rm ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE
		fi
		exit
	fi
fi

if ( [ ! -f ${HOME}/runtime/INITIAL_SCALING_PROCESSED ] )
then
	/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE  
	if ( [ -f ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE ] )
	then
		/bin/rm ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE
	fi
fi

if ( [ -f ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE ] )
then
	if test "`/usr/bin/find ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE -mmin +30`"
	then
		/bin/echo "${0} `/bin/date`: Scaling has been contnuously disabled for more than 30 minutes there must be something wrong and so must be rebooted" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		/bin/echo "${0} `/bin/date`: Authorising post reboot scaling" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE  
		/bin/rm ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE
		${HOME}/providerscripts/utilities/ShutdownThisAutoscaler.sh "reboot"
	fi
fi

if ( [ "`/bin/ls ${HOME}/runtime/INITIALLY_PROVISIONING* 2>/dev/null`" != "" ] )
then
	/bin/rm ${HOME}/runtime/INITIALLY_PROVISIONING*
fi

if ( [ ! -f ${HOME}/runtime/AUTHORISED_TO_SCALE ] )
then
   exit
fi

CLOUDHOST="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'CLOUDHOST'`"
BUILD_IDENTIFIER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'BUILDIDENTIFIER'`"
ALGORITHM="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'ALGORITHM'`"
SSH_PORT="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SSHPORT'`"
SERVER_USER="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSER'`"
SERVER_USER_PASSWORD="`${HOME}/providerscripts/utilities/ExtractConfigValue.sh 'SERVERUSERPASSWORD'`"

SUDO=" DEBIAN_FRONTEND=noninteractive /bin/echo ${SERVER_USER_PASSWORD} | /usr/bin/sudo -S -E "

autoscalerip="`/bin/hostname -I | /usr/bin/awk '{print $1}'`"
/bin/echo "${0} `/bin/date`: This autoscaler's IP address is ${autoscalerip}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

#Make very sure we have got the autoscaler name
autoscaler_name="`${HOME}/providerscripts/server/GetServerName.sh ${autoscalerip} ${CLOUDHOST}`"
/bin/echo "${0} `/bin/date`: This autoscaler's name is ${autoscaler_name}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

autoscaler_no="`/bin/echo ${autoscaler_name} | /usr/bin/awk -F'-' '{print $2}'`"
initial_no_webservers="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"
no_autoscalers="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "autoscaler" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"


/bin/echo "${0} `/bin/date`: This machine is found to be autoscaler number ${autoscaler_no}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
/bin/echo "${0} `/bin/date`: I found the number of autoscalers running to be ${no_autoscalers}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
/bin/echo "${0} `/bin/date`: I found the existing number of actioned webservers to be ${initial_no_webservers}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

if ( [ "${initial_no_webservers}" = "" ] || [ "${no_autoscalers}" = "" ] )
then
	exit
fi

count="0"
while ( ! [ "${NO_WEBSERVERS}" -eq "${NO_WEBSERVERS}" 2>/dev/null ] && [ "${count}" -lt "5" ] )
do 
	if ( [ "`${HOME}/providerscripts/datastore/configwrapper/ListFromConfigDatastore.sh "MAINTENANCE_MODE"`" != "" ] )
	then
		NO_WEBSERVERS="1"
	else
		. ${HOME}/autoscaler/CalculateNumberOfWebserversNeeded.sh
	fi
	/bin/sleep 10
	count="`/usr/bin/expr ${count} + 1`"
done

if ( [ "${count}" -eq "5" ] )
then
	/bin/echo "${0} `/bin/date`: Failed to get valid number of webservers to scale to the value I got was: ${NO_WEBSERVERS}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	${HOME}/providerscripts/email/SendEmail.sh "COULDN'T GET SCALING VALUE" "I failed to get a valid scaling value the value I got was {${NO_WEBSERVERS}). I therefore am refusing to scale." "ERROR"
	exit
fi

/bin/echo "${0} `/bin/date`: I found the total number of webservers that need to be running based on the current scaling policy to be: ${NO_WEBSERVERS}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

if ( [ "${NO_WEBSERVERS}" != "${initial_no_webservers}" ] )
then
	 /bin/echo "${0} `/bin/date`: That means a total of `/usr/bin/expr ${NO_WEBSERVERS} - ${initial_no_webservers}` are needed and this autoscaler might have a role to play in that..." >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
else
	 /bin/echo "${0} `/bin/date`: No additional webservers are needed on this check" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
fi


if ( [ "${NO_WEBSERVERS}" = "" ] || [ "${initial_no_webservers}" = "${NO_WEBSERVERS}" ] )
then
   exit
fi

/bin/sleep 10

total_needed="`/usr/bin/expr ${NO_WEBSERVERS} - ${initial_no_webservers}`"

if ( [ "${total_needed}" -ge "${no_autoscalers}" ] )
then
	no_needed_here="`/usr/bin/expr ${total_needed} / ${no_autoscalers}`"
	no_needed_here="`/bin/echo ${no_needed_here} | /usr/bin/awk -F'.' '{print $1}'`"
	
	/bin/echo "${0} `/bin/date`: There is ${no_autoscalers} autoscalers and there's ${no_neeeded_here} webserver(s) being built on each one" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	
	total_actioned="`/usr/bin/expr ${no_needed_here} \* ${no_autoscalers}`"

	/bin/echo "${0} `/bin/date`: The total webservers across all autoscalers actioned to be built is ${total_actioned}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	/bin/echo "${0} `/bin/date`: The total webservers across all autoscalers that need to be built is ${total_needed}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	
	if ( [ "${autoscaler_no}" = "0" ] && [ "${total_actioned}" != "${total_needed}" ] )
	then
		/bin/echo "${0} `/bin/date`: The total webservers needed and the total webservers actioned to be built are not equal" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		/bin/echo "${0} `/bin/date`: This is the first autoscaler and therefore I will  apply a the necessary top up here" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		topup="`/usr/bin/expr ${total_needed} - ${total_actioned}`"
		/bin/echo "${0} `/bin/date`: The topup value is ${topup} and I am about to apply it" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		no_needed_here="`/usr/bin/expr ${no_needed_here} + ${topup}`"  
		/bin/echo "${0} `/bin/date`: The number of webservers being built on this autoscaler (including newly applied topup) is ${no_needed_here}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	 fi
fi

if ( [ "${autoscaler_no}" = "0" ] && [ "${total_needed}" -lt "${no_autoscalers}" ] )
then
	no_needed_here="${total_needed}"
fi

if ( [ "${autoscaler_no}" != "0" ] && [ "${total_needed}" -lt "${no_autoscalers}" ] )
then
	/bin/sleep 180
	initial_no_webservers="`${HOME}/providerscripts/server/GetServerIPAddresses.sh "webserver" ${CLOUDHOST} | /usr/bin/tr '\n' ' ' | /usr/bin/wc -w`"
	total_needed="`/usr/bin/expr ${NO_WEBSERVERS} - ${initial_no_webservers}`"

	if ( [ "${total_needed}" -lt "${no_autoscalers}" ] )
	then
		no_needed_here="${total_needed}"
	fi
fi

if ( [ "${no_needed_here}" -gt "20" ] )
then
	no_needed_here="20"
	/bin/echo "${0} `/bin/date`: You tried to build more than 20 webservers on this autoscaler so I have applied a limit of 20 to your request" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
fi

/bin/echo "${0} `/bin/date`: The final number of webservers I am building on this autoscaler is ${no_needed_here}" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

if ( [ "${no_needed_here}" -gt "0" ] )
then
	loop="0"

	/bin/rm ${HOME}/runtime/AUTHORISED_TO_SCALE 
	/bin/touch ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE 

	/bin/echo "${0} `/bin/date`: A scaling cycle has been initiated, additional new scaling events will not be processed until this scaling cycle is complete" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

	while ( [ "${loop}" -le "`/usr/bin/expr ${no_needed_here} - 1`" ] )
	do
		loop="`/usr/bin/expr ${loop} + 1`"
		/bin/touch ${HOME}/runtime/AUTOSCALINGMONITOR:${loop}
		if ( [ "`${HOME}/providerscripts/utilities/CheckConfigValue.sh SNAPAUTOSCALE:1`" = "1" ] )
		then 
			/bin/echo "${0} `/bin/date`: I have calculated that a webserver needs booting so am booting a new one from a snapshot" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
			newip="`${HOME}/autoscaler/BuildWebserver.sh ${loop} &`"
		else
			/bin/echo "${0} `/bin/date`: I have calculated that a webserver needs booting so am booting a new one as a regular build (not a snapshot)" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
			newip="`${HOME}/autoscaler/BuildWebserver.sh ${loop} &`"
		fi
	done

	/bin/echo "${0} `/bin/date`: This autoscaler is now waiting for the new webservers to build and will continue after they have all completed" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	/bin/echo "${0} `/bin/date`: Action will be taken if any webserver that we are building doesn't complete in a maximum time of 30 minutes" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log

	while ( [ "`/bin/ls ${HOME}/runtime/AUTOSCALINGMONITOR* 2>/dev/null`" != "" ] )
	do
		loop1="1"
		while ( [ "${loop1}" -le "${no_needed_here}" ] )
		do
			if ( [ -f ${HOME}/runtime/AUTOSCALINGMONITOR:${loop1} ] )
			then
				if test "`/usr/bin/find ${HOME}/runtime/AUTOSCALINGMONITOR:${loop1} -mmin +30 2>/dev/null`"
				then
					/bin/echo "${0} `/bin/date`: Have removed autoscaling monitor ${loop1} because it was older than 30 minutes which looks like a stall" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
					/bin/rm ${HOME}/runtime/AUTOSCALINGMONITOR:${loop1}
				fi
			fi
			/bin/sleep 10
			loop1="`/usr/bin/expr ${loop1} + 1`"
		done
	done
	

	/bin/touch ${HOME}/runtime/AUTHORISED_TO_SCALE
	/bin/rm ${HOME}/runtime/NOT_AUTHORISED_TO_SCALE 
	
	/bin/echo "${0} `/bin/date`: This autoscaler has now been re-authorised to scale in response to new scaling events" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		
	if ( [ "${newip}" != "" ] )
	then
		/bin/echo "${0} `/bin/date`:  Added the new IP for the webserver( ${newip} ) to the DNS system" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
		${HOME}/providerscripts/email/SendEmail.sh "A WEBSERVER HAS BEEN DEPLOYED" "Webserver ( ${ip} ) has just been deployed and activated" "INFO"
	fi   
		
	/bin/echo "${0} `/bin/date`: Rebooting autoscaler before next scaling event for hygiene reasons" >> ${HOME}/logs/${logdir}/ScalingEventsLog.log
	${HOME}/providerscripts/utilities/ShutdownThisAutoscaler.sh "reboot"  
fi
