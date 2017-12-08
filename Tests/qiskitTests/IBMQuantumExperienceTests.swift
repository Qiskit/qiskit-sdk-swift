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

class IBMQuantumExperienceTests: XCTestCase {

    static let allTests = [
        ("test_api_auth_token",test_api_auth_token),
        ("test_api_get_my_credits",test_api_get_my_credits),
        ("test_api_auth_token_fail",test_api_auth_token_fail),
        ("test_api_last_codes",test_api_last_codes),
        ("test_api_run_experiment",test_api_run_experiment),
        ("test_api_run_experiment_with_seed",test_api_run_experiment_with_seed),
        ("test_api_run_experiment_fail_backend",test_api_run_experiment_fail_backend),
        ("test_api_run_job",test_api_run_job),
        ("test_api_run_job_fail_backend",test_api_run_job_fail_backend),
        ("test_api_get_jobs",test_api_get_jobs),
        ("test_api_backend_status",test_api_backend_status),
        ("test_api_backend_calibration",test_api_backend_calibration),
        ("test_api_backend_parameters",test_api_backend_parameters),
        ("test_api_backends_availables",test_api_backends_availables),
        ("test_api_backend_simulators_available",test_api_backend_simulators_available),
        ("test_register_size_limit_exception",test_register_size_limit_exception),
        ("test_qx_api_version",test_qx_api_version)
    ]

    private var QE_TOKEN: String? = nil
    private var QE_URL = Qconfig.BASEURL
    private var _api: IBMQuantumExperience? = nil
    private var qasm: String = ""
    private var qasms: [[String:String]] = []

    override func setUp() {
        super.setUp()
        let environment = ProcessInfo.processInfo.environment
        if let token = environment["QE_TOKEN"] {
            self.QE_TOKEN = token
        }
        if let url = environment["QE_URL"] {
            self.QE_URL = url
        }
        self.qasm = """
IBMQASM 2.0;
include "qelib1.inc";
qreg q[5];
creg c[5];
u2(-4*pi/3,2*pi) q[0];
u2(-3*pi/2,2*pi) q[0];
u3(-pi,0,-pi) q[0];
u3(-pi,0,-pi/2) q[0];
u2(pi,-pi/2) q[0];
u3(-pi,0,-pi/2) q[0];
measure q -> c;
"""
        self.qasms = [ ["qasm": qasm],
                     ["qasm": """
IBMQASM 2.0;

include "qelib1.inc";
qreg q[5];
creg c[3];
creg f[2];
x q[0];
measure q[0] -> c[0];
measure q[2] -> f[0];
"""]]
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func getAPI() throws -> IBMQuantumExperience? {
        if let api = self._api {
            return api
        }
        guard let token = self.QE_TOKEN else {
            return nil
        }
        self._api = try IBMQuantumExperience(token, Qconfig(url: self.QE_URL))
        return self._api
    }

    func test_api_auth_token() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_auth_token")
            api.check_connection() { (error) in
                if error != nil {
                    XCTFail("Failure in test_api_auth_token: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                let credential = api.check_credentials()
                XCTAssert(credential)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_auth_token_fail")
            })
        } catch {
            XCTFail("test_api_auth_token: \(error)")
        }
    }

    func test_api_get_my_credits() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_get_my_credits")
            api.get_my_credits() { (my_credits,error) in 
                if error != nil {
                    XCTFail("Failure in test_api_get_my_credits: \(error!)")
                    asyncExpectation.fulfill()
                    return
                }
                var check_credits: Int? = nil
                if let c = my_credits["remaining"] as? Int {
                    check_credits = c
                    SDKLogger.logInfo("\(c)")
                }
                XCTAssertNotNil(check_credits)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_get_my_credits")
            })
        } catch {
            XCTFail("test_api_get_my_credits: \(error)")
        }
    }

    func test_api_auth_token_fail() {
        do {
            let api = try IBMQuantumExperience()
            let asyncExpectation = self.expectation(description: "test_api_auth_token_fail")
            api.check_connection() { (e) in
                guard let error = e else {
                    XCTFail("test_api_auth_token_fail should have failed to get connection")
                    asyncExpectation.fulfill()
                    return
                }
                switch error {
                case IBMQuantumExperienceError.missingTokenId:
                    break
                default:
                    XCTFail("test_api_auth_token_fail: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_auth_token_fail")
            })
        } catch {
            XCTFail("test_api_auth_token_fail: \(error)")
        }
    }

    func test_api_last_codes() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_last_codes")
            api.get_last_codes() { (lastCodes,error) in
                if error != nil {
                    XCTFail("Failure in test_api_last_codes: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(lastCodes)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_last_codes")
            })
        } catch {
            XCTFail("test_api_last_codes: \(error)")
        }
    }

    func test_api_run_experiment() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_run_experiment")
            api.available_backend_simulators() { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_api_run_experiment: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let backend = backends.first?["name"] as? String else {
                    XCTFail("Failure in test_api_run_experiment: no backends.")
                    asyncExpectation.fulfill()
                    return
                }
                let shots = 1
                api.run_experiment(qasm: self.qasm, backend: backend, shots: shots) { (experiment,error) in
                    if error != nil {
                        XCTFail("Failure in test_api_run_experiment: \(error!.localizedDescription)")
                        asyncExpectation.fulfill()
                        return
                    }
                    var check_status: String? = nil
                    if let s = experiment["status"] as? String {
                        check_status = s
                        SDKLogger.logInfo("\(s)")
                    }
                    XCTAssertNotNil(check_status)
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_run_experiment")
            })
        } catch {
            XCTFail("test_api_run_experiment: \(error)")
        }
    }

    func test_api_run_experiment_with_seed() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_run_experiment_with_seed")
            api.available_backend_simulators() { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_api_run_experiment_with_seed: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let backend = backends.first?["name"] as? String else {
                    XCTFail("Failure in test_api_run_experiment_with_seed: no backends.")
                    asyncExpectation.fulfill()
                    return
                }
                let shots = 1
                let seed = 815
                api.run_experiment(qasm: self.qasm, backend: backend, shots: shots, seed: seed) { (experiment,error) in
                    if error != nil {
                        XCTFail("Failure in test_api_run_experiment_with_seed: \(error!.localizedDescription)")
                        asyncExpectation.fulfill()
                        return
                    }
                    guard let result = experiment["result"] as? [String:Any] else {
                        XCTFail("Failure in test_api_run_experiment_with_seed: no results.")
                        asyncExpectation.fulfill()
                        return
                    }
                    guard let extraInfo = result["extraInfo"] as? [String:Any] else {
                        XCTFail("Failure in test_api_run_experiment_with_seed: no extraInfo.")
                        asyncExpectation.fulfill()
                        return
                    }
                    guard let check_seed = extraInfo["seed"] as? Int else {
                        XCTFail("Failure in test_api_run_experiment_with_seed: no seed.")
                        asyncExpectation.fulfill()
                        return
                    }
                    XCTAssertEqual(seed,check_seed)
                    asyncExpectation.fulfill()
                }
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_run_experiment_with_seed")
            })
        } catch {
            XCTFail("test_api_run_experiment_with_seed: \(error)")
        }
    }

    func test_api_run_experiment_fail_backend() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let backend = "5qreal"
            let shots = 1
            let asyncExpectation = self.expectation(description: "test_api_run_experiment_fail_backend")
            api.run_experiment(qasm: self.qasm, backend: backend, shots: shots) { (experiment,e) in
                guard let error = e else {
                    XCTFail("test_api_run_experiment_fail_backend should have failed")
                    asyncExpectation.fulfill()
                    return
                }
                switch error {
                case IBMQuantumExperienceError.missingBackend(_):
                    break
                default:
                    XCTFail("test_api_run_experiment_fail_backend: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_run_experiment_fail_backend")
            })
        } catch {
            XCTFail("test_api_run_experiment_fail_backend: \(error)")
        }
    }

    func test_api_run_job() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let backend = "simulator"
            let shots = 1
            let asyncExpectation = self.expectation(description: "test_api_run_job")
            api.run_job(qasms: self.qasms, backend: backend, shots: shots) { (job,error) in
                if error != nil {
                    XCTFail("Failure in test_api_run_job: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                var check_status: String? = nil
                if let s = job["status"] as? String {
                    check_status = s
                    SDKLogger.logInfo("\(s)")
                }
                XCTAssertNotNil(check_status)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_run_job")
            })
        } catch {
            XCTFail("test_api_run_job: \(error)")
        }
    }

    func test_api_run_job_fail_backend() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let backend = "real5"
            let shots = 1
            let asyncExpectation = self.expectation(description: "test_api_run_job_fail_backend")
            api.run_job(qasms: self.qasms, backend: backend, shots: shots) { (experiment,e) in
                guard let error = e else {
                    XCTFail("test_api_run_job_fail_backend should have failed")
                    asyncExpectation.fulfill()
                    return
                }
                switch error {
                case IBMQuantumExperienceError.missingBackend(_):
                    break
                default:
                    XCTFail("test_api_run_job_fail_backend: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_run_job_fail_backend")
            })
        } catch {
            XCTFail("test_api_run_job_fail_backend: \(error)")
        }
    }

    func test_api_get_jobs() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_get_jobs")
            api.get_jobs(limit: 2) { (jobs,error) in
                if error != nil {
                    XCTFail("Failure in test_api_get_jobs: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                XCTAssert(jobs.count == 2)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_get_jobs")
            })
        } catch {
            XCTFail("test_api_get_jobs: \(error)")
        }
    }

    func test_api_backend_status() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_backend_status")
            api.backend_status() { (status,error) in
                if error != nil {
                    XCTFail("Failure in test_api_backend_status: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let available = status["available"] as? Bool else {
                    XCTFail("test_backend_status: Missing status.")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(available)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_backend_status")
            })
        } catch {
            XCTFail("test_api_backend_status: \(error)")
        }
    }

    func test_api_backend_calibration() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_backend_calibration")
            api.backend_calibration() { (calibration,error) in
                if error != nil {
                    XCTFail("Failure in test_api_backend_calibration: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(calibration)
                XCTAssert(!calibration.isEmpty)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_backend_status")
            })
        } catch {
            XCTFail("test_api_backend_calibration: \(error)")
        }
    }

    func test_api_backend_parameters() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_backend_parameters")
            api.backend_parameters() { (parameters,error) in
                if error != nil {
                    XCTFail("Failure in test_api_backend_parameters: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(parameters)
                XCTAssert(!parameters.isEmpty)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_backend_parameters")
            })
        } catch {
            XCTFail("test_api_backend_parameters: \(error)")
        }
    }

    func test_api_backends_availables() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_backends_availables")
            api.available_backends() { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_api_backends_availables: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(backends)
                XCTAssertGreaterThanOrEqual(backends.count,2)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_backends_availables")
            })
        } catch {
            XCTFail("test_api_backends_availables: \(error)")
        }
    }

    func test_api_backend_simulators_available() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_api_backend_simulators_available")
            api.available_backend_simulators() { (backends,error) in
                if error != nil {
                    XCTFail("Failure in test_api_backend_simulators_available: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(backends)
                XCTAssertGreaterThanOrEqual(backends.count,1)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_api_backend_simulators_available")
            })
        } catch {
            XCTFail("test_api_backend_simulators_available: \(error)")
        }
    }

    func test_register_size_limit_exception() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let backend = "simulator"
            let shots = 1
            let qasm = """
OPENQASM 2.0;
include "qelib1.inc";
qreg q[25];
creg c[25];
h q[0];
h q[24];
measure q[0] -> c[0];
measure q[24] -> c[24];
"""
            let asyncExpectation = self.expectation(description: "test_register_size_limit_exception")
            api.run_job(qasms: [["qasm":qasm]], backend: backend, shots: shots) { (experiment,e) in
                guard let error = e else {
                    XCTFail("test_register_size_limit_exception should have failed")
                    asyncExpectation.fulfill()
                    return
                }
                switch error {
                case IBMQuantumExperienceError.registerSizeError(_):
                    break
                default:
                    XCTFail("test_register_size_limit_exception: \(error)")
                }
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_register_size_limit_exception")
            })
        } catch {
            XCTFail("test_register_size_limit_exception: \(error)")
        }
    }

    func test_qx_api_version() {
        do {
            guard let api = try self.getAPI() else {
                return
            }
            let asyncExpectation = self.expectation(description: "test_qx_api_version")
            api.api_version() { (version,error) in
                if error != nil {
                    XCTFail("Failure in test_qx_api_version: \(error!.localizedDescription)")
                    asyncExpectation.fulfill()
                    return
                }
                SDKLogger.logInfo(version)
                let components = version.components(separatedBy: ".")
                guard let first = components.first else {
                    XCTFail("Failure in test_qx_api_version: \(version)")
                    asyncExpectation.fulfill()
                    return
                }
                guard let major = Int(first) else {
                    XCTFail("Failure in test_qx_api_version: \(version)")
                    asyncExpectation.fulfill()
                    return
                }
                XCTAssertGreaterThanOrEqual(major,4)
                asyncExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 180, handler: { (error) in
                XCTAssertNil(error, "Failure in test_register_size_limit_exception")
            })
        } catch {
            XCTFail("test_qx_api_version: \(error)")
        }
    }
}
