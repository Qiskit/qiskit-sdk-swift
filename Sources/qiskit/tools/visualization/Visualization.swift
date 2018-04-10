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

import Foundation

// MARK: - Public types

public enum Method {
    case city
    case paulivec
    case bloch
    case qsphere
}

// MARK: - Public methods

public func plot_histogram(_ counts: [String : Int],
                           size: VisualizationTypes.Size = VisualizationTypes.Size(width: 600, height: 600)) -> VisualizationTypes.View {
    let labels = Array(counts.keys)

    let values = Array(counts.values)
    let total = Double(values.reduce(0, +))
    let probabilities = values.map { Double($0) / total }

    let configuration = BarChartConfiguration(alignXAxisTickWithLabel: true,
                                              yAxisName: "Probabilities",
                                              showValueOnTop: true)

    let html = BarChartHtmlFactory.makeHtml(labels: labels,
                                            values: probabilities,
                                            configuration: configuration)

    return WebViewFactory.makeWebView(size: size, html: html)
}

public func plot_state(_ rho: Matrix<Complex>,
                       _ method: Method = .city,
                       size: VisualizationTypes.Size = VisualizationTypes.Size(width: 600, height: 1200)) -> VisualizationTypes.View {
    switch method {
    case .city:
        return plot_state_city(rho, size: size)
    case .paulivec:
        return plot_state_paulivec(rho, size: size)
    case .bloch:
        return plot_state_bloch(rho, size: size)
    case .qsphere:
        return plot_state_qsphere(rho, size: size)
    }
}

// MARK: - Private methods

private func plot_state_city(_ rho: Matrix<Complex>,
                             size: VisualizationTypes.Size) -> VisualizationTypes.View {
    assert(rho.isSquare)
    let rowCount = rho.rowCount

    let numberOfBits = Int(log2(Double(rowCount)))
    let rows = Array(0..<rowCount).map { String($0, radix: 2).zfill(numberOfBits) }
    let cols = rows

    let realValues = rho.real().columnRowValueArray()
    let imagValues = rho.imag().columnRowValueArray()

    let html = StateCityChartHtmlFactory.makeHtml(xLabels: cols,
                                                  yLabels: rows,
                                                  realValues: realValues,
                                                  imagValues: imagValues)

    return WebViewFactory.makeWebView(size: size, html: html)
}

private func plot_state_paulivec(_ rho: Matrix<Complex>,
                                 size: VisualizationTypes.Size) -> VisualizationTypes.View {
    let rowCount = rho.rowCount
    let numberOfBits = Int(log2(Double(rowCount)))
    let pauliGroup = pauli_group(numberOfBits)

    var labels: [String] = [""]
    var values: [Double] = [Double(0)]
    for pauli in pauliGroup {
        labels.append(pauli.to_label())
        values.append(pauli_to_matrix(pauli).dot(rho).trace().real)
    }
    labels.append("")
    values.append(Double(0))

    let configuration = BarChartConfiguration(xAxisName: "Pauli",
                                              showXAxisSplitLine: true,
                                              yAxisName: "Expectation value",
                                              showYAxisSplitLine: true)

    let html = BarChartHtmlFactory.makeHtml(labels: labels,
                                            values: values,
                                            configuration: configuration)

    return WebViewFactory.makeWebView(size: size, html: html)
}

private func pauli_group(_ numberofqubits: Int) -> [Pauli] {
    var group: [Pauli] = []

    do {
        group = try Pauli.pauli_group(numberofqubits)
    } catch {
        print(error)
    }

    return group
}

private func pauli_to_matrix(_ pauli: Pauli) -> Matrix<Complex> {
    do {
        return try pauli.to_matrix()
    } catch {
        print(error)
    }

    return Matrix()
}

private func plot_state_bloch(_ rho: Matrix<Complex>,
                              size: VisualizationTypes.Size) -> VisualizationTypes.View {
    let rowCount = rho.rowCount
    let numberOfBits = Int(log2(Double(rowCount)))

    let bloch_states = (0..<numberOfBits).map {
        Pauli.pauli_singles($0, numberOfBits).map {
            pauli_to_matrix($0).dot(rho).trace().real
        }
    }

    let html = StateBlochChartHtmlFactory.makeHtml(blochStates: bloch_states)

    return WebViewFactory.makeWebView(size: size, html: html)
}

private func plot_state_qsphere(_ rho: Matrix<Complex>,
                                size: VisualizationTypes.Size) -> VisualizationTypes.View {
    var series: [StateQsphereChartSerie] = []

    let numberOfBits = Int(log2(Double(rho.rowCount)))
    var (eigenvalues, eigenvectors) = matrix_eigh(rho)

    for _ in 0..<eigenvalues.count {
        // start with the max
        let probLocation = eigenvalues.argmax()

        let probMix = eigenvalues[probLocation]
        if (probMix <= 0.001) {
            break
        }
        eigenvalues[probLocation] = 0.0

        let state = remove_state_global_phase(eigenvectors[probLocation])

        let values = make_qsphere_values(numberOfBits: numberOfBits, state: state)
        let serie = StateQsphereChartSerie(probMix: probMix, values: values)

        series.append(serie)
    }

    let html = StateQsphereChartHtmlFactory.makeHtml(numberOfBits: numberOfBits, series: series)

    return WebViewFactory.makeWebView(size: size, html: html)
}

private func matrix_eigh(_ rho: Matrix<Complex>) -> (Vector<Double>, [Vector<Complex>]) {
    var values = Vector<Double>(value: [])
    var vectors = Array<Vector<Complex>>()

    do {
        (values, vectors) = try rho.eigh()
    } catch {
        print(error)
    }

    return (values, vectors)
}

private func remove_state_global_phase(_ state: Vector<Complex>) -> Vector<Complex> {
    // get the element location closes to lowest bin representation
    let stateAbsolute = state.absolute()

    var loc = stateAbsolute.argmax()
    let absolute = stateAbsolute[loc]
    for (j, value) in stateAbsolute.enumerated() {
        if ((value - absolute).absolute() < 0.001) {
            loc = j

            break
        }
    }

    // remove the global phase
    let angles = (state[loc].arg + 2.0 * Double.pi).truncatingRemainder(dividingBy: 2.0 * Double.pi)
    let angleset = Complex(0, -1).multiply(angles).exp()

    return state.mult(angleset)
}

private func make_qsphere_values(numberOfBits: Int, state: Vector<Complex>) -> [StateQsphereChartValue] {
    return Array(0..<state.count).map {
        // get x,y,z points
        let element = String($0, radix: 2).zfill(numberOfBits)
        let weight = element.occurrences(of: "1")

        let zValue = 1.0 - 2.0 * Double(weight) / Double(numberOfBits)

        let numberOfDivisions = n_choose_k(numberOfBits, weight)
        let weightOrder = bit_string_index(element)
        let angle = (Double(weightOrder) * 2.0 * Double.pi / numberOfDivisions)

        let xValue = (1.0 - pow(zValue, 2.0)).squareRoot() * cos(angle)
        let yValue = (1.0 - pow(zValue, 2.0)).squareRoot() * sin(angle)

        // get prob and angle - prob will be shade and angle color
        let prob = state[$0].multiply(state[$0].conjugate()).real
        let colorstate = phase_to_color_wheel(state[$0])

        return StateQsphereChartValue(xValue: xValue,
                                      yValue: yValue,
                                      zValue: zValue,
                                      alpha: prob,
                                      color: colorstate)
    }
}

private func n_choose_k(_ n: Int, _ k: Int) -> Double {
    guard n > 0 else {
        return 0
    }

    let zipped = zip(Array((n - k + 1)..<(n + 1)), Array(1..<(k + 1)))
    return zipped.reduce(1.0) { $0 * Double($1.0) / Double($1.1) }
}

private func bit_string_index(_ s: String) -> Int {
    let n = s.count
    let k = s.occurrences(of: "1")
    assert(s.occurrences(of: "0") == (n - k), "s must be a string of 0 and 1")

    var ones: [Int] = []
    for (pos, char) in Array(s).enumerated() {
        if (char == "1") {
            ones.append(pos)
        }
    }

    return lex_index(n, k, ones)
}

private func lex_index(_ n: Int, _ k: Int, _ lst: [Int]) -> Int {
    assert(k == lst.count, "list should have length k")

    let comb = lst.map { n - 1 - $0 }
    let dualm = Array(0..<k).reduce(0.0) { $0 + n_choose_k(comb[k - 1 - $1], $1 + 1) }

    return Int(dualm)
}

private func phase_to_color_wheel(_ complex: Complex) -> StateQsphereChartValue.Color {
    let angle_round = Int(6.0 * (complex.arg + 2.0 * Double.pi).truncatingRemainder(dividingBy: 2.0 * Double.pi) / Double.pi)

    return StateQsphereChartValue.Color(rawValue: angle_round)!
}
