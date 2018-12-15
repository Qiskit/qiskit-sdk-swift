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

public struct Complex: Hashable, CustomStringConvertible, NumericType, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {

    public var real: Double {
        get { return _real }
        set { _real = newValue }
    }
    public var imag: Double {
        get { return _imag }
        set { _imag = newValue }
    }

    private var _real: Double = 0
    private var _imag: Double = 0

    public init() {
        self.init(0, 0)
    }

    public init(_ str: String) throws {
        var complexStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if complexStr.hasSuffix("j") {
            var r = complexStr.index(complexStr.endIndex, offsetBy: -1)..<complexStr.endIndex
            complexStr.removeSubrange(r)
            r = complexStr.startIndex..<complexStr.endIndex
            repeat {
                var rangeFound: Range<String.Index>? = nil
                if let range = complexStr.range(of: "+", options:.backwards, range: r) {
                    rangeFound = range
                }
                else if let range = complexStr.range(of: "-", options:.backwards, range: r) {
                    rangeFound = range
                }
                if let range = rangeFound {
                    r = complexStr.index(range.lowerBound, offsetBy: -1)..<complexStr.index(range.upperBound, offsetBy: -1)
                    if complexStr[r] != "e" {
                        if let v = Double(String(complexStr[range.lowerBound..<complexStr.endIndex])) {
                            self._imag = v
                        }
                        complexStr.removeSubrange(range.lowerBound..<complexStr.endIndex)
                        break
                    }
                    r = complexStr.startIndex..<complexStr.index(range.lowerBound, offsetBy: -1)
                }
                else {
                    break
                }
            }
            while true
        }
        if let v = Double(complexStr) {
            self._real = v
        }
    }

    public init(_ real: Double, _ imag: Double) {
        self._real = real
        self._imag = imag
    }

    public init(real: Double) {
        self.init(real, 0)
    }

    public init(real: SymbolicValue) {
        self.init(real.value, 0)
    }

    public init(integerLiteral value: Int) {
        self.init(real: Double(value))
    }

    public init(floatLiteral value: Double) {
        self.init(real: value)
    }

    public init(imag: Double) {
        self.init(0, imag)
    }

    public var radiusSquare: Double { return self.real * self.real + self.imag * self.imag }
    public var radius: Double { return self.radiusSquare.squareRoot() }
    public var arg: Double { return atan2(self.imag, self.real) }

    public var hashValue: Int {
        return self.real.hashValue &+ self.imag.hashValue
    }

    public var description: String {
        if self.real != 0 {
            if self.imag > 0 {
                return "\(self.real)+\(self.imag)j"
            } else if self.imag < 0 {
                return "\(self.real)-\(-self.imag)j"
            } else {
                return "\(self.real)"
            }
        } else {
            if self.imag == 0 {
                return "0"
            } else {
                return "\(self.imag)j"
            }
        }
    }

    public func abs() -> Double {
        return self.radius
    }

    public func absolute() -> Double {
        return self.abs()
    }

    // e ** x+iy = e**x * (cos(y) + i sin(y))
    public func exp() -> Complex {
        let first: Double = pow(M_E,self.real)
        let second = Complex(cos(self.imag), sin(self.imag))
        return second.multiply(first)
    }

    public func conjugate() -> Complex {
        return Complex(self.real, -self.imag)
    }

    public func sqrt() -> Complex {
        let a = ((self.radiusSquare + self.real) / 2.0).squareRoot()
        let b = (self.imag / self.imag.absolute()) * ((self.radiusSquare - self.real) / 2.0).squareRoot()
        return Complex(a, b)
    }

    public func almostEqual(_ n: Complex, _ delta: Double = 0.0000001) -> Bool {
        return (self.real-n.real).absolute() <= delta && (self.imag-n.imag).absolute() <= delta
    }

    public func add(_ n: Complex) -> Complex {
        return Complex(self.real + n.real, self.imag + n.imag)
    }
    public func subtract(_ n: Complex) -> Complex {
        return Complex(self.real - n.real, self.imag - n.imag)
    }
    public func multiply(_ n: Complex) -> Complex {
        return Complex(self.real * n.real - self.imag * n.imag, self.real * n.imag + self.imag * n.real)
    }
    public func multiply(_ n: Double) -> Complex {
        return Complex(self.real * n, self.imag * n)
    }
    public func multiply(_ n: SymbolicValue) -> Complex {
        return Complex(self.real * n.value, self.imag * n.value)
    }
    public func divide(_ n: Complex) -> Complex {
        return self.multiply((n.conjugate().divide(n.radiusSquare)))
    }
    public func divide(_ n: Double) -> Complex {
        return Complex(self.real / n, self.imag / n)
    }
    public func divide(_ n: SymbolicValue) -> Complex {
        return Complex(self.real / n.value, self.imag / n.value)
    }
    public func power(_ n: Double) -> Complex {
        return pow(radiusSquare, n / 2) *  Complex(cos(n * arg), sin(n * arg))
    }

    public func power(_ n: Int) -> Complex {
        switch n {
        case 0: return 1
        case 1: return self
        case -1: return Complex(real: 1).divide(self)
        case 2: return self.multiply(self)
        case -2: return Complex(real: 1).divide(self.multiply(self))
        default: return power(Double(n))
        }
    }

    public mutating func conjugateInPlace() {
        self.imag = -self.imag
    }

    public mutating func addInPlace(_ n: Complex) {
        self.real += n.real
        self.imag += n.imag
    }

    public mutating func subtractInPlace(_ n: Complex) {
        self.real -= n.real
        self.imag -= n.imag
    }

    public mutating func multiplyInPlace(_ n: Double) {
        self.real *= n
        self.imag *= n
    }

    public mutating func multiplyInPlace(_ n: Complex) {
        self = self.multiply(n)
    }

    public mutating func divideInPlace(_ n: Complex) {
        self = self.divide(n)
    }

    public mutating func divideInPlace(_ n: Double) {
        self.real /= n
        self.imag /= n
    }
}

public func ==(left: Complex, right: Complex) -> Bool {
    return left.real == right.real && left.imag == right.imag
}

precedencegroup PowerPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: left
    assignment: false
}

infix operator ^ : PowerPrecedence
infix operator * : MultiplicationPrecedence
infix operator / : MultiplicationPrecedence
infix operator + : AdditionPrecedence
infix operator - : AdditionPrecedence

infix operator += : AssignmentPrecedence
infix operator -= : AssignmentPrecedence
infix operator *= : AssignmentPrecedence
infix operator /= : AssignmentPrecedence

public func + (left: Complex, right: Complex) -> Complex {
    return left.add(right)
}
public func + (left: Double,  right: Complex) -> Complex {
    return Complex(real: left).add(right)
}
public func + (left: Complex, right: Double ) -> Complex {
    return left.add(Complex(real: right))
}

public func - (left: Complex, right: Complex) -> Complex {
    return left.subtract(right)
}
public func - (left: Double,  right: Complex) -> Complex {
    return Complex(real: left).subtract(right)
}
public func - (left: Complex, right: Double ) -> Complex {
    return left.subtract(Complex(real: right))
}

public func * (left: Complex, right: Complex) -> Complex {
    return left.multiply(right)
}
public func * (left: Double,  right: Complex) -> Complex {
    return right.multiply(left)
}
public func * (left: Complex, right: Double ) -> Complex {
    return left.multiply(right)
}
public func * (left: Complex, right: SymbolicValue ) -> Complex {
    return left.multiply(right)
}

public func / (left: Complex, right: Complex) -> Complex {
    return left.divide(right)
}
public func / (left: Double,  right: Complex) -> Complex {
    return Complex(real: left).divide(right)
}
public func / (left: Complex, right: Double ) -> Complex {
    return left.divide(right)
}
public func / (left: Complex, right: SymbolicValue ) -> Complex {
    return left.divide(right)
}

public func ^ (left: Complex, right: Double) -> Complex {
    return left.power(right)
}
public func ^ (left: Complex, right: Int) -> Complex {
    return left.power(right)
}

public func += (left: inout Complex, right: Complex) {
    left.addInPlace(right)
}
public func += (left: inout Complex, right: Double) {
    left.addInPlace(Complex(real: right))
}
public func -= (left: inout Complex, right: Complex) {
    left.subtractInPlace(right)
}
public func -= (left: inout Complex, right: Double) {
    left.subtractInPlace(Complex(real: right))
}
public func *= (left: inout Complex, right: Complex) {
    left.multiplyInPlace(right)
}
public func *= (left: inout Complex, right: Double) {
    left.multiplyInPlace(right)
}
public func /= (left: inout Complex, right: Complex) {
    left.divideInPlace(right)
}
public func /= (left: inout Complex, right: Double) {
    left.divideInPlace(right)
}
