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

final class ProcessNodesReturn {

    let nodes: [NodeRealValue]
    let regBits: [[RegBit]]

    init() {
        self.nodes = []
        self.regBits = []
    }
    init(_ nodes: [NodeRealValue]) {
        self.nodes = nodes
        self.regBits = []
    }
    init(_ regBits: [[RegBit]]) {
        self.nodes = []
        self.regBits = regBits
    }
}

/**
 OPENQASM interpreter object that unrolls subroutines and loops.
 */
final class Unroller {

    /**
     Abstract syntax tree from parser
     */
    private let ast: NodeMainProgram
    /**
     Backend object
     */
    private var backend: UnrollerBackend?
    /**
     Number of digits of precision
     */
    private var precision: Int
    /**
     Input file name
     */
    private var filename: String
    /**
     OPENQASM version number
     */
    private var version: Double = 0.0
    /**
     Dict of qreg names and sizes
     */
    private var qregs: [String:Int] = [:]
    /**
     Dict of creg names and sizes
    */
    private var cregs: [String:Int] = [:]
    /**
     Dict of gates names and properties
     */
    private var gates: [String:GateData] = [:]
    /**
     List of dictionaries mapping local parameter ids to expression Nodes
     */
    private var arg_stack: Stack<[String:NodeRealValue]> = Stack<[String:NodeRealValue]>()
    /**
     List of dictionaries mapping local bit ids to global ids (name,idx)
     */
    private var bit_stack: Stack<[String:RegBit]> = Stack<[String:RegBit]>()

    /**
     Initialize interpreter's data.
     */
    init(_ ast: NodeMainProgram, _ backend: UnrollerBackend? = nil, _ precision: Int = 15, _ filename: String? = nil) {
        self.ast = ast
        self.backend = backend
        self.precision = precision
        self.filename = filename ?? ""
    }

    /**
     Process an Id or IndexedId node as a bit or register type.

     Return a list of tuples (name,index).
     */
    private func _process_bit_id(_ n: Node) throws -> [RegBit] {
        if let node = n as? NodeIndexedId {
            // An indexed bit or qubit
            return [RegBit(node.name, node.index)]
        }
        if let node = n as? NodeId {
            // A qubit or qreg or creg
            var bits: [String:RegBit] = [:]
            if let map = self.bit_stack.peek() {
                bits = map
            }
            if bits.isEmpty {
                // Global scope
                if let size = self.qregs[node.name] {
                    var array: [RegBit] = []
                    for j in 0..<size {
                        array.append(RegBit(node.name,j))
                    }
                    return array
                }
                if let size = self.cregs[node.name] {
                    var array: [RegBit] = []
                    for j in 0..<size {
                        array.append(RegBit(node.name,j))
                    }
                    return array
                }
                throw UnrollerError.errorRegName(qasm: node.qasm(self.precision))
            }
            // local scope
            if let regBit = bits[node.name] {
                return [regBit]
            }
            throw UnrollerError.errorLocalBit(qasm: node.qasm(self.precision))
        }
        return []
    }

    /**
     Process a custom unitary node.
     */
    private func _process_custom_unitary(_ node: NodeCustomUnitary) throws {
        let name = node.name
        var args: [NodeRealValue] = []
        if let list = node.arguments {
            args = try self._process_node(list).nodes
        }
        var bits: [[RegBit]] = []
        var maxidx: Int = 0
        for node_element in node.bitlist.children {
            let bitList = try self._process_bit_id(node_element)
            if maxidx < bitList.count {
                maxidx = bitList.count
            }
            bits.append(bitList)
        }

        if let gate = self.gates[name] {
            let gargs = gate.args
            let gbits = gate.bits
            let gbody = gate.body
            // Loop over register arguments, if any.
            for idx in 0..<maxidx {
                var map: [String:NodeRealValue] = [:]
                for (j, garg) in gargs.enumerated() {
                    map[garg] = args[j]
                }
                self.arg_stack.push(map)
                // Only index into register arguments.
                var element: [Int] = []
                for bitList in bits {
                    let condition = bitList.count > 1 ? 1 : 0
                    element.append(idx * condition)
                }
                var regBitMap: [String:RegBit] = [:]
                for (j, gbit) in gbits.enumerated() {
                    regBitMap[gbit] = bits[j][element[j]]
                }
                self.bit_stack.push(regBitMap)
                var args: [NodeRealValue] = []
                if let map = self.arg_stack.peek() {
                    for s in gargs {
                        if let value = map[s] {
                            args.append(value)
                        }
                    }
                }
                var qubits: [RegBit] = []
                if let map = self.bit_stack.peek() {
                    for s in gbits {
                        if let value = map[s] {
                            qubits.append(value)
                        }
                    }
                }
                if let backend = self.backend {
                    let endIndex: Int = self.arg_stack.items.count - 1
                    let array = Array(self.arg_stack.items[0..<endIndex])
                    try backend.start_gate(name,args,qubits,array)
                }
                if !gate.opaque && gbody != nil {
                    try self._process_children(gbody!)
                }
                if let backend = self.backend {
                    let endIndex: Int = self.arg_stack.items.count - 1
                    let array = Array(self.arg_stack.items[0..<endIndex])
                    try backend.end_gate(name,args,qubits,array)
                }
                self.arg_stack.pop()
                self.bit_stack.pop()
            }
            return
        }
        throw UnrollerError.errorUndefinedGate(qasm: node.qasm(self.precision))
    }

    /**
     Process a gate decl node.
     If opaque is True, process the node as an opaque gate node.
     """Process a gate node.
    */
    private func _process_gate(_ node: NodeGate) throws {

        let n_args = node.n_args
        let n_bits = node.n_bits

        var args: [String] = []
        if let arguments = node.arguments as? NodeIdList {
            for a in arguments.children {
                args.append((a as! NodeId).name)
            }
        }

        var bits: [String] = []
        if let bitlist = node.bitlist as? NodeIdList{
            for b in bitlist.children {
                bits.append((b as! NodeId).name)
            }

        }

        let body: NodeGateBody? = node.body as? NodeGateBody
        let gatedata = GateData(false, n_args, n_bits, args, bits, body)
        self.gates[node.name] = gatedata
        if let backend = self.backend {
            try backend.define_gate(node.name, gatedata)
        }
    }

    private func _process_opaque(_ node: NodeOpaque) throws {

        let n_args = node.n_args
        let n_bits = node.n_bits

        var args: [String] = []
        if let arguments = node.arguments as? NodeIdList {
            for a in arguments.children {
                args.append((a as! NodeId).name)
            }
        }

        var bits: [String] = []
        if let bitlist = node.bitlist as? NodeIdList{
            for b in bitlist.children {
                bits.append((b as! NodeId).name)
            }

        }

        let gatedata = GateData(true, n_args, n_bits, args, bits, nil)
        self.gates[node.name] = gatedata
        if let backend = self.backend {
            try backend.define_gate(node.name, gatedata)
        }
    }

    /**
     Process a CNOT gate node.
     */
    private func _process_cnot(_ node: NodeCnot) throws {
        let id0 = try self._process_bit_id(node.arg1)
        let id1 = try self._process_bit_id(node.arg2)

        if !(id0.count == id1.count || id0.count == 1 || id1.count == 1) {
            throw UnrollerError.errorQregSize(qasm: node.qasm(self.precision))
        }
        let maxidx = max(id0.count, id1.count)
        if let backend = self.backend {
            for idx in 0..<maxidx {
                if id0.count > 1 && id1.count > 1 {
                    try backend.cx(id0[idx], id1[idx])
                    continue
                }
                if id0.count > 1 {
                    try backend.cx(id0[idx], id1[0])
                    continue
                }
                try backend.cx(id0[0], id1[idx])
            }
        }
    }

    /**
     Process a measurement node.
     */
    private func _process_measure(_ node: NodeMeasure) throws {
        let id0 = try self._process_bit_id(node.arg1)
        let id1 = try self._process_bit_id(node.arg2)
        if id0.count != id1.count {
            throw UnrollerError.errorRegSize(qasm: node.qasm(self.precision))
        }
        if let backend = self.backend {
            for i in 0..<id0.count {
                try backend.measure(id0[i], id1[i])
            }
        }
    }

    /**
     Process an if node.
     */
    private func _process_if(_ node: NodeIf) throws {
        if let creg = node.nodeId as? NodeId,
            let cval = node.nodeNNInt as? NodeNNInt {
            if let backend = self.backend {
                backend.set_condition(creg.name, cval.value)
                try self._process_node(node.children[2])
                backend.drop_condition()
            }
        }
    }

    /**
     Call process_node for all children of node.
     */
    private func _process_children(_ node: Node) throws {
        for c in node.children {
            try self._process_node(c)
        }
    }

    /**
     Carry out the action associated with node n.
     */
    @discardableResult
    private func _process_node(_ node: Node) throws -> ProcessNodesReturn {
        switch node.type {
        case .N_MAINPROGRAM:
            try self._process_node((node as! NodeMainProgram).program)
        case .N_PROGRAM:
            try self._process_children(node)
        case .N_QREG:
            let n = node as! NodeQreg
            self.qregs[n.name] = n.index
            try self.backend!.new_qreg(n.name, n.index)
        case .N_CREG:
            let n = node as! NodeCreg
            self.cregs[n.name] = n.index
            try self.backend!.new_creg(n.name, n.index)
        case .N_ID:
            throw UnrollerError.processNodeId
        case .N_INT:
            throw UnrollerError.processNodeInt
        case .N_REAL:
            throw UnrollerError.processNodeReal
        case .N_INDEXEDID:
            throw UnrollerError.processNodeIndexedId
        case .N_IDLIST:
            // We process id_list nodes when they are leaves of barriers.
            var regBits:[[RegBit]] = []
            for child in node.children {
                regBits.append(try self._process_bit_id(child))
            }
            return ProcessNodesReturn(regBits)
        case .N_PRIMARYLIST:
            // We should only be called for a barrier.
            var regBits:[[RegBit]] = []
            for child in node.children {
                regBits.append(try self._process_bit_id(child))
            }
            return ProcessNodesReturn(regBits)
        case .N_GATE:
            try self._process_gate(node as! NodeGate)
        case .N_CUSTOMUNITARY:
            try self._process_custom_unitary(node as! NodeCustomUnitary)
        case .N_UNIVERSALUNITARY:
            let unode = node as! NodeUniversalUnitary
            let args = try self._process_node(unode.explist).nodes
            if args.count >= 3 {
                let qid = try self._process_bit_id(unode.indexedid)
                for element in qid {
                    try self.backend!.u((args[0], args[1], args[2]), element, self.arg_stack.items)
                }
            }
        case .N_CNOT:
            try self._process_cnot(node as! NodeCnot)
        case .N_EXPRESSIONLIST:
            var nodes: [NodeRealValue] = []
            for child in node.children {
                if let value = child as? NodeRealValue {
                    nodes.append(value)
                }
            }
            return ProcessNodesReturn(nodes)
        case .N_BINARYOP:
            throw UnrollerError.processNodeBinop
        case .N_PREFIX:
            throw UnrollerError.processNodePrefix
        case .N_MEASURE:
            try self._process_measure(node as! NodeMeasure)
        case .N_MAGIC:
            if let magicVersion = (node as! NodeMagic).nodeVersion {
                self.version = Double(magicVersion.value)
                self.backend!.version("\(magicVersion.value)")
            }
        case .N_BARRIER:
            try self.backend?.barrier(try self._process_node(node.children[0]).regBits)
        case .N_RESET:
            let id0 = try self._process_bit_id((node as! NodeReset).children[0])
            for idx in 0..<id0.count {
                try self.backend!.reset(id0[idx])
            }
        case .N_IF:
            try self._process_if(node as! NodeIf)
        case .N_OPAQUE:
            try self._process_opaque(node as! NodeOpaque)
        case .N_EXTERNAL:
            throw UnrollerError.processNodeExternal
        default:
            throw UnrollerError.errorType(type: node.type.rawValue, qasm: node.qasm(self.precision))
        }
        return ProcessNodesReturn()
    }

    /**
     Set the backend object
     */
    func set_backend(_ backend: UnrollerBackend?) {
        self.backend = backend
    }

    /**
     Interpret OPENQASM and make appropriate backend calls.
     */
    func execute() throws -> Any? {
        if self.backend != nil {
            try self._process_node(self.ast)
            return try self.backend!.get_output()
        }
        throw UnrollerError.errorBackend
    }
}
