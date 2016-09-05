#!/bin/bash -e

leader=http://10.225.4.105:8500
# assume three servers
servers=( http://10.225.4.105:8500 http://10.225.4.116:8500 http://10.225.4.117:8500 )

# consul agent as client mode
client=http://127.0.0.1:8500

keyarray=( 64 128 256 512)