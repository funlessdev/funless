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

export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

.ONESHELL:

.PHONY: build-core-image build-worker-image credo dial test

SECRET_KEY_BASE ?= $(shell mix phx.gen.secret)
## Compile core docker image
build-core-image: 
	docker build \
	--build-arg SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
	--build-arg MIX_ENV="prod" \
	--build-arg COMPONENT="core" \
	-t core .

## Compile worker docker image
build-worker-image: 
	docker build --build-arg COMPONENT="worker" \
	--build-arg MIX_ENV="prod" -t worker .

## Run credo --strict
credo: 
	mix credo --strict

## Run dialyzer
dial:
	mix dialyzer

 ## Run test suite, launch Postgres with docker-compose
test: 
	function tearDown {
		docker compose -f docker-compose.yml down
	}
	trap tearDown EXIT
	mix deps.get
	docker compose -f docker-compose.yml up --detach
	mix core.utest
	mix worker.utest
	mix core.itest
