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

/*
 Node for an OPENQASM if statement.
 children[0] is an id node.
 children[1] is an integer.
 children[2] is quantum operation node, including U, CX, custom_unitary,
 measure, reset, (and BUG: barrier, if).
 */
final class NodeIf: Node {

    let nodeId: Node
    let nodeNNInt: Node
    let nodeQop: Node

    init(identifier: Node, nninteger: Node, qop: Node) {
        nodeId = identifier
        nodeNNInt = nninteger
        nodeQop = qop
    }

    var type: NodeType {
        return .N_IF
    }

    var children: [Node] {
        return [self.nodeId,self.nodeNNInt,self.nodeQop]
    }

    func qasm(_ prec: Int) -> String {
        var qasm: String = "if"
        qasm += " (\(self.nodeId.qasm(prec))"
        qasm += " == \(self.nodeNNInt.qasm(prec))"
        qasm += " ) \(self.nodeQop.qasm(prec))"
        return qasm
    }
}
