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
 Built-in Single Qubit Gate class
 */
public final class UBase: Gate, CopyableInstruction {

    public let instructionComponent: InstructionComponent

    fileprivate init(_ params: [Double], _ qubit: QuantumRegisterTuple, _ circuit: QuantumCircuit) throws {
        if params.count != 3 {
            throw QISKitError.not3Params
        }
        self.instructionComponent = InstructionComponent("U", params, [qubit], circuit)
    }

    private init(_ name: String, _ params: [Double], _ args: [RegisterArgument], _ circuit: QuantumCircuit) {
        self.instructionComponent = InstructionComponent(name, params, args, circuit)
    }

    func copy(_ c: QuantumCircuit) -> Instruction {
        return UBase(self.name, self.params, self.args, c)
    }

    public var description: String {
        let theta = self.params[0].format(15)
        let phi = self.params[1].format(15)
        let lam = self.params[2].format(15)
        return self._qasmif("\(name)(\(theta),\(phi),\(lam)) \(self.args[0].identifier)")
    }

    /**
     Invert this gate.
     U(theta,phi,lambda)^dagger = U(-theta,-lambda,-phi)
     */
    @discardableResult
    public func inverse() -> UBase {
        self.instructionComponent.params[0] = -self.instructionComponent.params[0]
        let phi = self.params[1]
        self.instructionComponent.params[1] = -self.instructionComponent.params[2]
        self.instructionComponent.params[2] = -phi
        return self
    }

    /**
     Reapply this gate to corresponding qubits in circ.
     */
    public func reapply(_ circ: QuantumCircuit) throws {
        try self._modifiers(circ.u_base(self.params, self.args[0] as! QuantumRegisterTuple))
    }
}

extension QuantumCircuit {

    /**
     Apply U to q
     */
    @discardableResult
    public func u_base(_ params: [Double], _ q: QuantumRegisterTuple) throws -> UBase {
        try self._check_qubit(q)
        return try self._attach(UBase(params, q, self)) as! UBase
    }
}

extension CompositeGate {

    /**
     Apply U to q
     */
    @discardableResult
    public func u_base(_ params: [Double], _ q: QuantumRegisterTuple) throws -> UBase {
        try self._check_qubit(q)
        return try self._attach(UBase(params, q, self.circuit)) as! UBase
    }
}
