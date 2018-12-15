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

// Name of Experiment: W3test v1
// example of W-state |001> + |010> + |100>
// found by user lukasknips at http://ibm.biz/qiskit-W3-Example
struct W3Test {
static let QASM = """
OPENQASM 2.0;
include "qelib1.inc";


qreg q[5];
creg c[5];

u3(-1.230960000000000,0,0) q[0];
u3(pi/4,0,0) q[1];
cx q[0],q[2];
z q[2];
h q[2];
cx q[1],q[2];
z q[2];
u3(pi/4,0,0) q[1];
h q[2];
cx q[1],q[2];
measure q[0] -> c[0];
measure q[1] -> c[1];
measure q[2] -> c[2];
"""
}
