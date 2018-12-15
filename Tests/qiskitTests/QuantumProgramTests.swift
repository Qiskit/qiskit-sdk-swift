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
 QISKIT QuatumProgram Object Tests.
 */
class QuantumProgramTests: XCTestCase {

    static let allTests = [
        ("test_create_program_with_specs",test_create_program_with_specs),
        ("test_create_program",test_create_program),
        ("test_create_classical_register",test_create_classical_register),
        ("test_create_quantum_register",test_create_quantum_register),
        ("test_fail_create_quantum_register",test_fail_create_quantum_register),
        ("test_fail_create_classical_register",test_fail_create_classical_register),
        ("test_create_quantum_register_same",test_create_quantum_register_same),
        ("test_create_classical_register_same",test_create_classical_register_same),
        ("test_create_classical_registers",test_create_classical_registers),
        ("test_create_quantum_registers",test_create_quantum_registers),
        ("test_destroy_classical_register",test_destroy_classical_register),
        ("test_destroy_quantum_register",test_destroy_quantum_register),
        ("test_create_circuit",test_create_circuit),
        ("test_create_several_circuits",test_create_several_circuits),
        ("test_destroy_circuit",test_destroy_circuit),
        ("test_load_qasm_file",test_load_qasm_file),
        ("test_fail_load_qasm_file",test_fail_load_qasm_file),
        ("test_load_qasm_text",test_load_qasm_text),
        ("test_get_register_and_circuit",test_get_register_and_circuit),
        ("test_get_register_and_circuit_names",test_get_register_and_circuit_names),
        ("test_get_qasm",test_get_qasm),
        ("test_get_qasms",test_get_qasms),
        ("test_get_qasm_all_gates",test_get_qasm_all_gates),
        ("test_get_initial_circuit",test_get_initial_circuit),
        ("test_save",test_save),
        ("test_save_wrong",test_save_wrong),
        ("test_load",test_load),
        ("test_setup_api",test_setup_api),
        ("test_available_backends_exist",test_available_backends_exist),
        ("test_local_backends_exist",test_local_backends_exist),
        ("test_online_backends_exist",test_online_backends_exist),
        ("test_online_devices",test_online_devices),
        ("test_online_simulators",test_online_simulators),
        ("test_backend_status",test_backend_status),
        ("test_get_backend_configuration",test_get_backend_configuration),
        ("test_get_backend_configuration_fail",test_get_backend_configuration_fail),
        ("test_get_backend_calibration",test_get_backend_calibration),
        ("test_get_backend_parameters",test_get_backend_parameters),
        ("test_compile_program",test_compile_program),
        ("test_get_compiled_configuration",test_get_compiled_configuration),
        ("test_get_compiled_qasm",test_get_compiled_qasm),
        ("test_get_execution_list",test_get_execution_list),
        ("test_compile_coupling_map",test_compile_coupling_map),
        ("test_change_circuit_qobj_after_compile",test_change_circuit_qobj_after_compile),
        ("test_run_program",test_run_program),
        ("test_run_batch",test_run_batch),
        ("test_combine_results",test_combine_results),
        ("test_local_qasm_simulator",test_local_qasm_simulator),
        ("test_local_qasm_simulator_one_shot",test_local_qasm_simulator_one_shot),
        ("test_local_unitary_simulator",test_local_unitary_simulator),
        ("test_run_program_map",test_run_program_map),
        ("test_execute_program_map",test_execute_program_map),
        ("test_average_data",test_average_data),
        ("test_execute_one_circuit_simulator_online",test_execute_one_circuit_simulator_online),
        ("test_simulator_online_size",test_simulator_online_size),
        ("test_execute_several_circuits_simulator_online",test_execute_several_circuits_simulator_online),
        ("test_execute_one_circuit_real_online",test_execute_one_circuit_real_online),
        ("test_local_qasm_simulator_two_registers",test_local_qasm_simulator_two_registers),
        ("test_online_qasm_simulator_two_registers",test_online_qasm_simulator_two_registers),
        ("test_add_circuit",test_add_circuit),
        ("test_add_circuit_fail",test_add_circuit_fail),
        ("test_example_multiple_compile",test_example_multiple_compile),
        ("test_example_swap_bits",test_example_swap_bits),
        ("test_offline",test_offline),
        ("test_results_save_load",test_results_save_load),
        ("test_qubitpol",test_qubitpol),
        ("test_ccx",test_ccx),
        ("test_reconfig",test_reconfig),
        ("test_timeout",test_timeout),
        ("test_hpc_parameter_is_correct",test_hpc_parameter_is_correct),
        ("test_hpc_parameter_is_incorrect",test_hpc_parameter_is_incorrect)
    ]

    private var QE_TOKEN: String? = nil
    private var QE_URL = IBMQuantumExperience.URL_BASE
    private var QPS_SPECS: [String:Any] = [:]
    private var QASM_FILE_PATH: String = ""
    private var QASM_FILE_PATH_2: String = ""

    override func setUp() {
        super.setUp()
        let environment = ProcessInfo.processInfo.environment
        if let token = environment["QE_TOKEN"] {
            self.QE_TOKEN = token
        }
        if let url = environment["QE_URL"] {
            self.QE_URL = url
        }
        self.QPS_SPECS = [
            "circuits": [[
            "name": "circuitName",
            "quantum_registers": [[
            "name": "qname",
            "size": 3]],
            "classical_registers": [[
            "name": "cname",
            "size": 3]]
            ]]
        ]
        self.QASM_FILE_PATH = self._get_resource_path("entangled_registers.qasm")
        self.QASM_FILE_PATH_2 = self._get_resource_path("plaquette_check.qasm")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func _get_resource_path(_ filename: String) -> String {
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        return path.path
    }

    //###############################################################
    //# Tests to initiate an build a quantum program
    //###############################################################

    func test_create_program_with_specs() {
        do {
            let result = try QuantumProgram(specs: self.QPS_SPECS)
            SDKLogger.logInfo(result)
        } catch {
            XCTFail("test_create_program_with_specs: \(error)")
        }
    }

    func test_create_program() {
        do {
            let result = try QuantumProgram()
            SDKLogger.logInfo(result)
        } catch {
            XCTFail("test_create_program: \(error)")
        }
    }

    func test_create_classical_register() {
        do {
            let QP_program = try QuantumProgram()
            let cr = try QP_program.create_classical_register("cr", 3)
            SDKLogger.logInfo(cr)
        } catch {
            XCTFail("test_create_classical_register: \(error)")
        }
    }

    func test_create_quantum_register() {
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 3)
            SDKLogger.logInfo(qr)
        } catch {
            XCTFail("test_create_quantum_register: \(error)")
        }
    }

    func test_fail_create_quantum_register() {
        do {
            let QP_program = try QuantumProgram()
            try QP_program.create_quantum_register("qr", 3)
            XCTAssertThrowsError(try QP_program.create_quantum_register("qr", 2)) { (error) -> Void in
                switch error {
                case QISKitError.registerSize:
                    break
                default:
                    XCTFail("test_fail_create_quantum_register: \(error)")
                }
            }
        } catch {
            XCTFail("test_fail_create_quantum_register: \(error)")
        }
    }

    func test_fail_create_classical_register() {
         do {
            let QP_program = try QuantumProgram()
            try QP_program.create_classical_register("cr", 3)
            XCTAssertThrowsError(try QP_program.create_classical_register("cr", 2)) { (error) -> Void in
                switch error {
                case QISKitError.registerSize:
                    break
                default:
                    XCTFail("test_fail_create_quantum_register: \(error)")
                }
            }
         } catch {
            XCTFail("test_fail_create_classical_register: \(error)")
        }
    }

    func test_create_quantum_register_same() {
        do {
            let QP_program = try QuantumProgram()
            let qr1 = try QP_program.create_quantum_register("qr", 3)
            let qr2 = try QP_program.create_quantum_register("qr", 3)
            XCTAssertEqual(qr1, qr2)
        } catch {
            XCTFail("test_create_quantum_register_same: \(error)")
        }
    }

    func test_create_classical_register_same() {
        do {
            let QP_program = try QuantumProgram()
            let cr1 = try QP_program.create_classical_register("cr", 3)
            let cr2 = try QP_program.create_classical_register("cr", 3)
            XCTAssertEqual(cr1, cr2)
        } catch {
            XCTFail("test_create_classical_register_same: \(error)")
        }
    }

    func test_create_classical_registers() {
         do {
            let QP_program = try QuantumProgram()
            let classical_registers = [["name": "c1", "size": 4],
                                       ["name": "c2", "size": 2]]
            let crs = try QP_program.create_classical_registers(classical_registers)
            for i in crs {
                SDKLogger.logInfo(i)
            }
         } catch {
            XCTFail("test_create_classical_registers: \(error)")
        }
    }

    func test_create_quantum_registers() {
        do {
            let QP_program = try QuantumProgram()
            let quantum_registers = [["name": "q1", "size": 4],
                                     ["name": "q2", "size": 2]]
            let qrs = try QP_program.create_quantum_registers(quantum_registers)
            for i in qrs {
                SDKLogger.logInfo(i)
            }
        } catch {
            XCTFail("test_create_quantum_registers: \(error)")
        }
    }

    func test_destroy_classical_register() {
         do {
            let QP_program = try QuantumProgram()
            try QP_program.create_classical_register("c1", 3)
            XCTAssert(Set<String>(QP_program.get_classical_register_names()).contains("c1"))
            try QP_program.destroy_classical_register("c1")
            XCTAssertFalse(Set<String>(QP_program.get_classical_register_names()).contains("c1"))
            do {
                // Destroying an invalid register should fail.
                try QP_program.destroy_classical_register("c1")
            } catch {
                switch error {
                case QISKitError.regNotExists(_):
                    break
                default:
                    XCTFail("test_destroy_classical_register: \(error)")
                }
            }
        } catch {
            XCTFail("test_destroy_classical_register: \(error)")
        }
    }

    func test_destroy_quantum_register() {
        do {
            let QP_program = try QuantumProgram()
            try QP_program.create_quantum_register("q1", 3)
            XCTAssert(Set<String>(QP_program.get_quantum_register_names()).contains("q1"))
            try QP_program.destroy_quantum_register("q1")
            XCTAssertFalse(Set<String>(QP_program.get_quantum_register_names()).contains("q1"))
            do {
                // Destroying an invalid register should fail.
                try QP_program.destroy_quantum_register("q1")
            } catch {
                switch error {
                case QISKitError.regNotExists(_):
                    break
                default:
                    XCTFail("test_destroy_quantum_register: \(error)")
                }
            }
        } catch {
            XCTFail("test_destroy_quantum_register: \(error)")
        }
    }

    func test_create_circuit() {
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 3)
            let cr = try QP_program.create_classical_register("cr", 3)
            let qc = try QP_program.create_circuit("qc", [qr], [cr])
            SDKLogger.logInfo(qc)
        } catch {
            XCTFail("test_create_circuit: \(error)")
        }
    }

    func test_create_several_circuits() {
        do {
            let QP_program = try QuantumProgram()
            let qr1 = try QP_program.create_quantum_register("qr1", 3)
            let cr1 = try QP_program.create_classical_register("cr1", 3)
            let qr2 = try QP_program.create_quantum_register("qr2", 3)
            let cr2 = try QP_program.create_classical_register("cr2", 3)
            let qc1 = try QP_program.create_circuit("qc1", [qr1], [cr1])
            let qc2 = try QP_program.create_circuit("qc2", [qr2], [cr2])
            let qc3 = try QP_program.create_circuit("qc2", [qr1, qr2], [cr1, cr2])
            SDKLogger.logInfo(qc1)
            SDKLogger.logInfo(qc2)
            SDKLogger.logInfo(qc3)
        } catch {
            XCTFail("test_create_several_circuits: \(error)")
        }
    }

    func test_destroy_circuit() {
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 3)
            let cr = try QP_program.create_classical_register("cr", 3)
            try QP_program.create_circuit("qc", [qr], [cr])
            XCTAssert(Set<String>(QP_program.get_circuit_names()).contains("qc"))
            try QP_program.destroy_circuit("qc")
            XCTAssertFalse(Set<String>(QP_program.get_circuit_names()).contains("qc"))
            do {
                // Destroying an invalid register should fail.
                try QP_program.destroy_circuit("qc")
            } catch {
                switch error {
                case QISKitError.missingCircuit(_):
                    break
                default:
                    XCTFail("test_destroy_circuit: \(error)")
                }
            }
        } catch {
            XCTFail("test_destroy_circuit: \(error)")
        }
    }

    func test_load_qasm_file() {
        do {
            try EntangledRegisters.QASM.write(toFile: self.QASM_FILE_PATH, atomically: true, encoding: .utf8)
            let QP_program = try QuantumProgram()
            let name = try QP_program.load_qasm_file(self.QASM_FILE_PATH, name:"")
            let result = try QP_program.get_circuit(name)
            let to_check = result.qasm()
            SDKLogger.logInfo(to_check)
            XCTAssertEqual(to_check.count, 554)
        } catch {
            XCTFail("test_load_qasm_file: \(error)")
        }
    }

    func test_fail_load_qasm_file() {
        do {
            let QP_program = try QuantumProgram()
            XCTAssertThrowsError(try QP_program.load_qasm_file("")) { (error) -> Void in
                switch error {
                case QasmError.internalError(let error):
                    SDKLogger.logInfo(error.localizedDescription)
                default:
                    XCTFail("test_fail_load_qasm_file: \(error)")
                }
            }
        } catch {
            XCTFail("test_fail_load_qasm_file: \(error)")
        }
    }

    func test_load_qasm_text() {
        do {
            let QP_program = try QuantumProgram()
            var QASM_string = "// A simple 8 qubit example\nOPENQASM 2.0;\n"
            QASM_string += "include \"qelib1.inc\";\nqreg a[4];\n"
            QASM_string += "qreg b[4];\ncreg c[4];\ncreg d[4];\nh a;\ncx a, b;\n"
            QASM_string += "barrier a;\nbarrier b;\nmeasure a[0]->c[0];\n"
            QASM_string += "measure a[1]->c[1];\nmeasure a[2]->c[2];\n"
            QASM_string += "measure a[3]->c[3];\nmeasure b[0]->d[0];\n"
            QASM_string += "measure b[1]->d[1];\nmeasure b[2]->d[2];\n"
            QASM_string += "measure b[3]->d[3];"
            let name = try QP_program.load_qasm_text(QASM_string)
            let result = try QP_program.get_circuit(name)
            let to_check = result.qasm()
            SDKLogger.logInfo(to_check)
            XCTAssertEqual(to_check.count, 554)
        } catch {
            XCTFail("test_load_qasm_text: \(error)")
        }
    }

    func test_get_register_and_circuit() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            SDKLogger.logInfo(qc)
            SDKLogger.logInfo(qr)
            SDKLogger.logInfo(cr)
        } catch {
            XCTFail("test_get_register_and_circuit: \(error)")
        }
    }

    func test_get_register_and_circuit_names() {
        do {
            let QP_program = try QuantumProgram()
            let qr1 = try QP_program.create_quantum_register("qr1", 3)
            let cr1 = try QP_program.create_classical_register("cr1", 3)
            let qr2 = try QP_program.create_quantum_register("qr2", 3)
            let cr2 = try QP_program.create_classical_register("cr2", 3)
            try QP_program.create_circuit("qc1", [qr1], [cr1])
            try QP_program.create_circuit("qc2", [qr2], [cr2])
            try QP_program.create_circuit("qc2", [qr1, qr2], [cr1, cr2])
            let qrn = QP_program.get_quantum_register_names()
            let crn = QP_program.get_classical_register_names()
            let qcn = QP_program.get_circuit_names()
            XCTAssertEqual(qrn, ["qr1", "qr2"])
            XCTAssertEqual(crn, ["cr1", "cr2"])
            XCTAssertEqual(qcn, ["qc1", "qc2"])
        } catch {
            XCTFail("test_get_register_and_circuit_names: \(error)")
        }
    }

    func test_get_qasm() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.h(qr[0])
            try qc.cx(qr[0], qr[1])
            try qc.cx(qr[1], qr[2])
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            try qc.measure(qr[2], cr[2])
            let result = try QP_program.get_qasm("circuitName")
            XCTAssertEqual(result.count, 212)
        } catch {
            XCTFail("test_get_qasm: \(error)")
        }
    }

    func test_get_qasms() {
         do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 3)
            let cr = try QP_program.create_classical_register("cr", 3)
            let qc1 = try QP_program.create_circuit("qc1", [qr], [cr])
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc1.h(qr[0])
            try qc1.cx(qr[0], qr[1])
            try qc1.cx(qr[1], qr[2])
            try qc1.measure(qr[0], cr[0])
            try qc1.measure(qr[1], cr[1])
            try qc1.measure(qr[2], cr[2])
            try qc2.h(qr)
            try qc2.measure(qr[0], cr[0])
            try qc2.measure(qr[1], cr[1])
            try qc2.measure(qr[2], cr[2])
            let result = try QP_program.get_qasms(["qc1", "qc2"])
            XCTAssertEqual(result[0].count, 173)
            XCTAssertEqual(result[1].count, 159)
        } catch {
            XCTFail("test_get_qasms: \(error)")
        }
    }

    func test_get_qasm_all_gates() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.u1(0.3, qr[0])
            try qc.u2(0.2, 0.1, qr[1])
            try qc.u3(0.3, 0.2, 0.1, qr[2])
            try qc.s(qr[1])
            try qc.s(qr[2]).inverse()
            try qc.cx(qr[1], qr[2])
            try qc.barrier()
            try qc.cx(qr[0], qr[1])
            try qc.h(qr[0])
            try qc.x(qr[2]).c_if(cr, 0)
            try qc.y(qr[2]).c_if(cr, 1)
            try qc.z(qr[2]).c_if(cr, 2)
            try qc.barrier(qr)
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            try qc.measure(qr[2], cr[2])
            let result = try QP_program.get_qasm("circuitName")
            XCTAssertEqual(result.count, 535)
        } catch {
            XCTFail("test_get_qasm_all_gates: \(error)")
        }
    }

    func test_get_initial_circuit() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            guard let qc = QP_program.get_initial_circuit() else {
                XCTFail("test_get_initial_circuit: Missing initial circuit")
                return
            }
            SDKLogger.logInfo(qc)
        } catch {
            XCTFail("test_get_initial_circuit: \(error)")
        }
    }

    func test_save() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.u3(0.3, 0.2, 0.1, qr[0])
            try qc.h(qr[1])
            try qc.cx(qr[1], qr[2])
            try qc.barrier()
            try qc.cx(qr[0], qr[1])
            try qc.h(qr[0])
            try qc.z(qr[2]).c_if(cr, 1)
            try qc.x(qr[2]).c_if(cr, 1)
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            let result = try QP_program.save(self._get_resource_path("test_save.json"),beauty: true)
            SDKLogger.logInfo(result)
        } catch {
            XCTFail("test_save: \(error)")
        }
    }

    func test_save_wrong() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            XCTAssertThrowsError(try QP_program.save("")) { (error) -> Void in
                switch error {
                case QISKitError.internalError(let error):
                    SDKLogger.logInfo(error.localizedDescription)
                default:
                    XCTFail("test_save_wrong: \(error)")
                }
            }
        } catch {
            XCTFail("test_save_wrong: \(error)")
        }
    }

    func test_load() {
        do {
            var QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            try QP_program.load_qasm_text(EntangledRegisters.QASM, name: "circuitName")
            try QP_program.save(self._get_resource_path("test_save.json"),beauty: true)
            QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let result = try QP_program.load(self._get_resource_path("test_save.json"))
            SDKLogger.logInfo(result)
            let check_result = try QP_program.get_qasm("circuitName")
            XCTAssertEqual(check_result.count, 554)
        } catch {
            XCTFail("test_load: \(error)")
        }
    }

    //###############################################################
    //# Tests for working with backends
    //###############################################################

    func test_setup_api() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            QP_program.set_api(token:token, url:QE_URL)
            let config = QP_program.get_api_config()
            SDKLogger.logInfo(config)
        } catch {
            XCTFail("test_setup_api: \(error)")
        }
    }

    func test_available_backends_exist() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_available_backends_exist")
            QP_program.available_backends() { (available_backends,error) in
                if error != nil {
                    XCTFail("Failure in test_available_backends_exist: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(available_backends)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_available_backends_exist")
            })
        } catch {
            XCTFail("test_available_backends_exist: \(error)")
        }
    }

    func test_local_backends_exist() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let local_backends = QP_program.local_backends()
            SDKLogger.logInfo(local_backends)
        } catch {
            XCTFail("test_local_backends_exist: \(error)")
        }
    }

    func test_online_backends_exist() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            // TODO: should we check if we the QX is online before running
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_available_backends_exist")
            QP_program.online_backends()  { (online_backends,error) in
                if error != nil {
                    XCTFail("Failure in test_online_backends_exist: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(online_backends)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_online_backends_exist")
            })
        } catch {
            XCTFail("test_online_backends_exist: \(error)")
        }
    }

    func test_online_devices() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            // TODO: should we check if we the QX is online before running
            let qp = try QuantumProgram(specs: self.QPS_SPECS)
            qp.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_online_devices")
            qp.online_devices()  { (online_devices,error) in
                if error != nil {
                    XCTFail("Failure in test_online_devices: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(online_devices)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_online_devices")
            })
        } catch {
            XCTFail("test_online_devices: \(error)")
        }
    }

    func test_online_simulators() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            // TODO: should we check if we the QX is online before running
            let qp = try QuantumProgram(specs: self.QPS_SPECS)
            qp.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_online_simulators")
            qp.online_simulators() { (online_simulators,error) in
                if error != nil {
                    XCTFail("Failure in test_online_simulators: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(online_simulators)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_online_devices")
            })
        } catch {
            XCTFail("test_online_simulators: \(error)")
        }
    }

    func test_backend_status() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let asyncExpectation = self.expectation(description: "test_backend_status")
            QP_program.get_backend_status("local_qasm_simulator") { (status,error) in
                if error != nil {
                    XCTFail("Failure in test_backend_status: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(status)
                guard let available = status["available"] as? Bool else {
                    XCTFail("test_backend_status: Missing status.")
                    asyncExpectation.fulfill()
                    return
                }
                XCTAssertEqual(available, true)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_backend_status")
            })
        } catch {
            XCTFail("test_backend_status: \(error)")
        }
    }

    func test_get_backend_configuration() {
        do {
            let qp = try QuantumProgram(specs: self.QPS_SPECS)
            let config_keys = ["name", "simulator", "local", "description",
                               "coupling_map", "basis_gates"]
            let asyncExpectation = self.expectation(description: "test_get_backend_configuration")
            qp.get_backend_configuration("local_qasm_simulator")  { (backend_config,error) in
                if error != nil {
                    XCTFail("Failure in test_get_backend_configuration: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(backend_config)
                XCTAssert(config_keys.count < backend_config.keys.count)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_backend_configuration")
            })
        } catch {
            XCTFail("test_get_backend_configuration: \(error)")
        }
    }

    func test_get_backend_configuration_fail() {
        do {
            let qp = try QuantumProgram(specs: self.QPS_SPECS)
            let asyncExpectation = self.expectation(description: "test_get_backend_configuration_fail")
            qp.get_backend_configuration("fail")  { (backend_config,error) in
                if error != nil {
                    switch error! {
                    case IBMQuantumExperienceError.badBackendError(let backend):
                        SDKLogger.logInfo(backend)
                        break
                    default:
                        XCTFail("test_get_backend_configuration_fail: \(error!)")
                    }
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(backend_config)
                XCTFail("test_get_backend_configuration_fail should have failed.")
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_backend_configuration_fail")
            })
        } catch {
            XCTFail("test_get_backend_configuration_fail: \(error)")
        }
    }

    func test_get_backend_calibration() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_get_backend_calibration")
            QP_program.online_backends() { (backend_list,error) in
                if error != nil {
                    XCTFail("Failure in test_get_backend_calibration: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                if let backend = backend_list.first {
                    QP_program.get_backend_calibration(backend)  { (result,error) in
                        if error != nil {
                            XCTFail("Failure in test_get_backend_calibration: \(error!.localizedDescription)")
                            asyncExpectation.fulfill()
                            return
                        }
                        SDKLogger.logInfo(result)
                        XCTAssertEqual(result.count, 4)
                        asyncExpectation.fulfill()
                    }
                }
                else {
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_backend_calibration")
            })
        } catch {
            XCTFail("test_get_backend_calibration: \(error)")
        }
    }

    func test_get_backend_parameters() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_get_backend_parameters")
            QP_program.online_backends() { (backend_list,error) in
                if error != nil {
                    XCTFail("Failure in test_get_backend_parameters: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                if let backend = backend_list.first {
                    QP_program.get_backend_parameters(backend)  { (result,error) in
                        if error != nil {
                            XCTFail("Failure in test_get_backend_parameters: \(error!.localizedDescription)")
                            asyncExpectation.fulfill()
                            return
                        }
                        SDKLogger.logInfo(result)
                        XCTAssertEqual(result.count, 4)
                        asyncExpectation.fulfill()
                    }
                }
                else {
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_backend_parameters")
            })
        } catch {
            XCTFail("test_get_backend_parameters: \(error)")
        }
    }

    //###############################################################
    //# Test for compile
    //###############################################################

    func test_compile_program() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.h(qr[0])
            try qc.cx(qr[0], qr[1])
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            let backend = "local_qasm_simulator"
            let coupling_map: [Int:[Int]]? = nil
            let asyncExpectation = self.expectation(description: "test_compile_program")
            QP_program.compile(["circuitName"],
                                   backend: backend,
                                   coupling_map: coupling_map,
                                   qobj_id: "cooljob") { (out,error) in
                if error != nil {
                    XCTFail("Failure in test_compile_program: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(out)
                XCTAssertEqual(out.count, 3)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_compile_program")
            })
        } catch {
            XCTFail("test_compile_program: \(error)")
        }
    }

    func test_get_compiled_configuration() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.h(qr[0])
            try qc.cx(qr[0], qr[1])
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            let backend = "local_qasm_simulator"
            let coupling_map: [Int:[Int]]? = nil
            let asyncExpectation = self.expectation(description: "test_get_compiled_configuration")
            QP_program.compile(["circuitName"],
                               backend: backend,
                               coupling_map: coupling_map) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_get_compiled_configuration: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                do {
                    let result = try QP_program.get_compiled_configuration(qobj, "circuitName")
                    SDKLogger.logInfo(result)
                    XCTAssertEqual(result.count, 4)
                } catch {
                    XCTFail("test_compile_program: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_compiled_configuration")
            })
        } catch {
            XCTFail("test_compile_program: \(error)")
        }
    }

    func test_get_compiled_qasm() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.h(qr[0])
            try qc.cx(qr[0], qr[1])
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            let backend = "local_qasm_simulator"
            let coupling_map: [Int:[Int]]? = nil
            let asyncExpectation = self.expectation(description: "test_get_compiled_qasm")
            QP_program.compile(["circuitName"],
                              backend: backend,
                              coupling_map: coupling_map) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_get_compiled_qasm: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                do {
                    let result = try QP_program.get_compiled_qasm(qobj, "circuitName")
                    SDKLogger.logInfo(result)
                    XCTAssertEqual(result.count, 167)
                } catch {
                    XCTFail("test_get_compiled_qasm: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_compiled_qasm")
            })
        } catch {
            XCTFail("test_get_compiled_qasm: \(error)")
        }
    }

    func test_get_execution_list() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qc = try QP_program.get_circuit("circuitName")
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            try qc.h(qr[0])
            try qc.cx(qr[0], qr[1])
            try qc.measure(qr[0], cr[0])
            try qc.measure(qr[1], cr[1])
            let backend = "local_qasm_simulator"
            let coupling_map: [Int:[Int]]? = nil
            let asyncExpectation = self.expectation(description: "test_get_execution_list")
            QP_program.compile(["circuitName"],
                               backend: backend,
                               coupling_map: coupling_map,
                               qobj_id: "cooljob") { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_get_compiled_qasm: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                let result = QP_program.get_execution_list(qobj)
                SDKLogger.logInfo(result)
                XCTAssertEqual(result, ["circuitName"])
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_get_execution_list")
            })
        } catch {
            XCTFail("test_get_execution_list: \(error)")
        }
    }

    func test_compile_coupling_map() {
        do {
            let QP_program = try QuantumProgram()
            let q = try QP_program.create_quantum_register("q", 3)
            let c = try QP_program.create_classical_register("c", 3)
            let qc = try QP_program.create_circuit("circuitName", [q], [c])
            try qc.h(q[0])
            try qc.cx(q[0], q[1])
            try qc.cx(q[0], q[2])
            try qc.measure(q[0], c[0])
            try qc.measure(q[1], c[1])
            try qc.measure(q[2], c[2])
            let backend = "local_qasm_simulator"  // the backend to run on
            let shots = 1024  // the number of shots in the experiment.
            let coupling_map = [0: [1], 1: [2]]
            let initial_layout:OrderedDictionary<RegBit,RegBit> = [RegBit(("q", 0)): RegBit(("q", 0)),
                                                                   RegBit(("q", 1)): RegBit(("q", 1)),
                                                                   RegBit(("q", 2)): RegBit(("q", 2))]
            let circuits = ["circuitName"]
            let asyncExpectation = self.expectation(description: "test_compile_coupling_map")
            QP_program.compile(circuits, backend: backend,
                                              coupling_map: coupling_map,
                                              initial_layout: initial_layout,
                                              shots: shots,
                                              seed: 88) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_compile_coupling_map: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.run_async(qobj) { (result) in
                    do {
                        if let error = result.get_error() {
                            XCTFail("Failure in test_compile_coupling_map: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let to_check = try QP_program.get_qasm("circuitName")
                        XCTAssertEqual(to_check.count, 160)
                        XCTAssertEqual(try result.get_counts("circuitName"), ["000": 518, "111": 506])
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_compile_coupling_map: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_compile_coupling_map")
            })
        } catch {
            XCTFail("test_compile_coupling_map: \(error)")
        }
    }

    func test_change_circuit_qobj_after_compile() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            let qc3 = try QP_program.create_circuit("qc3", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc2.cx(qr[0], qr[2])
            try qc3.h(qr)
            try qc2.measure(qr, cr)
            try qc3.measure(qr, cr)
            let circuits = ["qc2", "qc3"]
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            var config: [String:Any] = ["seed": 10, "shots": 1, "xvals": [1, 2, 3, 4]]
            let asyncExpectation = self.expectation(description: "test_change_circuit_qobj_after_compile")
            QP_program.compile(circuits,
                               backend: backend,
                               config: config,
                               shots:shots,
                               seed: 88) { (q1,error) in
                if error != nil {
                    XCTFail("Failure in test_change_circuit_qobj_after_compile: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                var qobj1 = q1
                guard var qobj1Circuits = qobj1["circuits"] as? [[String:Any]] else {
                    XCTFail("test_change_circuit_qobj_after_compile")
                    asyncExpectation.fulfill()
                    return
                }
                guard var circuitConfig = qobj1Circuits[0]["config"] as? [String:Any] else {
                    XCTFail("test_change_circuit_qobj_after_compile")
                    asyncExpectation.fulfill()
                    return
                }
                circuitConfig["shots"] = 50
                circuitConfig["xvals"] = [1,1,1]
                qobj1Circuits[0]["config"] = circuitConfig
                qobj1["circuits"] = qobj1Circuits
                config["shots"] = 1000
                guard var xvals = config["xvals"] as? [Any] else {
                    XCTFail("test_change_circuit_qobj_after_compile")
                    asyncExpectation.fulfill()
                    return
                }
                xvals[0] = "only for qobj2"
                config["xvals"] = xvals
                QP_program.compile(circuits,
                                   backend: backend,
                                   config: config,
                                   shots: shots,
                                   seed: 88) { (qobj2,error) in
                    if error != nil {
                        XCTFail("Failure in test_change_circuit_qobj_after_compile: \(error!)")
                        asyncExpectation.fulfill()
                        return
                    }
                    if let q1Circuits = qobj1["circuits"] as? [[String:Any]] {
                        if let config0 = q1Circuits[0]["config"] as? [String:Any],
                            let config1 = q1Circuits[1]["config"] as? [String:Any] {
                            XCTAssert(config0["shots"] as! Int == 50)
                            XCTAssert(config1["shots"] as! Int == 1)
                            XCTAssert(config0["xvals"] as! [Int] == [1,1,1])
                            XCTAssert(config1["xvals"] as! [Int] == [1,2,3,4])
                        }
                        else {
                            XCTFail("test_change_circuit_qobj_after_compile")
                            asyncExpectation.fulfill()
                            return
                        }
                    }
                    else {
                        XCTFail("test_change_circuit_qobj_after_compile")
                        asyncExpectation.fulfill()
                        return
                    }
                    if let q1Config = qobj1["config"] as? [String:Any] {
                        XCTAssert(q1Config["shots"] as! Int == 1024)
                    }
                    else {
                        XCTFail("test_change_circuit_qobj_after_compile")
                        asyncExpectation.fulfill()
                        return
                    }
                    if let q2Circuits = qobj2["circuits"] as? [[String:Any]] {
                        if let config0 = q2Circuits[0]["config"] as? [String:Any],
                            let config1 = q2Circuits[1]["config"] as? [String:Any] {
                            XCTAssert(config0["shots"] as! Int == 1000)
                            XCTAssert(config1["shots"] as! Int == 1000)
                            if let xvals = config0["xvals"]  as? [Any] {
                                XCTAssert(xvals[0] as! String == "only for qobj2")
                                XCTAssert(xvals[1] as! Int == 2)
                                XCTAssert(xvals[2] as! Int == 3)
                                XCTAssert(xvals[3] as! Int == 4)
                            }
                            else {
                                XCTFail("test_change_circuit_qobj_after_compile")
                                asyncExpectation.fulfill()
                                return
                            }
                            if let xvals = config1["xvals"] as? [Any] {
                                XCTAssert(xvals[0] as! String == "only for qobj2")
                                XCTAssert(xvals[1] as! Int == 2)
                                XCTAssert(xvals[2] as! Int == 3)
                                XCTAssert(xvals[3] as! Int == 4)
                            }
                            else {
                                XCTFail("test_change_circuit_qobj_after_compile")
                            }
                        }
                        else {
                            XCTFail("test_change_circuit_qobj_after_compile")
                        }
                    }
                    else {
                        XCTFail("test_change_circuit_qobj_after_compile")
                    }
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_change_circuit_qobj_after_compile")
            })
        } catch {
            XCTFail("test_change_circuit_qobj_after_compile: \(error)")
        }
    }

    //###############################################################
    //# Test for running programs
    //###############################################################

    func test_run_program() {
         do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            let qc3 = try QP_program.create_circuit("qc3", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc2.cx(qr[0], qr[2])
            try qc3.h(qr)
            try qc2.measure(qr, cr)
            try qc3.measure(qr, cr)
            let circuits = ["qc2", "qc3"]
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_run_program")
            QP_program.compile(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 88) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_run_program: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.run_async(qobj) { (out) in
                    do {
                        if let error = out.get_error() {
                            XCTFail("Failure in test_run_program: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let results2 = try out.get_counts("qc2")
                        let results3 = try out.get_counts("qc3")
                        XCTAssertEqual(results2, ["000": 518, "111": 506])
                        XCTAssertEqual(results3, ["001": 119, "111": 129, "110": 134,
                                                  "100": 117, "000": 129, "101": 126,
                                                  "010": 145, "011": 125])
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_run_program: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_run_program")
            })
        } catch {
            XCTFail("test_run_program: \(error)")
        }
    }

    func test_run_batch() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            let qc3 = try QP_program.create_circuit("qc3", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc2.cx(qr[0], qr[2])
            try qc3.h(qr)
            try qc2.measure(qr, cr)
            try qc3.measure(qr, cr)
            let circuits = ["qc2", "qc3"]
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_run_batch")
            QP_program.compile(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 88) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_run_batch: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                let qobj_list = [ qobj, qobj, qobj, qobj ]
                QP_program.run_batch_async(qobj_list) { (results) in
                    do {
                        for result in results {
                            if let error = result.get_error() {
                                XCTFail("Failure in test_run_batch: \(error)")
                                asyncExpectation.fulfill()
                                return
                            }
                            let counts2 = try result.get_counts("qc2")
                            let counts3 = try result.get_counts("qc3")
                            XCTAssertEqual(counts2, ["000": 518, "111": 506])
                            XCTAssertEqual(counts3, ["001": 119, "111": 129, "110": 134,
                                                     "100": 117, "000": 129, "101": 126,
                                                     "010": 145, "011": 125])
                        }
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_run_batch: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_run_batch")
            })
        } catch {
            XCTFail("test_run_batch: \(error)")
        }
    }

    func test_combine_results() {
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 1)
            let cr = try QP_program.create_classical_register("cr", 1)
            let qc1 = try QP_program.create_circuit("qc1", [qr], [cr])
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc1.measure(qr[0], cr[0])
            try qc2.x(qr[0])
            try qc2.measure(qr[0], cr[0])
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_combine_results")
            QP_program.execute(["qc1"], backend: backend, shots: shots)  { (res) in
                var res1 = res
                if let error = res1.get_error() {
                    XCTFail("Failure in test_combine_results: \(error)")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.execute(["qc2"], backend: backend, shots: shots)   { (res2) in
                    do {
                        if let error = res2.get_error() {
                            XCTFail("Failure in test_combine_results: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let counts1 = try res1.get_counts("qc1")
                        let counts2 = try res2.get_counts("qc2")
                        try res1.append(res2)  // combine results
                        let counts12 = [try res1.get_counts("qc1"), try res1.get_counts("qc2")]
                        XCTAssertEqual(counts12[0], counts1)
                        XCTAssertEqual(counts12[1], counts2)
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_combine_results: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_combine_results")
            })
        } catch {
            XCTFail("test_combine_results: \(error)")
        }
    }

    func test_local_qasm_simulator() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            let qc3 = try QP_program.create_circuit("qc3", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc2.cx(qr[0], qr[2])
            try qc3.h(qr)
            try qc2.measure(qr[0], cr[0])
            try qc3.measure(qr[0], cr[0])
            try qc2.measure(qr[1], cr[1])
            try qc3.measure(qr[1], cr[1])
            try qc2.measure(qr[2], cr[2])
            try qc3.measure(qr[2], cr[2])
            let circuits = ["qc2", "qc3"]
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_local_qasm_simulator")
            QP_program.execute(circuits, backend: backend, shots: shots, seed:88)  { (out) in
                do {
                    if let error = out.get_error() {
                        XCTFail("Failure in test_local_qasm_simulator: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    let results2 = try out.get_counts("qc2")
                    let results3 = try out.get_counts("qc3")
                    SDKLogger.logInfo(results3)
                    XCTAssertEqual(results2, ["000": 518, "111": 506])
                    XCTAssertEqual(results3, ["001": 119, "111": 129, "110": 134,
                                              "100": 117, "000": 129, "101": 126,
                                              "010": 145, "011": 125])
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_local_qasm_simulator: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_local_qasm_simulator")
            })
        } catch {
            XCTFail("test_local_qasm_simulator: \(error)")
        }
    }

    func test_local_qasm_simulator_one_shot() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            let qc3 = try QP_program.create_circuit("qc3", [qr], [cr])
            try qc2.h(qr[0])
            try qc3.h(qr[0])
            try qc3.cx(qr[0], qr[1])
            try qc3.cx(qr[0], qr[2])
            let circuits = ["qc2", "qc3"]
            let backend = "local_qasm_simulator"  // the backend to run on
            let shots = 1  // the number of shots in the experiment.
            let asyncExpectation = self.expectation(description: "test_local_qasm_simulator_one_shot")
            QP_program.execute(circuits, backend: backend, shots: shots, seed: 9) { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_local_qasm_simulator_one_shot: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    var quantum_state: Vector<Complex> = [0.70710678, 0.70710678,
                                                          0.00000000, 0.00000000,
                                                          0.00000000, 0.00000000,
                                                          0.00000000, 0.00000000]
                    let qc2 = try result.get_data("qc2")
                    guard let qs2 = qc2["quantum_state"] as? [Complex] else {
                        XCTFail("Failure in test_local_qasm_simulator_one_shot.")
                        asyncExpectation.fulfill()
                        return
                    }
                    var qsVector = Vector<Complex>(value:qs2)
                    var norm = quantum_state.conjugate().dot(qsVector)
                    XCTAssert(norm.almostEqual(1))
                    quantum_state = [0.70710678, 0.00000000,
                                     0.00000000, 0.00000000,
                                     0.00000000, 0.00000000,
                                     0.00000000, 0.70710678]
                    let qc3 = try result.get_data("qc3")
                    guard let qs3 = qc3["quantum_state"] as? [Complex] else {
                        XCTFail("Failure in test_local_qasm_simulator_one_shot.")
                        asyncExpectation.fulfill()
                        return
                    }
                    qsVector = Vector<Complex>(value:qs3)
                    norm = quantum_state.conjugate().dot(qsVector)
                    XCTAssert(norm.almostEqual(1))
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_local_qasm_simulator: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_local_qasm_simulator_one_shot")
            })
        } catch {
            XCTFail("test_local_qasm_simulator_one_shot: \(error)")
        }
    }

    func test_local_unitary_simulator() {
        do {
            let QP_program = try QuantumProgram()
            let q = try QP_program.create_quantum_register("q", 2)
            let c = try QP_program.create_classical_register("c", 2)
            let qc1 = try QP_program.create_circuit("qc1", [q], [c])
            let qc2 = try QP_program.create_circuit("qc2", [q], [c])
            try qc1.h(q)
            try qc2.cx(q[0], q[1])
            let circuits = ["qc1", "qc2"]
            let backend = "local_unitary_simulator"  // the backend to run on
            let asyncExpectation = self.expectation(description: "test_local_unitary_simulator")
            QP_program.execute(circuits, backend: backend)  { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_local_unitary_simulator: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    guard let unitary1 = try result.get_data("qc1")["unitary"] as? Matrix<Complex> else {
                        XCTFail("test_local_unitary_simulator missing unitary result.")
                        return
                    }
                    guard let unitary2 = try result.get_data("qc2")["unitary"] as? Matrix<Complex> else {
                        XCTFail("test_local_unitary_simulator missing unitary result.")
                        return
                    }
                    let unitaryreal1: Matrix<Complex> = [[0.5, 0.5,  0.5,  0.5], [0.5, -0.5,  0.5, -0.5],
                                                         [0.5, 0.5, -0.5, -0.5], [0.5, -0.5, -0.5,  0.5]]
                    let unitaryreal2: Matrix<Complex> = [[1,  0,  0, 0], [0, 0,  0,  1],
                                                         [0,  0,  1, 0], [0, 1,  0,  0]]
                    let norm1 = unitaryreal1.conjugate().transpose().dot(unitary1).trace()
                    let norm2 = unitaryreal2.conjugate().transpose().dot(unitary2).trace()
                    XCTAssert(norm1.almostEqual(4))
                    XCTAssert(norm2.almostEqual(4))
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_local_unitary_simulator: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_local_unitary_simulator")
            })
        } catch {
            XCTFail("test_local_unitary_simulator: \(error)")
        }
    }

    func test_run_program_map() {
        do {
            let QP_program = try QuantumProgram()
            let backend = "local_qasm_simulator"  // the backend to run on
            let shots = 100  // the number of shots in the experiment.
            let max_credits = 3
            let coupling_map = [0: [1], 1: [2], 2: [3], 3: [4]]
            let initial_layout:OrderedDictionary<RegBit,RegBit> = [RegBit(("q", 0)): RegBit(("q", 0)),
                                                                   RegBit(("q", 1)): RegBit(("q", 1)),
                                                                   RegBit(("q", 2)): RegBit(("q", 2)),
                                                                   RegBit(("q", 3)): RegBit(("q", 3)),
                                                                   RegBit(("q", 4)): RegBit(("q", 4))]
            try PlaquetteCheck.QASM.write(toFile: self.QASM_FILE_PATH_2, atomically: true, encoding: .utf8)
            try QP_program.load_qasm_file(self.QASM_FILE_PATH_2, name: "circuit-dev")
            let circuits = ["circuit-dev"]
            let asyncExpectation = self.expectation(description: "test_run_program_map")
            QP_program.compile(circuits,
                              backend: backend,
                              coupling_map: coupling_map,
                              initial_layout: initial_layout,
                              shots: shots,
                              max_credits: max_credits,
                              seed: 65) { (qobj,error) in
                if error != nil {
                    XCTFail("Failure in test_run_program_map: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.run_async(qobj) { result in
                    do {
                        if let error = result.get_error() {
                            XCTFail("Failure in test_run_program_map: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let counts = try result.get_counts("circuit-dev")
                        XCTAssertEqual(counts, ["10010": 100])
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_run_program_map: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_run_program_map")
            })
        } catch {
            XCTFail("test_run_program_map: \(error)")
        }
    }

    func test_execute_program_map() {
        do {
            let QP_program = try QuantumProgram()
            let backend = "local_qasm_simulator"  // the backend to run on
            let shots = 100  // the number of shots in the experiment.
            let max_credits = 3
            let coupling_map = [0: [1], 1: [2], 2: [3], 3: [4]]
            let initial_layout:OrderedDictionary<RegBit,RegBit> = [RegBit(("q", 0)): RegBit(("q", 0)),
                                                                   RegBit(("q", 1)): RegBit(("q", 1)),
                                                                   RegBit(("q", 2)): RegBit(("q", 2)),
                                                                   RegBit(("q", 3)): RegBit(("q", 3)),
                                                                   RegBit(("q", 4)): RegBit(("q", 4))]
            try PlaquetteCheck.QASM.write(toFile: self.QASM_FILE_PATH_2, atomically: true, encoding: .utf8)
            try QP_program.load_qasm_file(self.QASM_FILE_PATH_2, name: "circuit-dev")
            let circuits = ["circuit-dev"]
            let asyncExpectation = self.expectation(description: "test_execute_program_map")
            QP_program.execute(circuits,
                               backend: backend,
                               coupling_map: coupling_map,
                               initial_layout: initial_layout,
                               shots: shots,
                               max_credits: max_credits,
                               seed: 5455) { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_execute_program_map: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    let counts = try result.get_counts("circuit-dev")
                    XCTAssertEqual(counts, ["10010": 100])
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_run_program_map: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_run_program_map")
            })
        } catch {
            XCTFail("test_execute_program_map: \(error)")
        }
    }

    func test_average_data() {
        do {
            let QP_program = try QuantumProgram()
            let q = try QP_program.create_quantum_register("q", 2)
            let c = try QP_program.create_classical_register("c", 2)
            let qc = try QP_program.create_circuit("qc", [q], [c])
            try qc.h(q[0])
            try qc.cx(q[0], q[1])
            try qc.measure(q[0], c[0])
            try qc.measure(q[1], c[1])
            let circuits = ["qc"]
            let shots = 10000  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_average_data")
            QP_program.execute(circuits, backend: backend, shots: shots) { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_average_data: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    var observable = ["00": 1, "11": 1, "01": -1, "10": -1]
                    let meanzz = try result.average_data("qc", observable)
                    observable = ["00": 1, "11": -1, "01": 1, "10": -1]
                    let meanzi = try result.average_data("qc", observable)
                    observable = ["00": 1, "11": -1, "01": -1, "10": 1]
                    let meaniz = try result.average_data("qc", observable)
                    XCTAssert(meanzz.almostEqual(1, 0.1))
                    XCTAssert(meanzi.almostEqual(0, 0.1))
                    XCTAssert(meaniz.almostEqual(0, 0.1))
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_average_data: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_average_data")
            })
        } catch {
            XCTFail("test_average_data: \(error)")
        }
    }

    func test_execute_one_circuit_simulator_online() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("q", 1)
            let cr = try QP_program.create_classical_register("c", 1)
            let qc = try QP_program.create_circuit("qc", [qr], [cr])
            try qc.h(qr[0])
            try qc.measure(qr[0], cr[0])
            let shots = 1024  // the number of shots in the experiment.
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_execute_one_circuit_simulator_online")
            QP_program.online_simulators()  { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_execute_one_circuit_simulator_online: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let backend = backends.first else {
                    XCTFail("Failure in test_execute_one_circuit_simulator_online: Missing backend.")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.execute(["qc"],
                                   backend: backend,
                                   shots: shots,
                                   max_credits: 3,
                                   seed: 73846087) { result in
                    do {
                        if let error = result.get_error() {
                            XCTFail("Failure in test_execute_one_circuit_simulator_online: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let counts = try result.get_counts("qc")
                        XCTAssertEqual(counts, ["0": 498, "1": 526])
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_execute_one_circuit_simulator_online: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_execute_one_circuit_simulator_online")
            })
        } catch {
            XCTFail("test_execute_one_circuit_simulator_online: \(error)")
        }
    }

    func test_simulator_online_size() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("q", 25)
            let cr = try QP_program.create_classical_register("c", 25)
            let qc = try QP_program.create_circuit("qc", [qr], [cr])
            try qc.h(qr)
            try qc.measure(qr, cr)
            let shots = 1  // the number of shots in the experiment.
            QP_program.set_api(token:token, url:QE_URL)
            let backend = "ibmqx_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_simulator_online_size")
            QP_program.execute(["qc"],
                               backend: backend,
                               shots: shots,
                               max_credits: 3,
                               seed: 73846087) { result in
                if let error = result.get_error() {
                    switch error {
                        case IBMQuantumExperienceError.registerSizeError(_):
                            break
                        default:
                            XCTFail("test_simulator_online_size: \(error)")
                    }
                    asyncExpectation.fulfill()
                    return
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_simulator_online_size")
            })
        } catch {
            XCTFail("test_simulator_online_size: \(error)")
        }
    }

    func test_execute_several_circuits_simulator_online() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("q", 2)
            let cr = try QP_program.create_classical_register("c", 2)
            let qc1 = try QP_program.create_circuit("qc1", [qr], [cr])
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc1.h(qr)
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc1.measure(qr[0], cr[0])
            try qc1.measure(qr[1], cr[1])
            try qc2.measure(qr[0], cr[0])
            try qc2.measure(qr[1], cr[1])
            let circuits = ["qc1", "qc2"]
            let shots = 1024  // the number of shots in the experiment.
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_execute_several_circuits_simulator_online")
            QP_program.online_simulators()  { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_execute_several_circuits_simulator_online: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let backend = backends.first else {
                    XCTFail("Failure in test_execute_several_circuits_simulator_online: Missing backend.")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.execute(circuits,
                                   backend: backend,
                                   shots: shots,
                                   max_credits: 3,
                                   seed: 1287126141) { result in
                    do {
                        if let error = result.get_error() {
                            XCTFail("Failure in test_execute_several_circuits_simulator_online: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let counts1 = try result.get_counts("qc1")
                        let counts2 = try result.get_counts("qc2")
                        XCTAssertEqual(counts1,  ["10": 277, "11": 238, "01": 258, "00": 251])
                        XCTAssertEqual(counts2, ["11": 515, "00": 509])
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_execute_several_circuits_simulator_online: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_execute_several_circuits_simulator_online")
            })
        } catch {
            XCTFail("test_execute_several_circuits_simulator_online: \(error)")
        }
    }

    func test_execute_one_circuit_real_online() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 1)
            let cr = try QP_program.create_classical_register("cr", 1)
            let qc = try QP_program.create_circuit("circuitName", [qr], [cr])
            try qc.h(qr)
            try qc.measure(qr[0], cr[0])
            QP_program.set_api(token:token, url:QE_URL)
            let backend = "ibmqx_qasm_simulator"
            let shots = 1  // the number of shots in the experiment.
            let asyncExpectation = self.expectation(description: "test_execute_one_circuit_real_online")
            QP_program.get_backend_status(backend) { (status,error) in
                if error != nil {
                    XCTFail("Failure in test_execute_one_circuit_real_online: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(status)
                if let available = status["available"] as? Bool {
                    if !available {
                        SDKLogger.logInfo("'\(backend)' not available")
                        asyncExpectation.fulfill()
                        return
                    }
                }
                QP_program.execute(["circuitName"],
                                   backend: backend,
                                   shots: shots,
                                   max_credits: 3,
                                   seed: 1287126141) { result in
                    if let error = result.get_error() {
                        XCTFail("Failure in test_execute_one_circuit_real_online: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    SDKLogger.logInfo(result)
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_execute_one_circuit_real_online")
            })
        } catch {
            XCTFail("test_execute_one_circuit_real_online: \(error)")
        }
    }

    func test_local_qasm_simulator_two_registers() {
        do {
            let QP_program = try QuantumProgram()
            let q1 = try QP_program.create_quantum_register("q1", 2)
            let c1 = try QP_program.create_classical_register("c1", 2)
            let q2 = try QP_program.create_quantum_register("q2", 2)
            let c2 = try QP_program.create_classical_register("c2", 2)
            let qc1 = try QP_program.create_circuit("qc1", [q1, q2], [c1, c2])
            let qc2 = try QP_program.create_circuit("qc2", [q1, q2], [c1, c2])

            try qc1.x(q1[0])
            try qc2.x(q2[1])
            try qc1.measure(q1[0], c1[0])
            try qc1.measure(q1[1], c1[1])
            try qc1.measure(q2[0], c2[0])
            try qc1.measure(q2[1], c2[1])
            try qc2.measure(q1[0], c1[0])
            try qc2.measure(q1[1], c1[1])
            try qc2.measure(q2[0], c2[0])
            try qc2.measure(q2[1], c2[1])
            let circuits = ["qc1", "qc2"]
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_local_qasm_simulator_two_registers")
            QP_program.execute(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 8458) { result in
            do {
                if let error = result.get_error() {
                    XCTFail("Failure in test_local_qasm_simulator_two_registers: \(error)")
                    asyncExpectation.fulfill()
                    return
                }
                let result1 = try result.get_counts("qc1")
                let result2 = try result.get_counts("qc2")
                XCTAssertEqual(result1, ["00 01": 1024])
                XCTAssertEqual(result2, ["10 00": 1024])
                asyncExpectation.fulfill()
            } catch {
                XCTFail("Failure in test_local_qasm_simulator_two_registers: \(error)")
                asyncExpectation.fulfill()
            }
            }

            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_local_qasm_simulator_two_registers")
            })
        } catch {
            XCTFail("test_local_qasm_simulator_two_registers: \(error)")
        }
    }

    func test_online_qasm_simulator_two_registers() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram()
            let q1 = try QP_program.create_quantum_register("q1", 2)
            let c1 = try QP_program.create_classical_register("c1", 2)
            let q2 = try QP_program.create_quantum_register("q2", 2)
            let c2 = try QP_program.create_classical_register("c2", 2)
            let qc1 = try QP_program.create_circuit("qc1", [q1, q2], [c1, c2])
            let qc2 = try QP_program.create_circuit("qc2", [q1, q2], [c1, c2])

            try qc1.x(q1[0])
            try qc2.x(q2[1])
            try qc1.measure(q1[0], c1[0])
            try qc1.measure(q1[1], c1[1])
            try qc1.measure(q2[0], c2[0])
            try qc1.measure(q2[1], c2[1])
            try qc2.measure(q1[0], c1[0])
            try qc2.measure(q1[1], c1[1])
            try qc2.measure(q2[0], c2[0])
            try qc2.measure(q2[1], c2[1])
            let circuits = ["qc1", "qc2"]
            let shots = 1024  // the number of shots in the experiment.
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_online_qasm_simulator_two_registers")
            QP_program.online_simulators()  { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_online_qasm_simulator_two_registers: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let backend = backends.first else {
                    XCTFail("Failure in test_online_qasm_simulator_two_registers: Missing backend.")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.execute(circuits,
                                   backend: backend,
                                   shots: shots,
                                   seed: 8458) { result in
                    do {
                        if let error = result.get_error() {
                            XCTFail("Failure in test_online_qasm_simulator_two_registers: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let result1 = try result.get_counts("qc1")
                        let result2 = try result.get_counts("qc2")
                        XCTAssertEqual(result1, ["00 01": 1024])
                        XCTAssertEqual(result2, ["10 00": 1024])
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_online_qasm_simulator_two_registers: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_online_qasm_simulator_two_registers")
            })
        } catch {
            XCTFail("test_online_qasm_simulator_two_registers: \(error)")
        }
    }

    //###############################################################
    //# More test cases for interesting examples
    //###############################################################

    func test_add_circuit() {
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 2)
            let cr = try QP_program.create_classical_register("cr", 2)
            let qc1 = try QP_program.create_circuit("qc1", [qr], [cr])
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc1.h(qr[0])
            try qc1.measure(qr[0], cr[0])
            try qc2.measure(qr[1], cr[1])
            let new_circuit = try qc1.combine(qc2)
            try QP_program.add_circuit("new_circuit", new_circuit)
            let circuits = ["new_circuit"]
            let backend = "local_qasm_simulator"  // the backend to run on
            let shots = 1024  // the number of shots in the experiment.
            let asyncExpectation = self.expectation(description: "test_add_circuit")
            QP_program.execute(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 78) { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_add_circuit: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    let c = try result.get_counts("new_circuit")
                    XCTAssertEqual(c,["00": 505, "01": 519])
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_add_circuit: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_add_circuit")
            })
        } catch {
            XCTFail("test_add_circuit: \(error)")
        }
    }

    func test_add_circuit_fail() {
        do {
            let QP_program = try QuantumProgram()
            let qr = try QP_program.create_quantum_register("qr", 1)
            let cr = try QP_program.create_classical_register("cr", 1)
            let q = try QP_program.create_quantum_register("q", 1)
            let c = try QP_program.create_classical_register("c", 1)
            let qc1 = try QP_program.create_circuit("qc1", [qr], [cr])
            let qc2 = try QP_program.create_circuit("qc2", [q], [c])
            try qc1.h(qr[0])
            try qc1.measure(qr[0], cr[0])
            try qc2.measure(q[0], c[0])
            XCTAssertThrowsError(try qc1.combine(qc2)) { (error) -> Void in
                switch error {
                case QISKitError.circuitsNotCompatible:
                    break
                default:
                    XCTFail("test_add_circuit_fail: \(error)")
                }
            }
        } catch {
            XCTFail("test_add_circuit_fail: \(error)")
        }
    }

    func test_example_multiple_compile() {
        do {
            let coupling_map = [0: [1, 2],
                                1: [2],
                                2: [],
                                3: [2, 4],
                                4: [2]]
            let QPS_SPECS = [
                "circuits": [[
                    "name": "ghz",
                    "quantum_registers": [[
                        "name": "q",
                        "size": 5
                    ]],
                    "classical_registers": [[
                        "name": "c",
                        "size": 5]
                    ]], [
                    "name": "bell",
                    "quantum_registers": [[
                        "name": "q",
                        "size": 5
                    ]],
                    "classical_registers": [[
                        "name": "c",
                        "size": 5
                    ]]]
                ]
            ]
            let qp = try QuantumProgram(specs: QPS_SPECS)
            let ghz = try qp.get_circuit("ghz")
            let bell = try qp.get_circuit("bell")
            let q = try qp.get_quantum_register("q")
            let c = try qp.get_classical_register("c")
            // Create a GHZ state
            try ghz.h(q[0])
            for i in 0..<4 {
                try ghz.cx(q[i], q[i+1])
            }
            // Insert a barrier before measurement
            try ghz.barrier()
            // Measure all of the qubits in the standard basis
            for i in 0..<5 {
                try ghz.measure(q[i], c[i])
            }
            // Create a Bell state
            try bell.h(q[0])
            try bell.cx(q[0], q[1])
            try bell.barrier()
            try bell.measure(q[0], c[0])
            try bell.measure(q[1], c[1])
            let asyncExpectation = self.expectation(description: "test_example_multiple_compile")
            qp.compile(["bell"],
                     backend:"local_qasm_simulator",
                     shots:2048,
                     seed:10) { (bellobj,error) in
                    if error != nil {
                        XCTFail("Failure in test_example_multiple_compile: \(error!)")
                        asyncExpectation.fulfill()
                        return
                    }
                    qp.compile(["ghz"],
                                backend:"local_qasm_simulator",
                                coupling_map: coupling_map,
                                shots:2048,
                                seed: 10) { (ghzobj,error) in
                        if error != nil {
                            XCTFail("Failure in test_example_multiple_compile: \(error!)")
                            asyncExpectation.fulfill()
                            return
                        }
                        qp.run_async(bellobj) { (bellresult) in
                            if let error = bellresult.get_error() {
                                XCTFail("Failure in test_example_multiple_compile: \(error)")
                                asyncExpectation.fulfill()
                                return
                            }
                            qp.run_async(ghzobj) { (ghzresult) in
                                do {
                                    if let error = ghzresult.get_error() {
                                        XCTFail("Failure in test_example_multiple_compile: \(error)")
                                        asyncExpectation.fulfill()
                                        return
                                    }
                                    let bell = try bellresult.get_counts("bell")
                                    SDKLogger.logInfo(bell)
                                    let ghz = try ghzresult.get_counts("ghz")
                                    SDKLogger.logInfo(ghz)
                                    XCTAssertEqual(bell,["00000": 1034, "00011": 1014])
                                    XCTAssertEqual(ghz,["00000": 1047, "11111": 1001])
                                    asyncExpectation.fulfill()
                                } catch {
                                    XCTFail("Failure in test_example_multiple_compile: \(error)")
                                    asyncExpectation.fulfill()
                                }
                            }
                        }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_example_multiple_compile")
            })
        } catch {
            XCTFail("test_example_multiple_compile: \(error)")
        }
    }

    func test_example_swap_bits() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let backend = "ibmqx_qasm_simulator"
            let coupling_map = [0: [1,  8], 1: [2, 9],  2: [3, 10], 3: [4, 11],
                                4: [5, 12], 5: [6, 13], 6: [7, 14], 7: [15],  8: [9],
                                9: [10],   10: [11],   11: [12],   12: [13], 13: [14], 14: [15]]

            func swap(_ qc: QuantumCircuit, _ q0: QuantumRegisterTuple, _ q1: QuantumRegisterTuple) throws {
                try qc.cx(q0, q1)
                try qc.cx(q1, q0)
                try qc.cx(q0, q1)
            }
            let n = 3  // make this at least 3
            let QPS_SPECS = [
                "circuits": [[
                    "name": "swapping",
                    "quantum_registers": [[
                        "name": "q",
                        "size": n],
                        ["name": "r",
                        "size": n]
                    ],
                    "classical_registers": [
                        ["name": "ans",
                        "size": 2*n],
                    ]
                ]]
            ]
            let qp = try QuantumProgram(specs: QPS_SPECS)
            qp.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_example_swap_bits")
            qp.online_simulators() { (backends,error) in
                do {
                    if error != nil {
                        XCTFail("Failure in test_example_swap_bits: \(error!.localizedDescription)")
                        asyncExpectation.fulfill()
                        return
                    }
                    if !backends.contains(backend) {
                        SDKLogger.logInfo("backend '\(backend)' not available")
                        asyncExpectation.fulfill()
                        return
                    }
                    let qc = try qp.get_circuit("swapping")
                    let q = try qp.get_quantum_register("q")
                    let r = try qp.get_quantum_register("r")
                    let ans = try qp.get_classical_register("ans")
                    // Set the first bit of q
                    try qc.x(q[0])
                    // Swap the set bit
                    try swap(qc, q[0], q[n-1])
                    try swap(qc, q[n-1], r[n-1])
                    try swap(qc, r[n-1], q[1])
                    try swap(qc, q[1], r[1])
                    // Insert a barrier before measurement
                    try qc.barrier()
                    // Measure all of the qubits in the standard basis
                    for j in 0..<n {
                        try qc.measure(q[j], ans[j])
                        try qc.measure(r[j], ans[j+n])
                    }
                    // First version: no mapping
                    qp.execute(["swapping"], backend:backend,
                               coupling_map: nil, shots:1024,
                               seed:14)  { result in
                        do {
                            if let error = result.get_error() {
                                XCTFail("Failure in test_example_swap_bits: \(error)")
                                asyncExpectation.fulfill()
                                return
                            }
                            let c = try result.get_counts("swapping")
                            XCTAssertEqual(c,["010000": 1024])
                            // Second version: map to coupling graph
                            qp.execute(["swapping"], backend:backend,
                                                coupling_map:coupling_map, shots:1024,
                                                seed:14) { result in
                                do {
                                    if let error = result.get_error() {
                                        XCTFail("Failure in test_example_swap_bits: \(error)")
                                        asyncExpectation.fulfill()
                                        return
                                    }
                                    let c = try result.get_counts("swapping")
                                    XCTAssertEqual(c,["010000": 1024])
                                    asyncExpectation.fulfill()
                                } catch {
                                    XCTFail("Failure in test_example_swap_bits: \(error)")
                                    asyncExpectation.fulfill()
                                }
                            }
                        } catch {
                            XCTFail("Failure in test_example_swap_bits: \(error)")
                            asyncExpectation.fulfill()
                        }
                    }
                } catch {
                    XCTFail("Failure in test_example_swap_bits: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_example_swap_bits")
            })
        } catch {
            XCTFail("test_example_swap_bits: \(error)")
        }
    }

    func test_offline() {
        do {
            let qp = try QuantumProgram()
            let FAKE_TOKEN = "thistokenisnotgoingtobesentnowhere"
            let FAKE_URL = "http://\(String.randomAlphanumeric(length: 63)).com"
            // SDK will throw ConnectionError on every call that implies a connection
            qp.set_api(token:FAKE_TOKEN, url:FAKE_URL)
            let asyncExpectation = self.expectation(description: "test_offline")
            qp.check_connection() { (e) in
                guard let error = e else {
                    XCTFail("test_offline should have failed to get connection")
                    asyncExpectation.fulfill()
                    return
                }
                switch error {
                case IBMQuantumExperienceError.internalError(_):
                    break
                default:
                    XCTFail("test_offline: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_offline")
            })
        } catch {
            XCTFail("test_offline: \(error)")
        }
    }

    func test_results_save_load() {
        do {
            let QP_program = try QuantumProgram()
            let metadata = ["testval":5]
            let q = try QP_program.create_quantum_register("q", 2)
            let c = try QP_program.create_classical_register("c", 2)
            let qc1 = try QP_program.create_circuit("qc1", [q], [c])
            let qc2 = try QP_program.create_circuit("qc2", [q], [c])
            try qc1.h(q)
            try qc2.cx(q[0], q[1])
            let circuits = ["qc1", "qc2"]
            let asyncExpectation = self.expectation(description: "test_results_save_load")
            QP_program.execute(circuits, backend:"local_unitary_simulator") { result1 in
                if let error = result1.get_error() {
                    XCTFail("Failure in test_results_save_load: \(error)")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.execute(circuits, backend:"local_qasm_simulator") { result2 in
                    do {
                        if let error = result2.get_error() {
                            XCTFail("Failure in test_results_save_load: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let test_1_path = self._get_resource_path("test_save_load1.json")
                        let test_2_path = self._get_resource_path("test_save_load2.json")

                        // delete these files if they exist
                        var url = URL(fileURLWithPath: test_1_path)
                        if FileManager.default.fileExists(atPath: url.path) {
                            try FileManager.default.removeItem(at: url)
                        }
                        url = URL(fileURLWithPath: test_2_path)
                        if FileManager.default.fileExists(atPath: url.path) {
                            try FileManager.default.removeItem(at: url)
                        }

                        let file1 = try FileIO.save_result_to_file(result1, test_1_path, metadata: metadata)
                        let file2 = try FileIO.save_result_to_file(result2, test_2_path, metadata: metadata)

                        let (_, metadata_loaded1) = try FileIO.load_result_from_file(file1)
                        let (_, metadata_loaded2) = try FileIO.load_result_from_file(file1)

                        // remove files to keep directory clean
                        try FileManager.default.removeItem(at: URL(fileURLWithPath: file1))
                        try FileManager.default.removeItem(at: URL(fileURLWithPath: file2))

                        guard let val1 = metadata_loaded1["testval"] as? Int else {
                            XCTFail("Failure in test_results_save_load. Invalid metadata_loaded1")
			                asyncExpectation.fulfill()
                            return
                        }
                        guard let val2 = metadata_loaded2["testval"] as? Int else {
                            XCTFail("Failure in test_results_save_load. Invalid metadata_loaded2")
			                asyncExpectation.fulfill()
                            return
                        }
                        XCTAssertEqual(val1,5)
                        XCTAssertEqual(val2,5)
                        asyncExpectation.fulfill()
                    } catch {
                        XCTFail("Failure in test_results_save_load: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_results_save_load")
            })
        } catch {
            XCTFail("test_results_save_load: \(error)")
        }
    }

    func test_qubitpol() {
        do {
            let QP_program = try QuantumProgram()
            let q = try QP_program.create_quantum_register("q", 2)
            let c = try QP_program.create_classical_register("c", 2)
            let qc1 = try QP_program.create_circuit("qc1", [q], [c])
            let qc2 = try QP_program.create_circuit("qc2", [q], [c])
            try qc2.x(q[0])
            try qc1.measure(q, c)
            try qc2.measure(q, c)
            let circuits = ["qc1", "qc2"]
            let xvals_dict = [circuits[0]: 0.0, circuits[1]: 1.0]
            let asyncExpectation = self.expectation(description: "test_qubitpol")
            QP_program.execute(circuits, backend: "local_qasm_simulator") { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_qubitpol: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    let (yvals, xvals) = try result.get_qubitpol_vs_xval(xvals_dict: xvals_dict)
                    XCTAssert(Matrix<Double>(value: yvals) == Matrix<Double>(value: [[-1.0,-1.0],[1.0,-1.0]]))
                    XCTAssert(xvals == [0.0,1.0])
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_qubitpol: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_qubitpol")
            })
        } catch {
            XCTFail("test_qubitpol: \(error)")
        }
    }

    func test_ccx() {
        do {
            let Q_program = try QuantumProgram()
            let q = try Q_program.create_quantum_register("q", 3)
            let c = try Q_program.create_classical_register("c", 3)
            let pqm = try Q_program.create_circuit("pqm", [q], [c])

            // Toffoli gate.
            try pqm.ccx(q[0], q[1], q[2])

            // Measurement.
            for k in 0..<3 {
                try pqm.measure(q[k], c[k])
            }
            // Prepare run.
            let circuits = ["pqm"]
            let backend = "local_qasm_simulator"
            let shots = 1024  // the number of shots in the experiment
            // Run.
            let asyncExpectation = self.expectation(description: "test_reconfig")
            Q_program.execute(circuits,
                               backend: backend,
                               wait: 10,
                               timeout: 240,
                               shots: shots,
                               max_credits: 3) { result in
                do {
                    if let error = result.get_error() {
                        XCTFail("Failure in test_ccx: \(error)")
                        asyncExpectation.fulfill()
                        return
                    }
                    let count = try result.get_counts("pqm")
                    XCTAssertEqual(count,["000": 1024])
                    asyncExpectation.fulfill()
                } catch {
                    XCTFail("Failure in test_ccx: \(error)")
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_ccx")
            })
        } catch {
            XCTFail("test_ccx: \(error)")
        }
    }

    func test_reconfig() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc2.measure(qr[0], cr[0])
            try qc2.measure(qr[1], cr[1])
            try qc2.measure(qr[2], cr[2])
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let test_config = ["0": 0, "1": 1]
            let asyncExpectation = self.expectation(description: "test_reconfig")
            QP_program.compile(["qc2"],
                               backend:backend,
                               config:test_config,
                               shots:shots) { (q,error) in
                if  error != nil {
                    XCTFail("Failure in test_reconfig: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                var qobj = q
                QP_program.run_async(qobj) { out in
                    do {
                        if let error = out.get_error() {
                            XCTFail("Failure in test_reconfig: \(error)")
                            asyncExpectation.fulfill()
                            return
                        }
                        let results = try out.get_counts("qc2")
                        // change the number of shots and re-run to test if the reconfig does not break
                        // the ability to run the qobj
                        qobj = QP_program.reconfig(qobj, shots: 2048)
                        QP_program.run_async(qobj) { out2 in
                            do {
                                if let error = out2.get_error() {
                                    XCTFail("Failure in test_reconfig: \(error)")
                                    asyncExpectation.fulfill()
                                    return
                                }
                                let results2 = try out2.get_counts("qc2")
                                XCTAssertEqual(results, ["000": 1024])
                                XCTAssertEqual(results2, ["000": 2048])

                                // change backend
                                qobj = QP_program.reconfig(qobj, backend: "local_unitary_simulator")
                                if let config = qobj["config"] as? [String:Any] {
                                    XCTAssertEqual(config["backend"] as? String, "local_unitary_simulator")
                                }
                                // change maxcredits
                                qobj = QP_program.reconfig(qobj, max_credits: 11)
                                if let config = qobj["config"] as? [String:Any] {
                                    XCTAssertEqual(config["max_credits"] as? Int, 11)
                                }
                                //change seed
                                qobj = QP_program.reconfig(qobj, seed: 11)
                                if let circuits = qobj["circuits"] as? [[String:Any]] {
                                    XCTAssertEqual(circuits[0]["seed"] as? Int, 11)
                                }
                                // change the config
                                let test_config_2 = ["0": 2]
                                qobj = QP_program.reconfig(qobj, config: test_config_2)
                                if let circuits = qobj["circuits"] as? [[String:Any]] {
                                    if let config = circuits[0]["config"] as? [String:Any] {
                                        XCTAssertEqual(config["0"] as? Int, 2)
                                        XCTAssertEqual(config["1"] as? Int, 1)
                                    }
                                }
                                asyncExpectation.fulfill()
                            } catch {
                                XCTFail("Failure in test_reconfig: \(error)")
                                asyncExpectation.fulfill()
                            }
                        }
                    } catch {
                        XCTFail("Failure in test_reconfig: \(error)")
                        asyncExpectation.fulfill()
                    }
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_reconfig")
            })
        } catch {
            XCTFail("test_reconfig: \(error)")
        }
    }

    func test_timeout() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc2.cx(qr[0], qr[2])
            try qc2.measure(qr, cr)
            let circuits = ["qc2"]
            let shots = 1024  // the number of shots in the experiment.
            let backend = "local_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_timeout")
            QP_program.compile(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 88) { (qobj,error) in
                if  error != nil {
                    XCTFail("Failure in test_timeout: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                QP_program.run_async(qobj, timeout: 0) { out in
                    guard let error = out.get_error() else {
                        XCTFail("test_timeout should have failed.")
                        asyncExpectation.fulfill()
                        return
                    }
                    switch error {
                    case QISKitError.jobTimeout(_):
                        SDKLogger.logInfo(error.localizedDescription)
                        break
                    default:
                        XCTFail("test_offline: \(error)")
                    }
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_timeout")
            })
        } catch {
            XCTFail("test_timeout: \(error)")
        }
    }

    func test_hpc_parameter_is_correct() {
        guard let token = self.QE_TOKEN else {
            print("Set environment variable QE_TOKEN to execute this method")
            return
        }
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try  qc2.cx(qr[0], qr[2])
            try qc2.measure(qr, cr)
            let circuits = ["qc2"]
            let shots = 1  // the number of shots in the experiment.
            let backend = "ibmqx_hpc_qasm_simulator"
            QP_program.set_api(token:token, url:QE_URL)
            let asyncExpectation = self.expectation(description: "test_hpc_parameter_is_correct")
            QP_program.compile(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 88,
                               hpc: ["multi_shot_optimization": true, "omp_num_threads": 16]) { (qobj,error) in
                if  error != nil {
                    XCTFail("Failure in test_hpc_parameter_is_correct: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(qobj.description)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_hpc_parameter_is_correct")
            })
        } catch {
            XCTFail("test_hpc_parameter_is_correct: \(error)")
        }
    }

    func test_hpc_parameter_is_incorrect() {
        do {
            let QP_program = try QuantumProgram(specs: self.QPS_SPECS)
            let qr = try QP_program.get_quantum_register("qname")
            let cr = try QP_program.get_classical_register("cname")
            let qc2 = try QP_program.create_circuit("qc2", [qr], [cr])
            try qc2.h(qr[0])
            try qc2.cx(qr[0], qr[1])
            try qc2.cx(qr[0], qr[2])
            try qc2.measure(qr, cr)
            let circuits = ["qc2"]
            let shots = 1  // the number of shots in the experiment.
            let backend = "ibmqx_hpc_qasm_simulator"
            let asyncExpectation = self.expectation(description: "test_hpc_parameter_is_incorrect")
            QP_program.compile(circuits,
                               backend: backend,
                               shots: shots,
                               seed: 88,
                               hpc: ["invalid_key": NSNull()]) { (qobj,error) in
                guard let e = error else {
                    XCTFail("test_hpc_parameter_is_incorrect should have failed.")
                    asyncExpectation.fulfill()
                    return
                }
                switch e {
                case QISKitError.unknownHPC:
                    SDKLogger.logInfo(e.localizedDescription)
                    break
                default:
                    XCTFail("test_hpc_parameter_is_incorrect: \(e)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_hpc_parameter_is_incorrect")
            })
        } catch {
            XCTFail("test_hpc_parameter_is_incorrect: \(error)")
        }
    }
}
