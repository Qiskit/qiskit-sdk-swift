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

final class NodeGopList: Node {

   private(set) var gateops: [Node]

    init(gateop: Node) {
        self.gateops = [gateop]
    }

    func addIdentifier(gateop: Node) {
        self.gateops.append(gateop)
    }

    func calls() -> [String] {
        // Return a list of custom gate names in this gate body."""
        var _calls: [String] = []
        for g in self.gateops {
            if let gop = g as? NodeCustomUnitary {
                _calls.append(gop.name)
            }
        }
        return _calls
    }

    var type: NodeType {
        return .N_GATEOPLIST
    }

    var children: [Node] {
        return self.gateops
    }

    func qasm(_ prec: Int) -> String {
        let qasms: [String] = self.gateops.compactMap({ (node: Node) -> String in
            return node.qasm(prec)
        })
        return qasms.joined(separator: "\n")
    }
}

