#!/bin/bash -e

function deregister() {
       	curl -s -XPUT -d "{\"Node\": \"node\"}" http://127.0.0.1:8500/v1/catalog/deregister >>/dev/null
}

deregister