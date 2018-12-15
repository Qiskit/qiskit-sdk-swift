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
Node for an OPENQASM program.
children is a list of nodes (statements).
*/
final class NodeProgram: Node  {

    private(set) var statements: [Node]

    init(statement: Node) {
        self.statements = [statement]
    }

    func addStatement(statement: Node) {
        self.statements.append(statement)
    }

    var type: NodeType {
        return .N_PROGRAM
    }

    var children: [Node] {
        return self.statements
    }

    func qasm(_ prec: Int) -> String {
        let qasms: [String] = self.statements.compactMap({ (node: Node) -> String in
            return node.qasm(prec)
        })
        return qasms.joined(separator: "\n")
    }
}
