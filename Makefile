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

.PHONY: build-core-image build-worker-image credo dial test help
.DEFAULT: help

help: 
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_\-.*]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

## Compile core docker image
build-core-image: 
	docker build -t core -f Dokerfile.core .

## Compile worker docker image
build-worker-image: 
	docker build -t worker -f Dokerfile.worker .

## Run credo --strict
credo: 
	mix credo --strict

## Run dialyzer
dial:
	mix dialyzer

 ## Run test suite, launch Postgres with docker-compose
test: 
	mix deps.get
	docker compose -f docker-compose.yml up --detach
	mix core.test
	mix worker.test
	mix core.integration_test
	docker compose -f docker-compose.yml down
