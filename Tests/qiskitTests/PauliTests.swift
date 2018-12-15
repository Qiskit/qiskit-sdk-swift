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

import XCTest
@testable import qiskit

/**
 Tests for Pauli class.
 */
class PauliTests: XCTestCase {

    static let allTests = [
        ("test_pauli",test_pauli),
        ("test_equality_equal",test_equality_equal),
        ("test_equality_different",test_equality_different),
        ("test_inequality_equal",test_inequality_equal),
        ("test_inequality_different",test_inequality_different)
    ]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_pauli() {
        do {
            var v = Array(repeating:0, count: 3)
            var w = Array(repeating:0, count: 3)
            v[0] = 1
            w[1] = 1
            v[2] = 1
            w[2] = 1

            let p = Pauli(v, w)
            SDKLogger.logInfo(p)
            SDKLogger.logInfo("In label form:")
            SDKLogger.logInfo(p.to_label())
            SDKLogger.logInfo("In matrix form:")
            SDKLogger.logInfo(try p.to_matrix())


            let q = Pauli.random_pauli(2)
            SDKLogger.logInfo(q)

            let r = Pauli.inverse_pauli(p)
            SDKLogger.logInfo("In label form:")
            SDKLogger.logInfo(r.to_label())

            SDKLogger.logInfo("Group in tensor order:")
            var grp = try Pauli.pauli_group(3, 1)
            for j in grp {
                SDKLogger.logInfo(j.to_label())
            }

            SDKLogger.logInfo("Group in weight order:")
            grp = try Pauli.pauli_group(3)
            for j in grp {
                SDKLogger.logInfo(j.to_label())
            }

            SDKLogger.logInfo("sign product:")
            let p1 = Pauli([0], [1])
            let p2 = Pauli([1], [1])
            var (p3, sgn) = try Pauli.sgn_prod(p1, p2)
            SDKLogger.logInfo(p1.to_label())
            SDKLogger.logInfo(p2.to_label())
            SDKLogger.logInfo(p3.to_label())
            SDKLogger.logInfo(sgn)

            SDKLogger.logInfo("sign product reverse:")
            (p3, sgn) = try Pauli.sgn_prod(p2, p1)
            SDKLogger.logInfo(p2.to_label())
            SDKLogger.logInfo(p1.to_label())
            SDKLogger.logInfo(p3.to_label())
            SDKLogger.logInfo(sgn)
        } catch {
            XCTFail("test_pauli: \(error)")
        }
    }

    func test_equality_equal() {
        let p1 = Pauli.random_pauli(5)
        let p2 = p1
        XCTAssert(p1 == p2)
        SDKLogger.logInfo(p2.to_label())
        SDKLogger.logInfo(p1.to_label())
        SDKLogger.logInfo(p1 == p2)
    }

    func test_equality_different() {
        let p1 = Pauli.random_pauli(5)
        var p2 = p1
        p2.v[0] = (p1.v[0] + 1) % 2
        XCTAssertFalse(p1 == p2)
        SDKLogger.logInfo(p2.to_label())
        SDKLogger.logInfo(p1.to_label())
        SDKLogger.logInfo(p1 == p2)
    }

    func test_inequality_equal() {
        let p1 = Pauli.random_pauli(5)
        let p2 = p1
        XCTAssertFalse(p1 != p2)
        SDKLogger.logInfo(p2.to_label())
        SDKLogger.logInfo(p1.to_label())
        SDKLogger.logInfo(p1 != p2)
    }

    func test_inequality_different() {
        let p1 = Pauli.random_pauli(5)
        var p2 = p1
        p2.v[0] = (p1.v[0] + 1) % 2
        XCTAssert(p1 != p2)
        SDKLogger.logInfo(p2.to_label())
        SDKLogger.logInfo(p1.to_label())
        SDKLogger.logInfo(p1 != p2)
    }
}
