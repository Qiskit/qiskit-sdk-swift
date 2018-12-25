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
 Command Line Exceptions
 */
public enum CommandLineError: LocalizedError, CustomStringConvertible {

    case missingOption
    case invalidOption(option: String)
    case invalidInput(input: String)

    public var errorDescription: String? {
        return self.description
    }
    public var description: String {
        switch self {
        case .missingOption:
            return "Missing option."
        case .invalidOption(let option):
            return "Invalid option \(option)."
        case .invalidInput(let input):
            return "Invalid input \(input)."
        }
    }
}
