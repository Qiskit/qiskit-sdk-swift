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
 Backend for the unroller that prints OpenQASM.
 */
final class PrinterBackend: UnrollerBackend {

    private let prec: Int = 15
    private var creg:String? = nil
    private var cval:Int? = nil
    private var basis: [String]
    private var listen: Bool = true
    private var in_gate: String = ""
    private var gates: [String:GateData] = [:]
    private var printed_gates: [String] = []
    private var comments: Bool = false

    /**
     Setup this backend.
     basis is a list of operation name strings.
     */
    init(_ basis: [String] = []) {
        self.basis = basis
    }

    /**
     Set comments to True to enable.
     */
    private func set_comments(comments: Bool) {
        self.comments = comments
    }

    /**
     Declare the set of user-defined gates to emit.
     basis is a list of operation name strings.
     */
    func set_basis(_ basis: [String]) {
        self.basis = basis
    }

    /**
     Format a float f as a string with self.prec digits.
     */
    private func _fs(_ number: SymbolicValue) -> String {
        return number.format(self.prec)
    }

    /**
     Print the version string.
     v is a version number.
     */
    func version(_ version: String) {
        print("OPENQASM \(version);")
    }
    /**
     Create a new quantum register.
     name = name of the register
     sz = size of the register
     */
    func new_qreg(_ name: String, _ size: Int) throws {
        assert(size >= 0, "invalid qreg size")
        print("qreg \(name)[\(size)];")
    }

    /**
     Create a new classical register.
     name = name of the register
     sz = size of the register
     */
    func new_creg(_ name: String, _ size: Int) throws {
        print("creg \(name)[\(size)];")
    }

    /**
     Print OPENQASM for the named gate.
     */
    private func _gate_string(_ name: String) -> String {
        guard let gate = self.gates[name] else {
            return ""
        }
        var out: String = ""
        if gate.opaque {
            out = "opaque " + name
        }
        else {
            out = "gate " + name
        }
        if gate.n_args > 0 {
            out += "(" + gate.args.joined(separator: ",") + ")"
            var bits: [String] = []
            for bit in gate.bits {
                bits.append(bit.description)
            }
            out += " " + bits.joined(separator: ",")
        }
        if gate.opaque {
            out += ";"
        }
        else {
            out += "\n{\n" + (gate.body != nil ? gate.body!.qasm(self.prec) : "") + "}"
        }
        return out
    }

    /**
     Define a new quantum gate.
     name is a string.
     gatedata is the AST node for the gate.
     */
    func define_gate(_ name: String, _ gatedata: GateData) throws {
        let atomics = ["U", "CX", "measure", "reset", "barrier"]
        self.gates[name] = gatedata
        // Print out the gate definition if it is in self.basis
        if self.basis.contains(name) && !atomics.contains(name) {
            guard let gate = self.gates[name] else {
                return
            }
            // Print the hierarchy of gates this gate calls
            if !gate.opaque && gate.body != nil {
                let calls = gate.body!.calls()
                for call in calls {
                    if !self.printed_gates.contains(call) {
                        print(self._gate_string(call))
                        self.printed_gates.append(call)
                    }
                }
            }
            // Print the gate itself
            if !self.printed_gates.contains(name) {
                print(self._gate_string(name))
                self.printed_gates.append(name)
            }
        }
    }

    /**
     Fundamental single qubit gate.

     arg is 3-tuple of Node expression objects.
     qubit is (regname,idx) tuple.
     nested_scope is a list of dictionaries mapping expression variables
     to Node expression objects in order of increasing nesting depth.
     */
    func u(_ arg: (NodeRealValue, NodeRealValue, NodeRealValue), _ qubit: RegBit, _ nested_scope:[[String:NodeRealValue]]?) throws {
        if self.listen {
            if !self.basis.contains("U") {
                self.basis.append("U")
            }
            if let reg = self.creg {
                if let val = self.cval {
                    print("if(\(reg)==\(val)) ")
                }
            }
            print("U(\(self._fs(try arg.0.real(nested_scope))),\(self._fs(try arg.1.real(nested_scope))),\(self._fs(try arg.2.real(nested_scope)))) \(qubit.description);")
        }
    }

    /**
     Fundamental two qubit gate.
     qubit0 is (regname,idx) tuple for the control qubit.
     qubit1 is (regname,idx) tuple for the target qubit.
     */
    func cx(_ qubit0: RegBit, _ qubit1: RegBit) throws {
        if self.listen {
            if !self.basis.contains("CX") {
                self.basis.append("CX")
            }
            if let reg = self.creg {
                if let val = self.cval {
                    print("if(\(reg)==\(val)) ")
                }
            }
            print("CX \(qubit0.description),\(qubit1.description);")
        }
    }

    /**
     Measurement operation.
     qubit is (regname, idx) tuple for the input qubit.
     bit is (regname, idx) tuple for the output bit.
     */
    func measure(_ qubit: RegBit, _ bit: RegBit) throws {
        if !self.basis.contains("measure") {
            self.basis.append("measure")
        }
        if let reg = self.creg {
            if let val = self.cval {
                print("if(\(reg)==\(val)) ")
            }
        }
        print("measure \(qubit.description) -> \(bit.description);")
    }

    /**
     Barrier instruction.
     qubitlists is a list of lists of (regname, idx) tuples.
     */
    func barrier(_ qubitlists: [[RegBit]]) throws {
        if self.listen {
            if !self.basis.contains("barrier") {
                self.basis.append("barrier")
            }
            var names: [String] = []
            for qubitlist in qubitlists {
                if qubitlist.count == 1 {
                    names.append("\(qubitlist[0].description)")
                }
                else {
                    names.append("\(qubitlist[0].name)")
                }
            }
            print("barrier \(names.joined(separator: ","));")
        }
    }

    /**
     Reset instruction.
     qubit is a (regname, idx) tuple.
     */
    func reset(_ qubit: RegBit) throws {
        if !self.basis.contains("reset") {
            self.basis.append("reset")
        }
        if let reg = self.creg {
            if let val = self.cval {
                print("if(\(reg)==\(val)) ")
            }
        }
        print("reset \(qubit.description);")
    }

    /**
     Attach a current condition.
     creg is a name string.
     cval is the integer value for the test.
     */
    func set_condition(_ creg: String, _ cval: Int) {
        self.creg = creg
        self.cval = cval
        if self.comments {
            print("// set condition \(creg.description), \(cval.description)")
        }
    }

    /**
     Drop the current condition.
     */
    func drop_condition() {
        self.creg = nil
        self.cval = nil
        if self.comments {
            print("// drop condition")
        }
    }

    /**
     Begin a custom gate.

     name is name string.
     args is list of Node expression objects.
     qubits is list of (regname, idx) tuples.
     nested_scope is a list of dictionaries mapping expression variables
     to Node expression objects in order of increasing nesting depth.
     */
    func start_gate(_ name: String, _ args: [NodeRealValue], _ qubits: [RegBit], _ nested_scope:[[String:NodeRealValue]]?) throws {
        var sargs: [String] = []
        for arg in args {
            sargs.append(try self._fs(arg.real(nested_scope)))
        }
        var squbits: [String] = []
        for qubit in qubits {
            squbits.append(qubit.description)
        }
        if self.listen && self.comments {
            print("// start \(name), \(sargs.joined(separator:",")), \(squbits.joined(separator:","))")
        }
        if self.listen && !self.basis.contains(name) {
            if let gate = self.gates[name] {
                if gate.opaque {
                    throw BackendError.errorOpaque(name: name)
                }
            }
        }
        if self.listen && self.basis.contains(name) {
            self.in_gate = name
            self.listen = false
            if let reg = self.creg {
                if let val = self.cval {
                    print("if(\(reg)==\(val)) ")
                }
            }
            print(name)
            if !sargs.isEmpty {
                print("\(sargs.joined(separator:","))")
            }
            print(" \(squbits.joined(separator:","));")
        }
    }

    /**
     End a custom gate.

     name is name string.
     args is list of Node expression objects.
     qubits is list of (regname, idx) tuples.
     nested_scope is a list of dictionaries mapping expression variables
     to Node expression objects in order of increasing nesting depth..
     */
    func end_gate(_ name: String, _ args: [NodeRealValue], _ qubits: [RegBit], _ nested_scope:[[String:NodeRealValue]]?) throws {
        if name == self.in_gate {
            self.in_gate = ""
            self.listen = true
        }
        if self.listen && self.comments {
            var sargs: [String] = []
            for arg in args {
                sargs.append(self._fs(try arg.real(nested_scope)))
            }
            var squbits: [String] = []
            for qubit in qubits {
                squbits.append(qubit.description)
            }
            print("// end \(name), \(sargs.joined(separator:",")), \(squbits.joined(separator:","))")
        }
    }

    /**
     Returns the generated circuit.
     This backend will return nothing, as the output has been directly written to screen
     */
    func get_output() throws -> Any? {
        return nil
    }
}
