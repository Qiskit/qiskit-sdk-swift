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

public class QuantumCircuitHeader {

    public var name: String {
        return "OPENQASM"
    }
    public var majorVersion: Int {
        return 2
    }
    public var minorVersion: Int {
        return 0
    }
    public var value: String {
        return "\(self.name) \(self.majorVersion).\(self.minorVersion);"
    }

    public init() {
    }

    public func copy() -> QuantumCircuitHeader {
        return QuantumCircuitHeader()
    }
}

public final class QuantumCircuit: CustomStringConvertible {

    public let header: QuantumCircuitHeader

    /**
     Data contains a list of instructions in the order they were applied.
     */
    private var data: [Instruction] = []
    /**
     This is a map of registers bound to this circuit, by name.
     */
    private(set) var regs: OrderedDictionary<String,Register> = OrderedDictionary<String,Register>()

    /**
     Return number of operations in circuit
    */
    public var size: Int {
        return self.data.count
    }

    public init(_ regs: [Register], _ header: QuantumCircuitHeader = QuantumCircuitHeader()) throws {
        self.header = header
        try self.add(regs)
    }

    public init(_ header: QuantumCircuitHeader = QuantumCircuitHeader()) {
        self.header = header
    }

    private init(_ header: QuantumCircuitHeader, _ regs: OrderedDictionary<String,Register>) {
        self.header = header
        self.regs = regs
    }

    public func copy() -> QuantumCircuit {
        let qc = QuantumCircuit(self.header.copy(),self.regs)
        for instruction in self.data {
            qc.data.append((instruction as! CopyableInstruction).copy(qc))
        }
        return qc
    }

    /**
     Test if this circuit has the register r.
     Return true or false.
     */
    func has_register(_ register: Register) -> Bool {
        if let reg = self.regs[register.name] {
            if reg.size == register.size {
                if ((register is QuantumRegister && reg is QuantumRegister) ||
                    (register is ClassicalRegister && reg is ClassicalRegister)) {
                    return true
                }
            }
        }
        return false
    }

    /**
     Get the qregs from the registers.
     */
    public func get_qregs() -> OrderedDictionary<String,QuantumRegister> {
        var qregs = OrderedDictionary<String,QuantumRegister>()
        for (name, register) in self.regs {
            if let reg = register as? QuantumRegister {
                qregs[name] = reg
            }
        }
        return qregs
    }

    /**
     Get the cregs from the registers.
     */
    public func get_cregs() -> OrderedDictionary<String,ClassicalRegister> {
        var cregs = OrderedDictionary<String,ClassicalRegister>()
        for (name, register) in self.regs {
            if let reg = register as? ClassicalRegister {
                cregs[name] = reg
            }
        }
        return cregs
    }

    /**
     Append rhs to self if self contains rhs's registers.
     Return self + rhs as a new object.
     */
    public func combine(_ rhs: QuantumCircuit) throws -> QuantumCircuit {
        for (_,register) in rhs.regs {
            if !self.has_register(register) {
                throw QISKitError.circuitsNotCompatible
            }
        }
        let circuit = try QuantumCircuit(rhs.regs.values, rhs.header)
        for instruction in self.data {
            try instruction.reapply(circuit)
        }
        for instruction in rhs.data {
            try instruction.reapply(circuit)
        }
        return circuit
    }

    /**
     Append rhs to self if self contains rhs's registers.
     Return self + rhs as a new object.
     */
    @discardableResult
    public func extend(_ rhs: QuantumCircuit) throws -> QuantumCircuit {
        for (_,register) in rhs.regs {
            if !self.has_register(register) {
                throw QISKitError.circuitsNotCompatible
            }
        }
        for instruction in rhs.data {
            try instruction.reapply(self)
        }
        return self
    }

    /**
     Return indexed operation.
     */
    public func getitem(item: Int) -> Instruction {
        return self.data[item]
    }
    /**
     Attach a instruction.
     */
    func _attach(_ instruction: Instruction) -> Instruction {
        self.data.append(instruction)
        return instruction
    }

    /**
     Add register.
     */
    public func add(_ register: Register) throws {
        if self.regs[register.name] != nil {
            throw QISKitError.regExists(name: register.name)
        }
        self.regs[register.name] = register
    }

    /**
     Add registers.
     */
    public func add(_ regs: [Register]) throws {
        for register in regs {
            try self.add(register)
        }
    }

    public var description: String {
        var text = self.header.value
        for (_,register) in self.regs {
            text.append("\n\(register.description);")
        }
        for instruction in self.data {
            text.append("\n\(instruction.description);")
        }
        text.append("\n")
        return text
    }

    /**
     Raise exception if r is not in this circuit or not qreg.
     */
    func _check_qreg(_ register: QuantumRegister) throws {
        if !self.has_register(register) {
            throw QISKitError.regNotInCircuit(name: register.name)
        }
    }

    /**
     Raise exception if q is not in this circuit or invalid format.
     */
    func _check_qubit(_ qubit: QuantumRegisterTuple) throws {
        try self._check_qreg(qubit.register)
        try qubit.register.check_range(qubit.index)
    }

    /**
     Raise exception if r is not in this circuit or not creg.
     */
    func _check_creg(_ register: ClassicalRegister) throws {
        if !self.has_register(register) {
            throw QISKitError.regNotInCircuit(name: register.name)
        }
    }

    /**
     Raise exception if list of qubits contains duplicates.
     */
    static func _check_dups(_ qubits: [QuantumRegisterTuple]) throws {
        for qubit1 in qubits {
            for qubit2 in qubits {
                if qubit1 == qubit2 {
                    continue
                }
                if qubit1.register.name == qubit2.register.name &&
                    qubit1.index == qubit2.index {
                    throw QISKitError.duplicateQubits
                }
            }
        }
    }

    public func qasm() -> String {
        return self.description
    }

    /**
     Measure quantum bit into classical bit.
     */
    @discardableResult
    public func measure(_ qubit: QuantumRegister, _ cbit: ClassicalRegister) throws -> InstructionSet {
        let instructions = InstructionSet()
        for i in 0..<qubit.size {
            instructions.add(try self.measure(QuantumRegisterTuple(qubit, i),ClassicalRegisterTuple(cbit, i)))
        }
        return instructions
    }

    /**
     Measure quantum bit into classical bit (tuples).
     */
    @discardableResult
    public func measure(_ qubit: QuantumRegisterTuple, _ cbit: ClassicalRegisterTuple) throws -> Measure {
        try self._check_qubit(qubit)
        try self._check_creg(cbit.register)
        try cbit.register.check_range(cbit.index)
        return self._attach(Measure(qubit, cbit, self)) as! Measure
    }

    /**
     Reset q.
     */
    public func reset(_ quantum_register: QuantumRegister) throws -> InstructionSet {
        let instructions = InstructionSet()
        for sizes in 0..<quantum_register.size {
            instructions.add(try self.reset(QuantumRegisterTuple(quantum_register, sizes)))
        }
        return instructions
    }

    @discardableResult
    public func reset(_ quantum_register: QuantumRegisterTuple) throws -> Instruction {
        try self._check_qubit(quantum_register)
        return self._attach(Reset(quantum_register, self))
    }
}
