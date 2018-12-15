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
 Node for an OPENQASM gate definition.
 children[0] is an id node.
 If len(children) is 3, children[1] is an idlist node,
 and children[2] is a gatebody node.
 Otherwise, children[1] is an expressionlist node,
 children[2] is an idlist node, and children[3] is a gatebody node.
 */
final class NodeGate: Node {

    let identifier: Node
    let arguments: Node?
    let bitlist: Node
    let body: Node

    private(set) var _name: String = ""
    private(set) var line: Int = 0
    private(set) var file: String = ""
    private(set) var index: Int = 0

    var n_args: Int {
        return arguments?.children.count ?? 0
    }

    var n_bits: Int {
        return self.bitlist.children.count
    }

    init(identifier: Node, bitlist: Node, body: Node) {
        self.identifier = identifier
        self.arguments = nil
        self.bitlist = bitlist
        self.body = body

        if let _id = self.identifier as? NodeId {
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

    init(identifier: Node, arguments: Node, bitlist: Node, body: Node) {
        self.identifier = identifier
        self.arguments = arguments
        self.bitlist = bitlist
        self.body = body

        if let _id = self.identifier as? NodeId {
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
        return .N_GATE
    }

    var name: String {
        return _name
    }

    var children: [Node] {
        var _children: [Node] = []
        _children.append(self.identifier)
        if let args = arguments {
            _children.append(args)
        }
        _children.append(self.bitlist)
        _children.append(self.body)
        return _children
    }

    func qasm(_ prec: Int) -> String {
        var qasm = "gate \(self.name)"
        if let args = self.arguments {
            qasm += "(" + args.qasm(prec) + ")"
        }
        qasm += " \(self.bitlist.qasm(prec))\n"
        qasm += "{\n \(self.body.qasm(prec)) \n}"
        return qasm
    }
}
