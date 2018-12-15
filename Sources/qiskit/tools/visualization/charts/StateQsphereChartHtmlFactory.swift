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

#if os(OSX) || os(iOS)

import Foundation

// MARK: - Main body

struct StateQsphereChartHtmlFactory {

    // MARK: - Public class methods

    static func makeHtml(numberOfBits: Int, series: [StateQsphereChartSerie]) -> String {
        var divs = ""

        let percentage = (Double(100.0) / Double(series.count))
        for index in 0..<series.count {
            let oneSerie = series[index]

            let vectors: [[Double]] = oneSerie.values.map { $0.xyz }
            let vectorsData = (try? JSONSerialization.data(withJSONObject: vectors)) ?? Data()
            let vectorsJson = String(data: vectorsData, encoding: .utf8) ?? ""

            let colors: [[Double]] = oneSerie.values.map { $0.rgba }
            let colorsData = (try? JSONSerialization.data(withJSONObject: colors)) ?? Data()
            let colorsJson = String(data: colorsData, encoding: .utf8) ?? ""

            divs += """
            <div style="position: relative; height: \(percentage)%;">
                <div id="chart\(index)" style="height: 100%;"></div>
                <div style="position: absolute; top: 0;">The \(index)th eigenvalue = \(oneSerie.probMix)</div>
            </div>
            <script>
                drawChart('chart\(index)', \(numberOfBits), \(vectorsJson), \(colorsJson));
            </script>
            """
        }

        return """
        <!doctype html>
        <html>
            <head>
                <script>
                    \(echartsBase64.base64Decoded() ?? "")
                </script>
                <script>
                    \(echartsGlBase64.base64Decoded() ?? "")
                </script>
                <script>
                    function drawChart(elementId, circles, vectors, colors) {
                        var series = []

                        series.push({
                            type: 'surface',
                            parametric: true,
                            itemStyle: {
                                color: [0.5, 0.5, 0.5, 0.1]
                            },
                            wireframe: {
                                show: false
                            },
                            parametricEquation: {
                                u: {
                                    min: -Math.PI,
                                    max: Math.PI,
                                    step: Math.PI / 30
                                },
                                v: {
                                    min: 0,
                                    max: Math.PI,
                                    step: Math.PI / 30
                                },
                                x: function (u, v) {
                                    return Math.sin(v) * Math.sin(u);
                                },
                                y: function (u, v) {
                                    return Math.sin(v) * Math.cos(u);
                                },
                                z: function (u, v) {
                                    return Math.cos(v);
                                }
                            }
                        })

                        for (var i = 0; i <= vectors.length; i++) {
                            series.push({
                                type: 'line3D',
                                lineStyle: {
                                    width: 8,
                                    color: colors[i]
                                },
                                data: [[0, 0, 0], vectors[i]]
                            });
                        }

                        for (var weight = 0; weight <= circles; weight++) {
                            var data = [];

                            var z = (1 - 2 * weight / circles);
                            var r = Math.sqrt(1 - Math.pow(z, 2));
                            for (var t = 0; t < 2 * Math.PI; t += Math.PI / 30) {
                                var x = (r * Math.cos(t));
                                var y = (r * Math.sin(t));

                                data.push([x, y, z]);
                            }

                            series.push({
                                type: 'line3D',
                                lineStyle: {
                                    color: [0.5, 0.5, 0.5]
                                },
                                data: data
                            });
                        }

                        series.push({
                            type: 'scatter3D',
                            itemStyle: {
                                color: [0.5, 0.5, 0.5]
                            },
                            data: vectors.concat([0, 0, 0])
                        });

                        var chart = document.getElementById(elementId);
                        var myChart = echarts.init(chart);
                        var option = {
                            xAxis3D: {},
                            yAxis3D: {},
                            zAxis3D: {},
                            grid3D: {
                                show: false,
                                viewControl: {
                                    distance: 275
                                }
                            },
                            series: series
                        };
                        myChart.setOption(option);
                    }
                </script>
            </head>
            <body style="width: 100%; height: 100%; position: absolute;">
                \(divs)
            </body>
        </html>
        """
    }
}

#endif
