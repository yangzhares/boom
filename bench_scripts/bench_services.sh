#!/bin/bash -e

leader=http://10.225.4.105:8500
# assume three servers
servers=(http://10.225.4.105:8500 http://10.225.4.116:8500 http://10.225.4.117:8500)

# consul agent as client mode
agent=http://127.0.0.1:8500

bench=/tmp/bench/service

leader=${bench}/leader
server=${bench}/server
client=${bench}/client

leader_write=${leader}/write
leader_read=${leader}/read

if [ ! -d ${leader_write} ]
then
    mkdir -p ${leader_write}
fi

if [ ! -d ${leader_read} ]
then
    mkdir -p ${leader_read}
fi

server_write=${server}/write
server_read=${server}/read

if [ ! -d ${server_write} ]
then
    mkdir -p ${server_write}
fi

if [ ! -d ${server_read} ]
then
    mkdir -p ${server_read}
fi

client_write=${client}/write
client_read=${client}/read

if [ ! -d ${client_write} ]
then
    mkdir -p ${client_write}
fi

if [ ! -d ${client_read} ]
then
    mkdir -p ${client_read}
fi

log=${bench}/service.log

function clean() {
    rm -f ${output}
}

function init() {
    if [ $index -eq 0 ] && [ -e $result ] 
    then
        >$result
        echo "REQUESTS/sec,AVERAGE RESPONSE(sec),90TH PERCENTILE LATENCY(sec)" >${result}
    elif [ $index -eq 0 ]
    then 
        echo "REQUESTS/sec,AVERAGE RESPONSE(sec),90TH PERCENTILE LATENCY(sec)" >${result}
    fi
}

#function parse() {
#    if [ $index -eq 0 ]
#    then
#        echo "REQUESTS/sec,AVERAGE RESPONSE(sec),90TH PERCENTILE LATENCY(sec)" >${result}
#    fi 
#
#    req=`cat ${output} | grep -e "Requests/sec" | cut -d':' -f2 |  xargs echo`
#    avg=`cat ${output} | grep -e "Average" | cut -d':' -f2 | xargs echo | cut -d' ' -f1`
#    latency=`cat ${output} | grep  -e "90%" | cut -d' ' -f5`
#
#    echo ${req},${avg},${latency} >>${result}
#}

# client -> Consul client -> Consul Fellower -> Consul Leader
function client_write_service() {
    out=${client_write}/$1
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_client_write_service_$1.csv"
    
    init
    n=`expr $1 \* 100`
    ./boom -n $n -c $1 -o consul -f $result -m PUT -consul -type svc ${agent}
}

# client -> Consul Fellower -> Consul Leader
function server_write_service() {
    out=${server_write}/$1
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    
    result="${out}/result_server_write_service_$1.csv"
    init

    c=`expr $1 / 3`
    n=`expr $1 / 3 \* 100`

    for server in ${servers[@]}; do
        ./boom -n $n -c $c -o consul -f $result -m PUT -consul -type svc ${server} &
    done
    sleep 3

    for pid in $(pgrep 'boom'); do
        while kill -0 "$pid" 2> /dev/null; do
            sleep 3
        done
    done
}

# client -> Consul Leader
function leader_write_service() {
    out=${leader_write}/$1
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_leader_write_service_$1.csv"
    
    init
    n=`expr $1 \* 100`
    ./boom -n $n -c $1 -o consul -f $result -m PUT -consul -type svc ${leader}
}


# client -> Consul client -> Consul Fellower -> Consul Leader
function client_read_service() {
    out=${client_read}/$1
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_client_read_service_$1.csv"
    
    init
    n=`expr $1 \* 100`
    ./boom -n $n -c $1 -o consul -f $result -consul -type svc ${agent}
}

# client -> Consul Fellower -> Consul Leader
function server_read_service() {
    out=${server_read}/$1
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    
    c=`expr $1 / 3`
    n=`expr $1 / 3 \* 100`
    result="${out}/result_server_read_service_$1.csv"
    init

    for server in ${servers[@]}; do
        ./boom -n $n -c $c -o consul -f $result -consul -type svc ${server}
    done
}

# client -> Consul Leader
function leader_read_service() {
    out=${leader_read}/$1
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_leader_read_service_$1.csv"
    
    init
    n=`expr $1 \* 100`
    ./boom -n $n -c $1 -o consul -f $result -consul -type svc ${leader}
}


function test_write_service() {
    #in=${bench}/tmp.write.service.${index}.txt
    result="${client}/result_write_service_leader_2.csv"

    init
    ../boom -n 64 -c 2 -o consul -f $result -m PUT -consul -type svc http://127.0.0.1:8500 >${output}
}

function test_read_service() {
    #in=${bench}/tmp.read.service.${index}.txt
    result="${client}/result_read_service_leader_2.csv"
    init
    ../boom -n 64 -c 2 -o consul -f $result -m GET -consul -type svc http://127.0.0.1:8500 >${output}
}

function test_write_kv() {
    array=(64)
    
    for keysize in ${array[@]}; do
        #in=${bench}/tmp.read.kv.${keysize}.${index}.txt
        #echo write, 64 client, $keysize key size, to leader
        result="${client}/result_write_kv_${keysize}_leader_2.csv"
        
        init
        ../boom -n 64 -c 2 -o consul -f $result -m PUT -consul -type kv -size ${keysize} http://127.0.0.1:8500 >${output}
    done
}

number=$1
client_size=(64) # 128 256 512 1024)

for ((index=0; index<number; index++)) {
    #test_write_service
    #test_read_service
    #test_write_kv

    for i in ${client_size[@]}
    do
        client_write_service $i
        sleep 3
        client_read_service $i

        #server_write_service $i
        #sleep 3
        #server_read_service $i

        #leader_write_service $i
        #sleep 3
        #leader_read_service $i
    done
}