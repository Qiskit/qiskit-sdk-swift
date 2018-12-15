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
Node for an OPENQASM expression list.
children are expression nodes.
*/
final class NodeExpressionList: Node {

    private(set) var expressionList: [Node]

    init(expression: Node) {
        self.expressionList = [expression]
    }

    func addExpression(exp: Node) {
        self.expressionList.insert(exp, at: 0)
    }

    var type: NodeType {
        return .N_EXPRESSIONLIST
    }

    var children: [Node] {
        return self.expressionList
    }

    func qasm(_ prec: Int) -> String {
        var qasms: [String] = []
        for node in self.expressionList {
            qasms.append(node.qasm(prec))
        }
        return qasms.joined(separator: ",")
    }
}
