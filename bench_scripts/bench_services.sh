#!/bin/bash -e

leader=http://10.225.4.105:8500
# assume three servers
servers=( http://10.225.4.105:8500 http://10.225.4.116:8500 http://10.225.4.117:8500 )

# consul agent as client mode
client=http://127.0.0.1:8500

keyarray=(64 128 256 512)

for keysize in ${keyarray[@]}; do
  echo write, 64 client, $keysize key size, to leader
  ./boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader| grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo write, 128 client, $keysize key size, to leader
  ./boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader

  echo write, 256 client, $keysize key size, to leader
  ./boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
  
  echo write, 512 client, $keysize key size, to leader
  ./boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader

  echo write, 1024 client, $keysize key size, to leader
  ./boom -m PUT -n 10 -c 1 -m PUT -consul -type svc -size $keysize $leader

  echo write, 64 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 21 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done

  echo write, 128 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done


  echo write, 256 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done

  echo write, 512 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done

  echo write, 1024 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./boom -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 42 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
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
    ./boom -m PUT -n 850 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 85 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done
  sleep 3
  for pid in $(pgrep 'boom'); do
    while kill -0 "$pid" 2> /dev/null; do
      sleep 3
    done
  done

  echo read, 1 client, $keysize key size, to leader
  ./boom -n 100 -c 1 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo read, 64 client, $keysize key size, to leader
  ./boom -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo


  echo read, 128 client, $keysize key size, to leader
  ./boom -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo read, 256 client, $keysize key size, to leader
  ./boom -n 25600 -c 256 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

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

done