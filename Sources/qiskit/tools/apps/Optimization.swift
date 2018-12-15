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
 These are tools that are used in the classical optimization and chemistry
 tutorials
 */
public final class Optimization {

    private init() {
    }

    /**
     Minimizes obj_fun(theta) with a simultaneous perturbation stochastic
     approximation algorithm.

     Args:
         obj_fun : the function to minimize
         initial_theta : initial value for the variables of obj_fun
         SPSA_parameters (list[float]) :  the parameters of the SPSA
            optimization routine
         max_trials (int) : the maximum number of trial steps ( = function
            calls/2) in the optimization
         save_steps (int) : stores optimization outcomes each 'save_steps'
            trial steps
         last_avg (int) : number of last updates of the variables to average
            on for the final obj_fun
     Returns:
         cost_final : final optimized value for obj_fun
         theta_best : final values of the variables corresponding to cost_final
         cost_plus_save : array of stored values for obj_fun along the
            optimization in the + direction
         cost_minus_save : array of stored values for obj_fun along the
            optimization in the - direction
         theta_plus_save : array of stored variables of obj_fun along the
            optimization in the + direction
         theta_minus_save : array of stored variables of obj_fun along the
            optimization in the - direction
     */
    public static func SPSA_optimization(_ obj_fun: ((_:[Double]) -> Double),
                                         _ initial_theta: [Double],
                                         _ SPSA_parameters: [Double],
                                         _ max_trials: Int,
                                         _ save_steps: Int = 1,
                                         _ last_avg: Int = 1) throws -> (Double,[Double],[Double],[Double],[[Double]],[[Double]]) {
        let random = Random(time(nil))
        var theta_plus_save: [[Double]] = []
        var theta_minus_save: [[Double]] = []
        var cost_plus_save: [Double] = []
        var cost_minus_save: [Double] = []
        var theta = Vector<Double>(value:initial_theta)
        var theta_best = Vector<Double>(repeating:0.0, count: initial_theta.count)
        for k in 0..<max_trials {
            // SPSA Paramaters
            let a_spsa = Double(SPSA_parameters[0]) / pow(Double(k + 1) + SPSA_parameters[4], SPSA_parameters[2])
            let c_spsa = Double(SPSA_parameters[1]) / pow(Double(k + 1), SPSA_parameters[3])
            var arr = Vector<Double>(repeating: 0, count: initial_theta.count)
            for i in 0..<arr.count {
                arr[i] = Double(random.randint(0, 2))
            }
            let delta = arr.mult(2).subtract(1)
            // plus and minus directions
            let theta_plus = try theta.add(delta.mult(c_spsa))
            let theta_minus = try theta.subtract(delta.mult(c_spsa))
            // cost fuction for the two directions
            let cost_plus = obj_fun(theta_plus.value)
            let cost_minus = obj_fun(theta_minus.value)
            // derivative estimate
            let g_spsa = delta.mult(cost_plus - cost_minus).div(2.0 * c_spsa)
            // updated theta
            theta = try theta.subtract(g_spsa.mult(a_spsa))
            // saving
            if k % save_steps == 0 {
                SDKLogger.logInfo("objective function at theta+ for step # \(k)")
                SDKLogger.logInfo("\(cost_plus)")
                SDKLogger.logInfo("objective function at theta- for step # \(k)")
                SDKLogger.logInfo("\(cost_minus)")
                theta_plus_save.append(theta_plus.value)
                theta_minus_save.append(theta_minus.value)
                cost_plus_save.append(cost_plus)
                cost_minus_save.append(cost_minus)
            }
            if k >= max_trials - last_avg {
                theta_best = try theta_best.add(theta.div(Double(last_avg)))
            }
        }
        // final cost update
        let cost_final = obj_fun(theta_best.value)
        SDKLogger.logInfo("Final objective function is: \(cost_final)")
        return (cost_final, theta_best.value, cost_plus_save, cost_minus_save,
                theta_plus_save, theta_minus_save)
    }

    /**
     Calibrates and returns the SPSA parameters.

     Args:
        obj_fun : the function to minimize.
        initial_theta : initial value for the variables of obj_fun.
        initial_c (float) : first perturbation of intitial_theta.
        target_update (float) : the aimed update of variables on the first
            trial step.
        stat (int) : number of random gradient directions to average on in
            the calibration.
     Returns:
        An array of 5 SPSA_parameters to use in the optimization.
     */
    public static func SPSA_calibration(_ obj_fun: ((_:[Double]) -> Double),
                                        _ initial_theta: [Double],
                                        _ initial_c: Double,
                                        _ target_update: Double,
                                        _ stat: Int) throws -> [Double] {
        let random = Random(time(nil))
        var SPSA_parameters = Array<Double>(repeating:0.0, count: 5)
        SPSA_parameters[1] = initial_c
        SPSA_parameters[2] = 0.602
        SPSA_parameters[3] = 0.101
        SPSA_parameters[4] = 0
        let theta = Vector<Double>(value:initial_theta)
        var delta_obj: Double = 0
        for i in 0..<stat {
            if i % 5 == 0 {
                SDKLogger.logInfo("calibration step # \(i) of \(stat)")
            }
            var arr = Vector<Double>(repeating: 0, count: initial_theta.count)
            for i in 0..<arr.count {
                arr[i] = Double(random.randint(0, 2))
            }
            let delta = arr.mult(2).subtract(1)
            let obj_plus = obj_fun(try theta.add(delta.mult(initial_c)).value)
            let obj_minus = obj_fun(try theta.subtract(delta.mult(initial_c)).value)
            delta_obj += abs(obj_plus - obj_minus) / Double(stat)
        }
        SPSA_parameters[0] = target_update * 2 / delta_obj * SPSA_parameters[1] * (SPSA_parameters[4] + 1)

        SDKLogger.logInfo("calibrated SPSA_parameters[0] is \(SPSA_parameters[0])")

        return SPSA_parameters
    }

    /**
     Compute the expectation value of Z.

     Z is represented by Z^v where v has lenght number of qubits and is 1
     if Z is present and 0 otherwise.

     Args:
        data : a dictionary of the form data = {'00000': 10}
        pauli : a Pauli object
     Returns:
        Expected value of pauli given data
     */
    public static func measure_pauli_z(_ data: [String: Int], _ pauli: Pauli) -> Double {
        var observable: Double = 0.0
        let tot = Double(data.values.reduce(0, {$0 + $1}))
        for (key,dataValue) in data {
            var value: Double = 1.0
            let keyChars = Array(key)
            for j in 0..<pauli.numberofqubits {
                if ((pauli.v[j] == 1 || pauli.w[j] == 1) && keyChars[pauli.numberofqubits - j - 1] == "1") {
                    value = -value
                }
            }
            observable = observable + value * Double(dataValue) / tot
        }
        return observable
    }

    /**
     Compute expectation value of a list of diagonal Paulis with
     coefficients given measurement data. If somePaulis are non-diagonal
     appropriate post-rotations had to be performed in the collection of data

     Args:
        data : output of the execution of a quantum program
        pauli_list : list of [coeff, Pauli]
     Returns:
        The expectation value
     */
    public static func Energy_Estimate(_ data: [String: Int], _ pauli_list: [(Double,Pauli)]) -> Double {
        var energy: Double = 0
        for p in pauli_list {
            energy += p.0 * measure_pauli_z(data, p.1)
        }
        return energy
    }

    /**
     Returns bit string corresponding to quantum state index

     Args:
        state_index : basis index of a quantum state
        num_bits : the number of bits in the returned string
     Returns:
        A integer array with the binary representation of state_index
     */
    public static func index_2_bit(_ state_index: Int, _ num_bits: Int) -> [Int] {
        var binaryString = String(state_index, radix: 2)
        binaryString = String(repeating: "0", count: num_bits - binaryString.count) + binaryString
        var ret: [Int] = []
        for v in Array(binaryString) {
            ret.append(v == "1" ? 1 : 0)
        }
        return ret
    }

    /**
     Groups a list of (coeff,Pauli) tuples into tensor product basis (tpb) sets

     Args:
        pauli_list : a list of (coeff, Pauli object) tuples.
     Returns:
        A list of tpb sets, each one being a list of (coeff, Pauli object)
        tuples.
     */
    public static func group_paulis(_ pauli_list: [(Int,Pauli)]) -> [ [(Int,Pauli)] ] {
        let n = pauli_list[0].1.v.count
        var pauli_list_grouped: [ [(Int,Pauli)] ] = []
        var pauli_list_sorted = Set< HashableTuple<Int,Pauli> >()
        for p_1 in pauli_list {
            if !pauli_list_sorted.contains(HashableTuple<Int,Pauli>(p_1.0,p_1.1)) {
                var pauli_list_temp: [(Int,Pauli)] = []
                // pauli_list_temp.extend(p_1) # this is going to signal the total
                // post-rotations of the set (set master)
                pauli_list_temp.append(p_1)
                pauli_list_temp.append(p_1)
                pauli_list_temp[0].0 = 0
                for p_2 in pauli_list {
                    if !pauli_list_sorted.contains(HashableTuple<Int,Pauli>(p_2.0,p_2.1)) && p_1.1 != p_2.1 {
                        var j = 0
                        for i in 0..<n {
                            if !((p_2.1.v[i] == 0 && p_2.1.w[i] == 0) || (p_1.1.v[i] == 0 && p_1.1.w[i] == 0) ||
                                 (p_2.1.v[i] == p_1.1.v[i] && p_2.1.w[i] == p_1.1.w[i])) {
                                break
                            }
                            else {
                                // update master
                                if p_2.1.v[i] == 1 || p_2.1.w[i] == 1 {
                                    pauli_list_temp[0].1.v[i] = p_2.1.v[i]
                                    pauli_list_temp[0].1.w[i] = p_2.1.w[i]
                                }
                            }
                            j += 1
                        }
                        if j == n {
                            pauli_list_temp.append(p_2)
                            pauli_list_sorted.insert(HashableTuple<Int,Pauli>(p_2.0,p_2.1))
                        }
                    }
                }
                pauli_list_grouped.append(pauli_list_temp)
            }
        }
        return pauli_list_grouped
    }

    /**
     Print a list of Pauli operators which has been grouped into tensor
     product basis (tpb) sets.

     Args:
        pauli_list_grouped (list of lists of (coeff, pauli) tuples): the
        list of Pauli operators grouped into tpb sets
     Returns:
        None
     */
    public static func print_pauli_list_grouped(_ pauli_list_grouped: [ [(Int,Pauli)] ]) {
        for (i,pauli_list) in pauli_list_grouped.enumerated() {
            SDKLogger.logInfo("Post Rotations of TPB set \(i):")
            SDKLogger.logInfo(pauli_list[0].1.to_label())
            SDKLogger.logInfo("\(pauli_list[0].0)\n")
            for j in 0..<(pauli_list.count - 1) {
                SDKLogger.logInfo(pauli_list[j + 1].1.to_label())
                SDKLogger.logInfo("\(pauli_list[j + 1].0)")
            }
            SDKLogger.logInfo("\n")
        }
    }

    /**
     Calculates the average value of a Hamiltonian on a state created by the input circuit

     Args:
        Q_program : QuantumProgram object used to run the imput circuit.
        hamiltonian (array, matrix or list of Pauli operators grouped into
            tpb sets) :
            a representation of the Hamiltonian or observables to be measured.
        shots (int) : number of shots considered in the averaging. If 1 the
            averaging is exact.
        device : the backend used to run the simulation.
     Returns:
        Average value of the Hamiltonian or observable.
     */
    public static func eval_hamiltonian(_ Q_program: QuantumProgram,
                                        _ hamiltonian: Any,
                                        _ input_circuit: QuantumCircuit,
                                        _ shots: Int,
                                        _ device: String,
                                        _ callback: @escaping ((_:Complex, _:Error?) -> Void)) -> RequestTask {
        return eval_hamiltonianInternal(Q_program,
                                        hamiltonian,
                                        input_circuit,
                                        shots,
                                        device) { (ret,error) in
            DispatchQueue.main.async {
                callback(ret,error)
            }
        }
    }

    private static func eval_hamiltonianInternal(_ Q_program: QuantumProgram,
                                                 _ hamiltonian: Any,
                                                 _ input_circuit: QuantumCircuit,
                                                 _ shots: Int,
                                                 _ device: String,
                                                 _ callback: @escaping ((_:Complex, _:Error?) -> Void)) -> RequestTask {
        var energy: Complex = 0.0
        var requestTask = RequestTask()
        do {
            if shots == 1 {
                // Hamiltonian represented by a Pauli list
                if let hamiltonianList = hamiltonian as? [(Double,Pauli)]  { // Hamiltonian represented by a Pauli list
                    var circuits: [QuantumCircuit] = []
                    var circuits_labels: [String] = []
                    circuits.append(input_circuit)
                    // Trial circuit w/o the final rotations
                    circuits_labels.append("circuit_label0")
                    try Q_program.add_circuit(circuits_labels[0], circuits[0])
                    // Execute trial circuit with final rotations for each Pauli in
                    // hamiltonian and store from circuits[1] on
                    guard let n_qubits = input_circuit.regs["q"]?.size else {
                        throw ToolsError.unknownHamiltonian
                    }
                    let q = try QuantumRegister("q", n_qubits)
                    var i: Int = 1
                    for p in hamiltonianList {
                        circuits.append(input_circuit.copy())
                        for j in 0..<n_qubits {
                            if p.1.v[j] == 1 && p.1.w[j] == 0 {
                                try circuits[i].x(q[j])
                            }
                            else if p.1.v[j] == 0 && p.1.w[j] == 1 {
                                try circuits[i].z(q[j])
                            }
                            else if p.1.v[j] == 1 && p.1.w[j] == 1 {
                                try circuits[i].y(q[j])
                            }
                        }
                        circuits_labels.append("circuit_label\(i)")
                        try Q_program.add_circuit(circuits_labels[i], circuits[i])
                        i += 1
                    }
                    requestTask = Q_program.execute(circuits_labels, backend: device, shots: shots) { (result) in
                        if let error = result.get_error() {
                            callback(energy,error)
                            return
                        }
                        do {
                            // no Pauli final rotations
                            if let q_0 = try result.get_data(circuits_labels[0])["quantum_state"] as? [Complex] {
                                let quantum_state_0 = Vector<Complex>(value:q_0)
                                i = 1
                                for p in hamiltonianList {
                                    if let q_i = try result.get_data(circuits_labels[i])["quantum_state"] as? [Complex] {
                                        let quantum_state_i = Vector<Complex>(value:q_i)
                                        // inner product with final rotations of (i-1)-th Pauli
                                        energy += try quantum_state_0.conjugate().inner(quantum_state_i) * p.0
                                    }
                                    i += 1
                                }
                            }
                            callback(energy,nil)
                        } catch {
                            callback(energy,error)
                        }
                    }
                }
                else {
                    // Hamiltonian is not a pauli_list grouped into tpb sets
                    var circuit = ["c"]
                    try Q_program.add_circuit(circuit[0], input_circuit)
                    requestTask = Q_program.execute(circuit, backend: device, config: ["data": ["quantum_state"]], shots: shots) { (result) in
                        if let error = result.get_error() {
                            callback(energy,error)
                            return
                        }
                        do {
                            var quantum_state: Vector<Complex> = []
                            if let q = try result.get_data(circuit[0])["quantum_state"] as? [Complex] {
                                quantum_state = Vector<Complex>(value:q)
                            }
                            else {
                                if let q = try result.get_data(circuit[0])["quantum_states"] as? [[Complex]] {
                                    if q.count > 0 {
                                        quantum_state = Vector<Complex>(value:q[0])
                                    }
                                }
                            }

                            // Diagonal Hamiltonian represented by 1D array
                            if let h = hamiltonian as? [Complex] {
                                let hamiltonianVector = Vector<Complex>(value:h)
                                energy = try hamiltonianVector.mult(Vector<Complex>(value:quantum_state.absolute()).power(2)).sum()
                            }
                            // Hamiltonian represented by square matrix
                            else if let h = hamiltonian as? [[Complex]] {
                                //TODO fix this hamiltonian calculation
                                let hamiltonianMatrix = Matrix<Complex>(value:h)
                                let m = Matrix<Complex>(value: [quantum_state.value])
                                energy = try quantum_state.conjugate().inner(Vector<Complex>(value:hamiltonianMatrix.dot(m).value[0]))
                            }
                            else {
                                callback(energy,ToolsError.unknownHamiltonian)
                                return
                            }
                            callback(energy,nil)
                        } catch {
                            callback(energy,error)
                        }
                    }
                }
            }
            else if let hamiltonianMatrix = hamiltonian as? [[(Double,Pauli)]] { // finite number of shots and hamiltonian grouped in tpb sets
                var circuits: [QuantumCircuit] = []
                var circuits_labels: [String] = []
                let n = hamiltonianMatrix[0][0].1.v.count
                let q = try QuantumRegister("q", n)
                let c = try ClassicalRegister("c", n)
                var i: Int = 0
                for tpb_set in hamiltonianMatrix {
                    circuits.append(input_circuit.copy())
                    circuits_labels.append("tpb_circuit_\(i)")
                    for j in 0..<n {
                        // Measure X
                        if tpb_set[0].1.v[j] == 0 && tpb_set[0].1.w[j] == 1 {
                            try circuits[i].h(q[j])
                        }
                        // Measure Y
                        else if tpb_set[0].1.v[j] == 1 && tpb_set[0].1.w[j] == 1 {
                            try circuits[i].s(q[j]).inverse()
                            try circuits[i].h(q[j])
                        }
                        try circuits[i].measure(q[j], c[j])
                    }
                    try Q_program.add_circuit(circuits_labels[i], circuits[i])
                    i += 1
                }
                requestTask = Q_program.execute(circuits_labels, backend: device, shots: shots) { (result) in
                    if let error = result.get_error() {
                        callback(energy,error)
                        return
                    }
                    do {
                        for j in 0..<hamiltonianMatrix.count {
                            for k in 0..<hamiltonianMatrix[j].count {
                                energy +=
                                    hamiltonianMatrix[j][k].0 * measure_pauli_z(try result.get_counts(circuits_labels[j]), hamiltonianMatrix[j][k].1)
                            }
                        }
                        callback(energy,nil)
                    } catch {
                        callback(energy,error)
                    }
                }
            }
            else {
                callback(energy,ToolsError.unknownHamiltonian)
            }
        } catch {
            callback(energy,error)
        }
        return requestTask
    }

    /**
     Creates a QuantumCircuit object consisting in layers of
     parametrized single-qubit Y rotations and CZ two-qubit gates

     Args:
         n (int) : number of qubits
         m (int) : depth of the circuit
         theta array[float] : angles that parametrize the Y rotations
         entangler_map : CZ connectivity, e.g. {0: [1], 1: [2]}
         meas_string (str) : measure a given Pauli operator at the end of the
         circuit
         measurement (bool) : whether to measure the qubit (register "q")
         on classical bits (register "c")
     Returns:
        A QuantumCircuit object
     */
    public static func trial_circuit_ry(_ n: Int,
                                        _ m: Int,
                                        _ theta: [Double],
                                        _ entangler_map: [Int:[Int]],
                                        _ meas_string: String? = nil,
                                        _ measurement: Bool = true) throws -> QuantumCircuit {
        let q = try QuantumRegister("q", n)
        let c = try ClassicalRegister("c", n)
        let trial_circuit = try QuantumCircuit([q, c])
        try trial_circuit.h(q)
        let meas = Array(meas_string != nil ? meas_string! : String(repeating: " ", count: n))
        for i in 0..<m {
            try trial_circuit.barrier(q)
            for (node,value) in entangler_map {
                for j in value {
                    try trial_circuit.cz(q[node], q[j])
                }
            }
            for j in 0..<n {
                try trial_circuit.ry(theta[n * i + j], q[j])
            }
        }
        try trial_circuit.barrier(q)
        for j in 0..<n {
            if meas[j] == "X" {
                try trial_circuit.h(q[j])
            }
            else if meas[j] == "Y" {
                try trial_circuit.s(q[j]).inverse()
                try trial_circuit.h(q[j])
            }
        }
        if measurement {
            for j in 0..<n {
                try trial_circuit.measure(q[j], c[j])
            }
        }
        return trial_circuit
    }

    /**
     Creates a QuantumCircuit object consisting in layers of
     parametrized single-qubit Y and Z rotations and CZ two-qubit gates

     Args:
         n (int) : number of qubits
         m (int) : depth of the circuit
         theta array[float] : angles that parametrize the Y and Z rotations
         entangler_map : CZ connectivity, e.g. {0: [1], 1: [2]}
         meas_string (str) : measure a given Pauli operator at the end of the
         circuit
         measurement (bool) : whether to measure the qubit (register "q")
         on classical bits (register "c")
     Returns:
        A QuantumCircuit object
     */
    public static func trial_circuit_ryrz(_ n: Int,
                                          _ m: Int,
                                          _ theta: [Double],
                                          _ entangler_map: [Int:[Int]],
                                          _ meas_string: String? = nil,
                                          _ measurement: Bool = true) throws -> QuantumCircuit {
        let q = try QuantumRegister("q", n)
        let c = try ClassicalRegister("c", n)
        let trial_circuit = try QuantumCircuit([q, c])
        try trial_circuit.h(q)
        let meas = Array(meas_string != nil ? meas_string! : String(repeating: " ", count:n))
        for i in 0..<m {
            try trial_circuit.barrier(q)
            for (node,value) in entangler_map {
                for j in value {
                    try trial_circuit.cz(q[node], q[j])
                }
            }
            for j in 0..<n {
                try trial_circuit.ry(theta[n * i * 2 + 2 * j], q[j])
                try trial_circuit.rz(theta[n * i * 2 + 2 * j + 1], q[j])
            }
        }
        try trial_circuit.barrier(q)
        for j in 0..<n {
            if meas[j] == "X" {
                try trial_circuit.h(q[j])
            }
            else if meas[j] == "Y" {
                try trial_circuit.s(q[j]).inverse()
                try trial_circuit.h(q[j])
            }
        }
        if measurement {
            for j in 0..<n {
                try trial_circuit.measure(q[j], c[j])
            }
        }
        return trial_circuit
    }

    /**
     Creates a matrix operator out of a list of Paulis.

     Args:
        pauli_list : list of list [coeff,Pauli]
     Returns:
        A matrix representing pauli_list
     */
    public static func make_Hamiltonian(_ pauli_list: [(Double,Pauli)]) throws -> Matrix<Complex> {
        var Hamiltonian = Matrix<Complex>()
        for p in pauli_list {
            let m = try p.1.to_matrix().mult(Complex(real:p.0))
            Hamiltonian = Hamiltonian.shape != (0,0) ? try Hamiltonian.add(m) : m
        }
        return Hamiltonian
    }

    /**
     Creates a matrix operator out of a file with a list
     of Paulis.

     Args:
        file_name : a text file containing a list of Paulis and
        coefficients.
     Returns:
        A matrix representing pauli_list
     */
    public static func Hamiltonian_from_file(_ file_name: String) throws -> [(Double,Pauli)] {
        let fileContent = try String(contentsOfFile: file_name, encoding: .utf8)
        var ham_array = fileContent.components(separatedBy: "\n")
        ham_array = ham_array.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var pauli_list: [(Double,Pauli)] = []
        for i in 0..<(ham_array.count / 2) {
            let pauli = try Pauli.label_to_pauli(ham_array[2 * i])
            if let Numb = Double(ham_array[2 * i + 1]) {
                pauli_list.append((Numb, pauli))
            }
        }
        return pauli_list
    }
}
