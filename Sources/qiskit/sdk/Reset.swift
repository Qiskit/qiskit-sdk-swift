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

/**
 Qubit reset
 */
public final class Reset: Instruction, CopyableInstruction {

    public let instructionComponent: InstructionComponent

    init(_ qubit: QuantumRegisterTuple, _ circuit: QuantumCircuit) {
        self.instructionComponent = InstructionComponent("reset", [], [qubit], circuit)
    }

    private init(_ name: String, _ params: [Double], _ args: [RegisterArgument], _ circuit: QuantumCircuit) {
        self.instructionComponent = InstructionComponent(name, params, args, circuit)
    }

    func copy(_ c: QuantumCircuit) -> Instruction {
        return Reset(self.name, self.params, self.args, c)
    }

    public var description: String {
        return "\(name) \(self.args[0].identifier)"
    }

    @discardableResult
    public func inverse() -> Reset {
        preconditionFailure("inverse not implemented")
    }

    /**
     Reapply this gate to corresponding qubits in circ.
     */
    public func reapply(_ circ: QuantumCircuit) throws {
        try self._modifiers(try circ.reset(self.args[0] as! QuantumRegisterTuple))
    }
}
