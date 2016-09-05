#!/bin/bash -e

leader=http://10.225.4.105:8500
# assume three servers
servers=( http://10.225.4.105:8500 http://10.225.4.116:8500 http://10.225.4.117:8500 )

# consul agent as client mode
agent=http://127.0.0.1:8500

keyarray=(64 128 256 512)

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
output=${bench}/output.txt

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
    out=${client_write}/$2
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_client_write_service_$2.csv"
    
    init
    ../boom -n $1 -c $2 -o consul -f $result -m PUT -consul -type svc ${agent}
}

# client -> Consul Fellower -> Consul Leader
function server_write_service() {
    out=${server_write}/$2
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    
    result="${out}/result_server_write_service_$2.csv"
    init

    for server in ${servers[@]}; do
        ../boom -n $1 -c $2 -o consul -f $result -m PUT -consul -type svc ${server} &
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
    out=${leader_write}/$2
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_leader_write_service_$2.csv"
    
    init
    ../boom -n $1 -c $2 -o consul -f $result -m PUT -consul -type svc ${leader}
}


# client -> Consul client -> Consul Fellower -> Consul Leader
function client_read_service() {
    out=${client_read}/$2
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_client_read_service_$2.csv"
    
    init
    ../boom -n $1 -c $2 -o consul -f $result -consul -type svc ${agent}
}

# client -> Consul Fellower -> Consul Leader
function server_read_service() {
    out=${server_read}/$2
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    
    result="${out}/result_server_read_service_$2.csv"
    init

    for server in ${servers[@]}; do
        ../boom -n $1 -c $2 -o consul -f $result -consul -type svc ${server}
    done
}

# client -> Consul Leader
function leader_read_service() {
    out=${leader_read}/$2
    if [ ! -d ${out} ]
    then
        mkdir -p ${out}
    fi 
    result="${out}/result_leader_read_service_$2.csv"
    
    init
    ../boom -n $1 -c $2 -o consul -f $result -consul -type svc ${leader}
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

function services() {
        echo write, 64 client, $keysize key size, to leader
        boom -m PUT -n 640 -c 64 -m PUT -consul -type svc -size $keysize $leader >$tmp

        parse leader 64 write

        echo write, 128 client, $keysize key size, to leader
        boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader

        echo write, 256 client, $keysize key size, to leader
        boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
  
        echo write, 512 client, $keysize key size, to leader
        boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader

        echo write, 1024 client, $keysize key size, to leader
        boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader

        echo write, 64 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 21 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
        done

        echo write, 128 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
        done


        echo write, 256 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
        done

        echo write, 512 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
        done

        echo write, 1024 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
        done

        # wait for all booms to start running
        sleep 3
        # wait for all booms to finish
        for pid in $(pgrep 'boom'); do
            while kill -0 "$pid" 2> /dev/null; do
                sleep 3
                done
        done

        echo write, 256 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            boom -m PUT -n 850 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 85 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
        done
        sleep 3
        
        for pid in $(pgrep 'boom'); do
            while kill -0 "$pid" 2> /dev/null; do
                sleep 3
            done
        done

        echo read, 1 client, $keysize key size, to leader
        boom -n 100 -c 1 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

        echo read, 64 client, $keysize key size, to leader
        boom -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo


        echo read, 128 client, $keysize key size, to leader
        boom -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

        echo read, 256 client, $keysize key size, to leader
        boom -n 25600 -c 256 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

        echo read, 512 client, $keysize key size, to leader
        ./boom -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

        echo read, 1024 client, $keysize key size, to leader
        ./boom -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

        echo read, 64 client, $keysize key size, to all servers
        # bench servers one by one, so it doesn't overload this benchmark machine
        # It doesn't impact correctness because read request doesn't involve peer interaction.
        for i in ${servers[@]}; do
            ./boom -n 21000 -c 21 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
        done

        echo read, 128 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            ./boom -n 21000 -c 21 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
        done

        echo read, 256 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            ./boom -n 85000 -c 85 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
        done

        echo read, 512 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            ./boom -n 85000 -c 85 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
        done

        echo read, 1024 client, $keysize key size, to all servers
        for i in ${servers[@]}; do
            ./boom -n 85000 -c 85 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
        done
}

number=$1

for ((index=0; index<number; index++)) {
    #test_write_service
    #test_read_service
    #test_write_kv

    #client_write_service 64 2
    #client_read_service 64 2

    server_write_service 64 2
    server_read_service 64 2
}

clean