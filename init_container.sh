#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# The container should be run with -v /var/run/docker.sock:/var/run/docker-host.sock --network host
# e.g. docker run --rm -v /var/run/docker.sock:/var/run/docker-host.sock --network host image-name

# To specify another docker socket, use the -e DOCKER_HOST=<path>
DOCKER_SOCK="${DOCKER_HOST:-/var/run/docker.sock}"

echo "Launching worker in daemon mode"
/home/funless/worker/bin/worker daemon

echo "proxy socket is listening on ${DOCKER_SOCK}"
test -S ${DOCKER_SOCK} || exec sudo /usr/bin/socat \
  UNIX-LISTEN:${DOCKER_SOCK},fork,mode=660,user=funless \
  UNIX-CONNECT:/var/run/docker-host.sock
