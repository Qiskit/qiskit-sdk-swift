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

final class NodeMainProgram: Node {

    let magic: Node
    let incld: Node?
    let program: Node

    init(magic: Node, program: Node) {
        self.magic = magic
        self.incld = nil
        self.program = program
    }

    init(magic: Node, incld: Node, program: Node) {
        self.magic = magic
        self.incld = incld
        self.program = program
    }

    var type: NodeType {
        return .N_MAINPROGRAM
    }

    var children: [Node] {
        return []
    }

    func qasm(_ prec: Int) -> String {
        var qasm: String = self.magic.qasm(prec)
        qasm += "\(self.incld?.qasm(prec) ?? "")\n"
        qasm += "\(self.program.qasm(prec))\n"
        return qasm
    }
}
