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

/**
 A set of functions to map fermionic Hamiltonians to qubit Hamiltonians.

 References:
 - E. Wigner and P. Jordan., Über das Paulische Äguivalenzverbot,
    Z. Phys., 47:631 (1928).
 - S. Bravyi and A. Kitaev. Fermionic quantum computation,
    Ann. of Phys., 298(1):210–226 (2002).
 - A. Tranter, S. Sofia, J. Seeley, M. Kaicher, J. McClean, R. Babbush,
    P. Coveney, F. Mintert, F. Wilhelm, and P. Love. The Bravyi–Kitaev
    transformation: Properties and applications. Int. Journal of Quantum
    Chemistry, 115(19):1431–1441 (2015).
 - S. Bravyi, J. M. Gambetta, A. Mezzacapo, and K. Temme,
    arXiv e-print arXiv:1701.08213 (2017).
 */
public final class Fermion {

    private init() {
    }

    /**
     Computes the parity set of the j-th orbital in n modes

     Args:
        j (int) : the orbital index
        n (int) : the total number of modes
     Returns:
        Array of mode indexes
     */
    public static func parity_set(_ j: Int, _ n: Int) -> [Int] {
        var indexes: [Int] = []
        if n % 2 == 0 {
            if j < n / 2 {
                indexes = parity_set(j, n / 2)
            }
            else {
                indexes = parity_set(j - n / 2, n / 2).map { $0 + n / 2 }
                indexes.append(n / 2 - 1)
            }
        }
        return indexes
    }

    /**
     Computes the update set of the j-th orbital in n modes

     Args:
        j (int) : the orbital index
        n (int) : the total number of modes
     Returns:
        Array of mode indexes
     */
    public static func update_set(_ j: Int, _ n: Int) -> [Int] {
        var indexes: [Int] = []
        if n % 2 == 0 {
            if j < n / 2 {
                indexes = [n-1]
                indexes.append(contentsOf: update_set(j, n / 2))
            }
            else {
                indexes = update_set(j - n / 2, n / 2).map { $0 + n / 2 }
            }
        }
        return indexes
    }

    /**
     Computes the flip set of the j-th orbital in n modes

     Args:
        j (int) : the orbital index
        n (int) : the total number of modes
     Returns:
        Array of mode indexes
     */
    public static func flip_set(_ j: Int, _ n: Int) -> [Int] {
        var indexes: [Int] = []
        if n % 2 == 0 {
            if j < n / 2 {
                indexes = flip_set(j, n / 2)
            }
            else if j >= n / 2 && j < n - 1 {
                indexes = flip_set(j - n / 2, n / 2).map { $0 + n / 2 }
            }
            else {
                indexes = flip_set(j - n / 2, n / 2).map { $0 + n / 2 }
                indexes.append(n / 2 - 1)
            }
        }
        return indexes
    }

    /**
     """Appends a Pauli term to a Pauli list

     If pauli_term is already present in the list adjusts the coefficient
     of the existing pauli. If the new coefficient is less than
     threshold the pauli term is deleted from the list

     Args:
        pauli_term : list of [coeff, pauli]
        pauli_list : a list of pauli_terms
        threshold : simplification threshold
     Returns:
        an updated pauli_list
     */
    public static func pauli_term_append(_ pauli_term: (Complex,Pauli),
                                         _ p_list: [(Complex,Pauli)],
                                         _ threshold: Double) -> [(Complex,Pauli)] {
        var pauli_list = p_list
        var found = false
        if pauli_term.0.absolute() > threshold {
            if !pauli_list.isEmpty {   // if the list is not empty
                for i in 0..<pauli_list.count {
                    // check if the new pauli belongs to the list
                    if pauli_list[i].1 == pauli_term.1 {
                        // if found renormalize the coefficient of existent pauli
                        pauli_list[i].0 += pauli_term.0
                        // remove the element if coeff. value is now less than
                        // threshold
                        if pauli_list[i].0.absolute() < threshold {
                            pauli_list.remove(at: i)
                        }
                        found = true
                        break
                    }
                }
                if !found { // if not found add the new pauli
                    pauli_list.append(pauli_term)
                }
            }
            else {
                // if list is empty add the new pauli
                pauli_list.append(pauli_term)
            }
        }
        return pauli_list
    }

    /**
     Creates a list of Paulis with coefficients from fermionic one and
     two-body operator.

     Args:
         h1 : second-quantized fermionic one-body operator
         h2 : second-quantized fermionic two-body operator
         map_type : "JORDAN_WIGNER", "PARITY", "BINARY_TREE"
         out_file : name of the optional file to write the Pauli list on
         threshold : threshold for Pauli simplification
     Returns:
         A list of Paulis with coefficients
     */
    public static func fermionic_maps(_ h1: [[Double]],
                                      _ h2: [[[[Double]]]],
                                      _ map_type: String,
                                      _ out_file: String? = nil,
                                      _ threshold: Double = 0.000000000001) throws -> [(Complex,Pauli)] {

        //####################################################################
        //############   DEFINING MAPPED FERMIONIC OPERATORS    ##############
        //####################################################################

        var pauli_list: [(Complex,Pauli)] = []
        let n = h1.count  // number of fermionic modes / qubits
        var a: [[Pauli]] = []
        if map_type == "JORDAN_WIGNER" {
            for i in 0..<n {
                var xv = [Int](repeating: 1, count: i)
                xv.append(0)
                xv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                var xw = [Int](repeating: 0, count: i)
                xw.append(1)
                xw.append(contentsOf: [Int](repeating:0, count:n-i-1))
                var yv = [Int](repeating: 1, count: i)
                yv.append(1)
                yv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                var yw = [Int](repeating: 0, count: i)
                yw.append(1)
                yw.append(contentsOf: [Int](repeating:0, count:n-i-1))
                // defines the two mapped Pauli components of a_i and a_i^\dag,
                // according to a_i -> (a[i][0]+i*a[i][1])/2,
                // a_i^\dag -> (a_[i][0]-i*a[i][1])/2
                a.append([Pauli(xv, xw), Pauli(yv, yw)])
            }
        }
        if map_type == "PARITY" {
            for i in 0..<n {
                var Xv: [Int] = []
                var Xw: [Int] = []
                var Yv: [Int] = []
                var Yw: [Int] = []
                if i > 1 {
                    Xv = [Int](repeating: 0, count: i-1)
                    Xv.append(contentsOf: [1,0])
                    Xv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                    Xw = [Int](repeating: 0, count: i-1)
                    Xw.append(contentsOf: [0,1])
                    Xw.append(contentsOf: [Int](repeating:1, count:n-i-1))
                    Yv = [Int](repeating: 0, count: i-1)
                    Yv.append(contentsOf: [0,1])
                    Yv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                    Yw = [Int](repeating: 0, count: i-1)
                    Yw.append(contentsOf: [0,1])
                    Yw.append(contentsOf: [Int](repeating:1, count:n-i-1))
                }
                else if i > 0 {
                    Xv = [1, 0]
                    Xv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                    Xw = [0, 1]
                    Xw.append(contentsOf: [Int](repeating:1, count:n-i-1))
                    Yv = [0, 1]
                    Yv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                    Yw = [0, 1]
                    Yv.append(contentsOf: [Int](repeating:1, count:n-i-1))
                }
                else {
                    Xv = [0]
                    Xv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                    Xw = [1]
                    Xw.append(contentsOf: [Int](repeating:1, count:n-i-1))
                    Yv = [1]
                    Yv.append(contentsOf: [Int](repeating:0, count:n-i-1))
                    Yw = [1]
                    Yv.append(contentsOf: [Int](repeating:1, count:n-i-1))
                }
                // defines the two mapped Pauli components of a_i and a_i^\dag,
                // according to a_i -> (a[i][0]+i*a[i][1])/2,
                // a_i^\dag -> (a_[i][0]-i*a[i][1])/2
                a.append([Pauli(Xv, Xw), Pauli(Yv, Yw)])
            }
        }
        if map_type == "BINARY_TREE" {
            // FIND BINARY SUPERSET SIZE
            var bin_sup: Double = 1.0
            while Double(n) > pow(2.0, bin_sup) {
                bin_sup += 1.0
            }
            // DEFINE INDEX SETS FOR EVERY FERMIONIC MODE
            var update_sets: [[Int]] = []
            var update_pauli: [Pauli] = []

            var parity_sets: [[Int]] = []
            var parity_pauli: [Pauli] = []

            var flip_sets: [[Int]] = []

            var remainder_sets: [[Int]] = []
            var remainder_pauli: [Pauli] = []
            for j in 0..<n {

                update_sets.append(update_set(j, Int(pow(2.0, bin_sup))))
                var indexes = Set<Int>(update_sets[j].filter() { $0 < n })
                update_sets[j] = update_sets[j].enumerated().filter({ indexes.contains($0.offset)}).map() { $0.element }

                parity_sets.append(parity_set(j, Int(pow(2.0, bin_sup))))
                indexes = Set<Int>(parity_sets[j].filter() { $0 < n })
                parity_sets[j] = parity_sets[j].enumerated().filter({ indexes.contains($0.offset)}).map() { $0.element }

                flip_sets.append(flip_set(j, Int(pow(2.0, bin_sup))))
                indexes = Set<Int>(flip_sets[j].filter() { $0 < n })
                flip_sets[j] = flip_sets[j].enumerated().filter({ indexes.contains($0.offset)}).map() { $0.element }

                remainder_sets.append(Vector<Int>(value:parity_sets[j]).setdiff1d(Vector<Int>(value:flip_sets[j])).value)

                update_pauli.append(Pauli([Int](repeating: 0, count: n),[Int](repeating: 0, count: n)))
                parity_pauli.append(Pauli([Int](repeating: 0, count: n),[Int](repeating: 0, count: n)))
                remainder_pauli.append(Pauli([Int](repeating: 0, count: n),[Int](repeating: 0, count: n)))
                for k in 0..<n {
                    if Set<Int>(update_sets[j]).contains(k) {
                        update_pauli[j].w[k] = 1
                    }
                    if Set<Int>(parity_sets[j]).contains(k) {
                        parity_pauli[j].v[k] = 1
                    }
                    if Set<Int>(remainder_sets[j]).contains(k) {
                        remainder_pauli[j].v[k] = 1
                    }
                }
                var x_j = Pauli([Int](repeating: 0, count: n),[Int](repeating: 0, count: n))
                x_j.w[j] = 1
                var y_j = Pauli([Int](repeating: 0, count: n),[Int](repeating: 0, count: n))
                y_j.v[j] = 1
                y_j.w[j] = 1
                // defines the two mapped Pauli components of a_i and a_i^\dag,
                // according to a_i -> (a[i][0]+i*a[i][1])/2, a_i^\dag ->
                // (a_[i][0]-i*a[i][1])/2
                a.append([try update_pauli[j].multiply(x_j).multiply(parity_pauli[j]),
                          try update_pauli[j].multiply(y_j).multiply(remainder_pauli[j])])
            }
        }
        //####################################################################
        //############    BUILDING THE MAPPED HAMILTONIAN     ################
        //####################################################################

        //#######################    One-body    #############################

        for i in 0..<n {
            for j in 0..<n {
                if h1[i][j] != 0 {
                    for alpha in 0..<2 {
                        for beta in 0..<2 {
                            let pauli_prod = try Pauli.sgn_prod(a[i][alpha], a[j][beta])
                            let pauli_term = (h1[i][j] *
                                                1 / 4 *
                                                pauli_prod.1 *
                                                Complex(imag:-1).power(alpha) *
                                                Complex(imag:1).power(beta),
                                                pauli_prod.0)
                            pauli_list = pauli_term_append(pauli_term, pauli_list, threshold)
                        }
                    }
                }
            }
        }
        //#######################    Two-body    #############################

        for i in 0..<n {
            for j in 0..<n {
                for k in 0..<n {
                    for m in 0..<n {
                        if h2[i][j][k][m] != 0 {
                            for alpha in 0..<2 {
                                for beta in 0..<2 {
                                    for gamma in 0..<2 {
                                        for delta in 0..<2 {

                                            // Note: chemists' notation for the
                                            // labeling,
                                            // h2(i,j,k,m) adag_i adag_k a_m a_j

                                            let pauli_prod_1 = try Pauli.sgn_prod(a[i][alpha], a[k][beta])
                                            let pauli_prod_2 = try Pauli.sgn_prod(pauli_prod_1.0, a[m][gamma])
                                            let pauli_prod_3 = try Pauli.sgn_prod(pauli_prod_2.0, a[j][delta])

                                            let phase1 = pauli_prod_1.1 * pauli_prod_2.1 * pauli_prod_3.1
                                            let phase2 = Complex(imag:-1).power(alpha + beta) *
                                                         Complex(imag: 1).power(gamma + delta)
                                            let pauli_term = (h2[i][j][k][m] * 1 / 16 * phase1 * phase2,
                                                              pauli_prod_3.0)
                                            pauli_list = pauli_term_append(pauli_term, pauli_list, threshold)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        //####################################################################
        //#################          WRITE TO FILE         ###################
        //####################################################################

        if let out = out_file {
            var out_stream = ""
            for pauli_term in pauli_list {
                out_stream += pauli_term.1.to_label() + "\n"
                out_stream += pauli_term.0.real.format(15) + "\n"
            }
            try out_stream.write(toFile: out, atomically: true, encoding: .utf8)
        }
        return pauli_list
    }

    /**
     Eliminates the central and last qubit in a list of Pauli that has
     diagonal operators (Z,I) at those positions.abs

     It can be used to taper two qubits in parity and binary-tree mapped
     fermionic Hamiltonians when the spin orbitals are ordered in two spin
     sectors, according to the number of particles in the system.

     Args:
         ham_in : a list of Paulis representing the mapped fermionic Hamiltonian
         m (int) : number of fermionic particles
         out_file (string) : option to write the simplified Hamiltonian to a
         file
         out_file : name of the optional file to write the Pauli list on
         threshold : threshold for Pauli simplification
     Returns:
        A tapered Hamiltonian in the form of list of Paulis with coefficients
     */
    public static func two_qubit_reduction(_ ham_any: Any,
                                           _ m: Int,
                                           _ out_file: String? = nil,
                                           _ threshold: Double = 0.000000000001) throws -> [(Complex,Pauli)] {
        var ham_out: [(Complex,Pauli)] = []
        var par_1: Double = 0
        var par_2: Double = 0
        if m % 4 == 0 {
            par_1 = 1
            par_2 = 1
        }
        else if m % 4 == 1 {
            par_1 = -1
            par_2 = -1    // could be also +1, +1/-1 are  spin-parity sectors
        }
        else if m % 4 == 2 {
            par_1 = 1
            par_2 = -1
        }
        else {
            par_1 = -1
            par_2 = -1    // could be also +1, +1/-1 are  spin-parity sectors
        }
        var ham_in: [(Complex,Pauli)] = []
        if let file_name = ham_any as? String {
            // conversion from Hamiltonian text file to pauli_list
            let hamf = try Optimization.Hamiltonian_from_file(file_name)
            for h in hamf {
                ham_in.append((Complex(real:h.0),h.1))
            }
        }
        else if let h = ham_any as? [(Complex,Pauli)] {
            ham_in = h
        }
        else {
            throw ToolsError.unknownHamiltonian
        }
        // number of qubits
        let n = ham_in[0].1.v.count
        for pauli_term in ham_in {  // loop over Pauli terms
            var coeff_out = pauli_term.0
            // Z operator encountered at qubit n/2-1
            if pauli_term.1.v[n / 2 - 1] == 1 && pauli_term.1.w[n / 2 - 1] == 0 {
                coeff_out = par_2 * coeff_out
            }
            // Z operator encountered at qubit n-1
            if pauli_term.1.v[n - 1] == 1 && pauli_term.1.w[n - 1] == 0 {
                coeff_out = par_1 * coeff_out
            }
            var v_temp: [Int] = []
            var w_temp: [Int] = []
            for j in 0..<n {
                if j != (n / 2 - 1) && j != (n - 1) {
                    v_temp.append(pauli_term.1.v[j])
                    w_temp.append(pauli_term.1.w[j])
                }
            }
            let pauli_term_out = (coeff_out, Pauli(v_temp, w_temp))
            ham_out = pauli_term_append(pauli_term_out, ham_out, threshold)
        }
        //####################################################################
        //#################          WRITE TO FILE         ###################
        //####################################################################

        if let out = out_file {
            var out_stream = ""
            for pauli_term in ham_out {
                out_stream += pauli_term.1.to_label() + "\n"
                out_stream += pauli_term.0.real.format(15) + "\n"
            }
            try out_stream.write(toFile: out, atomically: true, encoding: .utf8)
        }
        return ham_out
    }
}
