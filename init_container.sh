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

echo "Launching worker in daemon mode"
/home/funless/worker/bin/worker daemon

echo "proxy socket is listening on /var/run/docker.sock"
test -S /var/run/docker.sock || exec sudo /usr/bin/socat \
  UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=funless \
  UNIX-CONNECT:/var/run/docker-host.sock
