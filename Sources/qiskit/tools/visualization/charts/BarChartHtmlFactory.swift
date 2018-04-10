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

struct BarChartHtmlFactory {

    // MARK: - Public class methods

    static func makeHtml(labels: [String],
                         values: [Double],
                         configuration: BarChartConfiguration) -> String {
        let labelsData = (try? JSONSerialization.data(withJSONObject: labels)) ?? Data()
        let labelsJSON = String(data: labelsData, encoding: .utf8) ?? ""
        let valuesData = (try? JSONSerialization.data(withJSONObject: values)) ?? Data()
        let valuesJSON = String(data: valuesData, encoding: .utf8) ?? ""

        return """
        <!doctype html>
        <html>
            <head>
                <script>
                    \(echartsBase64.base64Decoded() ?? "")
                </script>
                <script>
                    function drawChart(elementId,
                                       labels,
                                       values,
                                       xAxisName,
                                       alignXAxisTickWithLabel,
                                       showXAxisSplitLine,
                                       yAxisName,
                                       showYAxisSplitLine,
                                       showValueOnTop) {
                        var chart = document.getElementById(elementId);
                        var myChart = echarts.init(chart);
                        var option = {
                            animation: true,
                            xAxis: {
                                name: xAxisName,
                                nameLocation: 'middle',
                                nameGap: 30,
                                type: 'category',
                                axisTick: {
                                    interval: 0,
                                    alignWithLabel: alignXAxisTickWithLabel
                                },
                                axisLabel: {
                                    interval: 0,
                                    rotate: 70
                                },
                                splitLine: {
                                    show: showXAxisSplitLine
                                },
                                data: labels
                            },
                            yAxis: {
                                name: yAxisName,
                                nameLocation: 'middle',
                                nameGap: 35,
                                type: 'value',
                                splitLine: {
                                    show: showYAxisSplitLine
                                }
                            },
                            series: [{
                                type: 'bar',
                                label: {
                                    show: showValueOnTop,
                                    position: 'top'
                                },
                                data: values
                            }]
                        };
                        myChart.setOption(option);
                    }
                </script>
            </head>
            <body style="width: 100%; height: 100%; position: absolute;">
                <div id="chart" style="height: 100%;"></div>
                <script>
                    drawChart('chart',
                              \(labelsJSON),
                              \(valuesJSON),
                              '\(configuration.xAxisName)',
                              \(configuration.alignXAxisTickWithLabel.description),
                              \(configuration.showXAxisSplitLine.description),
                              '\(configuration.yAxisName)',
                              \(configuration.showYAxisSplitLine.description),
                              \(configuration.showValueOnTop.description));
                </script>
            </body>
        </html>
        """
    }
}
