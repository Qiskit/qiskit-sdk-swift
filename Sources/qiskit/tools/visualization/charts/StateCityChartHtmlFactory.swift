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

// MARK: - Main body

struct StateCityChartHtmlFactory {

    // MARK: - Public class methods

    static func makeHtml(xLabels: [String],
                         yLabels: [String],
                         realValues: [[Any]],
                         imagValues: [[Any]]) -> String {
        let xLabelsData = (try? JSONSerialization.data(withJSONObject: xLabels)) ?? Data()
        let yLabelsData = (try? JSONSerialization.data(withJSONObject: yLabels)) ?? Data()
        let realValuesData = (try? JSONSerialization.data(withJSONObject: realValues)) ?? Data()
        let imagValuesData = (try? JSONSerialization.data(withJSONObject: imagValues)) ?? Data()
        let xLabelsJSON = String(data: xLabelsData, encoding: .utf8) ?? ""
        let yLabelsJSON = String(data: yLabelsData, encoding: .utf8) ?? ""
        let realValuesJSON = String(data: realValuesData, encoding: .utf8) ?? ""
        let imagValuesJSON = String(data: imagValuesData, encoding: .utf8) ?? ""

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
                    function drawChart(elementId, xlabels, ylabels, zAxisName, zValues) {
                        var chart = document.getElementById(elementId);
                        var myChart = echarts.init(chart);
                        var option = {
                            grid3D: {
                                viewControl: {
                                    distance: 275
                                }
                            },
                            xAxis3D: {
                                name: '',
                                type: 'category',
                                axisLabel: {
                                    interval: 0
                                },
                                axisTick: {
                                    interval: 0
                                },
                                data: xlabels
                            },
                            yAxis3D: {
                                name: '',
                                type: 'category',
                                axisLabel: {
                                    interval: 0
                                },
                                axisTick: {
                                    interval: 0
                                },
                                data: ylabels
                            },
                            zAxis3D: {
                                name: zAxisName,
                                type: 'value'
                            },
                            series: [{
                                type: 'bar3D',
                                shading: 'lambert',
                                data: zValues
                            }]
                        };
                        myChart.setOption(option);
                    }
                </script>
            </head>
            <body style="width: 100%; height: 100%; position: absolute;">
                <div id="realChart" style="height: 50%;"></div>
                <div id="imagChart" style="height: 50%;"></div>
                <script>
                    drawChart('realChart',
                              \(xLabelsJSON),
                              \(yLabelsJSON),
                              'Real[rho]',
                              \(realValuesJSON));
                    drawChart('imagChart',
                              \(xLabelsJSON),
                              \(yLabelsJSON),
                              'Imag[rho]',
                              \(imagValuesJSON));
                </script>
            </body>
        </html>
        """
    }
}
