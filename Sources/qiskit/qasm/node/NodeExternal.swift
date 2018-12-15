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
 Node for an OPENQASM external function.
 children[0] is an id node with the name of the function.
 children[1] is an expression node.
 */
final class NodeExternal: NodeRealValue {

    private static let externalFunctions = ["sin", "cos", "tan", "exp", "ln", "sqrt"]

    let operation: String
    let expression: Node

    init(operation: String, expression: Node) {
        self.operation = operation
        self.expression = expression
    }

    var type: NodeType {
        return .N_EXTERNAL
    }

    var children: [Node] {
        return [self.expression]
    }

    func qasm(_ prec: Int) -> String {
        var qasm = self.operation
        qasm += "( \(self.expression.qasm(prec)) )"
        return qasm
    }

    func real(_ nested_scope: [[String:NodeRealValue]]?) throws -> SymbolicValue {
        if let expr = self.expression as? NodeRealValue {
            let arg = try expr.real(nested_scope)
            if self.operation == "sin" {
                return sin(arg)
            }
            if self.operation == "cos" {
                return cos(arg)
            }
            if self.operation == "tan" {
                return tan(arg)
            }
            if self.operation == "exp" {
                return exp(arg)
            }
            if self.operation == "ln" {
                return log(arg)
            }
            if self.operation == "sqrt" {
                return arg.squareRoot()
            }
        }
        throw QasmError.errorExternal(qasm: self.qasm(15))
    }
}
