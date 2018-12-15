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
 Tests for quantum optimization.
 */
class QuantumOptimizationTests: XCTestCase {

    static let allTests = [
        ("test_trial_functions",test_trial_functions)
    ]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_trial_functions() {
        do {
            let entangler_map: [Int: [Int]] = [0: [2], 1: [2], 3: [2], 4: [2]]

            let m = 1
            let n = 6
            let theta = [Double](repeating:0.0, count: m * n)

            var trial_circuit = try Optimization.trial_circuit_ry(n, m, theta, entangler_map)

            SDKLogger.logInfo(trial_circuit.qasm())

            SDKLogger.logInfo("With No measurement:\n")
            trial_circuit = try Optimization.trial_circuit_ry(n, m, theta, entangler_map)

            SDKLogger.logInfo(trial_circuit.qasm())

            SDKLogger.logInfo("With Y measurement:\n")
            let meas_sting = String(repeatElement("Y", count: n))

            trial_circuit = try Optimization.trial_circuit_ry(n, m, theta, entangler_map, meas_sting)

            SDKLogger.logInfo(trial_circuit.qasm())
        } catch {
            XCTFail("test_trial_functions: \(error)")
        }
    }
}

class HamiltonianTests: XCTestCase {

    static let allTests = [
        ("test_hamiltonian",test_hamiltonian)
    ]

    static private let H2Equilibrium: String =
"""
ZZ
0.011279956224107712
II
-1.0523760606256514
ZI
0.39793570529466216
IZ
0.39793570529466227
XX
0.18093133934472627
"""

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func _get_resource_path(_ filename: String) -> String {
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        return path.path
    }

    func test_hamiltonian() {
        do {
            // printing an example from a H2 file
            let hfile = self._get_resource_path("H2Equilibrium.txt")
            try HamiltonianTests.H2Equilibrium.write(toFile: hfile, atomically: true, encoding: .utf8)
            SDKLogger.logInfo(try Optimization.make_Hamiltonian(Optimization.Hamiltonian_from_file(hfile)))
            if FileManager.default.fileExists(atPath: hfile) {
                try FileManager.default.removeItem(atPath: hfile)
            }

            // printing an example from a graph input
            let n = 3
            var v0 = [Int](repeating:0, count:n)
            v0[2] = 1
            var v1 = [Int](repeating:0, count:n)
            v1[0] = 1
            v1[1] = 1
            var v2 = [Int](repeating:0, count:n)
            v2[0] = 1
            v2[2] = 1
            var v3 = [Int](repeating:0, count:n)
            v3[1] = 1
            v3[2] = 1

            let pauli_list: [(Double,Pauli)] = [
              (1.0, Pauli(v0, [Int](repeating:0, count:n))),
              (1.0, Pauli(v1, [Int](repeating:0, count:n))),
              (1.0, Pauli(v2, [Int](repeating:0, count:n))),
              (1.0, Pauli(v3, [Int](repeating:0, count:n)))
            ]
            let a = try Optimization.make_Hamiltonian(pauli_list)
            SDKLogger.logInfo(a)

            //let (w, v) = la.eigh(a, eigvals=(0, 0))
            //SDKLogger.logInfo(w)
            //SDKLogger.logInfo(v)

            var data: [String: Int] = ["000": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["001": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["010": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["011": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["100": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["101": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["110": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
            data = ["111": 10]
            SDKLogger.logInfo(Optimization.Energy_Estimate(data, pauli_list))
        } catch {
            XCTFail("test_hamiltonian: \(error)")
        }
    }
}
