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
import qiskit

/**
 Quantum Fourier Transform examples.
 */
public final class QFT {

    private static let QPS_SPECS: [String: Any] = [
        "name": "ghz",
        "circuits": [
            ["name": "qft3",
            "quantum_registers": [
                ["name": "q","size": 5]
                ],
            "classical_registers": [
                ["name": "c","size": 5]
                ]],
             ["name": "qft4",
                "quantum_registers": [
                    ["name": "q","size": 5
                ]],
                "classical_registers": [
                    ["name": "c","size": 5]
                ]],
             ["name": "qft5",
                "quantum_registers": [
                    ["name": "q","size": 5]
                ],
                "classical_registers": [
                    ["name": "c","size": 5]
                ]]
        ]
    ]

    //##############################################################
    // Set the device name and coupling map.
    //##############################################################
    private static let coupling_map = [0: [1, 2],
        1: [2],
        2: [],
        3: [2, 4],
        4: [2]]

    private init() {
    }

    //##############################################################
    // Make a quantum program for the GHZ state.
    //##############################################################

    private static func qftpow(_ x: Int, _ y: Int) -> Decimal {
        #if os(Linux)
            return Decimal(pow(Double(x),Double(y)))
        #else
            return pow(Decimal(x),y)
        #endif
    }

    /**
     n-qubit input state for QFT that produces output 1.
     */
    private class func input_state(_ circ: QuantumCircuit, _ q: QuantumRegister, _ n: Int) throws {
        for j in 0..<n {
            try circ.h(q[j])
            try circ.u1(Double.pi/NSDecimalNumber(decimal:QFT.qftpow(2,j)).doubleValue, q[j]).inverse()
        }
    }
    /**
     n-qubit QFT on q in circ
     */
    private class func qft(_ circ: QuantumCircuit, _ q: QuantumRegister, _ n: Int) throws {
        for j in 0..<n {
            for k in 0..<j {
                try circ.cu1(Double.pi/NSDecimalNumber(decimal:QFT.qftpow(2,j-k)).doubleValue, q[j], q[k])
            }
            try circ.h(q[j])
        }
    }

    private class func executeRemote(quantumProgram: QuantumProgram,
                                     circuits: [String],
                                     threeQBitCircuit: String,
                                     _ responseHandler: (() -> Void)?) -> RequestTask {
        var reqTask = RequestTask()
        
        var backend = CommandLineOption.Backend.ibmqxQasmSimulator
        let r = quantumProgram.execute(circuits, backend: backend.rawValue, coupling_map: coupling_map, shots: 1024) { (result) in
            do {
                if let error = result.get_error() {
                    print(error)
                    responseHandler?()

                    return
                }

                print(result)
                for name in circuits {
                    print(try result.get_ran_qasm(name))
                }
                for name in circuits {
                    print(try result.get_counts(name))
                }

                backend = CommandLineOption.Backend.ibmqx2
                let r = quantumProgram.get_backend_status(backend.rawValue) { (status, e) in
                    if let error = e {
                        print(error)
                        responseHandler?()

                        return
                    }

                    print("Status \(backend): \(status)")
                    guard let available = status["available"] as? Bool else {
                        print("backend \(backend) not available")
                        responseHandler?()

                        return
                    }

                    if !available {
                        print("backend \(backend) not available")
                        responseHandler?()

                        return
                    }

                    let r = quantumProgram.execute([threeQBitCircuit], backend: backend.rawValue, timeout: 120, coupling_map: coupling_map, shots: 1024) { (result) in
                        do {
                            if let error = result.get_error() {
                                print(error)
                                responseHandler?()

                                return
                            }

                            print(result)
                            print(try result.get_ran_qasm(threeQBitCircuit))
                            print(try result.get_counts(threeQBitCircuit))
                        } catch {
                            print(error.localizedDescription)
                        }

                        responseHandler?()
                    }
                    reqTask += r
                }
                reqTask += r
            } catch {
                print(error.localizedDescription)
                responseHandler?()
            }
        }
        reqTask += r

        return reqTask
    }

    private class func executeLocal(quantumProgram: QuantumProgram,
                                    circuits: [String],
                                    _ responseHandler: (() -> Void)?) -> RequestTask {
        var reqTask = RequestTask()

        let backend = CommandLineOption.Backend.localQasmSimulator
        let r = quantumProgram.execute(circuits, backend: backend.rawValue, coupling_map: coupling_map, shots: 1024) { (result) in
            do {
                if let error = result.get_error() {
                    print(error)
                    responseHandler?()

                    return
                }

                print(result)
                for name in circuits {
                    print(try result.get_ran_qasm(name))
                }
                for name in circuits {
                    print(try result.get_counts(name))
                }
            } catch {
                print(error.localizedDescription)
            }

            responseHandler?()
        }
        reqTask += r

        return reqTask
    }

    @discardableResult
    public class func qft(_ option: CommandLineOption, _ responseHandler: (() -> Void)? = nil) -> RequestTask {
        do {
            print()
            print("#################################################################")
            print("QFT:")
            let qp = try QuantumProgram(specs: QPS_SPECS)
            let q = try qp.get_quantum_register("q")
            let c = try qp.get_classical_register("c")

            let qft3 = try qp.get_circuit("qft3")
            let qft4 = try qp.get_circuit("qft4")
            let qft5 = try qp.get_circuit("qft5")

            try input_state(qft3, q, 3)
            try qft3.barrier()
            try qft(qft3, q, 3)
            try qft3.barrier()
            for j in 0..<3 {
                try qft3.measure(q[j], c[j])
            }

            try input_state(qft4, q, 4)
            try qft4.barrier()
            try qft(qft4, q, 4)
            try qft4.barrier()
            for j in 0..<4 {
                try qft4.measure(q[j], c[j])
            }

            try input_state(qft5, q, 5)
            try qft5.barrier()
            try qft(qft5, q, 5)
            try qft5.barrier()
            for j in 0..<5 {
                try qft5.measure(q[j], c[j])
            }

            print(qft3.qasm())
            print(qft4.qasm())
            print(qft5.qasm())

            let circuits = ["qft3", "qft4", "qft5"]
            if let token = option.apiToken {
                //##############################################################
                // Set up the API and execute the program.
                //##############################################################
                qp.set_api(token: token)

                return executeRemote(quantumProgram: qp, circuits: circuits, threeQBitCircuit: "qft3", responseHandler)
            }

            return executeLocal(quantumProgram: qp, circuits: circuits, responseHandler)
        } catch {
            print(error.localizedDescription)

            responseHandler?()
        }

        return RequestTask()
    }
}
