#!/bin/bash -e

function deregister() {
       	let n=$1
		client=$2
        for ((index=0; index<n; index++))
       	do
#      		cat <<EOF >service.json
#{
#      	"Node": "consul_service_$index.service.consul"
#}
#EOF
       		curl -s -XPUT -d "{\"Node\": \"consul_service_node_$client-$index\"}" http://127.0.0.1:8500/v1/catalog/deregister >>/dev/null
       	done
}

deregister $1 $2