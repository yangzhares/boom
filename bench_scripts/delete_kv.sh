#!/bin/bash -e

function delete_kv() {
       	let n=$1
        for ((index=0; index<n; index++))
       	do
           kv="consul_kv_$index"
       	   curl -s -XDELETE http://127.0.0.1:8500/v1/kv/bench/$kv_ >>/dev/null
       	done
}

delete_kv $1