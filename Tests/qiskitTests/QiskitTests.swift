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

class QiskitTests: XCTestCase {

    static let allTests = [
        ("test5Qubit",test5Qubit),
        ("testMakeBell1",testMakeBell1),
        ("testRippleCarryAdder",testRippleCarryAdder),
        ("testQFTAndMeasure2",testQFTAndMeasure2),
        ("test4Developers",test4Developers)
    ]

    // enter your token in your test schema environment variable "QUANTUM_TOKEN"
    static private var APItoken = ""
    static private let TESTURL = "https://quantumexperience.ng.bluemix.net/api/"

    override class func setUp() {
        let environment = ProcessInfo.processInfo.environment
        if let token = environment["QUANTUM_TOKEN"] {
            QiskitTests.APItoken = token
        }
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test5Qubit() {
        do {
            let str: String =
                "OPENQASM 2.0;\n" +
                    "include \"qelib1.inc\";\n" +
                    "qreg q[5];\n" +
                    "creg c[5];\n" +
                    "x q[0];\n" +
                    "x q[1];\n" +
                    "h q[2];\n" +
                    "measure q[0] -> c[0];\n" +
                    "measure q[1] -> c[1];\n" +
                    "measure q[2] -> c[2];\n" +
                    "measure q[3] -> c[3];\n" +
            "measure q[4] -> c[4];\n"
            let q = try QuantumRegister("q", 5)
            let c = try ClassicalRegister("c", 5)
            let circuit = try QuantumCircuit([q,c])
            try circuit.x(q[0])
            try circuit.x(q[1])
            try circuit.h(q[2])
            try circuit.measure(q[0], c[0])
            try circuit.measure(q[1], c[1])
            try circuit.measure(q[2], c[2])
            try circuit.measure(q[3], c[3])
            try circuit.measure(q[4], c[4])

            XCTAssertEqual(str, circuit.qasm())
            //try self.runJob(circuit,"simulator")
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testMakeBell1() {
        do {
            let str: String =
                "OPENQASM 2.0;\n" +
                    "include \"qelib1.inc\";\n" +
                    "qreg q[3];\n" +
                    "creg c[2];\n" +
                    "h q[0];\n" +
                    "cx q[0],q[2];\n" +
                    "measure q[0] -> c[0];\n" +
            "measure q[2] -> c[1];\n"

            let q = try QuantumRegister("q", 3)
            let c = try ClassicalRegister("c", 2)
            let circuit = try QuantumCircuit([q,c])
            try circuit.h(q[0])
            try circuit.cx(q[0], q[2])
            try circuit.measure(q[0], c[0])
            try circuit.measure(q[2], c[1])

            XCTAssertEqual(str, circuit.qasm())
        } catch let error {
            XCTFail("\(error)")
        }
    }

    /**
     Majority gate.
     */
    private class func majority(_ p: QuantumCircuit, _ a: QuantumRegisterTuple, _ b:QuantumRegisterTuple, _ c:QuantumRegisterTuple) throws {
        try p.cx(c, b)
        try p.cx(c, a)
        try p.ccx(a, b, c)
    }

    /**
     Majority gate.
     */
    private class func unmajority(_ p: QuantumCircuit, _ a: QuantumRegisterTuple, _ b:QuantumRegisterTuple, _ c:QuantumRegisterTuple) throws {
        try p.ccx(a, b, c)
        try p.cx(c, a)
        try p.cx(a, b)
    }

    func testRippleCarryAdder() {
        do {
            let str: String =
                "OPENQASM 2.0;\n" +
                    "include \"qelib1.inc\";\n" +
                    "qreg cin[1];\n" +
                    "qreg a[4];\n" +
                    "qreg b[4];\n" +
                    "qreg cout[1];\n" +
                    "creg ans[5];\n" +
                    "x a[0];\n" +
                    "x b[0];\n" +
                    "x b[1];\n" +
                    "x b[2];\n" +
                    "x b[3];\n" +
                    "cx a[0],b[0];\n" +
                    "cx a[0],cin[0];\n" +
                    "ccx cin[0],b[0],a[0];\n" +
                    "cx a[1],b[1];\n" +
                    "cx a[1],a[0];\n" +
                    "ccx a[0],b[1],a[1];\n" +
                    "cx a[2],b[2];\n" +
                    "cx a[2],a[1];\n" +
                    "ccx a[1],b[2],a[2];\n" +
                    "cx a[3],b[3];\n" +
                    "cx a[3],a[2];\n" +
                    "ccx a[2],b[3],a[3];\n" +
                    "cx a[3],cout[0];\n" +
                    "ccx a[2],b[3],a[3];\n" +
                    "cx a[3],a[2];\n" +
                    "cx a[2],b[3];\n" +
                    "ccx a[1],b[2],a[2];\n" +
                    "cx a[2],a[1];\n" +
                    "cx a[1],b[2];\n" +
                    "ccx a[0],b[1],a[1];\n" +
                    "cx a[1],a[0];\n" +
                    "cx a[0],b[1];\n" +
                    "ccx cin[0],b[0],a[0];\n" +
                    "cx a[0],cin[0];\n" +
                    "cx cin[0],b[0];\n" +
                    "measure b[0] -> ans[0];\n" +
                    "measure b[1] -> ans[1];\n" +
                    "measure b[2] -> ans[2];\n" +
                    "measure b[3] -> ans[3];\n" +
                    "measure cout[0] -> ans[4];\n"

            let cin = try QuantumRegister("cin", 1)
            let a = try QuantumRegister("a", 4)
            let b = try QuantumRegister("b", 4)
            let cout = try QuantumRegister("cout", 1)
            let ans = try ClassicalRegister("ans", 5)
            let circuit = try QuantumCircuit([cin,a,b,cout,ans])
            try circuit.x(a[0])
            try circuit.x(b)
            try QiskitTests.majority(circuit, cin[0], b[0], a[0])
            for j in 0..<3 {
                try QiskitTests.majority(circuit, a[j], b[j + 1], a[j + 1])
            }
            try circuit.cx(a[3], cout[0])
            for j in (0..<3).reversed() {
                try QiskitTests.unmajority(circuit, a[j], b[j + 1], a[j + 1])
            }
            try QiskitTests.unmajority(circuit, cin[0], b[0], a[0])
            for j in 0..<4 {
                try circuit.measure(b[j], ans[j])  // Measure the output register
            }
            try circuit.measure(cout[0], ans[4])

            XCTAssertEqual(str, circuit.qasm())
            //try self.runJob(circuit,"simulator")
         } catch let error {
            XCTFail("\(error)")
         }
    }

    func testQFTAndMeasure2() {
        do {
            let piDiv2: Double = Double.pi / 2.0
            let piDiv2S = piDiv2.format(15)
            let piDiv4: Double = Double.pi / 4.0
            let piDiv4S = piDiv4.format(15)
            let piDiv8: Double = Double.pi / 8.0
            let piDiv8S = piDiv8.format(15)
            let str: String =
                "OPENQASM 2.0;\n" +
                    "include \"qelib1.inc\";\n" +
                    "qreg q[4];\n" +
                    "creg c0[1];\n" +
                    "creg c1[1];\n" +
                    "creg c2[1];\n" +
                    "creg c3[1];\n" +
                    "h q[0];\n" +
                    "h q[1];\n" +
                    "h q[2];\n" +
                    "h q[3];\n" +
                    "barrier q[0],q[1],q[2],q[3];\n" +
                    "h q[0];\n" +
                    "measure q[0] -> c0[0];\n" +
                    "if(c0==1) u1(\(piDiv2S)) q[1];\n" +
                    "h q[1];\n" +
                    "measure q[1] -> c1[0];\n" +
                    "if(c0==1) u1(\(piDiv4S)) q[2];\n" +
                    "if(c1==1) u1(\(piDiv2S)) q[2];\n" +
                    "h q[2];\n" +
                    "measure q[2] -> c2[0];\n" +
                    "if(c0==1) u1(\(piDiv8S)) q[3];\n" +
                    "if(c1==1) u1(\(piDiv4S)) q[3];\n" +
                    "if(c2==1) u1(\(piDiv2S)) q[3];\n" +
                    "h q[3];\n" +
                    "measure q[3] -> c3[0];\n"

            let q = try QuantumRegister("q", 4)
            let c0 = try ClassicalRegister("c0", 1)
            let c1 = try ClassicalRegister("c1", 1)
            let c2 = try ClassicalRegister("c2", 1)
            let c3 = try ClassicalRegister("c3", 1)
            let circuit = try QuantumCircuit([q,c0,c1,c2,c3])
            try circuit.h(q)
            try circuit.barrier([q])
            try circuit.h(q[0])
            try circuit.measure(q[0], c0[0])
            try circuit.u1(piDiv2, q[1]).c_if(c0, 1)
            try circuit.h(q[1])
            try circuit.measure(q[1], c1[0])
            try circuit.u1(piDiv4, q[2]).c_if(c0, 1)
            try circuit.u1(piDiv2, q[2]).c_if(c1, 1)
            try circuit.h(q[2])
            try circuit.measure(q[2], c2[0])
            try circuit.u1(piDiv8, q[3]).c_if(c0, 1)
            try circuit.u1(piDiv4, q[3]).c_if(c1, 1)
            try circuit.u1(piDiv2, q[3]).c_if(c2, 1)
            try circuit.h(q[3])
            try circuit.measure(q[3], c3[0])

            XCTAssertEqual(str, circuit.qasm())
            //try self.runJob(circuit,"simulator")
         } catch let error {
            XCTFail("\(error)")
         }
    }

    func test4Developers() {
        do {
            let str: String =
            "OPENQASM 2.0;\n" +
            "include \"qelib1.inc\";\n" +
            "qreg qr[4];\n" +
            "creg cr[4];\n" +
            "h qr[0];\n" +
            "x qr[1];\n" +
            "y qr[2];\n" +
            "z qr[3];\n" +
            "cx qr[0],qr[2];\n" +
            "barrier qr[0],qr[1],qr[2],qr[3];\n" +
            "u1(0.300000000000000) qr[0];\n" +
            "u2(0.300000000000000,0.200000000000000) qr[1];\n" +
            "u3(0.300000000000000,0.200000000000000,0.100000000000000) qr[2];\n" +
            "s qr[0];\n" +
            "t qr[1];\n" +
            "id qr[1];\n" +
            "measure qr[0] -> cr[0];\n"

            let Q_program = try QuantumProgram()
            let qr = try Q_program.create_quantum_register("qr", 4)
            let cr = try Q_program.create_classical_register("cr", 4)
            try Q_program.create_circuit("Circuit", [qr], [cr])
            let circuit = try Q_program.get_circuit("Circuit")
            let quantum_r = try Q_program.get_quantum_register("qr")
            let classical_r = try Q_program.get_classical_register("cr")

            // H (Hadamard) gate to the qubit 0 in the Quantum Register "qr"
            try circuit.h(quantum_r[0])

            // Pauli X gate to the qubit 1 in the Quantum Register "qr"
            try circuit.x(quantum_r[1])

            // Pauli Y gate to the qubit 2 in the Quantum Register "qr"
            try circuit.y(quantum_r[2])

            // Pauli Z gate to the qubit 3 in the Quantum Register "qr"
            try circuit.z(quantum_r[3])

            // CNOT (Controlled-NOT) gate from qubit 0 to the Qbit 2
            try circuit.cx(quantum_r[0], quantum_r[2])

            // add a barrier to your circuit
            try circuit.barrier()

            // first physical gate: u1(lambda) to qubit 0
            try circuit.u1(0.3, quantum_r[0])

            // second physical gate: u2(phi,lambda) to qubit 1
            try circuit.u2(0.3, 0.2, quantum_r[1])

            // second physical gate: u3(theta,phi,lambda) to qubit 2
            try circuit.u3(0.3, 0.2, 0.1, quantum_r[2])

            // S Phase gate to qubit 0
            try circuit.s(quantum_r[0])

            // T Phase gate to qubit 1
            try circuit.t(quantum_r[1])

            // identity gate to qubit 1
            try circuit.iden(quantum_r[1])

            // Note: "if" is not implemented in the local simulator right now,
            //       so we comment it out here. You can uncomment it and
            //       run in the online simulator if you'd like.

            // Classical if, from qubit2 gate Z to classical bit 1
            // circuit.z(quantum_r[2]).c_if(classical_r, 0)

            // measure gate from the qubit 0 to classical bit 0
            try circuit.measure(quantum_r[0], classical_r[0])

            let QASM_source = try Q_program.get_qasm("Circuit")

            XCTAssertEqual(str, QASM_source)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    private func runJob(_ circuit: QuantumCircuit, _ device: String) throws {
        let qp = try QuantumProgram()
        try qp.add_circuit("circuit",circuit)
        qp.set_api(token: QiskitTests.APItoken)

        let asyncExpectation = self.expectation(description: "runJob")
        qp.execute(["circuit"], backend: device) { (result) in
            if let error = result.get_error() {
                XCTFail("Failure in runJob: \(error)")
                asyncExpectation.fulfill()
                return
            }
            do {
                SDKLogger.logInfo(try result.get_ran_qasm("circuit"))
                SDKLogger.logInfo(try result.get_counts("circuit"))
                asyncExpectation.fulfill()
            } catch let error {
                XCTFail("Failure in runJob: \(error)")
                asyncExpectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 180, handler: { (error) in
            XCTAssertNil(error, "Failure in runJob")
        })
    }
}
