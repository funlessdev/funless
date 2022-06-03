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
FROM elixir:1.13.4 as build

# install build dependencies
RUN apt-get update && apt-get install -y build-essential curl
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN mkdir /app
WORKDIR /app

# install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ENV MIX_ENV=prod

COPY . .

# COPY config config
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

RUN mix compile

# build release
# at this point we should copy the rel directory but
# we are not using it so we can omit it
# COPY rel rel
RUN mix release

# prepare release image
# FROM elixir:1.13.4-alpine AS app

# # install runtime dependencies
# RUN apk add --update bash openssl-dev

# EXPOSE 4000
# ENV MIX_ENV=prod

# # prepare app directory
# RUN mkdir /app
# WORKDIR /app

# # copy release to app container
# COPY --from=build /app/_build/prod/rel/core .
# RUN chown -R nobody: /app
# USER nobody

ENV HOME=/app
CMD ["bash", "_build/prod/rel/core/bin/core", "start"]