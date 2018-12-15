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

/**
 Test local unitary simulator.
 */
class LocalUnitarySimulatorTests: XCTestCase {

    static let allTests = [
        ("test_unitary_simulator",test_unitary_simulator),
        ("test_two_unitary_simulator",test_two_unitary_simulator)
    ]

    private var seed: Int = 0
    private var qp: QuantumProgram? = nil
    private var qobj: [String:Any] = [:]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        do {
            self.seed = 88
            self.qp = try QuantumProgram()
        } catch {
            XCTFail("LocalUnitarySimulatorTests: \(error)")
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /**
     Test generation of circuit unitary.
     */
    func test_unitary_simulator() {
        do {
            let lines = ExampleUnitaryMatrix.UNITARY_MATRIX.components(separatedBy:"\n")
            var complexMatrix = Matrix<Complex>(repeating: 0, rows: lines.count, cols: lines.count)
            for (i,line) in lines.enumerated() {
                let complexStrArray = line.components(separatedBy:",")
                for (j,complexStr) in complexStrArray.enumerated() {
                    complexMatrix[i,j] = try Complex(complexStr)
                }
            }
            try self.qp!.load_qasm_text(Example.QASM, name: "example")
            let basis_gates: [String] = []  // unroll to base gates
            let unroller = Unroller(try Qasm(data: try self.qp!.get_qasm("example")).parse(),JsonBackend(basis_gates))
            guard var circuit = try unroller.execute() as? [String: Any] else {
                XCTFail("LocalUnitarySimulatorTests missing unrolled circuit.")
                return
            }
            // strip measurements from circuit to avoid warnings
            var stripped: [[String:Any]] = []
            if let operations = circuit["operations"] as? [[String:Any]] {
                for op in operations {
                    if let name = op["name"] as? String {
                        if name == "measure" {
                            continue
                        }
                    }
                    stripped.append(op)
                }
            }
            circuit["operations"] = stripped

            let qobj: [String: Any] =
            [           "id": "unitary",
                         "config": [
                            "max_credits": NSNull(),
                            "shots": 1,
                            "backend": "local_unitary_simulator",
                         ],
                         "circuits": [
                            [
                                "name": "test",
                                "compiled_circuit": circuit,
                                "compiled_circuit_qasm": try self.qp!.get_qasm("example"),
                                "config": [
                                    "coupling_map": NSNull(),
                                    "basis_gate": NSNull(),
                                    "layout": NSNull(),
                                    "seed": NSNull(),
                                ]
                            ]
                ]
            ]

            let q_job = QuantumJob(qobj)
            let asyncExpectation = self.expectation(description: "test_unitary_simulator")
            UnitarySimulator().run(q_job) { (result) in
                XCTAssertEqual(result.get_status(), "COMPLETED")
                do {
                    guard let unitary = try result.get_data("test")["unitary"] as? Matrix<Complex> else {
                        XCTFail("LocalUnitarySimulatorTests missing unitary result.")
                        return
                    }
                    XCTAssertEqual(unitary.shape.0,complexMatrix.shape.0)
                    XCTAssertEqual(unitary.shape.1,complexMatrix.shape.1)
                    let cmp = 1e-3
                    var fail = false
                    for row in 0..<unitary.rowCount {
                        for col in 0..<unitary.colCount {
                            if !unitary[row,col].almostEqual(complexMatrix[row,col],cmp) {
                                XCTFail("test_unitary_simulator: (\(row),\(col)): \(unitary[row,col]) \(unitary[row,col])")
                                fail = true
                                break
                            }
                        }
                        if fail {
                            break
                        }
                    }
                } catch {
                    XCTFail("LocalUnitarySimulatorTests: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_unitary_simulator")
            })
        } catch {
            XCTFail("LocalUnitarySimulatorTests: \(error)")
        }
    }

    /**
     test running two circuits
     */
    func test_two_unitary_simulator() {
        do {
            let qr = try QuantumRegister("q", 2)
            let cr = try ClassicalRegister("c", 1)
            let qc1 = try QuantumCircuit([qr, cr])
            let qc2 = try QuantumCircuit([qr, cr])
            try qc1.h(qr)
            try qc2.cx(qr[0], qr[1])

            let basis_gates: [String] = [] // unroll to base gates
            var unroller = Unroller(try Qasm(data: qc1.qasm()).parse(),JsonBackend(basis_gates))
            let c1 = try unroller.execute()
            unroller = Unroller(try Qasm(data: qc2.qasm()).parse(),JsonBackend(basis_gates))
            let c2 = try unroller.execute()
            let qobj: [String:Any] = ["id": "unitary",
                                      "config": [
                                        "max_credits": NSNull(),
                                        "shots": 1,
                                        "backend": "local_unitary_simulator",
                                      ],
                                      "circuits": [
                                        [
                                            "name": "unitary",
                                            "compiled_circuit": c1,
                                            "compiled_circuit_qasm": NSNull(),
                                            "config": [
                                                "coupling_map": NSNull(),
                                                "basis_gate": NSNull(),
                                                "layout": NSNull(),
                                                "seed": NSNull(),
                                            ]
                                        ],
                                        [
                                            "name": "unitary",
                                            "compiled_circuit": c2,
                                            "compiled_circuit_qasm": NSNull(),
                                            "config": [
                                                "coupling_map": NSNull(),
                                                "basis_gate": NSNull(),
                                                "layout": NSNull(),
                                                "seed": NSNull(),
                                            ]
                                        ]
                ]
            ]
            let q_job = QuantumJob(qobj)

            let asyncExpectation = self.expectation(description: "test_two_unitary_simulator")
            JobProcessor().run_backend(q_job) { (result) in
                XCTAssertEqual(result.get_status(), "COMPLETED")
                guard let data1 = result[0]!["data"] as? [String:Any] else {
                    XCTFail("LocalUnitarySimulatorTests missing unitary result.")
                    return
                }
                guard let unitary1 = data1["unitary"] as? Matrix<Complex> else {
                    XCTFail("LocalUnitarySimulatorTests missing unitary result.")
                    return
                }
                guard let data2 = result[1]!["data"] as? [String:Any] else {
                    XCTFail("LocalUnitarySimulatorTests missing unitary result.")
                    return
                }
                guard let unitary2 = data2["unitary"] as? Matrix<Complex> else {
                    XCTFail("LocalUnitarySimulatorTests missing unitary result.")
                    return
                }
                let unitaryreal1: Matrix<Complex> = [[0.5, 0.5, 0.5, 0.5],
                                                     [0.5, -0.5, 0.5, -0.5],
                                                     [0.5, 0.5, -0.5, -0.5],
                                                     [0.5, -0.5, -0.5, 0.5]]
                let unitaryreal2: Matrix<Complex> = [[1,  0,  0, 0],
                                                     [0,  0,  0, 1],
                                                     [0,  0,  1, 0],
                                                     [0,  1,  0, 0]]
                let norm1 = unitaryreal1.conjugate().transpose().dot(unitary1).trace()
                let norm2 = unitaryreal2.conjugate().transpose().dot(unitary2).trace()
                XCTAssert(norm1.almostEqual(4.0))
                XCTAssert(norm2.almostEqual(4.0))
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_two_unitary_simulator")
            })
        } catch {
            XCTFail("LocalUnitarySimulatorTests: \(error)")
        }
    }
}
