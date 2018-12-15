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
 Contains a (slow) simulator.

 It simulates a qasm quantum circuit that has been compiled to run on the
 simulator. It is exponential in the number of qubits.

 We advise using the c++ simulator or online simulator for larger size systems.

 The input is a qobj dictionary
 and the output is a Results object
 if shots = 1
    compiled_circuit['result']['data']['quantum_state']
 and
    results['data']['classical_state']

 where 'quantum_state' is a 2\ :sup:`n` complex numpy array representing the
 quantum state vector and 'classical_state' is an integer representing
 the state of the classical registors.

 if shots > 1
    results['data']["counts"] where this is dict {"0000" : 454}

 The simulator is run using
 .. code-block:: python
    QasmSimulator(compiled_circuit,shots,seed).run().
 .. code-block:: guess
     compiled_circuit =
     {
     "header": {
     "number_of_qubits": 2, // int
     "number_of_clbits": 2, // int
     "qubit_labels": [["q", 0], ["v", 0]], // list[list[string, int]]
     "clbit_labels": [["c", 2]], // list[list[string, int]]
     }
     "operations": // list[map]
         [
             {
             "name": , // required -- string
             "params": , // optional -- list[double]
             "qubits": , // required -- list[int]
             "clbits": , //optional -- list[int]
             "conditional":  // optional -- map
                 {
                     "type": , // string
                     "mask": , // hex string
                     "val":  , // bhex string
                 }
             },
         ]
     }
 if shots = 1
 .. code-block:: python
     result =
     {
     'data':
         {
         'quantum_state': array([ 1.+0.j,  0.+0.j,  0.+0.j,  0.+0.j]),
         'classical_state': 0
         'counts': {'0000': 1}
         }
     'status': 'DONE'
     }
 if shots > 1
 .. code-block:: python
 result =
     {
     'data':
         {
         'counts': {'0000': 50, '1001': 44},
         }
     'status': 'DONE'
     }
 */

// TODO add the IF qasm operation.
// TODO add ["status"] = 'DONE', 'ERROR' especitally for empty circuit error
// does not show up

/**
 Implementation of a qasm simulator
 */
final class QasmSimulator: BaseBackend {

    /**
     Magic index1 function.

     Takes a bitstring k and inserts bit b as the ith bit,
     shifting bits >= i over to make room.
     */
    static private func _index1(_ b: Int, _ i: Int, _ k: Int) -> Int {
        var retval = k
        let lowbits: Int = k & ((1 << i) - 1)  // get the low i bits

        retval >>= i
        retval <<= 1

        retval |= b

        retval <<= i
        retval |= lowbits

        return retval
    }

    /**
     Magic index2 function.

     Takes a bitstring k and inserts bits b1 as the i1th bit
     and b2 as the i2th bit
     */
    static private func _index2(_ b1: Int, _ i1: Int, _ b2: Int, _ i2: Int, _ k: Int) -> Int {
        assert(i1 != i2)

        var retval: Int = 0
        if i1 > i2 {
            // insert as (i1-1)th bit, will be shifted left 1 by next line
            retval = QasmSimulator._index1(b1, i1-1, k)
            retval = QasmSimulator._index1(b2, i2, retval)
        }
        else { // i2>i1
            // insert as (i2-1)th bit, will be shifted left 1 by next line
            retval = QasmSimulator._index1(b2, i2-1, k)
            retval = QasmSimulator._index1(b1, i1, retval)
        }
        return retval
    }

    private var _number_of_qubits: Int = 0
    private var _number_of_cbits: Int = 0
    private var _quantum_state: [Complex] = []
    private var _classical_state: Int = 0
    private var _shots: Int = 0
    private let _local_random: Random = Random()

    /**
     Initialize the QasmSimulator object
     */
    public required init(_ configuration: [String:Any]? = nil) {
        super.init(configuration)
        if let conf = configuration {
            self._configuration = conf
        }
        else {
            self._configuration = [
                "name": "local_qasm_simulator",
                "url": "https://github.com/IBM/qiskit-sdk-swift",
                "simulator": true,
                "local": true,
                "description": "A swift simulator for qasm files",
                "coupling_map": "all-to-all",
                "basis_gates": "u1,u2,u3,cx,id"
            ]
        }
    }

    /**
     Apply an arbitary 1-qubit operator to a qubit.

     Gate is the single qubit applied.
     qubit is the qubit the gate is applied to.
     */
    private func _add_qasm_single(_ gate: Matrix<Complex>, _ qubit: Int) {
        var psi = self._quantum_state
        let bit: Int = 1 << qubit
        for k1 in stride(from: 0, to: 1 << self._number_of_qubits, by: 1 << (qubit+1)) {
            for k2 in 0..<(1 << qubit) {
                let k: Int = k1 | k2
                let cache0 = psi[k]
                let cache1 = psi[k | bit]
                psi[k] = gate[0,0] * cache0 + gate[0,1] * cache1
                psi[k | bit] = gate[1,0] * cache0 + gate[1,1] * cache1
            }
        }
        self._quantum_state = psi
    }

    /**
     Optimized ideal CX on two qubits.

     q0 is the first qubit (control) counts from 0.
     q1 is the second qubit (target).
     */
    private func _add_qasm_cx(_ q0: Int, _ q1: Int) {
        var psi = self._quantum_state
        for k in 0..<(1 << (self._number_of_qubits - 2)) {
            // first bit is control, second is target
            let ind1 = QasmSimulator._index2(1, q0, 0, q1, k)
            // swap target if control is 1
            let ind3 = QasmSimulator._index2(1, q0, 1, q1, k)
            let cache0 = psi[ind1]
            let cache1 = psi[ind3]
            psi[ind3] = cache0
            psi[ind1] = cache1
        }
        self._quantum_state = psi
    }

    /**
     Apply the decision of measurement/reset qubit gate.

     qubit is the qubit that is measured/reset
     */
    private func _add_qasm_decision(_ qubit: Int) -> (Int,Double) {
        var probability_zero: Double = 0
        let random_number = self._local_random.random()
        for ii in 0..<(1 << self._number_of_qubits) {
            if (ii & (1 << qubit)) == 0 {
                probability_zero += pow(self._quantum_state[ii].abs(),2)
            }
        }
        var outcome: Int = 0
        var norm: Double = 0
        if random_number <= probability_zero {
            outcome = 0
            norm = probability_zero.squareRoot()
        }
        else {
            outcome = 1
            norm = (1-probability_zero).squareRoot()
        }
        return (outcome, norm)
    }

    /**
     Apply the measurement qubit gate.

     qubit is the qubit measured.
     cbit is the classical bit the measurement is assigned to.
     */
    private func _add_qasm_measure(_ qubit: Int, _ cbit: Int) {
        let (outcome, norm) = self._add_qasm_decision(qubit)
        for ii in 0..<(1 << self._number_of_qubits) {
            // update quantum state
            if ((ii >> qubit) & 1) == outcome {
                self._quantum_state[ii] = self._quantum_state[ii]/norm
            }
            else {
                self._quantum_state[ii] = 0
            }
        }
        // update classical state
        let bit: Int = 1 << cbit
        self._classical_state = (self._classical_state & (~bit)) | (outcome << cbit)
    }

    /**
     Apply the reset to the qubit.

     This is done by doing a measruement and if 0 do nothing and
     if 1 flip the qubit.

     qubit is the qubit that is reset.

     */
    private func _add_qasm_reset(_ qubit: Int) {
        // TODO: slow, refactor later
        let (outcome, norm) = self._add_qasm_decision(qubit)
        var temp = self._quantum_state
        self._quantum_state = [Complex](repeating: Complex(), count: _quantum_state.count)
        // measurement
        for ii in 0..<(1 << self._number_of_qubits) {
            if ((ii >> qubit) & 1) == outcome {
                temp[ii] = temp[ii]/norm
            }
            else {
                temp[ii] = 0
            }
        }
        // reset
        if outcome == 1 {
            for ii in 0..<(1 << self._number_of_qubits) {
                let iip: Int = (~(1 << qubit)) & ii  // bit number qubit set to zero
                self._quantum_state[iip] += temp[ii]
            }
        }
        else {
            self._quantum_state = temp
        }
    }

    /**
     Run circuits in qobj
     */
    @discardableResult
    override public func run(_ q_job: QuantumJob, response: @escaping ((_:Result) -> Void)) -> RequestTask {
        let reqTask = RequestTask()
        DispatchQueue.global(qos: .background).async {
            var result: Result? = nil
            let job_id = UUID().uuidString
            do {
                self._shots = 0
                let qobj = q_job.qobj
                var result_list: [[String:Any]] = []
                if let config = qobj["config"] as? [String:Any] {
                    if let shots = config["shots"] as? Int {
                        self._shots = shots
                    }
                }
                if let circuits = qobj["circuits"] as? [[String:Any]] {
                    for circuit in circuits {
                        result_list.append(try self.run_circuit(circuit,reqTask))
                        if reqTask.isCancelled() {
                            throw SimulatorError.simulationCancelled
                        }
                    }
                }
                result = Result(["job_id": job_id, "result": result_list, "status": "COMPLETED"],qobj)
            } catch {
                result = Result(job_id,error,q_job.qobj)
            }
            DispatchQueue.main.async {
                 response(result!)
            }
        }
        return reqTask
    }

    /**
     Run a circuit and return a single Result.
     Args:
         circuit (dict): JSON circuit from qobj circuits list
         shots (int): number of shots to run circuit
     Returns:
         A dictionary of results which looks something like::
         {
         "data":
             {  #### DATA CAN BE A DIFFERENT DICTIONARY FOR EACH BACKEND ####
             "counts": {’00000’: XXXX, ’00001’: XXXXX},
             "time"  : xx.xxxxxxxx
             },
         "status": --status (string)--
         }
     */
    private func run_circuit(_ circuit: [String:Any], _ reqTask: RequestTask) throws -> [String:Any] {
        var result: [String:Any] = [:]
        result["data"] = [:]
        guard let ccircuit = circuit["compiled_circuit"] as? [String:Any] else {
            throw SimulatorError.missingCompiledCircuit
        }
        self._number_of_qubits = 0
        self._number_of_cbits = 0
        self._quantum_state = []
        self._classical_state = 0

        var cl_reg_index: [Int] = [] // starting bit index of classical register
        var cl_reg_nbits: [Int] = [] // number of bits in classical register
        if let header = ccircuit["header"]  as? [String:Any] {
            if let number_of_qubits = header["number_of_qubits"] as? Int {
                self._number_of_qubits = number_of_qubits
            }
            if let _number_of_cbits = header["number_of_clbits"] as? Int {
                self._number_of_cbits = _number_of_cbits
            }
            if let clbit_labels = header["clbit_labels"] as? [[Any]] {
                var cbit_index: Int = 0
                for cl_reg in clbit_labels {
                    if let index = cl_reg[1] as? Int {
                        cl_reg_nbits.append(index)
                        cl_reg_index.append(cbit_index)
                        cbit_index += index
                    }
                }
            }
        }
        if let config = circuit["config"] as? [String:Any] {
            if let seed = config["seed"] as? Int {
                self._local_random.seed(seed)
            }
            else {
                self._local_random.seed(time(nil))
            }
        }
        var outcomes: [String] = []

        for _ in 0..<self._shots {
            if reqTask.isCancelled() {
                throw SimulatorError.simulationCancelled
            }
            self._quantum_state = [Complex](repeating: Complex(), count: 1 << self._number_of_qubits)
            self._quantum_state[0] = 1
            self._classical_state = 0
            if let operations = ccircuit["operations"] as? [[String:Any]] {
                // Do each operation in this shot
                for operation in operations {
                    if let conditional = operation["conditional"] as? [String:Any] {
                        if let m = conditional["mask"] as? String {
                            let scanner = Scanner(string: m)
                            var n: UInt64 = 0
                            if scanner.scanHexInt64(&n) {
                                var mask = Int(n)
                                if mask > 0 {
                                    var value: Int = self._classical_state & mask
                                    while ((mask & 0x1) == 0) {
                                        mask >>= 1
                                        value >>= 1
                                    }
                                    if let v = conditional["val"] as? String {
                                        let scanner = Scanner(string: v)
                                        var n: UInt64 = 0
                                        if scanner.scanHexInt64(&n) {
                                            if value != Int(n) {
                                                continue
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    guard let name = operation["name"] as? String else {
                        throw SimulatorError.missingOperationName
                    }
                    // Check if single  gate
                    if ["U", "u1", "u2", "u3"].contains(name) {
                        if let qubits = operation["qubits"] as? [Int] {
                            var params: [Double]? = nil
                            if let _params = operation["params"] as? [Double] {
                                params = _params
                            }
                            let qubit = qubits[0]
                            let gate = SimulatorTools.single_gate_matrix(name, params)
                            self._add_qasm_single(gate, qubit)
                        }
                    }
                    else if ["id", "u0"].contains(name) {
                    }
                    // Check if CX gate
                    else if ["CX", "cx"].contains(name) {
                        if let qubits = operation["qubits"] as? [Int] {
                            self._add_qasm_cx(qubits[0], qubits[1])
                        }
                    }
                    // Check if measure
                    else if name == "measure" {
                        if let qubits = operation["qubits"] as? [Int] {
                            if let clbits = operation["clbits"] as? [Int] {
                                self._add_qasm_measure(qubits[0], clbits[0])
                            }
                        }
                    }
                    // Check if reset
                    else if name == "reset" {
                        if let qubits = operation["qubits"] as? [Int] {
                            self._add_qasm_reset(qubits[0])
                        }
                    }
                    else if name == "barrier" {
                    }
                    else {
                        throw SimulatorError.unrecognizedOperation(backend: self.configuration["name"] as! String, operation: name)
                    }
                }
            }
            // Turn classical_state (int) into bit string
            let binString = String(self._classical_state, radix: 2)
            let filledBin: String = String(repeating: "0", count: self._number_of_cbits - binString.count) + binString
            outcomes.append(filledBin)
        }
        // Return the results
        var data: [String:Any] = [:]
        if self._shots == 1 {
            data["quantum_state"] = self._quantum_state
            data["classical_state"] = self._classical_state
        }
        var counts: [String:Int] = [:]
        for outcome in outcomes {
            if let count = counts[outcome] {
                counts[outcome] = count + 1
            }
            else {
                counts[outcome] = 1
            }
        }
        data["counts"] = self._format_result(counts,cl_reg_index,cl_reg_nbits)
        result["data"] = data
        result["status"] = "DONE"
        return result
    }

    /**
     Format the result bit string.

     This formats the result bit strings such that spaces are inserted
     at register divisions.

     Args:
        counts : dictionary of counts e.g. {'1111': 1000, '0000':5}
     Returns:
        spaces inserted into dictionary keys at register boundries.
     */
    private func _format_result(_ counts: [String:Int], _ cl_reg_index: [Int], _ cl_reg_nbits: [Int]) -> [String:Int] {
        var fcounts: [String:Int] = [:]
        for (key, value) in counts {
            let start = key.index(key.endIndex, offsetBy: -cl_reg_nbits[0])
            var new_key: [String] = [String(key[start..<key.endIndex])]
            for (index, nbits) in zip(cl_reg_index[1...],cl_reg_nbits[1...]) {
                let start = key.index(key.endIndex, offsetBy: -(index+nbits))
                let end = key.index(key.endIndex, offsetBy: -index)
                new_key.insert(String(key[start..<end]), at:0)
            }
            fcounts[new_key.joined(separator: " ")] = value
        }
        return fcounts
    }
}
