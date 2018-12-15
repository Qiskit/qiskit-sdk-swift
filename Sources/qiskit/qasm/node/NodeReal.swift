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
Node for an OPENQASM real number.
This node has no children. The data is in the value field.
*/
class NodeReal: NodeRealValue {

    let value: Double

    init(id: Double) {
        self.value = id
    }

    var type: NodeType {
        return .N_REAL
    }

    var children: [Node] {
        return []
    }

    func qasm(_ prec: Int) -> String {
        return self.value.format(prec)
    }

    func real(_ nested_scope: [[String:NodeRealValue]]?) throws -> SymbolicValue {
        return SymbolicValue(self.value)
    }
}

final class NodeRealPI: NodeReal {

    init() {
        super.init(id: Double.pi)
    }

    override func qasm(_ prec: Int) -> String {
        return SymbolicValue.pi.format(prec)
    }

    override func real(_ nested_scope: [[String:NodeRealValue]]?) throws -> SymbolicValue {
        return SymbolicValue.pi
    }
}
