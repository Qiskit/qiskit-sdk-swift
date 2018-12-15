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
 Directed graph object for representing coupling between qubits.
 The nodes of the graph correspond to named qubits and the directed edges
 indicate which qubits are coupled and the permitted direction of CNOT gates.
 The object has a distance function that can be used to map quantum circuits
 onto a device with this coupling.
 */
final class Coupling: CustomStringConvertible {

    /**
     Convert coupling map dictionary into list.

     Example dictionary format: {0: [1, 2], 1: [2]}
     Example list format: [[0, 1], [0, 2], [1, 2]]

     We do not do any checking of the input.

     Return coupling map in list format.
     */
    static func coupling_dict2list(_ couplingdict: [Int:[Int]]) -> [[Int]] {
        var couplinglist: [[Int]] = []
        for (ctl, tgtlist) in couplingdict.sorted(by: { $0.0 < $1.0 }) {
            for tgt in tgtlist {
                couplinglist.append([ctl, tgt])
            }
        }
        return couplinglist
    }

    /**
     Convert coupling map list into dictionary.

     Example list format: [[0, 1], [0, 2], [1, 2]]
     Example dictionary format: {0: [1, 2], 1: [2]}

     We do not do any checking of the input.

     Return coupling map in dict format.
     */
    static func coupling_list2dict(_ couplinglist: [[Int]]) -> [Int:[Int]] {
        var couplingdict: [Int:[Int]] = [:]
        for pair in couplinglist {
            if var value = couplingdict[pair[0]] {
                value.append(pair[1])
                couplingdict[pair[0]] = value
            }
            else {
                couplingdict[pair[0]] = [pair[1]]
            }
        }
        return couplingdict
    }

    /**
    qubits is dict from qubit (regname,idx) tuples to node indices
     */
    private var qubits: OrderedDictionary<RegBit,Int> = OrderedDictionary<RegBit,Int>()

    /**
     index_to_qubit is a dict from node indices to qubits
     */
    private var index_to_qubit: [Int:RegBit] = [:]

    /**
     node_counter is integer counter for labeling nodes
     */
    private var node_counter = 0

    /**
     G is the coupling digraph
     */
    private var G: Graph<CouplingVertexData,EmptyGraphData> = Graph<CouplingVertexData,EmptyGraphData>(directed: true)

    /**
     dist is a dict of dicts from node pairs to distances
     it must be computed, it is the distance on the digraph
     */
    private var dist: [RegBit:[RegBit:Int]] = [:]

    /**
     Return a string representation of the coupling graph.
     */
    public var description: String {
        var s = "qubits: "
        var list: [String] = []
        for k in self.qubits.keys {
            if let v = self.qubits[k] {
                list.append("\(k.description) @ \(v)")
            }
        }
        s += list.joined(separator: ", ")
        s += "\nedges: "
        list = []
        for tuple in self.get_edges() {
            list.append("\(tuple.one.description)-\(tuple.two.description)")
        }
        s += list.joined(separator: ", ")
        return s
    }

    /**
     Directed graph specifying fixed coupling.
     Nodes correspond to qubits and directed edges correspond to permitted
     CNOT gates
     */
    /**
     Create coupling graph.
     By default, the coupling graph has no nodes. The optional couplingdict
     specifies the graph as an adjacency list. For example,
     couplingdict = {0: [1, 2], 1: [2]}.
     */
    init(_ couplingdict: [Int:[Int]]? = nil) throws {
        // Add edges to the graph if the couplingdict is present
        if let dict = couplingdict {
            let dictSorted = dict.sorted(by:{ (n1: (key: Int, value: [Int]), n2: (key: Int, value: [Int])) -> Bool in
                return n1.key < n2.key
            })
            for (v0, alist) in dictSorted {
                for v1 in alist {
                    let regname = "q"
                    try self.add_edge(RegBit(regname, v0), RegBit(regname, v1))
                }
            }
            try self.compute_distance()
        }
    }

    /**
     Return the number of qubits in this graph
     */
    public func size() -> Int {
        return self.qubits.count
    }

    /**
     Return the qubits in this graph as (qreg, index) tuples
     */
    public func get_qubits() -> [RegBit] {
        return self.qubits.keys
    }

    /**
     Return a list of edges in the coupling graph.
     Each edge is a pair of qubits and each qubit is a tuple (qreg, index).
     */
    public func get_edges() -> [TupleRegBit] {
        var edges: [TupleRegBit] = []
        for edge in self.G.edges {
            edges.append(TupleRegBit(self.index_to_qubit[edge.source]!,self.index_to_qubit[edge.neighbor]!))
        }
        return edges
    }

    /**
     Add a qubit to the coupling graph.
     name = tuple (regname, idx) for qubit
     */
    private func add_qubit(_ name: RegBit) throws {
        if self.qubits[name] != nil {
            throw CouplingError.duplicateregbit(regBit: name)
        }
        self.node_counter += 1
        self.qubits[name] = self.G.add_vertex(self.node_counter, CouplingVertexData(name)).key
        self.index_to_qubit[self.qubits[name]!] = name
    }

    /**
     Add directed edge to coupling graph.
     s_name = source qubit tuple
     d_name = destination qubit tuple
     */
    private func add_edge(_ s_name: RegBit, _ d_name: RegBit) throws {
        if self.qubits[s_name] == nil {
            try self.add_qubit(s_name)
        }
        if self.qubits[d_name] == nil {
            try self.add_qubit(d_name)
        }
        self.G.add_edge(self.qubits[s_name]!, self.qubits[d_name]!)
    }

    /**
     Test if the graph is connected.
     Return True if connected, False otherwise
     */
    public func connected() throws -> Bool {
        return try self.G.is_weakly_connected()
    }

    /**
     Compute the distance function on pairs of nodes.
     The distance map self.dist is computed from the graph using
     all_pairs_shortest_path_length
    */
    private func compute_distance() throws {
        if try !self.connected() {
            throw CouplingError.notconnected
        }
        let lengths = self.G.to_undirected().all_pairs_shortest_path_length()
        self.dist = [:]
        for i in self.qubits.keys {
            self.dist[i] = [:]
            guard let lengthSource = lengths[self.qubits[i]!] else {
                continue
            }
            for j in self.qubits.keys {
                guard let lengthEnd = lengthSource[self.qubits[j]!] else {
                    continue
                }
                self.dist[i]![j] = lengthEnd
            }
        }
    }

    /**
     Return the distance between qubit q1 to qubit q2
     */
    public func distance(_ q1: RegBit, _ q2: RegBit) throws -> Int {
        if self.dist.isEmpty {
            throw CouplingError.distancenotcomputed
        }
        if self.qubits[q1] == nil {
            throw CouplingError.notincouplinggraph(regBit: q1)
        }
        if self.qubits[q2] == nil {
            throw CouplingError.notincouplinggraph(regBit: q2)
        }
        return self.dist[q1]![q2]!
    }
}
