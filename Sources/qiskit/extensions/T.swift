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
 T=sqrt(S) Clifford phase gate.
 */
public final class TGate: CompositeGate, CopyableInstruction {

    public let instructionComponent: InstructionComponent
    public let compositeGateComponent: CompositeGateComponent

    fileprivate init(_ qubit: QuantumRegisterTuple, _ circuit: QuantumCircuit) throws {
        self.instructionComponent = InstructionComponent("t", [], [qubit], circuit)
        self.compositeGateComponent = CompositeGateComponent()
        try self.u1(Double.pi/4.0,qubit)
    }

    private init(_ name: String, _ params: [Double], _ args: [RegisterArgument], _ circuit: QuantumCircuit, _ compositeGateComponent: CompositeGateComponent) {
        self.instructionComponent = InstructionComponent(name, params, args, circuit)
        self.compositeGateComponent = compositeGateComponent
    }

    func copy(_ c: QuantumCircuit) -> Instruction {
        return TGate(self.name, self.params, self.args, c,self.compositeGateComponent.copy(c))
    }

    public var description: String {
        let u1Gate: U1Gate = self.compositeGateComponent.data[0] as! U1Gate
        let qubit = u1Gate.args[0] as! QuantumRegisterTuple
        let phi: Double = u1Gate.params[0]
        if phi > 0 {
            return self.compositeGateComponent.data[0]._qasmif("\(self.name) \(qubit.identifier)")
        }
        return self.compositeGateComponent.data[0]._qasmif("tdg \(qubit.identifier)")
    }

    /**
     Reapply this gate to corresponding qubits in circ.
     */
    public func reapply(_ circ: QuantumCircuit) throws {
        try self._modifiers(circ.t(self.args[0] as! QuantumRegisterTuple))
    }
}

extension QuantumCircuit {

    /**
     Apply T to q.
     */
    public func t(_ q: QuantumRegister) throws -> InstructionSet {
        let gs = InstructionSet()
        for j in 0..<q.size {
            gs.add(try self.t(QuantumRegisterTuple(q,j)))
        }
        return gs
    }

    /**
     Apply T to q.
     */
    @discardableResult
    public func t(_ q: QuantumRegisterTuple) throws -> TGate {
        try  self._check_qubit(q)
        return self._attach(try TGate(q, self)) as! TGate
    }

    /**
     Apply Tdg to q.
     */
    public func tdg(_ q: QuantumRegisterTuple) throws -> TGate {
        return try self.t(q).inverse()
    }

}

extension CompositeGate {

    /**
     Apply T to q.
     */
    public func t(_ q: QuantumRegister) throws -> InstructionSet {
        let gs = InstructionSet()
        for j in 0..<q.size {
            gs.add(try self.t(QuantumRegisterTuple(q,j)))
        }
        return gs
    }

    /**
     Apply T to q.
     */
    @discardableResult
    public func t(_ q: QuantumRegisterTuple) throws -> TGate {
        try  self._check_qubit(q)
        return self._attach(try TGate(q, self.circuit)) as! TGate
    }

    /**
     Apply Tdg to q.
     */
    public func tdg(_ q: QuantumRegisterTuple) throws -> TGate {
        return try self.t(q).inverse()
    }

}
