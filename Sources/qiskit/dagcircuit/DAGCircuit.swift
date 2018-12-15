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
 Object to represent a quantum circuit as a directed acyclic graph.
 The nodes in the graph are either input/output nodes or operation nodes.
 The operation nodes are elements of a basis that is part of the circuit.
 The QASM definitions of the basis elements are carried with the circuit.
 The edges correspond to qubits or bits in the circuit. A directed edge
 from node A to node B means that the (qu)bit passes from the output of A
 to the input of B. The object's methods allow circuits to be constructed,
 composed, and modified. Some natural properties like depth can be computed
 directly from the graph.
 */

/**
 Quantum circuit as a directed acyclic graph.
 There are 3 types of nodes in the graph: inputs, outputs, and operations.
 The nodes are connected by directed edges that correspond to qubits and
 bits.
 */
final class DAGCircuit {

    /**
     Map from a wire's name (reg,idx) to a Bool that is True if the
     wire is a classical bit and False if the wire is a qubit.
    */
    private var wire_type: [RegBit:Bool] = [:]

    /**
     Map from wire names (reg,idx) to input nodes of the graph
    */
    private var input_map: OrderedDictionary<RegBit,Int> = OrderedDictionary<RegBit,Int>()

    /**
     Map from wire names (reg,idx) to output nodes of the graph
    */
    private var output_map: OrderedDictionary<RegBit,Int> = OrderedDictionary<RegBit,Int>()

    /**
     Running count of the total number of nodes
     */
    private var node_counter = 0

    /**
     Map of named operations in this circuit and their signatures.
     The signature is an integer tuple (nq,nc,np) specifying the
     number of input qubits, input bits, and real parameters.
     The definition is external to the circuit object.
    */
    private(set) var basis: OrderedDictionary<String,(Int,Int,Int)> = OrderedDictionary<String,(Int,Int,Int)>()

    /**
      Directed multigraph whose nodes are inputs, outputs, or operations.
      Operation nodes have equal in- and out-degrees and carry
      additional data about the operation, including the argument order
      and parameter values.
      Input nodes have out-degree 1 and output nodes have in-degree 1.
      Edges carry wire labels (reg,idx) and each operation has
      corresponding in- and out-edges with the same wire labels.
    */
    private var multi_graph:Graph<CircuitVertexData,CircuitEdgeData> = Graph<CircuitVertexData,CircuitEdgeData>(directed: true)

    /**
      Map of qregs to sizes
    */
    private var qregs: OrderedDictionary<String,Int> = OrderedDictionary<String,Int>()

    /**
      Map of cregs to sizes
    */
    private var cregs: OrderedDictionary<String,Int> = OrderedDictionary<String,Int>()

    /**
     Map of user defined gates to ast nodes defining them
    */
    private var gates: OrderedDictionary<String,GateData> = OrderedDictionary<String,GateData>()

    /**
     Output precision for printing floats
    */
    private var prec = 15

    /**
     Create an empty circuit
     */
    public init() {

    }

    public init(_ circuit: DAGCircuit) {
        self.wire_type = circuit.wire_type
        self.input_map = circuit.input_map
        self.output_map = circuit.output_map
        self.node_counter = circuit.node_counter
        self.basis = circuit.basis
        self.multi_graph = circuit.multi_graph.copy()
        self.qregs = circuit.qregs
        self.cregs = circuit.cregs
        self.gates = circuit.gates
        self.prec = circuit.prec
    }

    /**
     Return a deep copy of self
     */
    public func deepcopy() -> DAGCircuit {
        return DAGCircuit(self)
    }

    /**
     Return a list of qubits as (qreg, index) pairs.
     */
    public func get_qubits() -> [RegBit] {
        var array:[RegBit] = []
        let qRegsSorted = self.qregs.sorted(by:{ (n1: (key: String, value: Int), n2: (key: String, value: Int)) -> Bool in
            return n1.key < n2.key
        })
        for (name,index) in qRegsSorted {
            for i in 0..<index {
                array.append(RegBit(name,i))
            }
        }
        return array
    }

    /**
     Rename a classical or quantum register throughout the circuit.
     - parameter regname: existing register name string
     - parameter newname: replacement register name string
     */
    public func rename_register(_ regname: String, _ newname: String) throws {
        if regname == newname {
            return
        }
        if self.qregs[newname] != nil || self.cregs[newname] != nil {
            throw DAGCircuitError.duplicateRegister(name: newname)
        }
        if self.qregs[regname] == nil && self.cregs[regname] == nil {
            throw DAGCircuitError.noRegister(name: newname)
        }
        var reg_size: Int = 0
        if self.qregs[regname] != nil {
            self.qregs[newname] = self.qregs[regname]
            self.qregs.removeValue(forKey: regname)
            reg_size = self.qregs[newname]!
        }
        var iscreg = false
        if self.cregs[regname] != nil {
            self.cregs[newname] = self.cregs[regname]
            self.cregs.removeValue(forKey: regname)
            reg_size = self.cregs[newname]!
            iscreg = true
        }
        for i in 0..<reg_size {
            let oldTuple = RegBit(regname, i)
            let newTuple = RegBit(newname, i)
            self.wire_type[newTuple] = iscreg
            self.wire_type.removeValue(forKey: oldTuple)
            self.input_map[newTuple] = self.input_map[oldTuple]
            self.input_map.removeValue(forKey: oldTuple)
            self.output_map[newTuple] = self.output_map[oldTuple]
            self.output_map.removeValue(forKey: oldTuple)
        }
        // n node d = data
        for (_,node) in self.multi_graph.vertices {
            guard let data = node.data else {
                continue
            }
            if data.type == "in" || data.type == "out" {
                let dataInOut = data as! CircuitVertexInOutData
                if dataInOut.name.name == regname {
                    dataInOut.name = RegBit(newname, dataInOut.name.index)
                }
            }
            else if data.type == "op" {
                let dataOp = data as! CircuitVertexOpData
                var qa: [RegBit] = []
                for var a in dataOp.qargs {
                    if a.name == regname {
                        a = RegBit(newname, a.index)
                    }
                    qa.append(a)
                }
                dataOp.qargs = qa
                var ca: [RegBit] = []
                for var a in dataOp.cargs {
                    if a.name == regname {
                        a = RegBit(newname, a.index)
                    }
                    ca.append(a)
                }
                dataOp.cargs = ca
                if let condition = dataOp.condition {
                    if condition.name == regname {
                        dataOp.condition  = RegBit(newname, condition.index)
                    }
                }
            }
        }
        // eX = edge, d= data
        for edge in self.multi_graph.edges {
            guard let data = edge.data else {
                continue
            }
            if data.name.name == regname {
                data.name = RegBit(newname, data.name.index)
            }
        }
    }

    /**
     Remove all operation nodes with the given name
     */
    public func remove_all_ops_named(_ opname: String) throws {
        let nlist = try self.get_named_nodes(opname)
        for n in nlist {
            self._remove_op_node(n.key)
        }
    }

    /**
     Format a float f as a string with self.prec digits.
     */
    public func fs(_ number: Double) -> String {
        return number.format(self.prec)
    }

    /**
     Add all wires in a quantum register named name with size.
     */
    public func add_qreg(_ name: String, _ size: Int) throws {
        if self.qregs[name] != nil || self.cregs[name] != nil {
            throw DAGCircuitError.duplicateRegister(name: name)
        }
        self.qregs[name] = size
        for j in 0..<size {
            try self._add_wire(RegBit(name, j))
        }
    }

    /**
     Add all wires in a classical register named name with size.
     */
    public func add_creg(_ name: String, _ size: Int) throws {
        if self.qregs[name] != nil || self.cregs[name] != nil {
            throw DAGCircuitError.duplicateRegister(name: name)
        }
        self.cregs[name] = size
        for j in 0..<size {
            try self._add_wire(RegBit(name, j), true)
        }
    }

    /**
    Add a qubit or bit to the circuit.
    name is a (string,int) tuple containing register name and index
    This adds a pair of in and out nodes connected by an edge.
     */
    private func _add_wire(_ name: RegBit, _ isClassical:Bool = false) throws {
        if self.wire_type[name] != nil {
            throw DAGCircuitError.duplicateWire(regBit: name)
        }
        self.wire_type[name] = isClassical
        self.node_counter += 1
        self.input_map[name] = self.node_counter
        self.node_counter += 1
        self.output_map[name] = self.node_counter
        let in_node: Int = self.input_map[name]!
        let out_node: Int = self.output_map[name]!
        self.multi_graph.add_edge(in_node, out_node,CircuitEdgeData(name))
        if let node = self.multi_graph.vertex(in_node) {
            node.data = CircuitVertexInData(name)
        }
        if let node = self.multi_graph.vertex(out_node) {
            node.data = CircuitVertexOutData(name)
        }
    }

    /**
     Add an operation to the basis.
     name is string label for operation
     number_qubits is number of qubit arguments
     number_classical is number of bit arguments
     number_parameters is number of real parameters
     The parameters (nq,nc,np) are ignored for the special case
     when name = "barrier". The barrier instruction has a variable
     number of qubit arguments.
     */
    public func add_basis_element(_ name: String, _ number_qubits: Int, _ number_classical: Int = 0, _ number_parameters: Int = 0) throws {
        if self.basis[name] == nil {
            self.basis[name] = (number_qubits,number_classical,number_parameters)
        }
        if let gateMap = self.gates[name] {
            if number_classical != 0 {
                throw DAGCircuitError.gateMatch
            }
            if gateMap.n_args != number_parameters {
                throw DAGCircuitError.gateMatch
            }
            if gateMap.n_bits != number_qubits {
                throw DAGCircuitError.gateMatch
            }
        }
    }

    /**
     Add the definition of a gate.
     gatedata is dict with fields:
     "opaque" = True or False
     "n_args" = number of real parameters
     "n_bits" = number of qubits
     "args"   = list of parameter names
     "bits"   = list of qubit names
     "body"   = GateBody AST node
     */
    func add_gate_data(_ name: String, _ gateMap: GateData) throws {
        if self.gates[name] == nil {
            self.gates[name] = gateMap
            if let basis = self.basis[name] {
                if gateMap.n_bits != basis.0 {
                    throw DAGCircuitError.gateMatch
                }
                if basis.1 != 0 {
                    throw DAGCircuitError.gateMatch
                }
                if gateMap.n_args != basis.2 {
                    throw DAGCircuitError.gateMatch
                }
            }
        }
    }

    /**
     Check the arguments against the data for this operation.
     name is a string
     qargs is a list of tuples like ("q",0)
     cargs is a list of tuples like ("c",0)
     params is a list of strings that represent floats
     */
    private func _check_basis_data(_ name: String,
                                   _ qargs: [RegBit],
                                   _ cargs: [RegBit],
                                   _ params: [SymbolicValue]) throws {
        // Check that we have this operation
        if self.basis[name] == nil {
            throw DAGCircuitError.noBasicOp(name: name)
        }
        // Check the number of arguments matches the signature
        if name != "barrier" {
            if let basis = self.basis[name] {
                if qargs.count != basis.0 {
                    throw DAGCircuitError.qbitsNumber(name: name)
                }
                if cargs.count != basis.1 {
                    throw DAGCircuitError.bitsNumber(name: name)
                }
                if params.count != basis.2 {
                    throw DAGCircuitError.paramsNumber(name: name)
                }
            }
        }
        else {
            // "barrier" is a special case
            if qargs.isEmpty {
                throw DAGCircuitError.qbitsNumber(name: name)
            }
            if !cargs.isEmpty {
                throw DAGCircuitError.bitsNumber(name: name)
            }
            if !params.isEmpty {
                throw DAGCircuitError.paramsNumber(name: name)
            }
        }
    }

    /**
     Verify that the condition is valid.
     name is a string used for error reporting
     condition is either None or a tuple (string,int) giving (creg,value)
     */
    private func _check_condition(_ name: String, _ cond: RegBit?) throws {
        // Verify creg exists
        if let condition = cond {
            if self.cregs[condition.name] == nil {
                throw DAGCircuitError.cregCondition(name: name)
            }
        }
    }

    /**
     Check the values of a list of (qu)bit arguments.
     For each element A of args, check that amap contains A and
     self.wire_type[A] equals bval.
     args is a list of (regname,idx) tuples
     amap is a dictionary keyed on (regname,idx) tuples
     bval is boolean
     */
    private func _check_bits(_ args: [RegBit], _ amap: OrderedDictionary<RegBit,Int>, _ bval: Bool) throws {
        // Check for each wire
        for q in args {
            if amap[q] == nil {
                throw DAGCircuitError.bitNotFound(q: q)
            }
            if let wt = self.wire_type[q] {
                if wt != bval {
                    throw DAGCircuitError.wireType(bVal: bval, q: q)
                }
            }
        }
    }

    /**
     Return a list of bits (regname,idx) in the given condition.
     cond is either None or a (regname,int) tuple specifying
     a classical if condition.
     */
    private func _bits_in_condition(_ condition: RegBit?) -> [RegBit] {
        var all_bits:[RegBit] = []
        if let cond = condition {
            if let size = self.cregs[cond.name] {
                for j in 0..<size {
                    all_bits.append(RegBit(cond.name,j))
                }
            }
        }
        return all_bits
    }

    /**
     Add a new operation node to the graph and assign properties.
     nname node name
     nqargs quantum arguments
     ncargs classical arguments
     nparams parameters
     ncondition classical condition (or None)
     */
    private func _add_op_node(_ nname: String,
                              _ nqargs: [RegBit],
                              _ ncargs: [RegBit],
                              _ nparams: [SymbolicValue],
                              _ ncondition: RegBit?) {
        // Add a new operation node to the graph
        self.node_counter += 1
        self.multi_graph.add_vertex(self.node_counter,CircuitVertexOpData(nname,nqargs,ncargs,nparams,ncondition))
    }

    /**
     Apply an operation to the output of the circuit.
     name is a string
     qargs is a list of tuples like ("q",0)
     cargs is a list of tuples like ("c",0)
     params is a list of strings that represent floats
     condition is either None or a tuple (string,int) giving (creg,value)
     */
    func apply_operation_back(_ name: String,
                                      _ qargs: [RegBit],
                                      _ cargs: [RegBit] = [],
                                      _ params:[SymbolicValue] = [],
                                      _ condition: RegBit? = nil) throws {
        var all_cbits = self._bits_in_condition(condition)
        all_cbits.append(contentsOf: cargs)

        try self._check_basis_data(name, qargs, cargs, params)
        try self._check_condition(name, condition)
        try self._check_bits(qargs, self.output_map, false)
        try self._check_bits(all_cbits, self.output_map, true)

        self._add_op_node(name, qargs, cargs, params, condition)
        // Add new in-edges from predecessors of the output nodes to the
        // operation node while deleting the old in-edges of the output nodes
        // and adding new edges from the operation node to each output node
        var al = qargs
        al.append(contentsOf: all_cbits)
        for q in al {
            if let index = self.output_map[q] {
                var ie = self.multi_graph.predecessors(index)
                assert(ie.count == 1, "output node has multiple in-edges")
                self.multi_graph.add_edge(ie[0].key, self.node_counter, CircuitEdgeData(q))
                self.multi_graph.remove_edge(ie[0].key, index)
                self.multi_graph.add_edge(self.node_counter, index, CircuitEdgeData(q))
            }
        }
    }

    /**
     Apply an operation to the input of the circuit.
     name is a string
     qargs is a list of strings like "q[0]"
     cargs is a list of strings like "c[0]"
     params is a list of strings that represent floats
     condition is either None or a tuple (string,int) giving (creg,value)
     */
    public func apply_operation_front(_ name: String,
                                      _ qargs: [RegBit],
                                      _ cargs: [RegBit] = [],
                                      _ params:[SymbolicValue] = [],
                                      _ condition: RegBit?) throws {
        var all_cbits = self._bits_in_condition(condition)
        all_cbits.append(contentsOf: cargs)

        try self._check_basis_data(name, qargs, cargs, params)
        try self._check_condition(name, condition)
        try self._check_bits(qargs, self.input_map, false)
        try self._check_bits(all_cbits, self.input_map, true)

        self._add_op_node(name, qargs, cargs, params, condition)
        // Add new out-edges to successors of the input nodes from the
        // operation node while deleting the old out-edges of the input nodes
        // and adding new edges to the operation node from each input node
        var al = qargs
        al.append(contentsOf: all_cbits)
        for q in al {
            if let index = self.input_map[q] {
                var ie = self.multi_graph.successors(index)
                assert(ie.count == 1, "input node has multiple out-edges")
                self.multi_graph.add_edge(self.node_counter, ie[0].key, CircuitEdgeData(q))
                self.multi_graph.remove_edge(index, ie[0].key)
                self.multi_graph.add_edge(index, self.node_counter, CircuitEdgeData(q))
            }
        }
    }

    /**
     Return a new basis map.
     The new basis is a copy of self.basis with
     new elements of input_circuit.basis added.
     input_circuit is a CircuitGraph
     */
    private func _make_union_basis(_ input_circuit: DAGCircuit) throws -> OrderedDictionary<String,(Int,Int,Int)> {
        var union_basis = self.basis
        for (g, val) in input_circuit.basis {
            if union_basis[g] == nil {
                union_basis[g] = val
            }
            if union_basis[g]! != val {
                throw DAGCircuitError.incompatibleBasis
            }
        }
        return union_basis
    }

    /**
     Return a new gates map.
     The new gates are a copy of self.gates with
     new elements of input_circuit.gates added.
     input_circuit is a CircuitGraph
     NOTE: gates in input_circuit that are also in self must
     be *identical* to the gates in self
     */
    private func _make_union_gates(_ input_circuit: DAGCircuit) throws -> OrderedDictionary<String,GateData> {
        var union_gates = self.gates
        for (k, v) in input_circuit.gates {
            if union_gates[k] == nil {
                union_gates[k] = v
            }
            guard let union_gate = union_gates[k] else {
                continue
            }
            guard let input_circuit_gate = input_circuit.gates[k] else {
                continue
            }
            if union_gate.opaque != input_circuit_gate.opaque ||
                union_gate.n_args != input_circuit_gate.n_args ||
                union_gate.n_bits != input_circuit_gate.n_bits ||
                union_gate.args != input_circuit_gate.args ||
                union_gate.bits != input_circuit_gate.bits {
                throw DAGCircuitError.ineqGate(name: k)
            }
            if !union_gate.opaque && union_gate.body != nil && input_circuit_gate.body != nil &&
                union_gate.body!.qasm(self.prec) != input_circuit_gate.body!.qasm(self.prec) {
                throw DAGCircuitError.ineqGate(name: k)
            }
        }
        return union_gates
    }

    /**
     Check that wiremap neither fragments nor leaves duplicate registers.
     1. There are no fragmented registers. A register in keyregs
     is fragmented if not all of its (qu)bits are renamed by wire_map.
     2. There are no duplicate registers. A register is duplicate if
     it appears in both self and keyregs but not in wire_map.
     wire_map is a map from (regname,idx) in keyregs to (regname,idx)
     in valregs
     keyregs is a map from register names to sizes
     valregs is a map from register names to sizes
     valreg is a Bool, if False the method ignores valregs and does not
     add regs for bits in the wire_map image that don't appear in valregs
     Return the set of regs to add to self
     */
    private func _check_wiremap_registers(_ wire_map: [RegBit:RegBit],
                                          _ keyregs: OrderedDictionary<String,Int>,
                                          _ valregs: OrderedDictionary<String,Int>,
                                          _ valreg:Bool = true) throws -> Set<RegBit> {
        var add_regs = Set<RegBit>()
        var reg_frag_chk: [String:[Bool]]  = [:]
        for (k, v) in keyregs {
            reg_frag_chk[k] = Array(repeating: false, count: v)
        }
        for (k,_) in wire_map {
            if keyregs[k.name] != nil {
                reg_frag_chk[k.name]![k.index] = true
            }
        }
        for (k, v) in reg_frag_chk {
            let s = Set<Bool>(v)
            if s.count == 2 {
                throw DAGCircuitError.wireFrag(name: k)
            }
            if s.count == 1 && s.contains(false) {
                if self.qregs[k] != nil || self.cregs[k] != nil {
                    throw DAGCircuitError.unmappeDupName(name: k)
                }
                else {
                    // Add registers that appear only in keyregs
                    add_regs.update(with: RegBit(k, keyregs[k]!))
                }
            }
            else {
                if valreg {
                    // If mapping to a register not in valregs, add it.
                    // (k,0) exists in wire_map because wire_map doesn't
                    // fragment k
                    let key = RegBit(k, 0)
                    if valregs[key.name] == nil {
                        if let tuple = wire_map[key] {
                            var size: Int = 0
                            for (_,x) in wire_map {
                                if x.name == tuple.name {
                                    if x.index > size {
                                        size = x.index
                                    }
                                }
                            }
                            add_regs.update(with: RegBit(tuple.name, size + 1))
                        }
                    }
                }
            }
        }
        return add_regs
    }

    /**
     Check that the wiremap is consistent.
     Check that the wiremap refers to valid wires and that
     those wires have consistent types.
     wire_map is a map from (regname,idx) in keymap to (regname,idx)
     in valmap
     keymap is a map whose keys are wire_map keys
     valmap is a map whose keys are wire_map values
     input_circuit is a CircuitGraph
     */
    private func _check_wiremap_validity(_ wire_map: [RegBit:RegBit],
                                         _ keymap: OrderedDictionary<RegBit,Int>,
                                         _ valmap: OrderedDictionary<RegBit,Int>,
                                         _ input_circuit: DAGCircuit) throws {
        for (k, v) in wire_map {
            if keymap[k] == nil {
                throw DAGCircuitError.invalidWireMapKey(regBit: k)
            }
            if valmap[v] == nil {
                throw DAGCircuitError.invalidWireMapValue(regBit: v)
            }
            if input_circuit.wire_type[k] != self.wire_type[v] {
                throw DAGCircuitError.inconsistenteWireMap(name: k, value: v)
            }
        }
    }

    /**
     "Use the wire_map dict to change the condition tuple's creg name.
     wire_map is map from wires to wires
     condition is a tuple (reg,int)
     Returns the new condition tuple
     */
    private func _map_condition(_ wire_map: [RegBit:RegBit],
                                _ condition: RegBit?) -> RegBit? {
        if condition == nil {
            return nil
        }
        // Map the register name, using fact that registers must not be
        // fragmented by the wire_map (this must have been checked
        // elsewhere)
        let bit0 = RegBit(condition!.name, 0)
        var value = bit0
        if let v = wire_map[bit0] {
            value = v
        }
        return  RegBit(value.name, condition!.index)
    }

    /**
     Apply the input circuit to the output of this circuit.
     The two bases must be "compatible" or an exception occurs.
     A subset of input qubits of the input circuit are mapped
     to a subset of output qubits of this circuit.
     wire_map[input_qubit_to_input_circuit] = output_qubit_of_self
     */
    public func compose_back(_ input_circuit: DAGCircuit, _ wire_map: [RegBit:RegBit] = [:]) throws {
        let union_basis = try self._make_union_basis(input_circuit)
        let union_gates = try self._make_union_gates(input_circuit)

        // Check the wire map for duplicate values
        if Set<RegBit>(wire_map.values).count != wire_map.count {
            throw DAGCircuitError.duplicatesWireMap
        }

        let add_qregs = try self._check_wiremap_registers(wire_map,input_circuit.qregs,self.qregs)
        for register in add_qregs {
            try self.add_qreg(register.name, register.index)
        }
        let add_cregs = try self._check_wiremap_registers(wire_map,input_circuit.cregs,self.cregs)
        for register in add_cregs {
            try self.add_creg(register.name, register.index)
        }
        try self._check_wiremap_validity(wire_map, input_circuit.input_map,self.output_map, input_circuit)

        // Compose
        self.basis = union_basis
        self.gates = union_gates
        let topological_sort = try input_circuit.multi_graph.topological_sort()
        for node in topological_sort {
            guard let nd = node.data else {
                continue
            }
            switch nd.type {
            case  "in":
                let dataIn = nd as! CircuitVertexInData
                // if in wire_map, get new name, else use existing name
                var m_name = dataIn.name
                if let n = wire_map[dataIn.name] {
                    m_name = n
                }
                // the mapped wire should already exist
                assert(self.output_map[m_name] != nil,"wire (\(m_name.name),\(m_name.index) not in self")
                assert(input_circuit.wire_type[dataIn.name] != nil,
                       "inconsistent wire_type for (\(dataIn.name.name),\(dataIn.name.index)) in input_circuit")
            case "out":
                // ignore output nodes
                break
            case "op":
                let dataOp = nd as! CircuitVertexOpData
                let condition = self._map_condition(wire_map, dataOp.condition)
                try self._check_condition(dataOp.name, condition)
                var m_qargs: [RegBit] = []
                for qarg in dataOp.qargs {
                    var value = qarg
                    if let v = wire_map[qarg] {
                        value = v
                    }
                    m_qargs.append(value)
                }
                var m_cargs: [RegBit] = []
                for carg in dataOp.cargs {
                    var value = carg
                    if let v = wire_map[carg] {
                        value = v
                    }
                    m_cargs.append(value)
                }
                try self.apply_operation_back(dataOp.name, m_qargs, m_cargs,dataOp.params, condition)
            default:
                assert(false, "bad node type \(nd.type)")
            }
        }
    }

    /**
     Apply the input circuit to the input of this circuit.
     The two bases must be "compatible" or an exception occurs.
     A subset of output qubits of the input circuit are mapped
     to a subset of input qubits of
     this circuit.
     */
    public func compose_front(_ input_circuit: DAGCircuit, _ wire_map: [RegBit:RegBit] = [:]) throws {
        let union_basis = try self._make_union_basis(input_circuit)
        let union_gates = try self._make_union_gates(input_circuit)

        // Check the wire map
        if Set<RegBit>(wire_map.values).count != wire_map.count {
            throw DAGCircuitError.duplicatesWireMap
        }

        let add_qregs = try self._check_wiremap_registers(wire_map,input_circuit.qregs,self.qregs)
        for r in add_qregs {
            try self.add_qreg(r.name, r.index)
        }

        let add_cregs = try self._check_wiremap_registers(wire_map,input_circuit.cregs,self.cregs)
        for r in add_cregs {
            try self.add_creg(r.name, r.index)
        }
        try self._check_wiremap_validity(wire_map, input_circuit.output_map,self.input_map, input_circuit)

        // Compose
        self.basis = union_basis
        self.gates = union_gates
        let topological_sort = try input_circuit.multi_graph.topological_sort(reverse: true)
        for node in topological_sort {
            guard let nd = node.data else {
                continue
            }
            switch nd.type {
            case "out":
                // if in wire_map, get new name, else use existing name
                let dataOut = nd as! CircuitVertexOutData
                var m_name = dataOut.name
                if let n = wire_map[dataOut.name] {
                    m_name = n
                }
                // the mapped wire should already exist
                assert(self.input_map[m_name] != nil,"wire (\(m_name.name),\(m_name.index) not in self")
                assert(input_circuit.wire_type[dataOut.name] != nil,
                       "inconsistent wire_type for (\(dataOut.name.name),\(dataOut.name.index)) in input_circuit")
            case "in":
                // ignore input nodes
                break
            case "op":
                let dataOp = nd as! CircuitVertexOpData
                let condition = self._map_condition(wire_map, dataOp.condition)
                try self._check_condition(dataOp.name, condition)
                var m_qargs: [RegBit] = []
                for qarg in dataOp.qargs {
                    var value = qarg
                    if let v = wire_map[qarg] {
                        value = v
                    }
                    m_qargs.append(value)
                }
                var m_cargs: [RegBit] = []
                for carg in dataOp.cargs {
                    var value = carg
                    if let v = wire_map[carg] {
                        value = v
                    }
                    m_cargs.append(value)
                }
                try self.apply_operation_front(dataOp.name, m_qargs, m_cargs,dataOp.params, condition)
            default:
                assert(false, "bad node type \(nd.type)")
            }
        }
    }

    /**
     Return the number of operations.
     */
    public func size() -> Int {
        return self.multi_graph.order() - 2 * self.wire_type.count
    }
    /**
     Return the circuit depth.
     */
    public func depth() throws -> Int {
        assert(self.multi_graph.is_directed_acyclic_graph(), "not a DAG")
        return try self.multi_graph.dag_longest_path_length() - 1
    }
    /**
     Return the total number of qubits used by the circuit
     */
    public func width() -> Int {
        return self.wire_type.count - self.num_cbits()
    }
    /**
     Return the total number of bits used by the circuit
     */
    public func num_cbits() -> Int {
        var n: Int = 0
        for (_,v) in self.wire_type {
            if v {
                n += 1
            }
        }
        return n
    }

    /**
     Compute how many components the circuit can decompose into
     */
    public func num_tensor_factors() throws -> Int {
        return try self.multi_graph.number_weakly_connected_components()
    }

    /**
     Return a QASM string for the named gate.
     */
    private func _gate_string(_ name: String) -> String {
        guard let data = self.gates[name] else {
            return ""
        }
        var out: String = ""
        if data.opaque {
            out = "opaque " + name
        }
        else {
            out = "gate " + name
        }
        if data.n_args > 0 {
            out += "(" + data.args.joined(separator: ",") + ")"
        }
        out += " " + data.bits.joined(separator: ",")
        if data.opaque {
            out += ";"
        }
        else {
            out += "\n{\n" + (data.body != nil ? data.body!.qasm(self.prec) : "") + "}"
        }
        return out
    }

    /**
     "Return a string containing QASM for this circuit.
     if qeflag is True, add a line to include "qelib1.inc"
     and only generate gate code for gates not in qelib1.
     if no_decls is True, only print the instructions.
     if aliases is not None, aliases contains a dict mapping
     the current qubits in the circuit to new qubit names.
     We will deduce the register names and sizes from aliases.
     if decls_only is True, only print the declarations.
     if add_swap is True, add the definition of swap in terms of
     cx if necessary.
     */
    public func qasm(decls_only: Bool = false,
                     add_swap: Bool = false,
                     no_decls: Bool = false,
                     qeflag: Bool = false,
                     aliases: OrderedDictionary<RegBit,RegBit>? = nil) throws -> String {
        // Rename qregs if necessary
        var qregdata: OrderedDictionary<String,Int> = OrderedDictionary<String,Int>()
        if let aliasesMap = aliases {
            for (_,q) in aliasesMap {
                guard let n = qregdata[q.name] else {
                    qregdata[q.name] = q.index + 1
                    continue
                }
                if n < q.index + 1 {
                    qregdata[q.name] = q.index + 1
                }
            }
        }
        else {
            qregdata = self.qregs
        }
        var out: String = ""
        // Write top matter
        if no_decls {
            out = ""
        }
        else {
            var printed_gates: [String] = []
            out = "OPENQASM 2.0;\n"
            if qeflag {
                out += "include \"qelib1.inc\";\n"
            }
            for (k,v) in qregdata.sorted(by: { $0.0 < $1.0 }) {
                out += "qreg \(k)[\(v)];\n"
            }
            for (k,v) in self.cregs.sorted(by: { $0.0 < $1.0 }) {
                out += "creg \(k)[\(v)];\n"
            }
            var omit:Set<String> = ["U", "CX", "measure", "reset", "barrier"]
            if qeflag {
                let qelib:Set<String> = ["u3", "u2", "u1", "cx", "id", "x", "y", "z", "h",
                                         "s", "sdg", "t", "tdg", "cz", "cy", "ccx", "cu1",
                                         "cu3"]
                omit = omit.union(qelib)
                printed_gates.append(contentsOf:qelib)
            }
            for (k,_) in self.basis {
                if !omit.contains(k) {
                    guard let gdata = self.gates[k] else {
                        continue
                    }
                    if !gdata.opaque && gdata.body != nil {
                        let calls = gdata.body!.calls()
                        for c in calls {
                            if !printed_gates.contains(c) {
                                out += self._gate_string(c) + "\n"
                                printed_gates.append(c)
                            }
                        }
                    }
                    if !printed_gates.contains(k) {
                        out += self._gate_string(k) + "\n"
                        printed_gates.append(k)
                    }
                }
            }
            if add_swap && !qeflag && self.basis["cx"] == nil {
                out += "gate cx a,b { CX a,b; }\n"
            }
            if add_swap && self.basis["swap"] == nil {
                out += "gate swap a,b { cx a,b; cx b,a; cx a,b; }\n"
            }
        }
        // Write the instructions
        if !decls_only {
            let topological_sort = try self.multi_graph.topological_sort()
            for node in topological_sort {
                guard let nd = node.data else {
                    continue
                }
                if nd.type == "op" {
                    let dataOp = nd as! CircuitVertexOpData
                    if let condition = dataOp.condition {
                        out += "if(\(condition.name)==\(condition.index)) "
                    }
                    if dataOp.cargs.isEmpty  {
                        let nm = dataOp.name
                        var qarglist:[RegBit] = []
                        if let aliasesMap = aliases {
                            for x in dataOp.qargs {
                                if let v = aliasesMap[x] {
                                    qarglist.append(v)
                                }
                            }
                        }
                        else {
                            qarglist = dataOp.qargs
                        }
                        var args: [String] = []
                        for v in qarglist {
                            args.append(v.qasm)
                        }
                        let qarg = args.joined(separator: ",")
                        if !dataOp.params.isEmpty {
                            let param = dataOp.formatParams(self.prec).joined(separator: ",")
                            out += "\(nm)(\(param)) \(qarg);\n"
                        }
                        else {
                            out += "\(nm) \(qarg);\n"
                        }
                    }
                    else {
                        if dataOp.name == "measure" {
                            assert(dataOp.cargs.count == 1 && dataOp.qargs.count == 1 && dataOp.params.count == 0, "bad node data")
                            var qname = dataOp.qargs[0].name
                            var qindex = dataOp.qargs[0].index
                            if let aliasesMap = aliases {
                                if let newq = aliasesMap[RegBit(qname, qindex)] {
                                    qname = newq.name
                                    qindex = newq.index
                                }
                            }
                            out += "measure \(RegBit.qasm(qname,qindex)) -> \(dataOp.cargs[0].qasm);\n"
                        }
                        else {
                            assert(false,"bad node data")
                        }
                    }
                }
            }
        }
        return out
    }

    /**
     Check that a list of wires satisfies some conditions.
     The wires give an order for (qu)bits in the input circuit
     that is replacing the named operation.
     - no duplicate names
     - correct length for named operation
     - elements are wires of input_circuit
     Raises an exception otherwise.
     */
    private func _check_wires_list(_ wires:[RegBit], _ name: String, _ input_circuit: DAGCircuit) throws {
        if Set<RegBit>(wires).count != wires.count {
            throw DAGCircuitError.duplicateWires
        }
        var wire_tot: Int = 0
        if let vals = self.basis[name] {
            wire_tot = vals.0 + vals.1
        }
        if wires.count != wire_tot {
            throw DAGCircuitError.totalWires(expected:wire_tot, total: wires.count)
        }
        for w in wires {
            if input_circuit.wire_type[w] == nil {
                throw DAGCircuitError.missingWire(wire: w)
            }
        }
    }

    /**
     Return predecessor and successor dictionaries.
     These map from wire names to predecessor and successor
     nodes for the operation node n in self.multi_graph.
     */
    private func _make_pred_succ_maps(_ n: Int) -> ([RegBit:Int],[RegBit:Int]) {
        var pred_map: [RegBit:Int] = [:]
        var edges = self.multi_graph.in_edges_iter(n)
        for edge in edges {
            if let data = edge.data {
                pred_map[data.name] = edge.source
            }
        }
        var succ_map: [RegBit:Int] = [:]
        edges = self.multi_graph.out_edges_iter(n)
        for edge in edges {
            if let data = edge.data {
                succ_map[data.name] = edge.neighbor
            }
        }
        return (pred_map, succ_map)
    }

    /**
     Map all wires of the input circuit.
     Map all wires of the input circuit to predecessor and
     successor nodes in self, keyed on wires in self.
     pred_map, succ_map dicts come from _make_pred_succ_maps
     input_circuit is the input circuit
     wire_map is the wire map from wires of input_circuit to wires of self
     returns full_pred_map, full_succ_map
     */
    private func _full_pred_succ_maps(_ pred_map: [RegBit:Int],
                                      _ succ_map: [RegBit:Int],
                                      _ input_circuit: DAGCircuit,
                                      _ wire_map: [RegBit:RegBit]) -> ([RegBit:Int],[RegBit:Int]) {
        var full_pred_map: [RegBit:Int] = [:]
        var full_succ_map: [RegBit:Int] = [:]
        for (w,_) in input_circuit.input_map {
            // If w is wire mapped, find the corresponding predecessor
            // of the node
            if let wm = wire_map[w] {
                full_pred_map[wm] = pred_map[wm]
                full_succ_map[wm] = succ_map[wm]
                continue
            }
            if let wm = self.output_map[w] {
                // Otherwise, use the corresponding output nodes of self
                // and compute the predecessor.
                full_succ_map[w] = wm
                full_pred_map[w] = self.multi_graph.predecessors(wm)[0].key
                assert(self.multi_graph.predecessors(wm).count == 1,
                       "too many predecessors for (\(w.name),\(w.index)) output node")
            }
        }
        return (full_pred_map, full_succ_map)
    }

    /**
     Replace every occurrence of named operation with input_circuit.
     */
    public func  substitute_circuit_all(_ name: String,
                                        _ input_circuit: DAGCircuit,
                                        _ wires: [RegBit] = []) throws {
        if self.basis[name] == nil {
            throw DAGCircuitError.missingName(name: name)
        }

        try self._check_wires_list(wires, name, input_circuit)
        let union_basis = try self._make_union_basis(input_circuit)
        let union_gates = try self._make_union_gates(input_circuit)

        // Create a proxy wire_map to identify fragments and duplicates
        // and determine what registers need to be added to self
        var proxy_map: [RegBit:RegBit] = [:]
        for w in wires {
            proxy_map[w] = RegBit("",0)
        }
        let add_qregs = try self._check_wiremap_registers(proxy_map,input_circuit.qregs,OrderedDictionary<String,Int>(), false)
        for r in add_qregs {
            try self.add_qreg(r.name, r.index)
        }

        let add_cregs = try self._check_wiremap_registers(proxy_map,input_circuit.cregs,OrderedDictionary<String,Int>(), false)
        for r in add_cregs {
            try self.add_creg(r.name, r.index)
        }

        // Iterate through the nodes of self and replace the selected nodes
        // by iterating through the input_circuit, constructing and
        // checking the validity of the wire_map for each replacement
        // NOTE: We do not replace conditioned gates. One way to implement
        //       this later is to add or update the conditions of each gate
        //       that we add from the input_circuit.
        self.basis = union_basis
        self.gates = union_gates
        let topological_sort = try self.multi_graph.topological_sort()
        for node in topological_sort {
            guard let nd = node.data else {
                continue
            }
            if nd.type != "op" {
                continue
            }
            let dataOp = nd as! CircuitVertexOpData
            if dataOp.name != name {
                continue
            }
            if dataOp.condition != nil {
                continue
            }
            var args: [RegBit] = dataOp.qargs
            args.append(contentsOf: dataOp.cargs)
            var wire_map:[RegBit:RegBit] = [:]
            for i in 0..<wires.count {
                if i < args.count {
                    wire_map[wires[i]] = args[i]
                }
            }
            var wm: OrderedDictionary<RegBit,Int> = OrderedDictionary<RegBit,Int>()
            for w in wires {
                wm[w] = 0
            }
            try self._check_wiremap_validity(wire_map, wm,self.input_map, input_circuit)
            let (pred_map, succ_map) = self._make_pred_succ_maps(node.key)
            var (full_pred_map, full_succ_map) = self._full_pred_succ_maps(pred_map, succ_map,input_circuit, wire_map)
            // Now that we know the connections, delete node
            self.multi_graph.remove_vertex(node.key)
            // Iterate over nodes of input_circuit
            let tsin = try input_circuit.multi_graph.topological_sort()
            for m in tsin {
                guard let md = m.data else {
                    continue
                }
                if md.type != "op" {
                    continue
                }
                let mdOp = md as! CircuitVertexOpData
                // Insert a new node
                let condition = self._map_condition(wire_map,mdOp.condition)
                var m_qargs: [RegBit] = []
                for x in mdOp.qargs {
                    if let v = wire_map[x] {
                        m_qargs.append(v)
                    }
                    else {
                        m_qargs.append(x)
                    }
                }
                var m_cargs: [RegBit] = []
                for x in mdOp.cargs {
                    if let v = wire_map[x] {
                        m_cargs.append(v)
                    }
                    else {
                        m_cargs.append(x)
                    }
                }
                self._add_op_node(mdOp.name, m_qargs, m_cargs, mdOp.params, condition)
                // Add edges from predecessor nodes to new node
                // and update predecessor nodes that change
                var all_cbits = self._bits_in_condition(condition)
                all_cbits.append(contentsOf: m_cargs)
                var al = m_qargs
                al.append(contentsOf: all_cbits)
                for q in al {
                    if let qp = full_pred_map[q] {
                        self.multi_graph.add_edge(qp,self.node_counter, CircuitEdgeData(q))
                        full_pred_map[q] = self.node_counter
                    }
                }
            }
            // Connect all predecessors and successors, and remove
            // residual edges between input and output nodes
            for (w,_) in full_pred_map {
                guard let wp = full_pred_map[w] else {
                    continue
                }
                guard let ws = full_succ_map[w] else {
                    continue
                }
                self.multi_graph.add_edge(wp, ws,CircuitEdgeData(w))
                guard let wo = self.output_map[w] else {
                    continue
                }
                let o_pred = self.multi_graph.predecessors(wo)
                if o_pred.count > 1 {
                    assert(o_pred.count == 2, "expected 2 predecessors here")
                    var p:[Int] = []
                    for x in o_pred {
                        if x.key != wp {
                            p.append(x.key)
                        }
                    }
                    assert(p.count == 1, "expected 1 predecessor to pass filter")
                    self.multi_graph.remove_edge(p[0], wo)
                }
            }
        }
    }

    /**
     Replace one node with input_circuit.
     node is a reference to a node of self.multi_graph of type "op"
     input_circuit is a CircuitGraph.
     */
    func substitute_circuit_one(_ node: GraphVertex<CircuitVertexData>,
                                _ input_circuit: DAGCircuit,
                                wires: [RegBit] = []) throws {

        if node.data!.type != "op" {
            throw DAGCircuitError.invalidOpType(type: node.data!.type)
        }
        let nd = node.data as! CircuitVertexOpData

        // TODO: reuse common code in substitute_circuit_one and _all

        let name = nd.name
        try self._check_wires_list(wires, name, input_circuit)
        let union_basis = try self._make_union_basis(input_circuit)
        let union_gates = try self._make_union_gates(input_circuit)

        // Create a proxy wire_map to identify fragments and duplicates
        // and determine what registers need to be added to self
        var proxy_map: [RegBit:RegBit] = [:]
        for w in wires {
            proxy_map[w] = RegBit("",0)
        }
        let add_qregs = try self._check_wiremap_registers(proxy_map,input_circuit.qregs,OrderedDictionary<String,Int>(), false)
        for r in add_qregs {
            try self.add_qreg(r.name, r.index)
        }

        let add_cregs = try self._check_wiremap_registers(proxy_map,input_circuit.cregs,OrderedDictionary<String,Int>(), false)
        for r in add_cregs {
            try self.add_creg(r.name, r.index)
        }

        // Replace the node by iterating through the input_circuit.
        // Constructing and checking the validity of the wire_map.
        // NOTE: We do not replace conditioned gates. One way to implement
        //       later is to add or update the conditions of each gate we add
        //       from the input_circuit.
        self.basis = union_basis
        self.gates = union_gates

        if nd.condition != nil {
            return
        }
        var args: [RegBit] = nd.qargs
        args.append(contentsOf: nd.cargs)
        var wire_map:[RegBit:RegBit] = [:]
        for i in 0..<wires.count {
            if i < args.count {
                wire_map[wires[i]] = args[i]
            }
        }
        var wm: OrderedDictionary<RegBit,Int> = OrderedDictionary<RegBit,Int>()
        for w in wires {
            wm[w] = 0
        }
        try self._check_wiremap_validity(wire_map, wm,self.input_map, input_circuit)
        let (pred_map, succ_map) = self._make_pred_succ_maps(node.key)
        var (full_pred_map, full_succ_map) = self._full_pred_succ_maps(pred_map, succ_map,input_circuit, wire_map)
        // Now that we know the connections, delete node
        self.multi_graph.remove_vertex(node.key)
        // Iterate over nodes of input_circuit
        let tsin = try input_circuit.multi_graph.topological_sort()
        for m in tsin {
            guard let md = m.data else {
                continue
            }
            if md.type != "op" {
                continue
            }
            let mdOp = md as! CircuitVertexOpData
            // Insert a new node
            let condition = self._map_condition(wire_map,mdOp.condition)
            var m_qargs: [RegBit] = []
            for x in mdOp.qargs {
                if let v = wire_map[x] {
                    m_qargs.append(v)
                }
                else {
                    m_qargs.append(x)
                }
            }
            var m_cargs: [RegBit] = []
            for x in mdOp.cargs {
                if let v = wire_map[x] {
                    m_cargs.append(v)
                }
                else {
                    m_cargs.append(x)
                }
            }
            self._add_op_node(mdOp.name, m_qargs, m_cargs, mdOp.params, condition)
            // Add edges from predecessor nodes to new node
            // and update predecessor nodes that change
            var all_cbits = self._bits_in_condition(condition)
            all_cbits.append(contentsOf: m_cargs)
            var al = m_qargs
            al.append(contentsOf: all_cbits)
            for q in al {
                if let qp = full_pred_map[q] {
                    self.multi_graph.add_edge(qp,self.node_counter, CircuitEdgeData(q))
                    full_pred_map[q] = self.node_counter
                }
            }
        }
        // Connect all predecessors and successors, and remove
        // residual edges between input and output nodes
        for (w,_) in full_pred_map {
            guard let wp = full_pred_map[w] else {
                continue
            }
            guard let ws = full_succ_map[w] else {
                continue
            }
            self.multi_graph.add_edge(wp, ws,CircuitEdgeData(w))
            guard let wo = self.output_map[w] else {
                continue
            }
            let o_pred = self.multi_graph.predecessors(wo)
            if o_pred.count > 1 {
                assert(o_pred.count == 2, "expected 2 predecessors here")
                var p:[Int] = []
                for x in o_pred {
                    if x.key != wp {
                        p.append(x.key)
                    }
                }
                assert(p.count == 1, "expected 1 predecessor to pass filter")
                self.multi_graph.remove_edge(p[0], wo)
            }
        }
    }

    /**
     Return a list of "op" nodes with the given name.
     */
    public func get_named_nodes(_ name: String) throws -> [GraphVertex<CircuitVertexData>] {
        if self.basis[name] == nil {
            throw DAGCircuitError.noBasicOp(name: name)
        }
        var nlist: [GraphVertex<CircuitVertexData>] = []
        // Iterate through the nodes of self in topological order
        let ts = try self.multi_graph.topological_sort()
        for nd in ts {
            if let data = nd.data {
                if data.type == "op" {
                    let dataOp = data as! CircuitVertexOpData
                    if dataOp.name == name {
                        nlist.append(nd)
                    }
                }
            }
        }
        return nlist
    }

    /**
     Remove an operation node n.
     Add edges from predecessors to successors.
     */
    func _remove_op_node(_ n: Int) {
        let (pred_map, succ_map) = self._make_pred_succ_maps(n)
        self.multi_graph.remove_vertex(n)
        for w in pred_map.keys {
            guard let predIndex = pred_map[w] else {
                continue
            }
            guard let succIndex = succ_map[w] else {
                continue
            }
            self.multi_graph.add_edge(predIndex, succIndex,CircuitEdgeData(w))
        }
    }

    /**
     Remove all of the ancestor operation nodes of node.
     */
    func remove_ancestors_of(_ node: GraphVertex<CircuitVertexData>) {
        let anc = self.multi_graph.ancestors(node.key)
        // TODO: probably better to do all at once using
        // multi_graph.remove_nodes_from; same for related functions ...
        for n in anc {
            if let nd = n.data {
                if nd.type == "op" {
                    self._remove_op_node(n.key)
                }
            }
        }
    }

    /**
     Remove all of the descendant operation nodes of node.
     */
    func remove_descendants_of(_ node: GraphVertex<CircuitVertexData>) {
        let dec = self.multi_graph.descendants(node.key)
        for n in dec {
            if let nd = n.data {
            if nd.type == "op" {
                self._remove_op_node(n.key)
                }
            }
        }
    }

    /**
     Remove all of the non-ancestors operation nodes of node.
     */
    func remove_nonancestors_of(_ node: GraphVertex<CircuitVertexData>) {
        let comp = self.multi_graph.nonAncestors(node.key)
        for n in comp {
            if let nd = n.data {
                if nd.type == "op" {
                    self._remove_op_node(n.key)
                }
            }
        }
    }

    /**
     Remove all of the non-descendants operation nodes of node.
     */
    func remove_nondescendants_of(_ node: GraphVertex<CircuitVertexData>) {
        let comp = self.multi_graph.nonDescendants(node.key)
        for n in comp {
            if let nd = n.data {
                if nd.type == "op" {
                    self._remove_op_node(n.key)
                }
            }
        }
    }

    /**
     Return a list of layers for all d layers of this circuit.
     A layer is a circuit whose gates act on disjoint qubits, i.e.
     a layer has depth 1. The total number of layers equals the
     circuit depth d. The layers are indexed from 0 to d-1 with the
     earliest layer at index 0. The layers are constructed using a
     greedy algorithm. Each returned layer is a dict containing
     {"graph": circuit graph, "partition": list of qubit lists}.
     TODO: Gates that use the same cbits will end up in different
     layers as this is currently implemented. This may not be
     the desired behavior.
     */
    public func layers() throws -> [Layer] {
        var layers_list: [Layer] = []
        // node_map contains an input node or previous layer node for
        // each wire in the circuit.
        var node_map = self.input_map
        // wires_with_ops_remaining is a set of wire names that have
        // operations we still need to assign to layers
        var wires_with_ops_remaining = self.input_map.keys
        while !wires_with_ops_remaining.isEmpty {
            // Create a new circuit graph and populate with regs and basis
            let new_layer = DAGCircuit()
            for (k, v) in self.qregs {
                try new_layer.add_qreg(k, v)
            }
            for (k, v) in self.cregs {
                try new_layer.add_creg(k, v)
            }
            new_layer.basis = self.basis
            new_layer.gates = self.gates

            // Save the support of each operation we add to the layer
            var support_list: [[RegBit]] = []
            // Determine what operations to add in this layer
            // ops_touched is a map from operation nodes touched in this
            // iteration to the set of their unvisited input wires. When all
            // of the inputs of a touched node are visited, the node is a
            // foreground node we can add to the current layer.
            var ops_touched: [Int:Set<RegBit>] = [:]
            let wires_loop = wires_with_ops_remaining
            var emit: Bool = false
            for w in wires_loop {
                let outEdges = self.multi_graph.out_edges_iter(node_map[w]!)
                var oe: [GraphEdge<CircuitEdgeData>] = outEdges.filter { $0.data?.name == w }
                assert(oe.count == 1, "should only be one out-edge per (qu)bit")
                let nxt_nd = self.multi_graph.vertex(oe[0].neighbor)!
                // If we reach an output node, we are done with this wire.
                if nxt_nd.data!.type == "out" {
                    wires_with_ops_remaining = wires_with_ops_remaining.filter() { $0 != w }
                }
                // Otherwise, we are somewhere inside the circuit
                else if nxt_nd.data!.type == "op" {
                    // Operation data
                    let dOp = nxt_nd.data! as! CircuitVertexOpData
                    let qa = dOp.qargs
                    let ca = dOp.cargs
                    let pa = dOp.params
                    let co = dOp.condition
                    let cob = self._bits_in_condition(co)
                    // First time we see an operation, add to ops_touched
                    if ops_touched[nxt_nd.key] == nil {
                        ops_touched[nxt_nd.key] = Set<RegBit>(qa).union(ca).union(cob)
                    }
                    // Mark inputs visited by deleting from set
                    // NOTE: expect trouble with if(c==1) measure q -> c;
                    assert(ops_touched[nxt_nd.key]!.contains(w), "expected wire")
                    ops_touched[nxt_nd.key]!.remove(w)
                    // Node becomes "foreground" if set becomes empty,
                    // i.e. every input is available for this operation
                    if ops_touched[nxt_nd.key]!.isEmpty {
                        // Add node to new_layer
                        try new_layer.apply_operation_back(dOp.name, qa, ca, pa, co)
                        // Update node_map to point to this op
                        for v in Set<RegBit>(qa).union(ca).union(cob) {
                            node_map[v] = nxt_nd.key
                        }
                        // Add operation to partition
                        if dOp.name != "barrier" {
                            // support_list.append(list(set(qa) | set(ca) |
                            //                          set(cob)))
                            support_list.append(Array(Set<RegBit>(qa)))
                        }
                        emit = true
                    }
                }
            }
            if emit {
                layers_list.append(Layer(new_layer,support_list))
                emit = false
            }
            else {
                assert(wires_with_ops_remaining.isEmpty, "not finished but empty?")
            }
        }
        return layers_list
    }

    /**
     Return a list of layers for all gates of this circuit.
     A serial layer is a circuit with one gate. The layers have the
     same structure as in layers().
     */
    func serial_layers() throws -> [Layer] {
        var layers_list: [Layer] = []
        let topological_sort = try self.multi_graph.topological_sort()
        for nxt_nd in topological_sort {
            guard let nd = nxt_nd.data else {
                continue
            }
            if nd.type != "op" {
                continue
            }
            let dOp = nd as! CircuitVertexOpData
            let new_layer = DAGCircuit()
            for (k, v) in self.qregs {
                try new_layer.add_qreg(k, v)
            }
            for (k, v) in self.cregs {
                try new_layer.add_creg(k, v)
            }
            new_layer.basis = self.basis
            for (key,value) in self.gates {
                new_layer.gates[key] = value
            }
            // Save the support of the operation we add to the layer
            var support_list: [[RegBit]] = []
            // Operation data
            let qa = dOp.qargs
            let ca = dOp.cargs
            let pa = dOp.params
            let co = dOp.condition
            // Add node to new_layer
            try new_layer.apply_operation_back(dOp.name,qa, ca, pa, co)
            //Add operation to partition
            if dOp.name != "barrier" {
                // support_list.append(list(set(qa) | set(ca) | set(cob)))
                support_list.append(Array(Set<RegBit>(qa)))
            }
            layers_list.append(Layer(new_layer,support_list))
        }
        return layers_list
    }

    /**
     Return a set of runs of "op" nodes with the given names.
     For example, "... h q[0]; cx q[0],q[1]; cx q[0],q[1]; h q[1]; .."
     would produce the tuple of cx nodes as an element of the set returned
     from a call to collect_runs(["cx"]). If instead the cx nodes were
     "cx q[0],q[1]; cx q[1],q[0];", the method would still return the
     pair in a tuple. The namelist can contain names that are not
     in the circuit's basis.
     Nodes must have only one successor to continue the run.
     */
    func collect_runs(_ namelist: Set<String>) throws -> [[GraphVertex<CircuitVertexData>]] {
        var group_list: [[GraphVertex<CircuitVertexData>]] = []

        // Iterate through the nodes of self in topological order
        // and form tuples containing sequences of gates
        // on the same qubit(s).
        let topological_sort = try self.multi_graph.topological_sort()
        var nodes_seen:[Int:Bool] = [:]
        for node in topological_sort {
            nodes_seen[node.key] = false
        }
        for node in topological_sort {
            guard let nd = node.data else {
                continue
            }
            if nd.type != "op" {
                continue
            }
            let ndOp = nd as! CircuitVertexOpData
            if !namelist.contains(ndOp.name) {
                continue
            }
            if nodes_seen[node.key]! {
                continue
            }
            var group: [GraphVertex<CircuitVertexData>] = [node]
            nodes_seen[node.key] = true
            var s = self.multi_graph.successors(node.key)
            while s.count == 1 {
                guard let sd = s[0].data else {
                    break
                }
                if sd.type != "op" {
                    break
                }
                let ndOp = sd as! CircuitVertexOpData
                if !namelist.contains(ndOp.name) {
                    break
                }
                group.append(s[0])
                nodes_seen[s[0].key] = true
                s = self.multi_graph.successors(s[0].key)
            }
            if group.count > 1 {
                group_list.append(group)
            }
        }
        return group_list
    }

    /**
     Count the occurrences of operation names.
     Returns a dictionary of counts keyed on the operation name.
    */
    func count_ops() throws -> [String:Int] {
        var op_dict: [String:Int] = [:]
        let topological_sort = try self.multi_graph.topological_sort()
        for node in topological_sort {
            guard let nd = node.data else {
                continue
            }
            if nd.type != "op" {
                continue
            }
            let ndOp = nd as! CircuitVertexOpData
            let name = ndOp.name
            if op_dict[name] == nil {
                op_dict[name] = 1
            }
            else {
                op_dict[name]! += 1
            }
        }
        return op_dict
    }

    /**
     Return a dictionary of circuit properties.
     */
    func property_summary() throws -> [String:Any] {
        return [ "size": self.size(),
                 "depth": try self.depth(),
                 "width": self.width(),
                 "bits":  self.num_cbits(),
                 "factors": try self.num_tensor_factors(),
                 "operations": try self.count_ops() ]
    }
}
