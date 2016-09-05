#!/bin/bash -e

function generate_dns() {
       	let n=$1
        client=$2
        for ((index=0; index<n; index++))
       	do
       		service_name="consul_service_${client}-$index"
       		let res=`curl -s http://127.0.0.1:8500/v1/catalog/service/${service_name} | jq 'length'`
       		if [ $res -ne 0 ]
       		then
       			echo "${service_name}.service.consul   	A" >>dns.txt
       		else
       			echo "${service_name} not exist in Consul"
       			exit 1
       		fi
       	done
}

generate_dns $1 $2