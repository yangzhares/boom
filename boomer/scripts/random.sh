#!/bin/bash -e

function generate_value() {
    value_size=$1
    dd if=/dev/urandom bs=2048 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=${value_size} count=1 2>/dev/null
}

generate_value $1