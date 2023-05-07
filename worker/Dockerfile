# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The version of Alpine to use for the final image
# This should match the version of Alpine that the `elixir:1.14-alpine` image uses
ARG ALPINE_VERSION=3.17
ARG MIX_ENV=prod

FROM elixir:1.14-alpine AS builder

ARG MIX_ENV

ENV MIX_ENV=${MIX_ENV}

# By convention, /opt is typically used for applications
WORKDIR /opt/app

# This step installs all the build tools we'll need
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache git build-base bash curl openssl ncurses-libs libgcc && \
    mix local.rebar --force && \
    mix local.hex --force

# This copies our app source code into the build container
COPY . .

RUN mix deps.get --only "${MIX_ENV}"
RUN mix compile
RUN MIX_ENV=${MIX_ENV} mix release

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:${ALPINE_VERSION}

ARG MIX_ENV
ARG NODE_IP=""
ARG DEPLOY_ENV=""

# The name of your application/release (required)
RUN apk update && \
    apk upgrade && \
    apk add --no-cache libstdc++ libgcc ncurses-libs

ENV REPLACE_OS_VARS=true \
    USER=funless \
    MIX_ENV=${MIX_ENV} \ 
    NODE_IP=${NODE_IP} \
    DEPLOY_ENV=${DEPLOY_ENV}


WORKDIR "/home/${USER}/app"

# Creates an unprivileged user to be used exclusively to run the Phoenix app
RUN addgroup -g 1000 -S "${USER}" && adduser -s /bin/sh -u 1000 -G "${USER}" \
    -h "/home/${USER}" -D "${USER}" && su "${USER}"

# Everything from this line onwards will run in the context of the unprivileged user.
USER "${USER}"

COPY --chown="${USER}":"${USER}" --from=builder /opt/app/_build/${MIX_ENV}/rel/${COMPONENT}/ .

CMD  ["sh", "-c", "bin/run"]
