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
 GHZ state example illustrating mapping onto the device
 */
public final class GHZ {

    private static let QPS_SPECS: [String: Any] = [
        "name": "ghz",
        "circuits": [[
            "name": "ghz",
            "quantum_registers": [
                ["name": "q", "size": 5]
            ],
            "classical_registers": [
                ["name": "c", "size": 5]
            ]]]
    ]

    //#############################################################
    // Set the device name and coupling map.
    //#############################################################
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
    private class func executeRemote(quantumProgram: QuantumProgram,
                                     circuit: String,
                                     _ responseHandler: (() -> Void)?) -> RequestTask {
        var reqTask = RequestTask()

        var backend = CommandLineOption.Backend.ibmqxQasmSimulator
        print("First version: not compiled")
        print("no mapping, simulator")
        let r = quantumProgram.execute([circuit], backend: backend.rawValue, coupling_map: nil,shots: 1024) { (result) in
            do {
                if let error = result.get_error() {
                    print(error)
                    responseHandler?()

                    return
                }

                print(result)
                print(try result.get_counts(circuit))

                print("Second version: map to qx2 coupling graph and simulate")
                print("map to \(backend), simulator")
                let r = quantumProgram.execute([circuit], backend: backend.rawValue, coupling_map: coupling_map, shots: 1024) { (result) in
                    do {
                        if let error = result.get_error() {
                            print(error)
                            responseHandler?()

                            return
                        }

                        print(result)
                        print(try result.get_counts(circuit))

                        backend = CommandLineOption.Backend.localQasmSimulator
                        print("Third version: map to qx2 coupling graph and simulate locally")
                        print("map to \(backend), local qasm simulator")
                        let r = quantumProgram.execute([circuit], backend: backend.rawValue, coupling_map: coupling_map, shots: 1024) { (result) in
                            do {
                                if let error = result.get_error() {
                                    print(error)
                                    responseHandler?()

                                    return
                                }

                                print(result)
                                print(try result.get_counts(circuit))

                                backend = CommandLineOption.Backend.ibmqx2
                                print("Fourth version: map to qx2 coupling graph and run on qx2")
                                print("map to \(backend), backend")
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
                                    let r = quantumProgram.execute([circuit], backend: backend.rawValue, timeout: 120, coupling_map: coupling_map, shots: 1024) { (result) in
                                        do {
                                            if let error = result.get_error() {
                                                print(error)
                                                responseHandler?()

                                                return
                                            }

                                            print(result)
                                            print(try result.get_counts(circuit))
                                            print("ghz end")
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
                    } catch {
                        print(error.localizedDescription)
                        responseHandler?()
                    }
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
                                    circuit: String,
                                    _ responseHandler: (() -> Void)?) -> RequestTask {
        var reqTask = RequestTask()

        let backend = CommandLineOption.Backend.localQasmSimulator
        print("map to qx2 coupling graph and simulate locally")
        print("map to \(backend), local qasm simulator")
        let r = quantumProgram.execute([circuit], backend: backend.rawValue, coupling_map: coupling_map, shots: 1024) { (result) in
            do {
                if let error = result.get_error() {
                    print(error)
                    responseHandler?()

                    return
                }

                print(result)
                print(try result.get_counts(circuit))
            } catch {
                print(error.localizedDescription)
            }

            responseHandler?()
        }
        reqTask += r

        return reqTask
    }

    @discardableResult
    public class func ghz(_ option: CommandLineOption, _ responseHandler: (() -> Void)? = nil) -> RequestTask {
        do {
            print()
            print("#################################################################")
            print("GHZ:")
            let qp = try QuantumProgram(specs: QPS_SPECS)
            let qc = try qp.get_circuit("ghz")
            let q = try qp.get_quantum_register("q")
            let c = try qp.get_classical_register("c")

            // Create a GHZ state
            try qc.h(q[0])
            for i in 0..<4 {
                try qc.cx(q[i], q[i+1])
            }
            // Insert a barrier before measurement
            try qc.barrier()
            // Measure all of the qubits in the standard basis
            for i in 0..<5 {
                try qc.measure(q[i], c[i])
            }

            if let token = option.apiToken {
                //##############################################################
                // Set up the API and execute the program.
                //##############################################################
                qp.set_api(token: token)

                return executeRemote(quantumProgram: qp, circuit: "ghz", responseHandler)
            }

            return executeLocal(quantumProgram: qp, circuit: "ghz", responseHandler)
        } catch {
            print(error.localizedDescription)

            responseHandler?()
        }

        return RequestTask()
    }
}
