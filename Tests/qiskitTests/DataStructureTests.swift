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

import XCTest
@testable import qiskit

class DataStructureTests: XCTestCase {

    static let allTests = [
        ("testOrderedDictionary",testOrderedDictionary),
        ("testTopologicalSort",testTopologicalSort),
        ("testPredecessors",testPredecessors),
        ("testAncestors",testAncestors),
        ("testSuccessors",testSuccessors),
        ("testDescendants",testDescendants),
        ("testWeaklyConnetectedComponents",testWeaklyConnetectedComponents),
        ("testLongestPath",testLongestPath),
        ("testVector",testVector),
        ("testMatrix",testMatrix),
        ("testComplexMatrix", testComplexMatrix),
        ("testTrace",testTrace)
    ]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOrderedDictionary() {
        var dict: OrderedDictionary<Int,String> = OrderedDictionary<Int,String>()
        dict[4] = "Four"
        dict[8] = "Eight"
        dict[15] = "Fifteen"
        XCTAssertEqual(dict.description, "[\"4\": \"Four\" ,\"8\": \"Eight\" ,\"15\": \"Fifteen\"]")
        dict[1] = nil
        dict[4] = nil
        XCTAssertEqual(dict.description, "[\"8\": \"Eight\" ,\"15\": \"Fifteen\"]")
    }

    func testTopologicalSort() {
        do {
            let g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
            g.add_edge(5, 2)
            g.add_edge(5, 0)
            g.add_edge(4, 0)
            g.add_edge(4, 1)
            g.add_edge(2, 3)
            g.add_edge(3, 1)

            var str = try DataStructureTests.formatList(g.topological_sort())
            XCTAssertEqual(str, "5 4 2 3 1 0")
            str = try DataStructureTests.formatList(g.topological_sort(reverse: true))
            XCTAssertEqual(str, "0 1 3 2 4 5")
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testPredecessors() {
        let g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
        g.add_edge(5, 2)
        g.add_edge(5, 0)
        g.add_edge(4, 0)
        g.add_edge(4, 1)
        g.add_edge(2, 3)
        g.add_edge(3, 1)

        var str = DataStructureTests.formatList(g.predecessors(0))
        XCTAssertEqual(str, "5 4")
        str = DataStructureTests.formatList(g.predecessors(1))
        XCTAssertEqual(str, "4 3")
        str = DataStructureTests.formatList(g.predecessors(2))
        XCTAssertEqual(str, "5")
        str = DataStructureTests.formatList(g.predecessors(3))
        XCTAssertEqual(str, "2")
        str = DataStructureTests.formatList(g.predecessors(4))
        XCTAssertEqual(str, "")
        str = DataStructureTests.formatList(g.predecessors(5))
        XCTAssertEqual(str, "")
    }

    func testAncestors() {
        let g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
        g.add_edge(5, 2)
        g.add_edge(5, 0)
        g.add_edge(4, 0)
        g.add_edge(4, 1)
        g.add_edge(2, 3)
        g.add_edge(3, 1)

        var str = DataStructureTests.formatList(g.ancestors(0))
        XCTAssertEqual(str, "5 4")
        str = DataStructureTests.formatList(g.ancestors(1))
        XCTAssertEqual(str, "3 2 5 4")
        str = DataStructureTests.formatList(g.ancestors(2))
        XCTAssertEqual(str, "5")
        str = DataStructureTests.formatList(g.ancestors(3))
        XCTAssertEqual(str, "2 5")
        str = DataStructureTests.formatList(g.ancestors(4))
        XCTAssertEqual(str, "")
        str = DataStructureTests.formatList(g.ancestors(5))
        XCTAssertEqual(str, "")
    }

    func testSuccessors() {
        let g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
        g.add_edge(5, 2)
        g.add_edge(5, 0)
        g.add_edge(4, 0)
        g.add_edge(4, 1)
        g.add_edge(2, 3)
        g.add_edge(3, 1)

        var str = DataStructureTests.formatList(g.successors(0))
        XCTAssertEqual(str, "")
        str = DataStructureTests.formatList(g.successors(1))
        XCTAssertEqual(str, "")
        str = DataStructureTests.formatList(g.successors(2))
        XCTAssertEqual(str, "3")
        str = DataStructureTests.formatList(g.successors(3))
        XCTAssertEqual(str, "1")
        str = DataStructureTests.formatList(g.successors(4))
        XCTAssertEqual(str, "0 1")
        str = DataStructureTests.formatList(g.successors(5))
        XCTAssertEqual(str, "0 2")
    }

    func testDescendants() {
        let g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
        g.add_edge(5, 2)
        g.add_edge(5, 0)
        g.add_edge(4, 0)
        g.add_edge(4, 1)
        g.add_edge(2, 3)
        g.add_edge(3, 1)

        var str = DataStructureTests.formatList(g.descendants(0))
        XCTAssertEqual(str, "")
        str = DataStructureTests.formatList(g.descendants(1))
        XCTAssertEqual(str, "")
        str = DataStructureTests.formatList(g.descendants(2))
        XCTAssertEqual(str, "3 1")
        str = DataStructureTests.formatList(g.descendants(3))
        XCTAssertEqual(str, "1")
        str = DataStructureTests.formatList(g.descendants(4))
        XCTAssertEqual(str, "0 1")
        str = DataStructureTests.formatList(g.descendants(5))
        XCTAssertEqual(str, "0 2 3 1")
    }

    func testWeaklyConnetectedComponents() {
        do {
            let g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
            g.add_edge(1, 0)
            g.add_edge(2, 3)
            g.add_edge(3, 4)

            let count = try g.number_weakly_connected_components()
            XCTAssertEqual(count, 2)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testLongestPath() {
        do {
            var g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
            g.add_edge(0, 1)
            g.add_edge(0, 2)
            g.add_edge(1, 3)
            g.add_edge(1, 2)
            g.add_edge(2, 4)
            g.add_edge(2, 5)
            g.add_edge(2, 3)
            g.add_edge(3, 5)
            g.add_edge(3, 4)
            g.add_edge(4, 5)

            var str = DataStructureTests.formatList(try g.dag_longest_path())
            XCTAssertEqual(str, "0 1 2 3 4 5")
            var count = try g.dag_longest_path_length()
            XCTAssertEqual(count, 5)

            g = Graph<EmptyGraphData,EmptyGraphData>(directed: true)
            g.add_edge(5, 2)
            g.add_edge(5, 0)
            g.add_edge(4, 0)
            g.add_edge(4, 1)
            g.add_edge(2, 3)
            g.add_edge(3, 1)

            str = DataStructureTests.formatList(try g.dag_longest_path())
            XCTAssertEqual(str, "5 2 3 1")
            count = try g.dag_longest_path_length()
            XCTAssertEqual(count, 3)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testVector() {
        let a: Vector<Complex> = [Complex(imag:2), Complex(imag:3)]
        let b: Vector<Complex> = [Complex(imag:2), Complex(imag:3)]
        XCTAssertEqual(a.dot(b).description, Complex(-13,0).description)
        let c: Vector<Int> = [5, 4, 1, 0]
        XCTAssertEqual(c.remainder(2).description, [1, 0, 1, 0].description)
    }

    func testMatrix() {
        var a: Matrix = [[1, 0], [0, 1]]
        var b: Matrix = [[4, 1], [2, 2]]
        XCTAssertEqual(a.dot(b).description, [[4, 1], [2, 2]].description)
        a = [[1,2],[3,4]]
        b = [[11,12],[13,14]]
        XCTAssertEqual(a.dot(b).description, [[37, 40], [85, 92]].description)
        a = [[10,0,3], [-2,-4,1], [3,0,2]]
        XCTAssertEqual(try a.det(), -116)
        a = [[2,-2,1], [-1,3,-1], [2,-4,1]]
        let dif = a.norm() - 6.4
        XCTAssertLessThan(dif, 0.004)
        a = [[0, 1, 2],[3, 4, 5],[6, 7, 8]]
        XCTAssertEqual(a.diag().description, [[0, 4, 8]].description)
        a = [[0, 4, 8]]
        XCTAssertEqual(a.diag().description, [[0, 0, 0],[0, 4, 0],[0, 0, 8]].description)
        a = [[10,0,3, 6], [-2,-4,1, 9], [3,0,2, 11], [7,8,9, 24]]
        XCTAssertEqual(try a.slice((0,2),(0,2)).description, [[10, 0],[-2, -4]].description)
        XCTAssertEqual(try a.slice((2,4),(2,4)).description, [[2, 11], [9, 24]].description)
    }

    func testComplexMatrix() {
        let a: Matrix<Complex> = [[Complex(2, 0), Complex(0, 1), Complex(0, 0)],
                                  [Complex(0, 1), Complex(2, 0), Complex(0, 0)],
                                  [Complex(0, 0), Complex(0, 0), Complex(3, 0)]]
        var b = a
        b[1, 0] = Complex(0, -1)
        XCTAssertFalse(a.isHermitian)
        XCTAssertTrue(b.isHermitian)
        XCTAssertThrowsError(try a.eigh())
        let (values, vectors) = try! b.eigh()
        let expectedValues = Vector(value: [1.0, 3.0, 3.0])
        let expectedVectors : Matrix<Complex> = [[Complex(-0.7071, 0), Complex(-0.7071, 0), Complex(0, 0)],
                                                 [Complex(0, -0.7071), Complex(0, 0.7071),  Complex(0, 0)],
                                                 [Complex(0, 0),       Complex(0, 0),       Complex(1, 0)]]
        XCTAssertEqual(values, expectedValues)
        XCTAssertEqual(vectors.rowCount, expectedVectors.rowCount)
        XCTAssertEqual(vectors.colCount, expectedVectors.colCount)
        for row in 0..<vectors.rowCount {
            for col in 0..<vectors.colCount {
                XCTAssertEqual(vectors[row, col].real, expectedVectors[row, col].real, accuracy: 0.00001)
                XCTAssertEqual(vectors[row, col].imag, expectedVectors[row, col].imag, accuracy: 0.00001)
            }
        }
    }

    func testTrace() {
        do {
            var m = try Vector<Int>(stop:8).reshape([2,2,2])
            XCTAssertEqual(m.description, [[[0,1], [2,3]], [[4,5], [6,7]]].description)
            XCTAssertEqual(try m.trace().description, [6, 8].description)
            m = try Vector<Int>(stop:24).reshape([2,2,2,3])
            XCTAssertEqual(m.description, [[[[ 0, 1, 2],[ 3, 4, 5]],
                                            [[ 6, 7, 8],[ 9,10,11]]],
                                           [[[12,13,14],[15,16,17]],
                                            [[18,19,20],[21,22,23]]]].description)
            XCTAssertEqual(try m.trace().description, [[18, 20, 22],[24, 26, 28]].description)

        } catch let error {
            XCTFail("testTrace: \(error)")
        }
    }

    private class func formatList(_ list: [GraphVertex<EmptyGraphData>]) -> String {
        var str = ""
        for vertex in list {
            if !str.isEmpty {
                str += " "
            }
            str += "\(vertex.key)"
        }
        return str
    }
}
