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

// MARK: - Main body

struct StateQsphereChartValue {

    // MARK: - Types

    enum Color: Int {
        case blue = 0
        case blueViolet = 1
        case violet = 2
        case redViolet = 3
        case red = 4
        case redOrange = 5
        case orange = 6
        case orangeYellow = 7
        case yellow = 8
        case yellowGreen = 9
        case green = 10
        case greenBlue = 11

        var rgb : [Double] {
            switch self {
            case .blue:
                return [0.0, 0.0, 1.0]
            case .blueViolet:
                return [0.5, 0.0, 1.0]
            case .violet:
                return [1.0, 0.0, 1.0]
            case .redViolet:
                return [1.0, 0.0, 0.5]
            case .red:
                return [1.0, 0.0, 0.0]
            case .redOrange:
                return [1.0, 0.5, 0.0]
            case .orange:
                return [1.0, 1.0, 0.0]
            case .orangeYellow:
                return [0.5, 1.0, 0.0]
            case .yellow:
                return [0.0, 1.0, 0.0]
            case .yellowGreen:
                return [0.0, 1.0, 0.5]
            case .green:
                return [0.0, 1.0, 1.0]
            case .greenBlue:
                return [0.0, 0.5, 1.0]
            }
        }
    }

    // MARK: - Public properties

    let xValue: Double
    let yValue: Double
    let zValue: Double
    let alpha: Double
    let color: Color

    var xyz: [Double] {
        return [xValue, yValue, zValue]
    }

    var rgba: [Double] {
        var rgba = color.rgb
        rgba.append(alpha)

        return rgba
    }
}
