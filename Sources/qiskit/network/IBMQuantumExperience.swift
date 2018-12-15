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
#if os(Linux)
import Dispatch
#endif

/**
 The Connector Class to do request to QX Platform
 */
public final class IBMQuantumExperience {

    public static let URL_BASE = "https://quantumexperience.ng.bluemix.net/api/"
    private static let __names_backend_ibmqxv2 = Set<String>(["ibmqx5qv2", "ibmqx2", "qx5qv2", "qx5q", "real"])
    private static let __names_backend_ibmqxv3 = Set<String>(["ibmqx3"])
    private static let __names_backend_simulator = Set<String>(["simulator", "sim_trivial_2", "ibmqx_qasm_simulator"])

    public  let credentials: Credentials
    public var config: [String:Any] {
        get {
            return self.credentials.config
        }
        set {
            self.credentials.config = newValue
        }
    }
    private var request: Request? = nil

    /**
     Creates Quantum Experience object with a given configuration.

     - parameter token: API token
     - parameter config: Dictionary
     */
    public init(_ token: String? = nil, _ config: [String:Any]? = nil) {
        self.credentials = Credentials(token,config)
    }

    /**
     Util method to get job url
     */
    private static func get_job_url(_ config: [String:Any]?, _ hub: String?, _ group: String?, _ project: String?) -> String {
        var hubValue: String? = hub
        var groupValue: String? = group
        var projectValue: String? = project
        if let c = config {
            if hub == nil {
                if let h = c["hub"] as? String {
                    hubValue = h
                }
            }
            if group == nil {
                if let g = c["group"] as? String {
                    groupValue = g
                }
            }
            if project == nil {
                if let p = c["project"] as? String {
                    projectValue = p
                }
            }
        }
        if hubValue != nil && groupValue != nil && projectValue != nil {
            return "Network/\(hubValue!)/Groups/\(groupValue!)/Projects/\(projectValue!)/jobs"
        }
        return "Jobs"
    }

    /**
     Util method to get backend stats url
     */
    private static func get_backend_stats_url(_ config: [String:Any]?, _ hub: String?, _ backend_type: String) -> String {
        var hubValue: String? = hub
        if let c = config {
            if hub == nil {
                if let h = c["hub"] as? String {
                    hubValue = h
                }
            }
        }
        if hubValue != nil {
            return "/Network/\(hubValue!)/devices/\(backend_type)"
        }
        return "Backends/\(backend_type)"
    }

    /**
     Util method to get backend url
     */
    private static func get_backend_url(_ config: [String:Any]?, _ hub: String?, _ group: String?, _ project: String?) -> String {
        var hubValue: String? = hub
        var groupValue: String? = group
        var projectValue: String? = project
        if let c = config {
            if hub == nil {
                if let h = c["hub"] as? String {
                    hubValue = h
                }
            }
            if group == nil {
                if let g = c["group"] as? String {
                    groupValue = g
                }
            }
            if project == nil {
                if let p = c["project"] as? String {
                    projectValue = p
                }
            }
        }
        if hubValue != nil && groupValue != nil && projectValue != nil {
            return "Network/\(hubValue!)/Groups/\(groupValue!)/Projects/\(projectValue!)/devices"
        }
        return "Backends"
    }

    @discardableResult
    public func check_connection(_ responseHandler: @escaping ((_:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.check_connectionInternal() { (error) in
            DispatchQueue.main.async {
                responseHandler(error)
            }
        }
    }

    private func check_connectionInternal(_ responseHandler: @escaping ((_:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.getRequest() { (request,error) -> Void in
            responseHandler(error)
        }
    }

    private func getRequest(_ responseHandler: @escaping ((_:Request?, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        if let req = self.request {
            responseHandler(req,nil)
            return RequestTask()
        }
        do {
            let req = try Request(self.credentials)
            return req.initialize() { (request,error) -> Void in
                self.request = request
                responseHandler(self.request,error)
            }
        } catch {
            if let e = error as? IBMQuantumExperienceError {
                responseHandler(nil,e)
            }
            else {
                responseHandler(nil,IBMQuantumExperienceError.internalError(error: error))
            }
            return RequestTask()
        }
    }

    /**
     Check if the name of a backend is valid to run in QX Platform
     */
    private func _check_backend(_ back: String,
                                _ endpoint: String,
                                _ responseHandler: @escaping ((_:String?, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        // First check against hacks for old backend names
        let original_backend = back
        let backend = back.lowercased()
        var ret: String? = nil
        if endpoint == "experiment" {
            if IBMQuantumExperience.__names_backend_ibmqxv2.contains(backend) {
                ret = "real"
            }
            else if IBMQuantumExperience.__names_backend_ibmqxv3.contains(backend) {
                ret = "ibmqx3"
            }
            else if IBMQuantumExperience.__names_backend_simulator.contains(backend) {
                ret = "sim_trivial_2"
            }
        }
        else if endpoint == "job" {
            if IBMQuantumExperience.__names_backend_ibmqxv2.contains(backend) {
                ret = "ibmqx2"
            }
            else if IBMQuantumExperience.__names_backend_ibmqxv3.contains(backend) {
                ret = "ibmqx3"
            }
            else if IBMQuantumExperience.__names_backend_simulator.contains(backend) {
                ret = "simulator"
            }
        }
        else if endpoint == "status" {
            if IBMQuantumExperience.__names_backend_ibmqxv2.contains(backend) {
                ret = "ibmqx2"
            }
            else if IBMQuantumExperience.__names_backend_ibmqxv3.contains(backend) {
                ret = "ibmqx3"
            }
            else if IBMQuantumExperience.__names_backend_simulator.contains(backend) {
                ret = "ibmqx_qasm_simulator"
            }
        }
        else if endpoint == "calibration" {
            if IBMQuantumExperience.__names_backend_ibmqxv2.contains(backend) {
                ret = "ibmqx2"
            }
            else if IBMQuantumExperience.__names_backend_ibmqxv3.contains(backend) {
                ret = "ibmqx3"
            }
            else if IBMQuantumExperience.__names_backend_simulator.contains(backend) {
                ret = "ibmqx_qasm_simulator"
            }
        }
        if ret != nil {
            responseHandler(ret,nil)
            return RequestTask()
        }
        // Check for new-style backends
        return self.available_backends() { (backends,error) -> Void in
            if error != nil {
                responseHandler(nil,error)
                return
            }
            for backend in backends {
                guard let name = backend["name"] as? String else {
                    continue
                }
                if name != original_backend {
                    continue
                }
                if let simulator = backend["simulator"] as? Bool {
                    if simulator {
                        responseHandler("chip_simulator",nil)
                        return
                    }
                }
                responseHandler(original_backend,nil)
                return
            }
            // backend unrecognized
            responseHandler(nil,nil)
        }
    }

    /**
     Check if the user has permission in QX platform
     */
    public func check_credentials() -> Bool {
        if let req = self.request {
            return req.credentials.get_token() != nil
        }
        return false
    }

    /**
     Gets execution information. Asynchronous.

     - parameter idExecution: execution identifier
     - parameter responseHandler: Closure to be called upon completion
     */
    @discardableResult
    public func get_execution(id_execution: String,
                              access_token: String? = nil,
                              user_id: String? = nil,
                              responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_executionInternal(id_execution,
                                   access_token,
                                   user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func get_executionInternal(_ id_execution: String,
                                       _ access_token: String?,
                                       _ user_id: String?,
                                       _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "Executions/\(id_execution)") { (out, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                guard var execution = out as? [String:Any] else {
                    responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                guard let codeId = execution["codeId"] as? String else {
                    responseHandler(execution, error)
                    return
                }
                let r = self.get_code(id_code: codeId) { (code, error) -> Void in
                    if error != nil {
                        responseHandler([:], error)
                        return
                    }
                    execution["code"] = code
                    responseHandler(execution, error)
                }
                reqTask.add(r)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the result of a execution, byt the execution id
     */
    @discardableResult
    public func get_result_from_execution(id_execution: String,
                                          access_token: String? = nil,
                                          user_id: String? = nil,
                                          responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_result_from_executionInternal(id_execution,
                                                      access_token,
                                                      user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func get_result_from_executionInternal(_ id_execution: String,
                                                   _ access_token: String?,
                                                   _ user_id: String?,
                                                   _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "Executions/\(id_execution)") { (out, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                guard let execution = out as? [String:Any] else {
                    responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                var result: [String:Any] = [:]
                if let executionResult = execution["result"] as? [String:Any] {
                    if let data =  executionResult["data"] as? [String:Any] {
                        if let p = data["p"] {
                            result["measure"] = p
                        }
                        if let valsxyz = data["valsxyz"] {
                            result["bloch"] = valsxyz
                        }
                        if let additionalData = data["additionalData"] {
                            result["extraInfo"] = additionalData
                        }
                        if let calibration = execution["calibration"] {
                            result["calibration"] = calibration
                        }
                        if let cregLabels = data["cregLabels"] {
                            result["creg_labels"] = cregLabels
                        }
                        if let time = data["time"] {
                            result["time_taken"] = time
                        }
                    }
                }
                if let calibration = execution["calibration"] as? [String:Any] {
                    result["calibration"] = calibration
                }
                responseHandler(result, error)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get a code, by its id
     */
    @discardableResult
    public func get_code(id_code: String,
                         access_token: String? = nil,
                         user_id: String? = nil,
                         responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_codeInternal(id_code,
                                     access_token,
                                     user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func get_codeInternal(_ id_code: String,
                                  _ access_token: String?,
                                  _ user_id: String?,
                                  _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "Codes/\(id_code)") { (out, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                guard var code = out as? [String:Any] else {
                    responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                let r = req!.get(path:"Codes/\(id_code)/executions",
                            params:"filter={\"limit\":3}") { (executions, error) -> Void in
                    if error != nil {
                        responseHandler([:], error)
                        return
                    }
                    code["executions"] = executions
                    responseHandler(code, error)
                }
                reqTask.add(r)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the image of a code, by its id
     */
    @discardableResult
    public func get_image_code(id_code: String,
                               access_token: String? = nil,
                               user_id: String? = nil,
                               responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_image_codeInternal(id_code,
                                           access_token,
                                           user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func get_image_codeInternal(_ id_code: String,
                                        _ access_token: String?,
                                        _ user_id: String?,
                                        _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "Codes/\(id_code)/export/png/url") { (out, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                guard let image = out as? [String:Any] else {
                    responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                responseHandler(image, error)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the last codes of the user
     */
    @discardableResult
    public func get_last_codes(access_token: String? = nil,
                               user_id: String? = nil,
                               responseHandler: @escaping ((_:[String], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_last_codesInternal(access_token,
                                           user_id) { (res,error) in
                DispatchQueue.main.async {
                    responseHandler(res,error)
                }
        }
    }

    private func get_last_codesInternal(_ access_token: String?,
                                        _ user_id: String?,
                                        _ responseHandler: @escaping ((_:[String], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "users/\(req!.credentials.get_user_id()!)/codes/latest",
                         params: "&includeExecutions=true") { (out, error) -> Void in
                if error != nil {
                    responseHandler([], error)
                    return
                }
                guard let result = out as? [String:Any] else {
                    responseHandler([],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                if let codes = result["codes"] as? [String] {
                    responseHandler(codes, error)
                }
                else {
                    responseHandler([],IBMQuantumExperienceError.invalidResponseData)
                }
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Execute and experiment
     */
    @discardableResult
    public func run_experiment(qasm: String,
                               backend: String = "simulator",
                               shots: Int = 1,
                               name: String? = nil,
                               seed: Int? = nil,
                               timeout: Int = 60,
                               access_token: String? = nil,
                               user_id: String? = nil,
                               responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.run_experimentInternal(qasm,
                                           backend,
                                           shots,
                                           name,
                                           seed,
                                           timeout,
                                           access_token,
                                           user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func run_experimentInternal(_ qasm: String,
                                        _ backend: String,
                                        _ shots: Int,
                                        _ name: String?,
                                        _ seed: Int?,
                                        _ timeout: Int,
                                        _ access_token: String?,
                                        _ user_id: String?,
                                        _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = self._check_backend(backend, "experiment") { (backend_type,error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                if backend_type == nil {
                    responseHandler([:],IBMQuantumExperienceError.missingBackend(backend: backend))
                    return
                }
                if !IBMQuantumExperience.__names_backend_simulator.contains(backend) && seed != nil {
                    responseHandler([:],IBMQuantumExperienceError.errorSeed(backend: backend))
                    return
                }
                var data: [String : Any] = [:]
                if let n = name {
                    data["name"] = n
                } else {
                    let date = Date()
                    let calendar = Calendar.current
                    let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                    data["name"] = "Experiment #\(c.year!)\(c.month!)\(c.day!)\(c.hour!)\(c.minute!)\(c.second!))"

                }
                data["qasm"] = qasm.replacingOccurrences(of: "IBMQASM 2.0;", with: "").replacingOccurrences(of: "OPENQASM 2.0;", with: "")
                data["codeType"] = "QASM2"

                if seed != nil {
                    if String(seed!).count >= 11 {
                        responseHandler([:],IBMQuantumExperienceError.errorSeedLength)
                        return
                    }
                    let r = req!.post(path: "codes/execute",
                                  params: "&shots=\(shots)&seed=\(seed!)&deviceRunType=\(backend_type!)",
                    data: data) { (out, error) -> Void in
                        if error != nil {
                            responseHandler([:], error)
                            return
                        }
                        guard let execution = out as? [String:Any] else {
                            responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                            return
                        }
                        let r = self.post_run_experiment(execution: execution,
                                                 error: error,
                                                 timeout: timeout,
                                                 access_token: access_token,
                                                 user_id: user_id,
                                                 responseHandler: responseHandler)
                        reqTask.add(r)
                    }
                    reqTask.add(r)
                }
                else {
                    let r = req!.post(path: "codes/execute",
                                  params: "&shots=\(shots)&deviceRunType=\(backend_type!)",
                    data: data) { (out, error) -> Void in
                        if error != nil {
                            responseHandler([:], error)
                            return
                        }
                        guard let execution = out as? [String:Any] else {
                            responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                            return
                        }
                        let r = self.post_run_experiment(execution: execution,
                                                 error: error,
                                                 timeout: timeout,
                                                 access_token: access_token,
                                                 user_id: user_id,
                                                 responseHandler: responseHandler)
                        reqTask.add(r)
                    }
                    reqTask.add(r)
                }
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    private func post_run_experiment(execution: [String:Any],
                                     error:IBMQuantumExperienceError?,
                                     timeout: Int,
                                     access_token: String?,
                                     user_id: String?,
                                     responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        if error != nil {
            responseHandler([:], error)
            return RequestTask()
        }
        var respond: [String:Any] = [:]
        guard let statusMap = execution["status"] as? [String:Any] else {
            responseHandler([:], IBMQuantumExperienceError.missingStatus)
            return RequestTask()
        }
        guard let status = statusMap["id"] as? String else {
            responseHandler([:], IBMQuantumExperienceError.missingStatus)
            return RequestTask()
        }
        guard let id_execution = execution["id"] as? String else {
            responseHandler([:], IBMQuantumExperienceError.missingExecutionId)
            return RequestTask()
        }
        var result: [String:Any] = [:]
        respond["status"] = status
        respond["idExecution"] = id_execution
        respond["idCode"] = execution["codeId"]
        if let infoQueue = execution["infoQueue"] as? [String:Any] {
            respond["infoQueue"] = infoQueue
        }
        if status == "DONE" {
            if let executionResult = execution["result"] as? [String:Any] {
                if let data =  executionResult["data"] as? [String:Any] {
                    if let additionalData = data["additionalData"] {
                        result["extraInfo"] = additionalData
                    }
                    if let p = data["p"] {
                        result["measure"] = p
                    }
                    if let valsxyz = data["valsxyz"] {
                        result["bloch"] = valsxyz
                    }
                    respond["result"] = result
                    respond.removeValue(forKey: "infoQueue")
                }
            }
            responseHandler(respond, nil)
            return RequestTask()
        }
        if status == "ERROR" {
            respond.removeValue(forKey: "infoQueue")
            responseHandler(respond, nil)
            return RequestTask()
        }
        return self.getCompleteResultFromExecution(id_execution: id_execution,
                                            timeOut: ((timeout > 300) ? 300 : timeout),
                                            access_token: access_token,
                                            user_id: user_id) { (result, error) in
            if error != nil {
                responseHandler([:], error)
                return
            }
            respond["status"] = "DONE"
            respond["result"] = result
            if let calibration = result["calibration"] {
                respond["calibration"] = calibration
            }
            respond.removeValue(forKey: "infoQueue")
            responseHandler(respond, error)
        }
    }

    private func getCompleteResultFromExecution(id_execution: String,
                                                timeOut: Int,
                                                access_token: String?,
                                                user_id: String?,
                                                responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            let r = self.get_result_from_execution(id_execution: id_execution,
                                           access_token: access_token,
                                           user_id: user_id) { (execution, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                if timeOut <= 0 {
                    responseHandler(execution, error)
                }
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
                    let r = self.getCompleteResultFromExecution(id_execution: id_execution,
                                                        timeOut: timeOut-1,
                                                        access_token: access_token,
                                                        user_id: user_id,
                                                        responseHandler: responseHandler)
                    reqTask.add(r)
                }
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Executes a job. Asynchronous.
     */
    @discardableResult
    public func run_job(qasms: [[String:Any]],
                        backend: String = "simulator",
                        shots: Int = 1,
                        maxCredits: Int? = nil,
                        seed: Int? = nil,
                        hub: String? = nil,
                        group: String? = nil,
                        project: String? = nil,
                        hpc: [String:Any]? = nil,
                        access_token: String? = nil,
                        user_id: String? = nil,
                        responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.run_jobInternal(qasms: qasms,
                                    backend: backend,
                                    shots: shots,
                                    maxCredits: maxCredits,
                                    seed: seed,
                                    hub: hub,
                                    group: group,
                                    project: project,
                                    hpc: hpc,
                                    access_token: access_token,
                                    user_id: user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    func run_jobInternal(qasms: [[String:Any]],
                         backend: String,
                         shots: Int,
                         maxCredits: Int?,
                         seed: Int?,
                         hub: String?,
                         group: String?,
                         project: String?,
                         hpc: [String:Any]?,
                         access_token: String?,
                         user_id: String?,
                         responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            var data: [String : Any] = [:]
            var qasmArray: [[String:Any]] = []
            for var dict in qasms {
                if var value = dict["qasm"] as? String {
                    value = value.replacingOccurrences(of: "IBMQASM 2.0;", with: "")
                    dict["qasm"] = value.replacingOccurrences(of: "OPENQASM 2.0;", with: "")
                }
                qasmArray.append(dict)
            }
            data["qasms"] = qasmArray
            data["shots"] = shots
            if let c = maxCredits {
                data["maxCredits"] = c
            }
            if let h = hpc {
                data["hpc"] = h
            }
            let r = self._check_backend(backend, "job") { (backend_type,error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                if backend_type == nil {
                    responseHandler([:],IBMQuantumExperienceError.missingBackend(backend: backend))
                    return
                }
                if !IBMQuantumExperience.__names_backend_simulator.contains(backend) && seed != nil {
                    responseHandler([:],IBMQuantumExperienceError.errorSeed(backend: backend))
                    return
                }
                if seed != nil {
                    if String(seed!).count >= 11 {
                        responseHandler([:],IBMQuantumExperienceError.errorSeedLength)
                        return
                    }
                    data["seed"] = seed!
                }
                var backendDict: [String:String] = [:]
                backendDict["name"] = backend_type!
                data["backend"] = backendDict

                let path = IBMQuantumExperience.get_job_url(self.config, hub, group, project)
                let r = req!.post(path: path, data: data) { (out, error) -> Void in
                    if error != nil {
                        responseHandler([:], error)
                        return
                    }
                    guard let json = out as? [String:Any] else {
                        responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                        return
                    }
                    responseHandler(json, error)
                }
                reqTask.add(r)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Gets job information. Asynchronous.

     - parameter jobId: job identifier
     - parameter responseHandler: Closure to be called upon completion
     */
    @discardableResult
    public func get_job(jobId: String,
                        hub: String? = nil,
                        group: String? = nil,
                        project: String? = nil,
                        access_token: String? = nil,
                        user_id: String? = nil,
                        responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_jobInternal(jobId: jobId,
                                    hub: hub,
                                    group: group,
                                    project: project,
                                    access_token: access_token,
                                    user_id: user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    func get_jobInternal(jobId: String,
                         hub: String?,
                         group: String?,
                         project: String?,
                         access_token: String?,
                         user_id: String?,
                         responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let path = IBMQuantumExperience.get_job_url(self.config, hub, group, project)
            let r = req!.get(path: "\(path)/\(jobId)") { (out, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                guard var job = out as? [String:Any] else {
                    responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                // To remove result object and add the attributes to data object
                if let qasms = job["qasms"] as? [[String:Any]] {
                    var new_qasms: [[String:Any]] = []
                    for qasm in qasms {
                        var new_qasm = qasm
                        if var result = new_qasm["result"] as? [String:Any] {
                            if var data = result["data"] as? [String:Any] {
                                new_qasm.removeValue(forKey:"result")
                                result.removeValue(forKey:"data")
                                for (key,value) in result {
                                    data[key] = value
                                }
                                new_qasm["data"] = data
                            }
                        }
                        new_qasms.append(new_qasm)
                    }
                    job["qasms"] = new_qasms
                }
                responseHandler(job, error)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Gets jobs information. Asynchronous.
     -limit: max result
     - parameter responseHandler: Closure to be called upon completion
     */
    @discardableResult
    public func get_jobs(limit: Int = 50,
                         access_token: String? = nil,
                         user_id: String? = nil,
                         responseHandler: @escaping ((_:[[String:Any]], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_jobsInternal(limit,
                                     access_token,
                                     user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func get_jobsInternal(_ limit: Int,
                                  _ access_token: String?,
                                  _ user_id: String?,
                                  _ responseHandler: @escaping ((_:[[String:Any]], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "Jobs", params: "&filter={\"limit\":\(limit)}") { (out, error) -> Void in
                if error != nil {
                    responseHandler([], error)
                    return
                }
                guard let json = out as? [[String:Any]] else {
                    responseHandler([],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                responseHandler(json, error)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the status of a chip
     */
    @discardableResult
    public func backend_status(backend: String = "ibmqx4",
                               access_token: String? = nil,
                               user_id: String? = nil,
                               responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.backend_statusInternal(backend,
                                           access_token,
                                           user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func backend_statusInternal(_ backend: String,
                                        _ access_token: String?,
                                        _ user_id: String?,
                                        _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self._check_backend(backend, "status") { (backend_type,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if backend_type == nil {
                responseHandler([:],IBMQuantumExperienceError.missingBackend(backend: backend))
                return
            }
            let r = self.getRequest() { (req,error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                let r = req!.get(path:"Backends/\(backend_type!)/queue/status",with_token: false) { (out, error) -> Void in
                    if error != nil {
                        responseHandler([:], error)
                        return
                    }
                    guard let status = out as? [String:Any] else {
                        responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                        return
                    }
                    var ret: [String:Any] = [:]
                    if let state = status["state"] as? Bool {
                        ret["available"] = state
                    }
                    if let busy = status["busy"] as? Bool {
                        ret["busy"] = busy
                    }
                    if let lengthQueue = status["lengthQueue"] {
                        ret["pending_jobs"] = lengthQueue
                    }
                    ret["backend"] = backend_type!
                    responseHandler(ret, error)
                }
                reqTask.add(r)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the calibration of a real chip
     */
    @discardableResult
    public func backend_calibration(backend: String = "ibmqx4",
                                    hub: String? = nil,
                                    access_token: String? = nil,
                                    user_id: String? = nil,
                                    responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.backend_calibrationInternal(backend,
                                                hub,
                                                access_token,
                                                user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func backend_calibrationInternal(_ backend: String,
                                             _ hub: String?,
                                             _ access_token: String?,
                                             _ user_id: String?,
                                             _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = self._check_backend(backend, "calibration") { (backend_type,error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                if backend_type == nil {
                    responseHandler([:],IBMQuantumExperienceError.missingBackend(backend: backend))
                    return
                }
                if IBMQuantumExperience.__names_backend_simulator.contains(backend_type!) {
                    responseHandler(["backend" : backend_type!],nil)
                    return
                }
                let path = IBMQuantumExperience.get_backend_stats_url(self.config, hub, backend_type!)
                let r = req!.get(path:"\(path)/calibration") { (out, error) -> Void in
                    if error != nil {
                        responseHandler([:], error)
                        return
                    }
                    guard var ret = out as? [String:Any] else {
                        responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                        return
                    }
                    ret["backend"] = backend_type!
                    responseHandler(ret,error)
                }
                reqTask.add(r)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the parameters of calibration of a real chip
     */
    @discardableResult
    public func backend_parameters(backend: String = "ibmqx4",
                                   hub: String? = nil,
                                   access_token: String? = nil,
                                   user_id: String? = nil,
                                   responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.backend_parametersInternal(backend,
                                               hub,
                                               access_token,
                                               user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func backend_parametersInternal(_ backend: String,
                                            _ hub: String?,
                                            _ access_token: String?,
                                            _ user_id: String?,
                                            _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = self._check_backend(backend, "calibration") { (backend_type,error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                if backend_type == nil {
                    responseHandler([:],IBMQuantumExperienceError.missingBackend(backend: backend))
                    return
                }
                if IBMQuantumExperience.__names_backend_simulator.contains(backend_type!) {
                    responseHandler(["backend" : backend_type!],nil)
                    return
                }
                let path = IBMQuantumExperience.get_backend_stats_url(self.config, hub, backend_type!)
                let r = req!.get(path:"\(path)/parameters") { (out, error) -> Void in
                    if error != nil {
                        responseHandler([:], error)
                        return
                    }
                    guard var ret = out as? [String:Any] else {
                        responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                        return
                    }
                    ret["backend"] = backend_type!
                    responseHandler(ret,error)
                }
                reqTask.add(r)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the backends availables to use in the QX Platform
     */
    @discardableResult
    public func available_backends(access_token: String? = nil,
                                   hub: String? = nil,
                                   group: String? = nil,
                                   project: String? = nil,
                                   user_id: String? = nil,
                                   responseHandler: @escaping ((_:[[String:Any]], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.available_backendsInternal(access_token,
                                               hub,
                                               group,
                                               project,
                                               user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func available_backendsInternal(_ access_token: String?,
                                            _ hub: String?,
                                            _ group: String?,
                                            _ project: String?,
                                            _ user_id: String?,
                                            _ responseHandler: @escaping ((_:[[String:Any]], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let path = IBMQuantumExperience.get_backend_url(self.config, hub, group, project)
            let r = req!.get(path: path) { (out, error) -> Void in
                if error != nil {
                    responseHandler([], error)
                    return
                }
                guard let backends = out as? [[String:Any]] else {
                    responseHandler([],IBMQuantumExperienceError.missingBackends)
                    return
                }
                var ret: [[String:Any]] = []
                for backend in backends {
                    if let status = backend["status"] as? String {
                        if "on" == status {
                            ret.append(backend)
                        }
                    }
                }
                responseHandler(ret, nil)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the backend simulators available to use in the QX Platform
     */
    @discardableResult
    public func available_backend_simulators(access_token: String? = nil,
                                             user_id: String? = nil,
                                             responseHandler: @escaping ((_:[[String:Any]], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.available_backend_simulatorsInternal(access_token,
                                                         user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func available_backend_simulatorsInternal(_ access_token: String?,
                                                      _ user_id: String? = nil,
                                                      _ responseHandler: @escaping ((_:[[String:Any]], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.available_backends(access_token: access_token,
                                user_id: user_id) { (backends,error) -> Void in
            if error != nil {
                responseHandler([], error)
                return
            }
            var ret: [[String:Any]] = []
            for backend in backends {
                if let simulator = backend["simulator"] as? Bool {
                    if simulator {
                        ret.append(backend)
                    }
                }
            }
            responseHandler(ret, nil)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the the credits by user to use in the QX Platform
     */
    @discardableResult
    public func get_my_credits(access_token: String? = nil,
                               user_id: String? = nil,
                               responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.get_my_creditsInternal(access_token,
                                           user_id) { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    public func get_my_creditsInternal(_ access_token: String?,
                                       _ user_id: String?,
                                       _ responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler([:], error)
                return
            }
            if let token = access_token {
                req!.credentials.set_token(token)
            }
            if let user = user_id {
                req!.credentials.set_user_id(user)
            }
            if !self.check_credentials() {
                responseHandler([:],IBMQuantumExperienceError.invalidCredentials)
                return
            }
            let r = req!.get(path: "users/\(req!.credentials.get_user_id()!)") { (out, error) -> Void in
                if error != nil {
                    responseHandler([:], error)
                    return
                }
                guard let user_data = out as? [String:Any] else {
                    responseHandler([:],IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                if var credit = user_data["credit"] as? [String:Any] {
                    if credit["promotionalCodesUsed"] != nil {
                        credit.removeValue(forKey: "promotionalCodesUsed")
                    }
                    if credit["lastRefill"] != nil {
                        credit.removeValue(forKey: "lastRefill")
                    }
                    responseHandler(credit,nil)
                    return
                }
                responseHandler([:], nil)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Get the API Version of the QX Platform
     */
    @discardableResult
    public func api_version(responseHandler: @escaping ((_:String, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.api_versionInternal() { (res,error) in
            DispatchQueue.main.async {
                responseHandler(res,error)
            }
        }
    }

    private func api_versionInternal(_ responseHandler: @escaping ((_:String, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.getRequest() { (req,error) -> Void in
            if error != nil {
                responseHandler("", error)
                return
            }
            let r = req!.get(path: "version") { (out, error) -> Void in
                if error != nil {
                    responseHandler("", error)
                    return
                }
                guard let version = out as? String else {
                    responseHandler("",IBMQuantumExperienceError.invalidResponseData)
                    return
                }
                responseHandler(version, nil)
            }
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }
}
