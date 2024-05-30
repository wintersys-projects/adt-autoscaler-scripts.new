#!/bin/sh
##################################################################################
# Author : Peter Winter
# Date   : 13/06/2016
# Description : This script will add an ip address (A Record) to the DNS provider
##################################################################################
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
####################################################################################
####################################################################################
#set -x

zoneid="${1}"
email="${2}"
authkey="${3}"
websiteurl="${4}"
ip="${5}"
dns="${6}"

if ( [ "${dns}" = "cloudflare" ] )
then
	/usr/bin/curl -X POST "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records" -H "X-Auth-Email: ${email}" -H "X-Auth-Key: ${authkey}" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"${websiteurl}\",\"content\":\"${ip}\",\"ttl\":120,\"proxiable\":true,\"proxied\":true,\"ttl\":120}"
fi

websiteurl="${4}"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
ip="${5}"
dns="${6}"

if ( [ "${dns}" = "digitalocean" ] )
then
	/usr/local/bin/doctl compute domain records create --record-type A --record-name ${subdomain} --record-data ${ip} --record-ttl 120 ${domainurl}
fi

authkey="${3}"
subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
ip="${5}"
dns="${6}"

if ( [ "${dns}" = "exoscale" ] )
then
	/usr/bin/exo dns add A ${domainurl} -a ${ip} -n ${subdomain} -t 120
	#Alternative
	#/usr/bin/curl  -H "X-DNS-Token: ${authkey}" -H 'Accept: application/json' -H 'Content-Type: application/json' -X POST -d "{\"record\":{\"name\": \"${subdomain}\",\"record_type\": \"A\",\"content\": \"${ip}\",\"ttl\": 120}}" https://api.exoscale.com/dns/v1/domains/${domainurl}/records
fi

subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
#domain_url="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
domain_url="${4}"
ip="${5}"
dns="${6}"

if ( [ "${dns}" = "linode" ] )
then
	domain_id="`/usr/local/bin/linode-cli --json domains list | /usr/bin/jq --arg tmp_domain_url "${domain_url}" '(.[] | select(.domain | contains($tmp_domain_url)) | .id)'`"
	/usr/local/bin/linode-cli domains records-create $domain_id --type A --name ${subdomain} --target ${ip} --ttl_sec 120
fi

subdomain="`/bin/echo ${4} | /usr/bin/awk -F'.' '{print $1}'`"
domainurl="`/bin/echo ${4} | /usr/bin/cut -d'.' -f2-`"
ip="${5}"
dns="${6}"

if ( [ "${dns}" = "vultr" ] )
then
	HOME="`/bin/cat /home/homedir.dat`"
	export VULTR_API_KEY="`/bin/ls ${HOME}/.config/VULTRAPIKEY:* | /usr/bin/awk -F':' '{print $NF}'`"
	/usr/bin/vultr dns record create -m ${domainurl} -n ${subdomain} -t A -d "${ip}" --priority=10 --ttl=120
fi

