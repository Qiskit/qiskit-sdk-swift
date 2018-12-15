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

import Foundation

enum NodeType: String {
    case N_BARRIER = "barrier"
    case N_BINARYOP = "binop"
    case N_CNOT = "cnot"
    case N_CREG = "creg"
    case N_CUSTOMUNITARY = "custom_unitary"
    case N_EXPRESSIONLIST = "expression_list"
    case N_EXTERNAL = "external"
    case N_GATE = "gate"
    case N_GATEBODY = "gate_body"
    case N_GATEOPLIST = "gateoplist"
    case N_ID = "id"
    case N_IDLIST = "id_list"
    case N_IF = "if"
    case N_INCLUDE = "incld"
    case N_INDEXEDID = "indexed_id"
    case N_INT = "int"
    case N_MAGIC = "magic"
    case N_MAINPROGRAM = "main_program"
    case N_MEASURE = "measure"
    case N_OPAQUE = "opaque"
    case N_PREFIX = "prefix"
    case N_PRIMARYLIST = "primary_list"
    case N_PROGRAM = "program"
    case N_REAL = "real"
    case N_RESET = "reset"
    case N_QREG = "qreg"
    case N_UNIVERSALUNITARY = "universal_unitary"
}

protocol Node {
    var type: NodeType { get }
    var children: [Node] { get }

    func qasm(_ prec: Int) -> String
}
