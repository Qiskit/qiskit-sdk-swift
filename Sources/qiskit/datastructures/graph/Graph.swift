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

protocol GraphDataCopying {
    func copy() -> GraphDataCopying
}

enum SearchProcessType {
    case vertexEarly
    case vertexLate
    case edge
}

enum EdgeClassification {
    case tree
    case back
    case forward
    case cross
    case unknown
}

final class BFSState {
    fileprivate(set) var discovered: Set<Int> = []
    fileprivate(set) var processed: Set<Int> = []
    fileprivate(set) var parent: [Int:Int] = [:]
}

final class EmptyGraphData: GraphDataCopying {
    func copy() -> GraphDataCopying {
        return EmptyGraphData()
    }
}

typealias BFSHandler<VertexDataType: GraphDataCopying,EdgeDataType: GraphDataCopying> = (SearchProcessType,
                        GraphVertex<VertexDataType>?,
                        [GraphEdge<EdgeDataType>],
                        BFSState) throws -> (Void)

final class DFSState {
    var finished = false
    fileprivate var queue: [Int] = []
    fileprivate(set) var discovered: Set<Int> = []
    fileprivate(set) var processed: Set<Int> = []
    fileprivate(set) var time: Int = 0
    fileprivate(set) var entryTime: [Int:Int] = [:]
    fileprivate(set) var exitTime: [Int:Int] = [:]
    fileprivate(set) var parent: [Int:Int] = [:]
}

typealias DFSHandler<VertexDataType: GraphDataCopying,EdgeDataType: GraphDataCopying> = (SearchProcessType,
                                                        GraphVertex<VertexDataType>?,
                                                        [GraphEdge<EdgeDataType>],
                                                        DFSState) throws -> (Void)

final class Graph<VertexDataType: GraphDataCopying,EdgeDataType: GraphDataCopying> {

    public private(set) var vertices: OrderedDictionary<Int,GraphVertex<VertexDataType>> =
                                                OrderedDictionary<Int,GraphVertex<VertexDataType>>()
    private var _edges: OrderedDictionary<TupleInt,[GraphEdge<EdgeDataType>]> =
                                                OrderedDictionary<TupleInt,[GraphEdge<EdgeDataType>]>()
    public private(set) var isDirected: Bool

    public var vertexKeys: [Int] {
        return self.vertices.keys.sorted()
    }

    public var edgeKeys: [TupleInt] {
        return self._edges.keys.sorted() {
            if $0.one < $1.one {
                return true
            }
            if $0.one > $1.one {
                return false
            }
            if $0.two < $1.two {
                return true
            }
            return false
        }
    }

    public var edges: [GraphEdge<EdgeDataType>] {
        var edges: [GraphEdge<EdgeDataType>] = []
        for key in self.edgeKeys {
            if let multiEdges = self._edges[key] {
                for edge in multiEdges {
                    edges.append(edge)
                }
            }
        }
        return edges
    }

    public init(directed: Bool) {
        self.isDirected = directed
    }

    public func copy() -> Graph<VertexDataType,EdgeDataType> {
        let copy = Graph(directed: self.isDirected)
        for (_,v) in self.vertices {
            let vertex = v.copy()
            copy.vertices[vertex.key] = vertex
        }
        for (key,multiEdges) in self._edges {
            var newMultiEdges: [GraphEdge<EdgeDataType>] = []
            for edge in multiEdges {
                newMultiEdges.append(edge.copy())
            }
            copy._edges[key] = newMultiEdges
        }
        return copy
    }

    public func vertex(_ key: Int) -> GraphVertex<VertexDataType>? {
        return self.vertices[key]
    }

    public func edges(_ sourceIndex: Int, _ neighborIndex: Int) -> [GraphEdge<EdgeDataType>] {
        return self._edges[TupleInt(sourceIndex,neighborIndex)] ?? []
    }

    public func add_vertex(_ key: Int) -> GraphVertex<VertexDataType> {
        var vertex = self.vertex(key)
        if vertex == nil {
            vertex = GraphVertex(key)
            self.vertices[key] = vertex!
        }
        return vertex!
    }

    @discardableResult
    public func add_vertex(_ key: Int, _ data: VertexDataType) -> GraphVertex<VertexDataType> {
        var vertex = self.vertex(key)
        if vertex == nil {
            vertex = GraphVertex(key)
            self.vertices[key] = vertex!
        }
        vertex!.data = data
        return vertex!
    }

    public func add_edge(_ sourceIndex: Int, _ neighborIndex: Int, _ data: EdgeDataType? = nil) {
        self.add_edge(self.add_vertex(sourceIndex),self.add_vertex(neighborIndex),data)
    }

    public func add_edge(_ source: GraphVertex<VertexDataType>, _ neighbor: GraphVertex<VertexDataType>, _ data: EdgeDataType? = nil) {
        var newEdge = GraphEdge<EdgeDataType>(source.key,neighbor.key)
        newEdge.data = data
        source.addNeighbor(neighbor.key)
        var grapMultiEdges = self.edges(newEdge.source,newEdge.neighbor)
        grapMultiEdges.append(newEdge)
        self._edges[TupleInt(source.key,neighbor.key)] = grapMultiEdges

        if !self.isDirected {
            newEdge = GraphEdge<EdgeDataType>(neighbor.key,source.key)
            newEdge.data = data
            if self._edges[TupleInt(newEdge.source,newEdge.neighbor)] == nil {
                neighbor.addNeighbor(source.key)
                self._edges[TupleInt(newEdge.source,newEdge.neighbor)] = [newEdge]
            }
        }
    }

    public func remove_edge(_ sourceIndex: Int, _ neighborIndex: Int) {
        self._edges[TupleInt(sourceIndex,neighborIndex)] = nil
        if let source = self.vertex(sourceIndex) {
            source.removeNeighbor(neighborIndex)
        }
        if !self.isDirected {
            self._edges[TupleInt(neighborIndex,sourceIndex)] = nil
            if let neighbor = self.vertex(neighborIndex) {
                neighbor.removeNeighbor(sourceIndex)
            }
        }
    }

    public func remove_vertex(_ index: Int) {
        if self.vertex(index) == nil {
            return
        }
        self._edges[TupleInt(index,index)] = nil
        self.vertices[index] = nil
        for (_,vertex) in self.vertices {
            vertex.removeNeighbor(index)
            self._edges[TupleInt(index,vertex.key)] = nil
            self._edges[TupleInt(vertex.key,index)] = nil
        }
    }

    public func in_edges_iter(_ index: Int) -> [GraphEdge<EdgeDataType>] {
        if self.vertex(index) == nil {
            return []
        }
        var inEdges: [GraphEdge<EdgeDataType>] = []
        for edge in self.edges {
            if edge.neighbor == index {
                inEdges.append(edge)
            }
        }
        return inEdges
    }

    public func out_edges_iter(_ index: Int) -> [GraphEdge<EdgeDataType>] {
        if self.vertex(index) == nil {
            return []
        }
        var outEdges: [GraphEdge<EdgeDataType>] = []
        for edge in self.edges {
            if edge.source == index {
                outEdges.append(edge)
            }
        }
        return outEdges
    }

    public func bfs(_ start:  GraphVertex<VertexDataType>,
                    _ state:   BFSState,
                    _ handler: BFSHandler<VertexDataType,EdgeDataType>) throws {
        var queue = Queue<GraphVertex<VertexDataType>>()
        queue.enqueue(start)
        state.discovered.update(with: start.key)
        while !queue.isEmpty {
            let vertex = queue.dequeue()
            try handler(SearchProcessType.vertexEarly,vertex,[],state)
            for key in vertex.neighbors {
                let neighbor = self.vertex(key)!
                try handler(SearchProcessType.edge,nil,self.edges(vertex.key,neighbor.key),state)
                if !state.discovered.contains(neighbor.key) {
                    state.discovered.update(with: neighbor.key)
                    state.parent[neighbor.key] = vertex.key
                    queue.enqueue(neighbor)
                }
            }
            state.processed.update(with: vertex.key)
            try handler(SearchProcessType.vertexLate,vertex,[],state)
        }
    }

    public func dfs(_ vertex:  GraphVertex<VertexDataType>,
                           _ state:   DFSState,
                           _ handler: DFSHandler<VertexDataType,EdgeDataType>) throws {

        if state.finished {
            return
        }
        state.discovered.update(with: vertex.key)
        state.time += 1
        state.entryTime[vertex.key] = state.time
        try handler(SearchProcessType.vertexEarly,vertex,[],state)
        for key in vertex.neighbors {
            let neighbor = self.vertex(key)!
            if !state.discovered.contains(neighbor.key) {
                state.parent[neighbor.key] = vertex.key
                try handler(SearchProcessType.edge,nil,self.edges(vertex.key,neighbor.key),state)
                try self.dfs(neighbor, state, handler)
                if state.finished {
                    return
                }
            }
        }
        try handler(SearchProcessType.vertexLate,vertex,[],state)
        state.time += 1
        state.exitTime[vertex.key] = state.time
        state.processed.update(with: vertex.key)
    }

    public static func edgeClassification(_ edge: GraphEdge<EdgeDataType>,
                                          _ state: DFSState) -> EdgeClassification {
        if let parent = state.parent[edge.neighbor] {
            if parent == edge.source {
                return EdgeClassification.tree
            }
        }
        if state.discovered.contains(edge.neighbor) &&
            !state.processed.contains(edge.neighbor) {
            return EdgeClassification.back
        }
        if state.processed.contains(edge.neighbor) {
            var entryTimeSource = 0
            if let time = state.entryTime[edge.source] {
                entryTimeSource = time
            }
            var entryTimeNeighbor = 0
            if let time = state.entryTime[edge.neighbor] {
                entryTimeNeighbor = time
            }
            if entryTimeNeighbor > entryTimeSource {
                return EdgeClassification.forward
            }
            if entryTimeNeighbor < entryTimeSource {
                return EdgeClassification.cross
            }
        }
        return EdgeClassification.unknown
    }

    public func topological_sort(reverse: Bool = false) throws -> [GraphVertex<VertexDataType>] {
        if !self.isDirected {
            throw GraphError.isUndirected
        }

        var seen: Set<Int> = []
        var order: [GraphVertex<VertexDataType>] = []
        var explored: Set<Int> = []
        for v in self.vertexKeys {
            if explored.contains(v) {
                continue
            }
            var fringe = [v]
            while !fringe.isEmpty {
                let w = fringe.last!
                if explored.contains(w) {
                    fringe.removeLast()
                    continue
                }
                seen.update(with: w)
                var new_nodes: [Int] = []
                for n in self.successors(w) {
                    if !explored.contains(n.key) {
                        if seen.contains(n.key) {
                            throw GraphError.isCyclic
                        }
                        new_nodes.append(n.key)
                    }
                }
                if !new_nodes.isEmpty {
                    fringe.append(contentsOf: new_nodes)
                }
                else {
                    explored.update(with: w)
                    order.append(self.vertex(w)!)
                    fringe.removeLast()
                }
            }
        }
        if reverse {
            return order
        }
        var vertices: [GraphVertex<VertexDataType>] = []
        while !order.isEmpty {
            vertices.append(order.removeLast())
        }
        return vertices
    }

    public func predecessors(_ key: Int) -> [GraphVertex<VertexDataType>] {
        if self.vertex(key) == nil {
            return []
        }
        var list: [GraphVertex<VertexDataType>] = []
        for (_,vertex) in self.vertices {
            for neighborKey in vertex.neighbors {
                if neighborKey == key {
                    list.append(vertex)
                }
            }
        }
        return list
    }

    public func ancestors(_ key: Int) -> [GraphVertex<VertexDataType>] {
        var list: [GraphVertex<VertexDataType>] = []
        var visited = Set<Int>()
        for (_,vertex) in self.vertices {
            if vertex.key == key {
                continue
            }
            if visited.contains(vertex.key) {
                continue
            }
            self.ancestorsUtil(vertex, key, &visited, &list)
        }
        return list
    }

    @discardableResult
    private func ancestorsUtil(_ vertex: GraphVertex<VertexDataType>,
                                 _ key: Int,
                                 _ visited: inout Set<Int>,
                                 _ list: inout [GraphVertex<VertexDataType>]) -> Bool {
        visited.update(with: vertex.key)
        for i in vertex.neighbors {
            let neighbor = self.vertex(i)!
            if visited.contains(neighbor.key) {
                continue
            }
            if neighbor.key == key {
                list.append(vertex)
                return true
            }
            if self.ancestorsUtil(neighbor, key, &visited, &list) {
                list.append(vertex)
                return true
            }
        }
        return false
    }

    public func nonAncestors(_ key: Int) -> [GraphVertex<VertexDataType>] {
        var vertexSet: Set<Int> = []
        for (_,vertex) in self.vertices {
            vertexSet.update(with: vertex.key)
        }
        var ancestorsSet: Set<Int> = []
        for ancestor in self.ancestors(key) {
            ancestorsSet.update(with: ancestor.key)
        }
        let nonAncestorsSet = vertexSet.subtracting(ancestorsSet)
        var nonAncestorsList: [GraphVertex<VertexDataType>] = []
        for nonAncestor in nonAncestorsSet {
            nonAncestorsList.append(self.vertex(nonAncestor)!)
        }
        return nonAncestorsList
    }

    public func neighbors(_ key: Int) -> [GraphVertex<VertexDataType>] {
        guard let vertex = self.vertex(key) else {
            return []
        }
        var list: [GraphVertex<VertexDataType>] = []
        for i in vertex.neighbors {
            let neighbor = self.vertex(i)!
            list.append(neighbor)
        }
        return list
    }

    public func successors(_ key: Int) -> [GraphVertex<VertexDataType>] {
        return self.neighbors(key)
    }

    public func descendants(_ key: Int) -> [GraphVertex<VertexDataType>] {
        guard let rootVertex = self.vertex(key) else {
            return []
        }
        var vertices: [GraphVertex<VertexDataType>] = []
        let state: DFSState = DFSState()
        for i in rootVertex.neighbors {
            let neighbor = self.vertex(i)!
            if !state.discovered.contains(neighbor.key) {
                do {
                    try self.dfs(neighbor, state) { (searchProcessType,vertex,edge,state) -> Void in
                        if searchProcessType == SearchProcessType.vertexEarly {
                            if let v = vertex {
                                vertices.append(v)
                            }
                        }
                    }
                }
                catch {
                }
            }
        }
        return vertices
    }

    public func nonDescendants(_ key: Int) -> [GraphVertex<VertexDataType>] {
        var vertexSet: Set<Int> = []
        for (_,vertex) in self.vertices {
            vertexSet.update(with: vertex.key)
        }
        var descendantsSet: Set<Int> = []
        for descendant in self.descendants(key) {
            descendantsSet.update(with: descendant.key)
        }
        let nonDescendantsSet = vertexSet.subtracting(descendantsSet)
        var nonDescendantsList: [GraphVertex<VertexDataType>] = []
        for nonDescendant in nonDescendantsSet {
            nonDescendantsList.append(self.vertex(nonDescendant)!)
        }
        return nonDescendantsList
    }

    public func order() -> Int {
        return self.vertices.count
    }

    public func is_directed_acyclic_graph() -> Bool {
        if !self.isDirected {
            return false
        }
        let state: DFSState = DFSState()
        for (_,vertex) in self.vertices {
            if !state.discovered.contains(vertex.key) {
                do {
                    try self.dfs(vertex, state) { (searchProcessType,vertex,edges,state) -> Void in
                        if searchProcessType == SearchProcessType.edge {
                            let classification = Graph.edgeClassification(edges[0],state)
                            if classification == EdgeClassification.back {
                                throw GraphError.isCyclic
                            }
                        }
                    }
                }
                catch {
                    return false
                }
            }
        }
        return true
    }

    public func dag_longest_path() throws -> [GraphVertex<VertexDataType>] {
        var distanceMap: [Int:(Int,GraphVertex<VertexDataType>)] = [:]
        for sortedVertex in try self.topological_sort() {
            var pairs: [(Int,GraphVertex<VertexDataType>)] = []
            for v in self.predecessors(sortedVertex.key) {
                var distance = 1
                if let pair = distanceMap[v.key] {
                    distance += pair.0
                }
                pairs.append((distance,v))
            }
            var maxPair: (Int,GraphVertex<VertexDataType>) = (0,sortedVertex)
            for pair in pairs {
                if maxPair.0 <= pair.0 {
                    maxPair = pair
                }
            }
            distanceMap[sortedVertex.key] = maxPair
        }
        var vertex: GraphVertex<VertexDataType>? = nil
        var length: Int = 0
        for (v, pair) in distanceMap {
            if length <= pair.0 {
                length = pair.0
                vertex = self.vertex(v)
            }
        }
        var path: [GraphVertex<VertexDataType>] = []
        if var v = vertex {
            while length > 0 {
                path.append(v)
                guard let pair = distanceMap[v.key] else {
                    break
                }
                length = pair.0
                v = pair.1
            }
            path.reverse()
        }
        return path
    }

    public func dag_longest_path_length() throws -> Int {
        let path = try self.dag_longest_path()
        if path.isEmpty {
            return 0
        }
        return path.count - 1
    }

    public func single_source_shortest_path_length(_ source: Int) -> [Int:Int] {
        guard let vertex = self.vertex(source) else {
            return [:]
        }
        var seen: [Int:Int] = [:]
        var level: Int = 0
        var nextlevel: [GraphVertex<VertexDataType>:Int] = [vertex:1]
        while !nextlevel.isEmpty {
            let thislevel = nextlevel
            nextlevel = [:]
            for (v,_) in thislevel {
                if seen[v.key] == nil {
                    seen[v.key] = level
                    for i in v.neighbors {
                        let neighbor = self.vertex(i)!
                        nextlevel[neighbor] = 0
                    }
                }
            }
            level += 1
        }
        return seen
    }

    public func all_pairs_shortest_path_length() -> [Int: [Int:Int]] {
        var paths: [Int: [Int:Int]] = [:]
        for (_,vertex) in self.vertices {
            paths[vertex.key] = self.single_source_shortest_path_length(vertex.key)
        }
        return paths
    }

    public func weakly_connected_components() throws -> [[Int]] {
        if !self.isDirected {
            throw GraphError.isUndirected
        }
        var list: [[Int]] = []
        var seen: Set<Int> = []
        for v in self.vertexKeys {
            if !seen.contains(v) {
                let vertices = self._plain_bfs(v)
                list.append(vertices)
                seen.formUnion(vertices)
            }
        }
        // longest components first
        return list.sorted { $0.count > $1.count }
    }

    private func _plain_bfs(_ source: Int) -> [Int] {
        var list: [Int] = []
        var seen: Set<Int> = []
        var nextlevel: Set<Int> = [source]
        while !nextlevel.isEmpty {
            let thislevel = nextlevel
            nextlevel = []
            for v in thislevel {
                if !seen.contains(v) {
                    list.append(v)
                    seen.update(with: v)
                    for successor in self.successors(v) {
                        nextlevel.update(with: successor.key)
                    }
                    for predecessor in self.predecessors(v) {
                        nextlevel.update(with: predecessor.key)
                    }
                }
            }
        }
        return list
    }

    public func number_weakly_connected_components() throws -> Int {
        return try self.weakly_connected_components().count
    }

    public func is_weakly_connected() throws -> Bool {
        let order = self.order()
        if order == 0 {
            throw GraphError.connectEmptyGraph
        }
        let list = try self.weakly_connected_components()
        if list.isEmpty {
            return false
        }
        let count = list.first!.count
        return count == order

    }

    public func to_undirected() -> Graph {
        let graph = self.copy()
        if !graph.isDirected {
            return graph
        }
        graph.isDirected = false
        for (_,multiEdges) in graph._edges {
            for edge in multiEdges {
                guard let source = graph.vertex(edge.source) else {
                    continue
                }
                guard let neighbor = graph.vertex(edge.neighbor) else {
                    continue
                }
                let newEdge = GraphEdge<EdgeDataType>(edge.neighbor,edge.source)
                newEdge.data = edge.data
                neighbor.addNeighbor(source.key)
                var grapMultiEdges = graph.edges(newEdge.source,newEdge.neighbor)
                if grapMultiEdges.isEmpty {
                    grapMultiEdges.append(newEdge)
                    graph._edges[TupleInt(newEdge.source,newEdge.neighbor)] = grapMultiEdges
                }
            }
        }
        return graph
    }
}
