// Copyright 2018 IBM RESEARCH. All Rights Reserved.
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

import qiskit
import CWebkitGtk_Linux
import Dispatch
import Foundation

gtk_init(nil, nil)

let window = window_widget()
let notebook = notebook_widget()
add_widget(notebook, to: window)

let histogram_semaphore = DispatchSemaphore(value: 1)
let state_semaphore = DispatchSemaphore(value: 1)

do {
    let Q_program = try QuantumProgram()
    let n = 3  // number of qubits
    let q = try Q_program.create_quantum_register("q", n)
    let c = try Q_program.create_classical_register("c", n)

    // quantum circuit to make a GHZ state
    let ghz_name = "ghz"
    let ghz = try Q_program.create_circuit(ghz_name, [q], [c])
    try ghz.h(q[0])
    try ghz.cx(q[0], q[1])
    try ghz.cx(q[0], q[2])
    try ghz.s(q[0])
    try ghz.measure(q[0], c[0])
    try ghz.measure(q[1], c[1])
    try ghz.measure(q[2], c[2])
    print(ghz.qasm())

    // quantum circuit to make a superpostion state
    let superposition_name = "superposition"
    let superposition = try Q_program.create_circuit(superposition_name, [q], [c])
    try superposition.h(q)
    try superposition.s(q[0])
    try superposition.measure(q[0], c[0])
    try superposition.measure(q[1], c[1])
    try superposition.measure(q[2], c[2])
    print(superposition.qasm())

    let circuits = [ghz_name, superposition_name]

    // execute the quantum circuit
    histogram_semaphore.wait()
    var backend = "local_qasm_simulator" // the device to run on
    Q_program.execute(circuits, backend: backend, shots: 1000) { (result) in
        if let error = result.get_error() {
            print(error)

            histogram_semaphore.signal()

            return
        }

        do {
            let ghz_histogram = plot_histogram(try result.get_counts(ghz_name))
            insert_page(ghz_histogram, in: notebook, position: 0, title: "Ghz Hist.")

            let superposition_histogram = plot_histogram(try result.get_counts(superposition_name))
            insert_page(superposition_histogram, in: notebook, position: 1, title: "Super. Hist.")
        } catch {
            print(error)
        }

        histogram_semaphore.signal()
    }

    // execute the quantum circuit
    state_semaphore.wait()
    backend = "local_unitary_simulator" // the device to run on
    Q_program.execute(circuits, backend: backend, shots: 1000) { (result) in
        if let error = result.get_error() {
            print(error)

            state_semaphore.signal()

            return
        }

        let groundRows = Int(truncating: NSDecimalNumber(decimal: Decimal(pow(Double(2), Double(n)))))
        var ground = Matrix(repeating: Complex(integerLiteral: 0), rows: groundRows, cols: 1)
        ground[0, 0] = Complex(integerLiteral: 1)

        do {
            guard let ghz_unitary = try result.get_data(ghz_name)["unitary"] as? Matrix<Complex>,
                let superposition_unitary = try result.get_data(superposition_name)["unitary"] as? Matrix<Complex> else {
                    print("Unable to get unitary matrices")

                    state_semaphore.signal()

                    return
            }

            let state_ghz = ghz_unitary.dot(ground)
            let flatten_state_ghz = state_ghz.flattenRow()
            let rho_ghz = flatten_state_ghz.outer(flatten_state_ghz.conjugate())

            let ghz_city = plot_state(rho_ghz, .city)
            insert_page(ghz_city, in: notebook, position: 2, title: "Ghz City")

            let ghz_paulivec = plot_state(rho_ghz, .paulivec)
            insert_page(ghz_paulivec, in: notebook, position: 3, title: "Ghz Pauli.")

            let ghz_qsphere = plot_state(rho_ghz, .qsphere)
            insert_page(ghz_qsphere, in: notebook, position: 4, title: "Ghz Qsphere")

            let state_superposition = superposition_unitary.dot(ground)
            let flatten_state_superposition = state_superposition.flattenRow()
            let rho_superposition = flatten_state_superposition.outer(flatten_state_superposition.conjugate())

            let superposition_city = plot_state(rho_superposition, .city)
            insert_page(superposition_city, in: notebook, position: 5, title: "Super. City")

            let superposition_paulivec = plot_state(rho_superposition, .paulivec)
            insert_page(superposition_paulivec, in: notebook, position: 6, title: "Super. Pauli.")

            let superposition_qsphere = plot_state(rho_superposition, .qsphere)
            insert_page(superposition_qsphere, in: notebook, position: 7, title: "Super. Qsphere")

            let superposition_bloch = plot_state(rho_superposition, .bloch)
            insert_page(superposition_bloch, in: notebook, position: 8, title: "Super. Bloch")

            let rho_superposition_by_half = rho_superposition.mult(Complex(0.5, 0))
            let rho_ghz_by_half = rho_ghz.mult(Complex(0.5, 0))
            let added_rho = try rho_superposition_by_half.add(rho_ghz_by_half)
            let added_qsphere = plot_state(added_rho, .qsphere)
            insert_page(added_qsphere, in: notebook, position: 9, title: "Added Qsphere")
        } catch {
            print(error)
        }

        state_semaphore.signal()
    }
} catch {
    print(error)
}

let handler: @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Void = { sender, data in
    gtk_main_quit()
    exit(0)
}
g_signal_connect_data(window, "destroy", unsafeBitCast(handler, to: GCallback.self), nil, nil, G_CONNECT_AFTER)

DispatchQueue.global().async {
    histogram_semaphore.wait()
    histogram_semaphore.signal()

    state_semaphore.wait()
    state_semaphore.signal()

    DispatchQueue.main.async {
        gtk_widget_show_all(window)

        gtk_main()
    }
}

RunLoop.main.run()
