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

public final class CommandLineHandler {
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) { 
        self.arguments = arguments
    }

    static private func printUsage() {
        print("Usage: qiskitexamples [options] [input]")
        print("Options:")
        print("--help                     Shows usage")
        print("--token <token>            Specifies IBM Quantum Experience Token")
        print("--local                    Run examples on local simulator")
        print("Input:")
        print("None                       Runs all examples")
        print("ghz|qft|rippleadd|teleport Runs specified example")
    }

    public func run() throws {
        guard arguments.count > 1 else {
            CommandLineHandler.printUsage()
            throw CommandLineError.missingOption
        }

        var token: String?
        var input = "all"

        let argument = arguments[1].lowercased()
        switch argument {
        case "--help":
            CommandLineHandler.printUsage()
            return
        case "--local":
            if arguments.count > 2 {
                input = arguments[2].lowercased()
            }
        case "--token":
            guard arguments.count > 2 else {
                CommandLineHandler.printUsage()
                throw CommandLineError.missingOption
            }
            token = arguments[2]
            
            if arguments.count > 3 {
                input = arguments[3].lowercased()
            }
        default:
            CommandLineHandler.printUsage()
            throw CommandLineError.invalidOption(option: argument)
        }

        let option = CommandLineOption(apiToken: token)

        switch input {
            case "ghz":
                GHZ.ghz(option) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "qft":
                QFT.qft(option) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "rippleadd":
                RippleAdd.rippleAdd(option) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "teleport":
                Teleport.teleport(option) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "all":
                GHZ.ghz(option) {
                    print("*** Finished ***")
                    QFT.qft(option) {
                        print("*** Finished ***")
                        RippleAdd.rippleAdd(option) {
                            print("*** Finished ***")
                            Teleport.teleport(option) {
                                print("*** Finished ***")
                                exit(0)
                            }
                        }
                    }
                }
            default:
                CommandLineHandler.printUsage()
                throw CommandLineError.invalidInput(input: input)
        }
        RunLoop.main.run()
    }
}
