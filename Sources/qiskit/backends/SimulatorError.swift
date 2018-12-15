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

/*
Exception for errors raised by the Simulator object.
*/
public enum SimulatorError: LocalizedError, CustomStringConvertible {
    case unrecognizedOperation(backend: String, operation: String)
    case notImplemented(backend: String)
    case missingCompiledCircuit
    case missingOperationName
    case simulationCancelled

    public var errorDescription: String? {
        return self.description
    }
    public var description: String {
        switch self {
        case .unrecognizedOperation(let backend,let operation):
            return "\(backend) encountered unrecognized operation '\(operation)'"
        case .notImplemented(let backend):
            return "\(backend) not implemented"
        case .missingCompiledCircuit:
            return "Missing compiled circuit."
        case .missingOperationName:
            return "Missing Operation name"
        case .simulationCancelled:
            return "Simulation cancelled."
        }
    }
}
