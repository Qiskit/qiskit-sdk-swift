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
Quantum Program Class.

Class internal properties.

    Elements that are not python identifiers or string constants are denoted
    by "--description (type)--". For example, a circuit's name is denoted by
    "--circuit name (string)--" and might have the value "teleport".

    Internal::

        __quantum_registers (list[dic]): An dictionary of quantum registers
            used in the quantum program.
            __quantum_registers =
                {
                    --register name (string)--: QuantumRegistor,
                }
        __classical_registers (list[dic]): An ordered list of classical registers
            used in the quantum program.
            __classical_registers =
                {
                    --register name (string)--: ClassicalRegistor,
                }
        __quantum_program (dic): An dictionary of quantum circuits
            __quantum_program =
                {
                    --circuit name (string)--:  --circuit object --,
                }
        __init_circuit (obj): A quantum circuit object for the initial quantum
            circuit
        __ONLINE_BACKENDS (list[str]): A list of online backends
        __LOCAL_BACKENDS (list[str]): A list of local backends
 */


//# -- FUTURE IMPROVEMENTS --
//# TODO: for status results make ALL_CAPS (check) or some unified method
//# TODO: Jay: coupling_map, basis_gates will move into a config object
//# only exists once you set the api to use the online backends

public final class QuantumProgram: CustomStringConvertible {

    final class JobProcessorData {
        let jobProcessor: JobProcessor
        let callbackSingle: ((_:Result) -> Void)?
        let callbackMultiple: ((_:[Result]) -> Void)?

        init(_ jobProcessor: JobProcessor,
            _ callbackSingle: ((_:Result) -> Void)?,
            _ callbackMultiple: ((_:[Result]) -> Void)?) {
            self.jobProcessor = jobProcessor
            self.callbackSingle = callbackSingle
            self.callbackMultiple = callbackMultiple
        }
    }

    private let lock = NSRecursiveLock()
    private var jobProcessors: [String: JobProcessorData] = [:]

    /**
     only exists once you set the api to use the online backends
     */
    private var __api_config: [String:Any] = [:]

    private var __quantum_registers:   OrderedDictionary<String,QuantumRegister> = OrderedDictionary<String,QuantumRegister>()
    private var __classical_registers: OrderedDictionary<String,ClassicalRegister> = OrderedDictionary<String,ClassicalRegister>()
    /**
     stores all the quantum programs
     */
    private var __quantum_program: OrderedDictionary<String,QuantumCircuit> = OrderedDictionary<String,QuantumCircuit>()
    /**
     stores the intial quantum circuit of the program
     */
    private var __init_circuit: QuantumCircuit? = nil

    private let backendUtils : BackendUtils = BackendUtils()

    static private func convert(_ name: String) throws -> String {
        do {
            let first_cap_re = try NSRegularExpression(pattern:"(.)([A-Z][a-z]+)")
            let s1 = first_cap_re.stringByReplacingMatches(in: name,
                                                           options: [],
                                                           range:  NSMakeRange(0, name.count),
                                                           withTemplate: "$1_$2")
            let all_cap_re = try NSRegularExpression(pattern:"([a-z0-9])([A-Z])")
            return all_cap_re.stringByReplacingMatches(in: s1,
                                                       options: [],
                                                       range: NSMakeRange(0, s1.count),
                                                       withTemplate: "$1_$2").lowercased()
        } catch {
            throw QISKitError.internalError(error: error)
        }
    }

    public var description: String {
        do {
            let (contents,_) = try self.getSaveElements(true)
            return contents
        } catch {
            return error.localizedDescription
        }
    }

    public init(specs: [String:Any]? = nil) throws {
        self.__quantum_program = [:]
        if let s = specs {
            try self.__init_specs(s)
        }
    }

    /**
     Populate the Quantum Program Object with initial Specs

     Args:
         specs (dict):
             Q_SPECS = {
                 "circuits": [{
                     "name": "Circuit",
                     "quantum_registers": [{
                        "name": "qr",
                        "size": 4
                     }],
                     "classical_registers": [{
                        "name": "cr",
                        "size": 4
                     }]
                 }],

     Returns:
        Sets up a quantum circuit.
     */
    private func __init_specs(_ specs:[String: Any]) throws {
        var quantumr:[QuantumRegister] = []
        var classicalr:[ClassicalRegister] = []
        if let circuits = specs["circuits"] as? [Any] {
            for circ in circuits {
                if let circuit = circ as? [String:Any] {
                    if let qregs = circuit["quantum_registers"] as? [[String:Any]] {
                        quantumr = try self.create_quantum_registers(qregs)
                    }
                    if let cregs = circuit["classical_registers"] as? [[String:Any]] {
                        classicalr = try self.create_classical_registers(cregs)
                    }
                    var name: String = "name"
                    if let n = circuit["name"] as? String {
                        name = n
                    }
                    try self.create_circuit(name,quantumr,classicalr)
                }
            }
            // TODO: Jay: I think we should return function handles for the registers
            // and circuit. So that we dont need to get them after we create them
            // with get_quantum_register etc
        }
    }

    /**
     Create a new Quantum Register.

     Args:
        name (str): the name of the quantum register
        size (int): the size of the quantum register

     Returns:
        internal reference to a quantum register in __quantum_registers
     */
    @discardableResult
    public func create_quantum_register(_ name: String, _ size: Int) throws -> QuantumRegister {
        if let register = self.__quantum_registers[name] {
            if size != register.size {
                throw QISKitError.registerSize
            }
            SDKLogger.logInfo(">> quantum_register exists:\(name) \(size)")
        }
        else {
            SDKLogger.logInfo(">> new quantum_register created: \(name) \(size)")
            try self.__quantum_registers[name] = QuantumRegister(name, size)
        }
        return self.__quantum_registers[name]!
    }

    /**
     Destroy an existing Quantum Register.

     Args:
        name (str): the name of the quantum register

     Raises:
        QISKitError: if the register does not exist in the program.
     */
    public func destroy_quantum_register(_ name: String) throws {
        if self.__quantum_registers[name] == nil {
            throw QISKitError.regNotExists(name: name)
        }
        self.__quantum_registers[name] = nil
        SDKLogger.logInfo(">> quantum register destroyed: '\(name)'")
    }

    /**
     Create a new set of Quantum Registers based on a array of them.

     Args:
        register_array (list[dict]): An array of quantum registers in
        dictionay format::

             "quantum_registers": [
                 {
                    "name": "qr",
                    "size": 4
                 },
                 ...
             ]
        Returns:
            Array of quantum registers objects
     */
    @discardableResult
    public func create_quantum_registers(_ register_array: [[String: Any]]) throws -> [QuantumRegister] {
        var new_registers: [QuantumRegister] = []
        for register in register_array {
            guard let name = register["name"] as? String else {
                continue
            }
            guard let size = register["size"] as? Int else {
                continue
            }
            new_registers.append(try self.create_quantum_register(name,size))
        }
        return new_registers
    }

    /**
     Destroy a set of Quantum Registers based on a array of them.

     Args:
        register_array (list[dict]): An array of quantum registers in
             dictionay format::

                 "quantum_registers": [
                     {
                     "name": "qr",
                     },
                     ...
                 ]
                "size" may be a key for compatibility, but is ignored.
     */
    public func destroy_quantum_registers(_ register_array: [String:Any]) throws {
        guard let registers = register_array["quantum_registers"] as? [[String:Any]] else {
            return
        }
        for register in registers {
            if let name = register["name"] as? String {
                try self.destroy_quantum_register(name)
            }
        }
    }

    /**
     Create a new Classical Register.

     Args:
        name (str): the name of the Classical register
        size (int): the size of the Classical register

     Returns:
        internal reference to a Classical register in __classical_registers
     */
    @discardableResult
    public func create_classical_register(_ name: String, _ size: Int) throws -> ClassicalRegister {
        if let register = self.__classical_registers[name] {
            if size != register.size {
                throw QISKitError.registerSize
            }
            SDKLogger.logInfo(">> classical register exists: \(name) \(size)")
        }
        else {
            SDKLogger.logInfo(">> new classical register created: \(name) \(size)")
            try self.__classical_registers[name] = ClassicalRegister(name, size)
        }
        return self.__classical_registers[name]!
    }

    /**
     Create a new set of Classical Registers based on a array of them.

     Args:
        register_array (list[dict]): An array of classical registers in
        dictionay format::

             "quantum_registers": [
                 {
                 "name": "qr",
                 "size": 4
                 },
                 ...
             ]
        Returns:
        Array of classical registers objects
     */
    @discardableResult
    public func create_classical_registers(_ register_array: [[String: Any]]) throws -> [ClassicalRegister] {
        var new_registers: [ClassicalRegister] = []
        for register in register_array {
            guard let name = register["name"] as? String else {
                continue
            }
            guard let size = register["size"] as? Int else {
                continue
            }
            new_registers.append(try self.create_classical_register(name,size))
        }
        return new_registers
    }

    /**
     Destroy an existing Classical Register.

     Args:
     name (str): the name of the classical register

     Raises:
     QISKitError: if the register does not exist in the program.
     */
    public func destroy_classical_register(_ name: String) throws {
        if self.__classical_registers[name] == nil {
            throw QISKitError.regNotExists(name: name)
        }
        self.__classical_registers[name] = nil
        SDKLogger.logInfo(">> classical register destroyed: '\(name)'")
    }

    /**
     Destroy a set of Quantum Registers based on a array of them.

     Args:
         register_array (list[dict]): An array of classical registers in
             dictionay format::

                 "classical_registers": [
                     {
                     "name": "qr",
                     },
                     ...
                 ]
                "size" may be a key for compatibility, but is ignored.
     */
    public func destroy_classical_registers(_ register_array: [String:Any]) throws {
        guard let registers = register_array["classical_registers"] as? [[String:Any]] else {
            return
        }
        for register in registers {
            if let name = register["name"] as? String {
                try self.destroy_classical_register(name)
            }
        }
    }


    /**
     Create a empty Quantum Circuit in the Quantum Program.

     Args:
        name (str): the name of the circuit
        qregisters list(object): is an Array of Quantum Registers by object reference
        cregisters list(object): is an Array of Classical Registers by
        object reference

     Returns:
        A quantum circuit is created and added to the Quantum Program
    */
    @discardableResult
    public func create_circuit(_ name: String,
                               _ qregisters: [QuantumRegister] = [],
                               _ cregisters: [ClassicalRegister] = []) throws -> QuantumCircuit {
        let quantum_circuit = QuantumCircuit()
        if self.__init_circuit == nil {
            self.__init_circuit = quantum_circuit
        }
        try quantum_circuit.add(qregisters)
        try quantum_circuit.add(cregisters)
        try self.add_circuit(name, quantum_circuit)
        return self.__quantum_program[name]!
    }

    /**
     "Destroy a Quantum Circuit in the Quantum Program. This will not
     destroy any registers associated with the circuit.

     Args:
        name (str): the name of the circuit

     Raises:
        QISKitError: if the register does not exist in the program.
     */
    public func destroy_circuit(_ name: String) throws {
        if self.__quantum_program[name] == nil {
            throw QISKitError.missingCircuit(name: name)
        }
        self.__quantum_program[name] = nil
    }

    /**
     Add a new circuit based on an Object representation.

     Args:
        name (str): the name of the circuit to add.
        quantum_circuit: a quantum circuit to add to the program-name
     Returns:
        the quantum circuit is added to the object.
     */
    @discardableResult
    public func add_circuit(_ name: String, _ quantum_circuit: QuantumCircuit) throws -> QuantumCircuit {
        for (qname, qreg) in quantum_circuit.get_qregs() {
            try self.create_quantum_register(qname, qreg.size)
        }
        for (cname, creg) in quantum_circuit.get_cregs() {
            try self.create_classical_register(cname, creg.size)
        }
        self.__quantum_program[name] = quantum_circuit
        return self.__quantum_program[name]!
    }

    /**
     Load qasm file into the quantum program.

     Args:
        qasm_file (str): a string for the filename including its location.
        name (str or None, optional): the name of the quantum circuit after
            loading qasm text into it. If no name is give the name is of
            the text file.

     Retuns:
        Adds a quantum circuit with the gates given in the qasm file to the
        quantum program and returns the name to be used to get this circuit
     */
    @discardableResult
    public func load_qasm_file(_ qasm_file: String, name: String? = nil, basis_gates: String = "u1,u2,u3,cx,id") throws -> String {
        var n: String = ""
        if name != nil {
            n = name!
        }
        else {
            let url = URL(fileURLWithPath: qasm_file)
            n = url.lastPathComponent
        }
        return try self.load_qasm(Qasm(filename:qasm_file),n,basis_gates)
     }

    /**
     Load qasm string in the quantum program.

     Args:
        qasm_string (str): a string for the file name.
        name (str): the name of the quantum circuit after loading qasm
            text into it. If no name is give the name is of the text file.

     Retuns:
        Adds a quantum circuit with the gates given in the qasm string to the
        quantum program.
     */
    @discardableResult
    public func load_qasm_text(_ qasm_string: String, name: String? = nil,basis_gates: String = "u1,u2,u3,cx,id") throws -> String {
        var n: String = ""
        if name != nil {
            n = name!
        }
        else {
            n = String.randomAlphanumeric(length: 10)
        }
        return try self.load_qasm(Qasm(data:qasm_string),n,basis_gates)
    }

    private func load_qasm(_ qasm: Qasm, _ name: String, _ basis_gates: String) throws -> String {
        let node_circuit = try qasm.parse()
        SDKLogger.logInfo("circuit name: \(name)")
        SDKLogger.logInfo("******************************")
        SDKLogger.logInfo(node_circuit.qasm(15))

        // current method to turn it a DAG quantum circuit.
        let unrolled_circuit = Unroller(node_circuit, CircuitBackend(basis_gates.components(separatedBy:",")))
        let circuit_unrolled = try unrolled_circuit.execute() as! QuantumCircuit
        try self.add_circuit(name, circuit_unrolled)
        return name
    }

    /**
     Return a Quantum Register by name.
     Args:
     name (str): the name of the register
     Returns:
     The quantum registers with this name
     */
    @discardableResult
    public func get_quantum_register(_ name: String) throws -> QuantumRegister {
        guard let reg = self.__quantum_registers[name] else {
            throw QISKitError.regNotExists(name: name)
        }
        return reg
    }

    /**
     Return a Classical Register by name.
     Args:
     name (str): the name of the register
     Returns:
     The classical registers with this name
     */
    @discardableResult
    public func get_classical_register(_ name: String) throws -> ClassicalRegister {
        guard let reg = self.__classical_registers[name] else {
            throw QISKitError.regNotExists(name: name)
        }
        return reg
    }

    /**
     Return all the names of the quantum Registers.
     */
    public func get_quantum_register_names() -> [String] {
        return Array(self.__quantum_registers.keys)
    }

    /**
     Return all the names of the classical Registers.
     */
    public func get_classical_register_names() -> [String] {
        return Array(self.__classical_registers.keys)
    }

    /**
     Return a Circuit Object by name
     Args:
        name (str): the name of the quantum circuit
     Returns:
        The quantum circuit with this name
     */
    @discardableResult
    public func get_circuit(_ name: String) throws -> QuantumCircuit {
        guard let qCircuit =  self.__quantum_program[name] else {
            throw QISKitError.missingCircuit(name: name)
        }
        return qCircuit
    }

    /**
     Return all the names of the quantum circuits.
     */
    public func get_circuit_names() -> [String] {
        return Array(self.__quantum_program.keys)
    }

    /**
     Get qasm format of circuit by name.
     Args:
        name (str): name of the circuit
     Returns:
        The quantum circuit in qasm format
     */
    public func get_qasm(_ name: String) throws -> String {
        let quantum_circuit = try self.get_circuit(name)
        return quantum_circuit.qasm()
    }

    /**
     Get qasm format of circuit by list of names.
     Args:
        list_circuit_name (list[str]): names of the circuit
     Returns:
        List of quantum circuit in qasm format
     */
    public func get_qasms(_ list_circuit_name: [String]) throws -> [String] {
        var qasm_source: [String] = []
        for name in list_circuit_name {
            qasm_source.append(try self.get_qasm(name))
        }
        return qasm_source
    }

    /**
     Return the initialization Circuit.
     */
    public func get_initial_circuit() -> QuantumCircuit? {
        return self.__init_circuit
    }

    /**
     Setup the API.

     Fills the __ONLINE_BACKENDS, __api, and __api_config variables.
     Does not catch exceptions from IBMQuantumExperience.

     Args:
         token (str): The token used to register on the online backend such
         as the quantum experience.
         url (str): The url used for online backend such as the quantum
         experience.
         hub (str): The hub used for online backend.
         group (str): The group used for online backend.
         proxies (dict): Proxy configuration for the API, as a dict with
            'urls' and credential keys.
         project (str): The project used for online backend.
     */
    public func set_api(token: String,
                        url: String = IBMQuantumExperience.URL_BASE,
                        hub: String? = nil,
                        group: String? = nil,
                        project: String? = nil,
                        proxies: [String:Any]? = nil) {
        var config_dict: [String:Any] = [
            "url": url,
            "hub": hub != nil ? hub! : NSNull(),
            "group": group != nil ? group! : NSNull(),
            "project": project != nil ? project! : NSNull()
        ]
        if let p = proxies {
            config_dict["proxies"] = p
        }
        self.backendUtils.api = IBMQuantumExperience(token, config_dict)
        self.__api_config["token"] = token
        self.__api_config["config"] = config_dict
    }

    /**
     Update the API hubs configuration, replacing the previous one.

        hub (str): The hub used for online backend.
        group (str): The group used for online backend.
        project (str): The project used for online backend.
     */
    public func set_api_hubs_config(hub: String, group: String, project: String) {
        let config_dict: [String:Any] = [
            "hub": hub,
            "group": group,
            "project": project
        ]
        var config: [String:Any] = [:]
        if let c = self.__api_config["config"] as? [String:Any] {
            config = c
        }
        var apiConfig: [String:Any] = [:]
        if let api = self.backendUtils.api {
            config = api.config
        }
        for (k,v) in config_dict {
            apiConfig[k] = v
            config[k] = v
        }
        self.__api_config["config"] = config
        if let api = self.backendUtils.api {
            api.config = apiConfig
        }
    }

    @discardableResult
    public func check_connection(_ responseHandler: @escaping ((_:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        if let api = self.backendUtils.api {
            return api.check_connection() { (error) -> Void in
                responseHandler(error)
            }
        }
        DispatchQueue.main.async {
            responseHandler(IBMQuantumExperienceError.invalidCredentials)
        }
        return RequestTask()
    }

    /**
     Return the program specs
     */
    public func get_api_config() -> [String:Any] {
        return self.__api_config
    }

    /**
     Returns a function handle to the API
     */
    public func get_api() -> IBMQuantumExperience? {
        return self.backendUtils.api
    }

    /**
     Save Quantum Program in a Json file.
     Args:
        file_name (str): file name and path.
        beauty (boolean): save the text with indent to make it readable.
     Returns:
        The dictionary with the result of the operation
     */
    @discardableResult
    public func save(_ file_name: String, beauty: Bool = false) throws -> [String:[String:Any]] {
        let (contents,elements_saved) = try self.getSaveElements()
        do {
            try contents.write(toFile: file_name, atomically: true, encoding: .utf8)
            return elements_saved
        } catch {
            throw QISKitError.internalError(error: error)
        }
    }

    private func getSaveElements(_ beauty: Bool = false) throws -> (String, [String:[String:Any]]) {
        do {
            let elements_to_save = self.__quantum_program
            var elements_saved: [String:[String:Any]] = [:]

            for (name,value) in elements_to_save {
                elements_saved[name] = [:]
                elements_saved[name]!["qasm"] = value.qasm()
            }

            let options = beauty ? JSONSerialization.WritingOptions.prettyPrinted : []
            let data = try JSONSerialization.data(withJSONObject: elements_saved, options: options)
            let contents = String(data: data, encoding: .utf8)
            return (contents!, elements_saved)
        } catch {
            throw QISKitError.internalError(error: error)
        }
    }

    /**
     Load Quantum Program Json file into the Quantum Program object.
     Args:
        file_name (str): file name and path.
     Returns:
        The result of the operation
    */
    public func load(_ file_name: String) throws -> OrderedDictionary<String,QuantumCircuit> {
        var elements_loaded = OrderedDictionary<String,QuantumCircuit>()
        do {
            guard let file = FileHandle(forReadingAtPath: file_name) else {
                throw QISKitError.invalidFile(file: file_name)
            }
            let data = file.readDataToEndOfFile()
            let jsonAny = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

            if let dict = jsonAny as? [String:[String:Any]] {
                for (name,value) in dict {
                    if let qasm_string = value["qasm"] as? String {
                        let qasm = Qasm(data:qasm_string)
                        let node_circuit = try qasm.parse()
                        // current method to turn it a DAG quantum circuit.
                        let basis_gates = "u1,u2,u3,cx,id"  // QE target basis
                        let unrolled_circuit = Unroller(node_circuit, CircuitBackend(basis_gates.components(separatedBy:",")))
                        let circuit_unrolled = try unrolled_circuit.execute() as! QuantumCircuit
                        elements_loaded[name] = circuit_unrolled
                    }
                }
            }
            self.__quantum_program = elements_loaded
            return self.__quantum_program
        } catch {
            throw QISKitError.internalError(error: error)
        }
    }

    /**
     All the backends that are seen by QISKIT.
     */
    @discardableResult
    public func available_backends(responseHandler: @escaping ((_:Set<String>, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        return self.online_backends() { (backends,error) in
            if error != nil {
                responseHandler([],error)
                return
            }
            var ret = backends
            ret.formUnion(self.backendUtils.local_backends())
            responseHandler(ret,nil)
        }
    }

    /**
     Local backends that are seen by QISKIT.
     */
    public func local_backends() -> Set<String> {
        return self.backendUtils.local_backends()
    }

    /**
     Queries network API if it exists.

     Returns
     -------
     List of online backends if the online api has been set or an empty
     list of it has not been set.
    */
    @discardableResult
    public func online_backends(responseHandler: @escaping ((_:Set<String>, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        guard let api = self.get_api() else {
            responseHandler(Set<String>(),nil)
            return RequestTask()
        }
        return api.available_backends() { (backends,error) in
            if error != nil {
                responseHandler([],error)
                return
            }
            var ret: Set<String> = []
            for backend in backends {
                if let name = backend["name"] as? String {
                    ret.update(with: name)
                }
            }
            responseHandler(ret,nil)
        }
    }

    /**
     Gets online simulators via QX API calls.

     Returns
     -------
     List of online simulator names.
     */
    @discardableResult
    public func online_simulators(responseHandler: @escaping ((_:Set<String>, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        guard let api = self.get_api() else {
            responseHandler(Set<String>(),nil)
            return RequestTask()
        }
        return api.available_backends() { (backends,error) in
            if error != nil {
                responseHandler([],error)
                return
            }
            var ret: Set<String> = []
            for backend in backends {
                guard let simulator = backend["simulator"] as? Bool else {
                    continue
                }
                if simulator {
                    if let name = backend["name"] as? String {
                        ret.update(with: name)
                    }
                }
            }
            responseHandler(ret,nil)
        }
    }

    /**
     Gets online devices via QX API calls
     */
    @discardableResult
    public func online_devices(responseHandler: @escaping ((_:Set<String>, _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        guard let api = self.get_api() else {
            responseHandler(Set<String>(),nil)
            return RequestTask()
        }
        return api.available_backends() { (backends,error) in
            if error != nil {
                responseHandler([],error)
                return
            }
            var ret: Set<String> = []
            for backend in backends {
                guard let simulator = backend["simulator"] as? Bool else {
                    continue
                }
                if !simulator {
                    if let name = backend["name"] as? String {
                        ret.update(with: name)
                    }
                }
            }
            responseHandler(ret,nil)
        }
    }

    /**
     Return the online backend status via QX API call or by local
     backend is the name of the local or online simulator or experiment
    */
    @discardableResult
    public func get_backend_status(_ backend: String,
                                  responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.online_backends() { (backends,error) in
            if error != nil {
                responseHandler([:],error)
                return
            }
            if backends.contains(backend) {
                guard let api = self.get_api() else {
                    responseHandler([:],IBMQuantumExperienceError.errorBackend(backend: backend))
                    return
                }
                let r = api.backend_status(backend: backend,responseHandler: responseHandler)
                reqTask.add(r)
                return
            }
            if self.backendUtils.local_backends().contains(backend) {
                responseHandler(["available" : true],nil)
                return
            }
            responseHandler([:],IBMQuantumExperienceError.errorBackend(backend: backend))
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Return the configuration of the backend
     */
    @discardableResult
    public func get_backend_configuration(_ backend: String, _ list_format: Bool = false,
                                   responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        guard let api = self.get_api() else {
            return self.backendUtils.get_backend_configuration(backend,responseHandler)
        }
        return api.available_backends() { (backends,error) in
            if error != nil {
                responseHandler([:],error)
                return
            }
            do {
                let set = Set<String>(["id", "serial_number", "topology_id", "status", "coupling_map"])
                var configuration_edit: [String:Any] = [:]
                for configuration in backends {
                    if let name = configuration["name"] as? String {
                        if name == backend {
                            for (key,value) in configuration {
                                let new_key = try QuantumProgram.convert(key)
                                // TODO: removed these from the API code
                                if !set.contains(new_key) {
                                    configuration_edit[new_key] = value
                                }
                                if new_key == "coupling_map" {
                                    var conf: String = ""
                                    if let c = value as? String {
                                        conf = c
                                    }
                                    if conf == "all-to-all" {
                                        configuration_edit[new_key] = value
                                    }
                                    else {
                                        var cmap = value
                                        if !list_format {
                                            if let list = value as? [[Int]] {
                                                cmap = Coupling.coupling_list2dict(list)
                                            }
                                        }
                                        configuration_edit[new_key] = cmap
                                    }
                                }
                            }
                            responseHandler(configuration_edit,nil)
                            return
                        }
                    }
                }
                responseHandler([:],IBMQuantumExperienceError.missingBackends)
            } catch {
                responseHandler([:],IBMQuantumExperienceError.internalError(error: error))
            }
        }
    }

    /**
     Return the online backend calibrations via QX API call
     backend is the name of the experiment
     */
    @discardableResult
    public func get_backend_calibration(_ backend: String,
                                       responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.online_backends() { (backends,error) in
            if error != nil {
                responseHandler([:],error)
                return
            }
            if backends.contains(backend) {
                guard let api = self.get_api() else {
                    responseHandler([:],IBMQuantumExperienceError.errorBackend(backend: backend))
                    return
                }
                let r = api.backend_calibration(backend: backend) { (calibrations,error) in
                    if error != nil {
                        responseHandler([:],error)
                        return
                    }
                    do {
                        var calibrations_edit: [String:Any] = [:]
                        for (key, vals) in calibrations {
                            let new_key = try QuantumProgram.convert(key)
                            calibrations_edit[new_key] = vals
                        }
                        responseHandler(calibrations_edit,nil)
                    } catch {
                        responseHandler([:],IBMQuantumExperienceError.internalError(error: error))
                    }
                }
                reqTask.add(r)
                return
            }
            if self.backendUtils.local_backends().contains(backend) {
                responseHandler(["backend" : backend],nil)
                return
            }
            responseHandler([:],IBMQuantumExperienceError.errorBackend(backend: backend))
        }
        reqTask.add(r)
        return reqTask
    }

    /**
     Return the online backend parameters via QX API call
     backend is the name of the experiment
     */
    @discardableResult
    public func get_backend_parameters(_ backend: String,
                                        responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.online_backends() { (backends,error) in
            if error != nil {
                responseHandler([:],error)
                return
            }
            if backends.contains(backend) {
                guard let api = self.get_api() else {
                    responseHandler([:],IBMQuantumExperienceError.errorBackend(backend: backend))
                    return
                }
                let r = api.backend_parameters(backend: backend) { (parameters,error) in
                    if error != nil {
                        responseHandler([:],error)
                        return
                    }
                    do {
                        var parameters_edit: [String:Any] = [:]
                        for (key, vals) in parameters {
                            let new_key = try QuantumProgram.convert(key)
                            parameters_edit[new_key] = vals
                        }
                        responseHandler(parameters_edit,nil)
                    } catch {
                        responseHandler([:],IBMQuantumExperienceError.internalError(error: error))
                    }
                }
                reqTask.add(r)
                return
            }
            if self.backendUtils.local_backends().contains(backend) {
                responseHandler(["backend" : backend],nil)
                return
            }
            responseHandler([:],IBMQuantumExperienceError.errorBackend(backend: backend))
        }
        reqTask.add(r)
        return reqTask
    }

    /**
    Compile the circuits into the exectution list.
    This builds the internal "to execute" list which is list of quantum
    circuits to run on different backends.
    Args:
        name_of_circuits (list[str]): circuit names to be compiled.
        backend (str): a string representing the backend to compile to
        config (dict): a dictionary of configurations parameters for the
        compiler
        basis_gates (str): a comma seperated string and are the base gates,
            which by default are: u1,u2,u3,cx,id
        coupling_map (dict): A directed graph of coupling::

            {
            control(int):
                [
                    target1(int),
                    target2(int),
                    , ...
                ],
                ...
            }
        eg. {0: [2], 1: [2], 3: [2]}
        initial_layout (dict): A mapping of qubit to qubit::
            {
                ("q", strart(int)): ("q", final(int)),
                ...
            }
            eg.
            {
                ("q", 0): ("q", 0),
                ("q", 1): ("q", 1),
                ("q", 2): ("q", 2),
                ("q", 3): ("q", 3)
            }
        shots (int): the number of shots
        max_credits (int): the max credits to use 3, or 5
        seed (int): the intial seed the simulatros use
    Returns:
        the job id and populates the qobj::
        qobj =
            {
                id: --job id (string),
                config: -- dictionary of config settings (dict)--,
                    {
                    "max_credits" (online only): -- credits (int) --,
                    "shots": -- number of shots (int) --.
                    "backend": -- backend name (str) --
                    }
                circuits:
                    [
                    {
                    "name": --circuit name (string)--,
                    "compiled_circuit": --compiled quantum circuit (DAG format)--,
                    "config": --dictionary of additional config settings (dict)--,
                        {
                        "coupling_map": --adjacency list (dict)--,
                        "basis_gates": --comma separated gate names (string)--,
                        "layout": --layout computed by mapper (dict)--,
                        "seed": (simulator only)--initial seed for the simulator (int)--,
                        }
                    },
                    ...
                ]
            }
    */
    @discardableResult
    public func compile(_ name_of_circuits: [String],
                        backend: String = "local_qasm_simulator",
                        config: [String:Any]? = nil,
                        basis_gates: String? = nil,
                        coupling_map: [Int:[Int]]? = nil,
                        initial_layout: OrderedDictionary<RegBit,RegBit>? = nil,
                        shots: Int = 1024,
                        max_credits: Int = 10,
                        seed: Int? = nil,
                        qobj_id: String? = nil,
                        hpc: [String:Any]? = nil,
                        _ responseHandler: @escaping ((_:[String:Any], _:QISKitError?) -> Void)) -> RequestTask {
        // TODO: Jay: currently basis_gates, coupling_map, initial_layout, shots,
        // max_credits and seed are extra inputs but I would like them to go
        // into the config.

        var qobj: [String:Any] = [:]
        let qobjId: String = (qobj_id != nil) ? qobj_id! : String.randomAlphanumeric(length: 30)
        qobj["id"] = qobjId
        qobj["config"] = ["max_credits": max_credits, "backend": backend, "shots": shots]

        // TODO This backend needs HPC parameters to be passed in order to work
        if backend == "ibmqx_hpc_qasm_simulator" {
            var h: [String:Any] = [:]
            if let v = hpc {
                h = v
            }
            else {
                SDKLogger.logInfo("ibmqx_hpc_qasm_simulator backend needs HPC " +
                                    "parameter. Setting defaults to hpc.multi_shot_optimization " +
                                    "= true and hpc.omp_num_threads = 16")
                h = ["multi_shot_optimization": true, "omp_num_threads": 16]
            }
            let m = h.keys.filter() { $0 != "multi_shot_optimization" && $0 != "omp_num_threads" }
            if !m.isEmpty {
                DispatchQueue.main.async {
                    responseHandler([:],QISKitError.unknownHPC)
                }
                return RequestTask()
            }
            if var config = qobj["config"] as? [String:Any] {
                config["hpc"] = h
                qobj["config"] = config
            }
        }
        else if hpc != nil {
            SDKLogger.logInfo("HPC paramter is only available for " +
                        "ibmqx_hpc_qasm_simulator. You are passing an HPC parameter " +
                        "but you are not using ibmqx_hpc_qasm_simulator, so we will " +
                        "ignore it.")
        }

        qobj["circuits"] = []
        let r = self.backendUtils.get_backend_configuration(backend) { (backend_conf,error) in
            if error != nil {
                responseHandler([:],QISKitError.internalError(error: error!))
                return
            }
            do {
                var basis: String = ""
                if let b = basis_gates {
                    if b.components(separatedBy:",").count < 2 {
                        // catches deprecated basis specification like 'SU2+CNOT'
                        SDKLogger.logInfo("encountered deprecated basis specification: " +
                                    "'\(b)' substituting u1,u2,u3,cx,id")
                         basis = "u1,u2,u3,cx,id"
                    }
                }
                else if let b = backend_conf["basis_gates"] as? String {
                    basis = b
                }
                var cmap: [Int:[Int]]? = nil
                if let c = coupling_map {
                    cmap = c
                }
                else {
                    if let c = backend_conf["coupling_map"] as? String {
                        if c == "all-to-all" {
                            cmap = nil
                        }
                    }
                    else {
                        cmap = backend_conf["coupling_map"] as? [Int:[Int]]
                    }
                }
                if name_of_circuits.isEmpty {
                    throw QISKitError.missingCircuits
                }
                for name in name_of_circuits {
                    guard let qCircuit = self.__quantum_program[name] else {
                        throw QISKitError.missingQuantumProgram(name: name)
                    }
                    // TODO: The circuit object has to have .qasm() method (be careful)
                    let num_qubits = qCircuit.get_qregs().values.reduce(0, { (result, qreg) in
                        return result + qreg.size
                    })
                    // TODO: A better solution is to have options to enable/disable optimizations
                    var cm: [Int:[Int]]? = cmap
                    if num_qubits == 1 {
                        cm = nil
                    }
                    let compiledCircuit = try OpenQuantumCompiler.compile(qCircuit.qasm(),
                                                                                  basis_gates: basis,
                                                                                  coupling_map: cm,
                                                                                  initial_layout: initial_layout,
                                                                                  get_layout: true)
                    // making the job to be added to qoj
                    var job: [String:Any] = [:]
                    job["name"] = name
                    // config parameters used by the runner
                    var conf: [String:Any] = config != nil ? config! : [:]
                    conf["coupling_map"] = cm != nil ? Coupling.coupling_dict2list(cm!) : NSNull()
                    // TODO: Jay: make config options optional for different backends
                    // Map the layout to a format that can be json encoded
                    if let final_layout = compiledCircuit.final_layout {
                        var list_layout: [[Any]] = []
                        for (k,v) in final_layout {
                            let k1: Any = [k.name , k.index]
                            let v1: Any = [v.name , v.index]
                            list_layout.append([k1,v1])
                        }
                        conf["layout"] = list_layout
                    }
                    else {
                        conf["layout"] = NSNull()
                    }
                    conf["basis_gates"] = basis
                    conf["seed"] = seed != nil ? seed! : NSNull()

                    job["config"] = conf

                    // the compuled circuit to be run saved as a dag
                    job["compiled_circuit"] = try OpenQuantumCompiler.dag2json(compiledCircuit.dag!,basis_gates: basis)
                    job["compiled_circuit_qasm"] = try compiledCircuit.dag!.qasm(qeflag:true)
                    // add job to the qobj
                    var circuits = qobj["circuits"] as! [Any]
                    circuits.append(job)
                    qobj["circuits"] = circuits
                }
                responseHandler(qobj,nil)
            } catch let error as QISKitError {
                responseHandler(qobj,error)
            } catch {
                responseHandler(qobj,QISKitError.internalError(error: error))
            }
        }
        return r
    }

    /**
     hange configuration parameters for a compile qobj. Only parameters which
     don't affect the circuit compilation can change, e.g., the coupling_map
     cannot be changed here!

     Notes:
        If the inputs are left as None then the qobj is not updated

     Args:
         qobj (dict): already compile qobj
         backend (str): see .compile
         config (dict): see .compile
         shots (int): see .compile
         max_credits (int): see .compile
         seed (int): see .compile

     Returns:
        qobj: updated qobj
     */
    public func reconfig(_ qobj: [String:Any],
                         backend: String? = nil,
                         config: [String:Any]? = nil,
                         shots: Int? = nil,
                         max_credits: Int? = nil,
                         seed: Int? = nil) -> [String:Any] {
        var newQobj = qobj
        var conf: [String:Any] = [:]
        if let c = newQobj["config"] as? [String:Any] {
            conf = c
        }
        if let b = backend {
            conf["backend"] = b
        }
        if let s = shots {
            conf["shots"] = s
        }
        if let mc = max_credits {
            conf["max_credits"] = mc
        }
        newQobj["config"] = conf
        if let circuits = newQobj["circuits"] as? [[String:Any]] {
            var newCircuits: [[String:Any]] = []
            for var circuit in circuits {
                if let s = seed {
                    circuit["seed"] = s
                }
                if let c = config {
                    var conf: [String:Any] = [:]
                    if let cc = circuit["config"] as? [String:Any] {
                        conf = cc
                    }
                    conf.merge(c) { (_, new) in new }
                    circuit["config"] = conf
                }
                newCircuits.append(circuit)
            }
            newQobj["circuits"] = newCircuits
        }
        return newQobj
    }

    /**
     Print the compiled circuits that are ready to run.
     */
    @discardableResult
    public func get_execution_list(_ qobj: [String: Any]) -> [String] {
        var execution_list: [String] = []
        if let iden = qobj["id"] as? String {
            SDKLogger.logInfo("id: \(iden)")
        }
        if let config = qobj["config"] as? [String:Any] {
            if let backend = config["backend"] as? String {
                SDKLogger.logInfo("backend: \(backend)")
            }
            SDKLogger.logInfo("qobj config:")
            for (key,value) in config {
                if key != "backend" {
                    SDKLogger.logInfo(" \(key): \(SDKLogger.debugString(value))")
                }
            }
        }
        if let circuits = qobj["circuits"] as? [[String:Any]] {
            for circuit in circuits {
                if let name = circuit["name"] as? String {
                    execution_list.append(name)
                    SDKLogger.logInfo("  circuit name: \(name)")
                }
                if let config = circuit["config"] as? [String:Any] {
                    SDKLogger.logInfo("  circuit config:")
                    for (key,value) in config {
                        SDKLogger.logInfo("   \(key): \(SDKLogger.debugString(value))")
                    }
                }
            }
        }
        return execution_list
    }

    /**
     Get the compiled layout for the named circuit and backend.
     Args:
        name (str):  the circuit name
        qobj (str): the name of the qobj
     Returns:
        the config of the circuit.
     */
    public func get_compiled_configuration(_ qobj: [String: Any], _ name: String) throws -> [String:Any] {
        if let circuits = qobj["circuits"]  as? [[String:Any]] {
            for circuit in circuits {
                if let n = circuit["name"] as? String {
                    if n == name {
                        if let config = circuit["config"] as? [String:Any] {
                            return config
                        }
                    }
                }
            }
        }
        throw QISKitError.missingCompiledConfig
    }

    /**
     Print the compiled circuit in qasm format.
     Args:
        qobj (str): the name of the qobj
        name (str): name of the quantum circuit
     */
    public func get_compiled_qasm(_ qobj: [String: Any], _ name: String) throws -> String {
        if let circuits = qobj["circuits"]  as? [[String:Any]] {
            for circuit in circuits {
                if let n = circuit["name"] as? String {
                    if n == name {
                        if let circuit = circuit["compiled_circuit_qasm"] as? String {
                            return circuit
                        }
                    }
                }
            }
        }
        throw QISKitError.missingCompiledQasm
    }

    /**
     Run a program (a pre-compiled quantum program) asynchronously. This
     is a non-blocking function, so it will return inmediately.

     All input for run comes from qobj.

     Args:
     qobj(dict): the dictionary of the quantum object to
     run or list of qobj.
     wait (int): Time interval to wait between requests for results
     timeout (int): Total time to wait until the execution stops
     callback (fn(result)): A function with signature:
     fn(result):
     The result param will be a Result object.
     */
    @discardableResult
    public func run_async(_ qobj: [String:Any],
                          wait: Int = 5,
                          timeout: Int = 60,
                          _ callback:  @escaping ((_:Result) -> Void)) -> RequestTask {
        return self._run_internal([qobj],
                           wait: wait,
                           timeout: timeout,
                           callbackSingle: callback)
    }

    /**
     Run various programs (a list of pre-compiled quantum program)
     asynchronously. This is a non-blocking function, so it will return
     inmediately.

     All input for run comes from qobj.

     Args:
     qobj_list (list(dict)): The list of quantum objects to run.
     wait (int): Time interval to wait between requests for results
     timeout (int): Total time to wait until the execution stops
     callback (fn(results)): A function with signature:
     fn(results):
     The results param will be a list of Result objects, one
     Result per qobj in the input list.
     */
    @discardableResult
    public func run_batch_async(_ qobj_list: [[String:Any]],
                                wait: Int = 5,
                                timeout: Int = 120,
                                _ callback: ((_:[Result]) -> Void)?) -> RequestTask {
        return self._run_internal(qobj_list,
                           wait: wait,
                           timeout: timeout,
                           callbackMultiple: callback)
    }

    private func _run_internal(_ qobj_list: [[String:Any]],
                               wait: Int,
                               timeout: Int,
                               callbackSingle: ((_:Result) -> Void)? = nil,
                               callbackMultiple: ((_:[Result]) -> Void)? = nil) -> RequestTask {
        var q_job_list: [QuantumJob] = []
        for qobj in qobj_list {
            var max_credits = 0
            if let config = qobj["config"] as? [String:Any] {
                if let m = config["max_credits"] as? Int {
                    max_credits = m
                }
            }
            q_job_list.append(QuantumJob(qobj, resources: [ "max_credits": max_credits, "wait": wait, "timeout":timeout]))
        }
        let job_processor = JobProcessor(self.backendUtils,q_job_list,self._jobs_done_callback)
        let data = JobProcessorData(job_processor,
                                    callbackSingle,
                                    callbackMultiple)
        self.lock.lock()
        self.jobProcessors[data.jobProcessor.identifier] = data
        self.lock.unlock()
        return job_processor.submit()
    }

    /**
     This internal callback will be called once all Jobs submitted have
     finished. NOT every time a job has finished.

     Args:
     identifier: JobProcessor unique identifier
     jobs_results (list): list of Result objects
     */
    private func _jobs_done_callback(_ identifier: String, _ jobs_results: [Result]) {
        self.lock.lock()
        let data = self.jobProcessors.removeValue(forKey:identifier)
        self.lock.unlock()
        if data != nil {
            DispatchQueue.main.async {
                if data!.callbackSingle != nil {
                    data!.callbackSingle?(jobs_results[0])
                }
                else {
                    data!.callbackMultiple?(jobs_results)
                }
            }
        }
    }

    /**
     Execute, compile, and run an array of quantum circuits).
     This builds the internal "to execute" list which is list of quantum
     circuits to run on different backends.
     Args:
         name_of_circuits (list[str]): circuit names to be compiled.
         backend (str): a string representing the backend to compile to
         config (dict): a dictionary of configurations parameters for the
         compiler
         wait (int): wait time is how long to check if the job is completed
         timeout (int): is time until the execution stops
         basis_gates (str): a comma seperated string and are the base gates,
         which by default are: u1,u2,u3,cx,id
         coupling_map (dict): A directed graph of coupling::
             {
             control(int):
                 [
                    target1(int),
                    target2(int),
                    , ...
                 ],
                 ...
             }
             eg. {0: [2], 1: [2], 3: [2]}
         initial_layout (dict): A mapping of qubit to qubit
             {
             ("q", strart(int)): ("q", final(int)),
             ...
             }
             eg.
             {
             ("q", 0): ("q", 0),
             ("q", 1): ("q", 1),
             ("q", 2): ("q", 2),
             ("q", 3): ("q", 3)
             }
         shots (int): the number of shots
         max_credits (int): the max credits to use 3, or 5
         seed (int): the intial seed the simulatros use
         hpc (dict): This will setup some parameter for
             ibmqx_hpc_qasm_simulator, using a JSON-like format like:
             {
             'multi_shot_optimization': Boolean,
             'omp_num_threads': Numeric
             }
             This paramter MUST be used only with
             ibmqx_hpc_qasm_simulator, otherwise the SDK will warn
             the user via logging.
     Returns:
        status done and populates the internal __quantum_program with the
        data
     */
    @discardableResult
    public func execute(_ name_of_circuits: [String],
                        backend: String = "local_qasm_simulator",
                        config: [String:Any]? = nil,
                        wait: Int = 5,
                        timeout: Int = 60,
                        basis_gates: String? = nil,
                        coupling_map: [Int:[Int]]? = nil,
                        initial_layout: OrderedDictionary<RegBit,RegBit>? = nil,
                        shots: Int = 1024,
                        max_credits: Int = 3,
                        seed: Int? = nil,
                        hpc: [String:Any]? = nil,
                        _ callback: @escaping ((_:Result) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        let r = self.compile(name_of_circuits,
                         backend: backend,
                         config: config,
                         basis_gates: basis_gates,
                         coupling_map: coupling_map,
                         initial_layout: initial_layout,
                         shots: shots,
                         max_credits: max_credits,
                         seed: seed,
                         hpc: hpc) { (qobj,error) in
            if error != nil {
                callback(Result("0",error!,[:]))
                return
            }
            let r = self.run_async(qobj,
                                   wait: wait,
                                   timeout: timeout,
                                   callback)
            reqTask.add(r)
        }
        reqTask.add(r)
        return reqTask
    }
}
