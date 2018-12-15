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
 Bits Register
 */
public struct ClassicalRegister: Register, Equatable {

    public private(set) var name:String = ""
    public private(set) var size:Int = 0

    public init(_ name: String, _ size: Int) throws {
        self.name = name
        self.size = size
        try self.checkProperties()
    }

    private init() {
    }

    public subscript(index: Int) -> ClassicalRegisterTuple {
        get {
            if index < 0 || index >= self.size {
                fatalError("Index out of range")
            }
            return ClassicalRegisterTuple(self, index)
        }
    }

    public var description: String {
        return "creg \(self.name)[\(self.size)]"
    }

    public static func ==(lhs: ClassicalRegister, rhs: ClassicalRegister) -> Bool {
        return lhs.name == rhs.name && lhs.size == rhs.size
    }
}

public struct ClassicalRegisterTuple: RegisterArgument, Equatable {
    public let register: ClassicalRegister
    public let index: Int

    init(_ register: ClassicalRegister, _ index: Int) {
        self.register = register
        self.index = index
    }

    public var identifier: String {
        return "\(self.register.name)[\(self.index)]"
    }

    public static func ==(lhs: ClassicalRegisterTuple, rhs: ClassicalRegisterTuple) -> Bool {
        return lhs.register == rhs.register && lhs.index == rhs.index
    }
}
