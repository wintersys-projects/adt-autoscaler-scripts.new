#!/bin/sh
###########################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will get a record id for a given ip address for the dns provider
# we are using
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
#######################################################################################
#######################################################################################
#set -x

zoneid="${1}"
websiteurl="${2}"
ip="${3}"
email="${4}"
authkey="${5}"
dns="${6}"

if ( [ "${dns}" = "cloudflare" ] )
then
	/usr/bin/curl -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=A&name=${websiteurl}&content=${ip}&page=1&per_page=20&order=type&direction=desc&match=all" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" | /usr/bin/jq '.result[].id' | /bin/sed 's/"//g'
fi


websiteurl="${2}"
domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${3}"
dns="${6}"

if ( [ "${dns}" = "digitalocean" ] )
then
	recordid="`/usr/local/bin/doctl compute domain records list ${domainurl} | /bin/grep ${subdomain} | /bin/grep ${ip} | /usr/bin/awk '{print $1}'`"
	count="0"
	while ( [ "${count}" -lt "5" ] && [ "${recordid}" = "" ] )
	do
		/bin/sleep 5
		recordid="`/usr/local/bin/doctl compute domain records list ${domainurl} | /bin/grep ${subdomain} | /bin/grep ${ip} | /usr/bin/awk '{print $1}'`"
	count="`/usr/bin/expr ${count} + 1`"
	done
	/bin/echo "${recordid}"
fi

domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${3}"
authkey="${5}"
dns="${6}"

if ( [ "${dns}" = "exoscale" ] )
then
	/usr/bin/exo -O json dns show ${domainurl} | /usr/bin/jq --arg tmp_content "${ip}" '.[] | select (.content == $tmp_content ) | .id' 
	#Alternative
	#/usr/bin/curl  -H "X-DNS-Token: ${authkey}" -H 'Accept: application/json' https://api.exoscale.com/dns/v1/domains/${domainurl}/records | /usr/bin/jq --arg tmp_subdomain "${subdomain}" --arg tmp_content "${ip}" '.[].record | select (.name == $tmp_subdomain and .content == $tmp_content ) | .id'
fi

domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${3}"
authkey="${5}"
dns="${6}"

if ( [ "${dns}" = "linode" ] )
then
	domain_id="`/usr/local/bin/linode-cli --json domains list | /usr/bin/jq --arg tmp_domainurl "${domainurl}" '(.[] | select(.domain | contains($tmp_domainurl)) | .id)'`"
	/usr/local/bin/linode-cli --json domains records-list ${domain_id} | /usr/bin/jq --arg tmp_ip "${ip}" '(.[] | select(.target | contains($tmp_ip)) | .id)'
fi

domainurl="`/bin/echo ${2} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${2} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${3}"
dns="${6}"

if ( [ "${dns}" = "vultr" ] )
then
	HOME="`/bin/cat /home/homedir.dat`"
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/usr/bin/vultr dns record list ${domainurl} | /bin/grep ${ip} | /usr/bin/awk '{print $1}'

fi
