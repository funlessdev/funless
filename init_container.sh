#!/bin/bash

# The container should be run with -v /var/run/docker.sock:/var/run/docker-host.sock --network host

echo "Launching worker in daemon mode"
/home/funless/worker/bin/worker daemon

echo "proxy socket is listening on /var/run/docker.sock"
test -S /var/run/docker.sock || exec sudo /usr/bin/socat \
  UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=funless \
  UNIX-CONNECT:/var/run/docker-host.sock
