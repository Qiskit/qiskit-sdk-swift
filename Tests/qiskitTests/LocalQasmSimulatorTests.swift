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
 Test local qasm simulator.
 */
class LocalQasmSimulatorTests: XCTestCase {

    static let allTests = [
        ("test_qasm_simulator_single_shot",test_qasm_simulator_single_shot),
        ("test_qasm_simulator",test_qasm_simulator),
        ("test_if_statement",test_if_statement),
        ("test_teleport",test_teleport)
    ]

    private var seed: Int = 0
    private var qp: QuantumProgram? = nil
    private var qobj: [String:Any] = [:]

    private static let resources: [String:Any] = ["max_credits": 3,
                                                  "wait": 5,
                                                  "timeout": 120]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        do {
            self.seed = 88
            self.qp = try QuantumProgram()
            try self.qp!.load_qasm_text(Example.QASM, name: "example")
            let basis_gates: [String] = []  // unroll to base gates
            let unroller = Unroller(try Qasm(data: try self.qp!.get_qasm("example")).parse(),JsonBackend(basis_gates))
            let circuit = try unroller.execute()
            let circuit_config: [String:Any] = ["coupling_map": NSNull(),
                                                "basis_gates": "u1,u2,u3,cx,id",
                                                "layout": NSNull(),
                                                "seed": self.seed]
            self.qobj = ["id": "test_sim_single_shot",
                "config": [
                    "max_credits": LocalQasmSimulatorTests.resources["max_credits"],
                    "shots": 1024,
                    "backend": "local_qasm_simulator",
                ],
                "circuits": [
                    [
                    "name": "test",
                    "compiled_circuit": circuit,
                    "compiled_circuit_qasm": NSNull(),
                    "config": circuit_config
                    ]
                ]
            ]
        } catch {
            XCTFail("LocalQasmSimulatorTest: \(error)")
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /**
     Test single shot run.
     */
    func test_qasm_simulator_single_shot() {
        let shots = 1
        var config: [String:Any] = ["shots":shots]
        if let c = self.qobj["config"] as? [String:Any] {
            config = c
            config["shots"] = shots
        }
        self.qobj["config"] = config
        let q_job = QuantumJob(self.qobj,
                                seed: self.seed,
                                resources: LocalQasmSimulatorTests.resources)
        let asyncExpectation = self.expectation(description: "test_qasm_simulator_single_shot")
        QasmSimulator().run(q_job) { (result) in
            XCTAssertEqual(result.get_status(), "COMPLETED")
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 180, handler: { (error) in
            XCTAssertNil(error, "Failure in test_qasm_simulator_single_shot")
        })
    }

    /**
     Test data counts output for single circuit run against reference.
     */
    func test_qasm_simulator() {
        let expected = ["100 100": 137, "011 011": 131, "101 101": 117, "111 111": 127, "000 000": 131, "010 010": 141, "110 110": 116, "001 001": 124]
        let q_job = QuantumJob(self.qobj,
                               seed: self.seed,
                               resources: LocalQasmSimulatorTests.resources)
        let asyncExpectation = self.expectation(description: "test_qasm_simulator")
        QasmSimulator().run(q_job) { (result) in
            do {
                let counts = try result.get_counts("test")
                XCTAssertEqual(counts, expected)
            } catch {
                XCTFail("\(error)")
            }
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 180, handler: { (error) in
            XCTAssertNil(error, "Failure in test_qasm_simulator")
        })
    }

    func test_if_statement() {
        do {
            SDKLogger.logInfo("test_if_statement_x")
            let shots = 100
            let max_qubits = 3
            let qp = try QuantumProgram()
            let qr = try qp.create_quantum_register("qr", max_qubits)
            let cr = try qp.create_classical_register("cr", max_qubits)
            let circuit_if_true = try qp.create_circuit("test_if_true", [qr], [cr])
            try circuit_if_true.x(qr[0])
            try circuit_if_true.x(qr[1])
            try circuit_if_true.measure(qr[0], cr[0])
            try circuit_if_true.measure(qr[1], cr[1])
            try circuit_if_true.x(qr[2]).c_if(cr, 0x3)
            try circuit_if_true.measure(qr[0], cr[0])
            try circuit_if_true.measure(qr[1], cr[1])
            try circuit_if_true.measure(qr[2], cr[2])
            let circuit_if_false = try qp.create_circuit("test_if_false", [qr], [cr])
            try circuit_if_false.x(qr[0])
            try circuit_if_false.measure(qr[0], cr[0])
            try circuit_if_false.measure(qr[1], cr[1])
            try circuit_if_false.x(qr[2]).c_if(cr, 0x3)
            try circuit_if_false.measure(qr[0], cr[0])
            try circuit_if_false.measure(qr[1], cr[1])
            try circuit_if_false.measure(qr[2], cr[2])
            let basis_gates: [String] = [] // unroll to base gates
            var unroller = Unroller(try Qasm(data: try qp.get_qasm("test_if_true")).parse(),JsonBackend(basis_gates))
            let ucircuit_true = try unroller.execute()
            unroller = Unroller(try Qasm(data: try qp.get_qasm("test_if_false")).parse(),JsonBackend(basis_gates))
            let ucircuit_false = try unroller.execute()
            let qobj: [String:Any] = ["id": "test_if_qobj",
                        "config": [
                            "max_credits": 3,
                            "shots": shots,
                            "backend": "local_qasm_simulator",
                        ],
                        "circuits": [
                            [
                                "name": "test_if_true",
                                "compiled_circuit": ucircuit_true,
                                "compiled_circuit_qasm": NSNull(),
                                "config": ["coupling_map": NSNull(),
                                            "basis_gates": "u1,u2,u3,cx,id",
                                            "layout": NSNull(),
                                            "seed": NSNull()
                                            ]
                            ],
                            [
                                "name": "test_if_false",
                                "compiled_circuit": ucircuit_false,
                                "compiled_circuit_qasm": NSNull(),
                                "config": ["coupling_map": NSNull(),
                                            "basis_gates": "u1,u2,u3,cx,id",
                                            "layout": NSNull(),
                                            "seed": NSNull()
                                            ]
                            ]
                        ]
            ]
            let q_job = QuantumJob(qobj)
            let asyncExpectation = self.expectation(description: "test_if_statement")
            QasmSimulator().run(q_job) { (result) in
                do {
                    let result_if_true = try result.get_data("test_if_true")
                    SDKLogger.logInfo("result_if_true circuit:")
                    SDKLogger.logInfo(circuit_if_true.qasm())
                    SDKLogger.logInfo("result_if_true= \(SDKLogger.debugString(result_if_true))")

                    let result_if_false = try result.get_data("test_if_false")
                    SDKLogger.logInfo("result_if_false circuit:")
                    SDKLogger.logInfo(circuit_if_false.qasm())
                    SDKLogger.logInfo("result_if_false= \(SDKLogger.debugString(result_if_false))")
                    if let counts = result_if_true["counts"] as? [String:Int] {
                        XCTAssertEqual(counts["111"],100)
                    }
                    else {
                        XCTFail("No counts result_if_true")
                    }
                    if let counts = result_if_false["counts"] as? [String:Int] {
                        XCTAssertEqual(counts["001"],100)
                    }
                    else {
                        XCTFail("No counts result_if_false")
                    }
                } catch {
                    XCTFail("\(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_if_statement")
            })
        } catch {
            XCTFail("\(error)")
        }
    }

    /**
     Test single shot run.
     */
    func test_teleport() {
        do {
            SDKLogger.logInfo("test_teleport")
            let pi = Double.pi
            let shots = 1000
            let qp = try QuantumProgram()
            let qr = try qp.create_quantum_register("qr", 3)
            let cr0 = try qp.create_classical_register("cr0", 1)
            let cr1 = try qp.create_classical_register("cr1", 1)
            let cr2 = try qp.create_classical_register("cr2", 1)
            let circuit = try qp.create_circuit("teleport", [qr], [cr0, cr1, cr2])
            try circuit.h(qr[1])
            try circuit.cx(qr[1], qr[2])
            try circuit.ry(pi/4, qr[0])
            try circuit.cx(qr[0], qr[1])
            try circuit.h(qr[0])
            try circuit.barrier(qr)
            try circuit.measure(qr[0], cr0[0])
            try circuit.measure(qr[1], cr1[0])
            try circuit.z(qr[2]).c_if(cr0, 1)
            try circuit.x(qr[2]).c_if(cr1, 1)
            try circuit.measure(qr[2], cr2[0])
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_teleport")
            qp.compile(["teleport"], backend: backend, shots: shots, seed: self.seed) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_teleport: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                qp.run_async(qobj) { (results) in
                    do {
                        let data = try results.get_counts("teleport")
                        var alice: [String:Int] = [:]
                        var bob: [String:Int] = [:]
                        alice["00"] = data["0 0 0"]! + data["1 0 0"]!
                        alice["01"] = data["0 1 0"]! + data["1 1 0"]!
                        alice["10"] = data["0 0 1"]! + data["1 0 1"]!
                        alice["11"] = data["0 1 1"]! + data["1 1 1"]!
                        bob["0"] = data["0 0 0"]! + data["0 1 0"]! +  data["0 0 1"]! + data["0 1 1"]!
                        bob["1"] = data["1 0 0"]! + data["1 1 0"]! +  data["1 0 1"]! + data["1 1 1"]!
                        SDKLogger.logInfo("test_telport: circuit:")
                        SDKLogger.logInfo(circuit.qasm())
                        SDKLogger.logInfo("test_teleport: data \(SDKLogger.debugString(data))")
                        SDKLogger.logInfo("test_teleport: alice \(SDKLogger.debugString(alice))")
                        SDKLogger.logInfo("test_teleport: bob \(SDKLogger.debugString(bob))")
                        let alice_ratio: Double = 1.0 / pow(tan(pi/8.0),2.0)
                        let bob_ratio: Double = Double(bob["0"]!) / Double(bob["1"]!)
                        let error: Double = abs(alice_ratio - bob_ratio) / alice_ratio
                        SDKLogger.logInfo("test_teleport: relative error = \(error)")
                        XCTAssertLessThan(error, 0.05)
                    } catch {
                        XCTFail("\(error)")
                    }
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_teleport")
            })
        } catch {
            XCTFail("\(error)")
        }
    }
}
