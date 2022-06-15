// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

mod atoms;
use rustler::NifStruct;

#[derive(Debug, PartialEq, NifStruct)]
#[module = "FnWorker"]
struct FnWorker {
    id: i32,
}

#[rustler::nif]
fn select(workers: Vec<FnWorker>) -> Option<FnWorker> {
    select_worker(&workers)
}

rustler::init!("Elixir.Core.Nif.Scheduler", [select]);

fn select_worker(workers: &Vec<FnWorker>) -> Option<FnWorker> {
    (!workers.is_empty()).then(|| FnWorker { id: workers[0].id })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn select_none_when_workers_empty() {
        let result = select_worker(&vec![]);
        assert_eq!(result, None);
    }

    #[test]
    fn select_first_worker() {
        let expected = FnWorker { id: 1 };
        let workers = vec![FnWorker { id: 1 }, FnWorker { id: 2 }];
        let result = select_worker(&workers);
        assert_eq!(result, Some(expected));
    }
}
