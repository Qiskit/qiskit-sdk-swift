// Copyright 2017 IBM RESEARCH. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================

struct QPT {
static let QASM = """
OPENQASM 2.0;
include "qelib1.inc";
gate pre q { }   // pre-rotation
gate post q { }  // post-rotation
qreg q[1];
creg c[1];
pre q[0];
barrier q;
h q[0];
barrier q;
post q[0];
measure q[0] -> c[0];
"""
}
