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
 rotation around the x-axis
 */
public final class RXGate: Gate, CopyableInstruction {

    public let instructionComponent: InstructionComponent

    fileprivate init(_ theta: Double, _ qubit: QuantumRegisterTuple, _ circuit: QuantumCircuit) {
        self.instructionComponent = InstructionComponent("rx", [theta], [qubit], circuit)
    }

    private init(_ name: String, _ params: [Double], _ args: [RegisterArgument], _ circuit: QuantumCircuit) {
        self.instructionComponent = InstructionComponent(name, params, args, circuit)
    }

    func copy(_ c: QuantumCircuit) -> Instruction {
        return RXGate(self.name, self.params, self.args, c)
    }

    public var description: String {
        let theta = self.params[0].format(15)
        return self._qasmif("\(name)(\(theta)) \(self.args[0].identifier)")
    }

    /**
     Invert this gate.
     rx(theta)^dagger = rx(-theta)
     */
    @discardableResult
    public func inverse() -> RXGate {
        self.instructionComponent.params[0] = -self.instructionComponent.params[0]
        return self
    }

    /**
     Reapply this gate to corresponding qubits in circ.
     */
    public func reapply(_ circ: QuantumCircuit) throws {
        try self._modifiers(circ.rx(self.params[0], self.args[0] as! QuantumRegisterTuple))
    }
}

extension QuantumCircuit {

    /**
     Apply rx to q.
     */
    public func rx(_ theta: Double, _ q: QuantumRegister) throws -> InstructionSet {
        let gs = InstructionSet()
        for j in 0..<q.size {
            gs.add(try self.rx(theta, QuantumRegisterTuple(q,j)))
        }
        return gs
    }

    /**
     Apply rx to q.
     */
    @discardableResult
    public func rx(_ theta: Double, _ q: QuantumRegisterTuple) throws -> RXGate {
        try  self._check_qubit(q)
        return self._attach(RXGate(theta, q, self)) as! RXGate
    }
}

extension CompositeGate {

    /**
     Apply rx to q.
     */
    public func rx(_ theta: Double, _ q: QuantumRegister) throws -> InstructionSet {
        let gs = InstructionSet()
        for j in 0..<q.size {
            gs.add(try self.rx(theta, QuantumRegisterTuple(q,j)))
        }
        return gs
    }

    /**
     Apply rx to q.
     */
    @discardableResult
    public func rx(_ theta: Double, _ q: QuantumRegisterTuple) throws -> RXGate {
        try  self._check_qubit(q)
        return self._attach(RXGate(theta, q, self.circuit)) as! RXGate
    }
}
