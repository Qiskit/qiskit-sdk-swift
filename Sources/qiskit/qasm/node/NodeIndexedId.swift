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
Node for an OPENQASM indexed id.
children[0] is an id node.
children[1] is an integer (not a node).
*/
final class NodeIndexedId: Node {

    let identifier: Node
    private(set) var _name: String = ""
    private(set) var line: Int = 0
    private(set) var file: String = ""
    private(set) var index: Int = -1

    init(identifier: Node, index: Node) {
        self.identifier = identifier
        if let _nnInt = index as? NodeNNInt {
            self.index = _nnInt.value
        }
        if let _id = self.identifier as? NodeId {
            // Name of the qreg
            self._name = _id.name
            // Source line number
            self.line = _id.line
            // Source file name
            self.file = _id.file
        }
    }

    var type: NodeType {
        return .N_INDEXEDID
    }

    var name: String {
        return self._name
    }

    var children: [Node] {
        return []
    }

    func qasm(_ prec: Int) -> String {
        var qasm: String = "\(self.identifier.qasm(prec))"
        if self.index >= 0 {
            qasm += " [\(self.index)]"
        }
        return qasm
    }
}
