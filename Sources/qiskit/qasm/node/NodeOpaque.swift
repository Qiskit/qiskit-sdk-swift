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
 Node for an OPENQASM opaque gate declaration.
 children[0] is an id node.
 If len(children) is 3, children[1] is an expressionlist node,
 and children[2] is an idlist node.
 Otherwise, children[1] is an idlist node.
 */
final class NodeOpaque: Node {

    let identifier: Node
    let arguments: Node
    let bitlist: Node?

    private(set) var _name: String = ""
    private(set) var line: Int = 0
    private(set) var file: String = ""
    private(set) var index: Int = 0

    var n_args: Int {
        return self.arguments.children.count
    }

    var n_bits: Int {
        return self.bitlist?.children.count ?? 0
    }

    init(identifier: Node, arguments: Node) {
        self.identifier = identifier
        self.arguments = arguments
        self.bitlist = nil
        if let _id = self.identifier as? NodeId{
            // Name of the qreg
            self._name = _id.name
            // Source line number
            self.line = _id.line
            // Source file name
            self.file = _id.file
            // Size of the register
            self.index = _id.index
        }
    }

    init(identifier: Node, arguments: Node, bitlist: Node) {
        self.identifier = identifier
        self.arguments = arguments
        self.bitlist = bitlist
        if let _id = self.identifier as? NodeId{
            // Name of the qreg
            self._name = _id.name
            // Source line number
            self.line = _id.line
            // Source file name
            self.file = _id.file
            // Size of the register
            self.index = _id.index
        }
    }

    var type: NodeType {
        return .N_OPAQUE
    }

    var name: String {
        return _name
    }

    var children: [Node] {
        var _children: [Node] = []
        _children.append(self.identifier)
        _children.append(self.arguments)
        if let l2 = bitlist {
            _children.append(l2)
        }
        return _children
    }

    func qasm(_ prec: Int) -> String {
        var qasm: String = "opaque"
        if let l2 = bitlist {
            qasm += " \(self.identifier.qasm(prec)) ( \(self.arguments.qasm(prec)) ) \(l2.qasm(prec));"
        } else {
            qasm += " \(self.identifier.qasm(prec)) \(self.arguments.qasm(prec));"
        }
        return qasm
    }
}
