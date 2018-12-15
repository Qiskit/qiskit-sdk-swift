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
        print("Input:")
        print("None                       Runs all examples")
        print("ghz|qft|rippleadd|teleport Runs specified example")
    }

    public func run() throws {
        guard arguments.count > 1 else {
            CommandLineHandler.printUsage()
            throw CommandLineError.missingToken
        }
        // The first argument is the execution path
        let argument = arguments[1].lowercased()
        if argument == "--help" {
            CommandLineHandler.printUsage()
            return
        }
        guard argument == "--token" else {
            CommandLineHandler.printUsage()
            throw CommandLineError.invalidArgument(argument: argument)
        }
        guard arguments.count > 2 else {
            CommandLineHandler.printUsage()
            throw CommandLineError.missingToken
        }
        let token = arguments[2]
        var option: String = "all"
        if arguments.count > 3 {
            option = arguments[3].lowercased()
        }
        switch option {
            case "ghz":
                GHZ.ghz(token) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "qft":
                QFT.qft(token) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "rippleadd":
                RippleAdd.rippleAdd(token) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "teleport":
                Teleport.teleport(token) {
                    print("*** Finished ***")
                    exit(0)
                }
            case "all":
                GHZ.ghz(token) {
                    print("*** Finished ***")
                    QFT.qft(token) {
                        print("*** Finished ***")
                        RippleAdd.rippleAdd(token) {
                            print("*** Finished ***")
                            Teleport.teleport(token) {
                                print("*** Finished ***")
                                exit(0)
                            }
                        }
                    }
                }
            default:
                CommandLineHandler.printUsage()
                throw CommandLineError.invalidOption(option: option)
        }
        RunLoop.main.run()
    }
}
