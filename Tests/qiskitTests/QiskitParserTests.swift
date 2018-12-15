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

class QiskitParserTests: XCTestCase {

    static let allTests = [
        ("testExamples",testExamples),
        ("testParser",testParser),
        ("testErrorCorrection",testErrorCorrection),
        ("testParserBell",testParserBell),
        ("testParserRipple",testParserRipple),
        ("testParserRippleAdd",testParserRippleAdd),
        ("testParserExpressionList",testParserExpressionList),
        ("testParserQPT",testParserQPT)
    ]

    private static let qasmProgram1 =
                "OPENQASM 2.0;\n" +
                    "qreg q[5];\n" +
                    "creg c[5];\n" +
                    "x q[0];\n" +
                    "x q[1];\n" +
                    "h q[2];\n" +
                    "measure q[0] -> c[0];\n" +
                    "measure q[1] -> c[1];\n" +
                    "measure q[2] -> c[2];\n" +
                    "measure q[3] -> c[3];\n" +
                    "measure q[4] -> c[4];"

    private static let qasmProgram2 =
                "OPENQASM 2.0;\n" +
                    "qreg q[3];\n" +
                    "qreg a[2];\n" +
                    "creg c[3];\n" +
                    "creg syn[2];\n" +
                    "gate syndrome d1, d2, d3, a1, a2\n" +
                    "{\n" +
                    "    cx d1, a1; cx d2, a1;\n" +
                    "    cx d2, a2; cx d3, a2;\n" +
                    "}\n" +
                    "x q[0];\n" +
                    "barrier q;\n" +
                    "syndrome q[0],q[1],q[2],a[0],a[1];\n" +
                    "measure a -> syn;\n" +
                    "if(syn==1) x q[0];\n" +
                    "if(syn==2) x q[2];\n" +
                    "if(syn==3) x q[1];\n" +
                    "measure q -> c;\n"

    private static let qasmProgram3 =
            "OPENQASM 2.0;\n" +
            "qreg q[3];\n" +
            "creg c[2];\n" +
            "h q[0];\n" +
            "cx q[0],q[2];\n" +
            "measure q[0] -> c[0];\n" +
            "measure q[2] -> c[1];"

    private static let qasmSamples : [String] = [
        Adder.QASM, BigAdder.QASM, InverseQFT1.QASM, InversQFT2.QASM, Ipea3pi8.QASM, Pea3pi8.QASM,
        QEC.QASM, QFT.QASM, QPT.QASM, RB.QASM, Teleport.QASM, WState.QASM, Q011_3_qubit_grover_50.QASM,
        Deutsch.QASM, ISwap.QASM, QE_QFT_3.QASM, QE_QFT_4.QASM, QE_QFT_5.QASM, W3Test.QASM
    ]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private static func firstDifferenceBetweenStrings(_ s1: String, _ s2: String) -> Int {
        let len1 = s1.count
        let len2 = s2.count

        let lenMin = min(len1, len2)

        for i in 0..<lenMin {
            let c1 = s1[s1.index(s1.startIndex, offsetBy: i)]
            let c2 = s2[s2.index(s2.startIndex, offsetBy: i)]
            if  c1 !=  c2 {
                SDKLogger.logInfo("\(c1) \(c2)")
                return i
            }
        }

        if len1 < len2 {
            return len1
        }

        if len2 < len1 {
            return len2
        }
        return 0
    }


    private class func runParser(_ qasmProgram: String) throws -> (String,String) {
        // eliminate comments, substitute pi, eliminate include
        var lines: [String] = []
        for var line in qasmProgram.components(separatedBy: CharacterSet.newlines) {
            line = line.replacingOccurrences(of:"pi", with:"3.141592653589793")
            line = line.replacingOccurrences(of:"include \"qelib1.inc\";", with:"")
            if line.isEmpty {
                continue
            }
            if let range = line.range(of: "//") {
                let start = range.lowerBound
                let newLine = line[line.startIndex..<start]
                if !newLine.isEmpty {
                    lines.append(String(newLine))
                }
            }
            else {
                lines.append(line)
            }
        }
        let qasm = lines.joined()
        let parser = Qasm(data: qasm)
        return (qasm,try parser.parse().qasm(15))
    }


    func testExamples() {
        var differences: [String: (String,String)] = [:]
        for qasm in QiskitParserTests.qasmSamples {
            do {
                let (qasmProgram,qasm) = try QiskitParserTests.runParser(qasm)
                let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
                let emittedQasm = qasm.components(separatedBy: whitespaceCharacterSet).joined()

                let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()

                if emittedQasm != targetQasm {
                    differences[qasm] = (emittedQasm,targetQasm)
                }
            } catch {
                XCTFail("\(error)")
            }
        }
        if !differences.isEmpty {
            for (qasm,difference) in differences {
                SDKLogger.logInfo("Qasm: \(qasm) doesn't match:")
                SDKLogger.logInfo("Emmited: \(difference.0)")
                SDKLogger.logInfo("Original: \(difference.1)")
            }
            XCTFail("Error not equal.")
        }
    }

    func testParser() {
        do {
            let (qasmProgram,qasm) = try QiskitParserTests.runParser(QiskitParserTests.qasmProgram1)
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = qasm.components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testErrorCorrection() {
        do {
            let (qasmProgram,qasm) = try QiskitParserTests.runParser(QiskitParserTests.qasmProgram2)
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = qasm.components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testParserBell () {
        do {
            let (qasmProgram,qasm) = try QiskitParserTests.runParser(QiskitParserTests.qasmProgram3)
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = qasm.components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testParserRipple () {

        let qasmProgram: String =
            "OPENQASM 2.0;\n" +
                "qreg cin[1];\n" +
                "qreg a[4];\n" +
                "qreg b[4];\n" +
                "qreg cout[1];\n" +
                "creg ans[5];\n" +
                "x a[0];\n" +
                "x b[0];\n" +
                "x b[1];\n" +
                "x b[2];\n" +
                "x b[3];\n" +
                "cx a[0],b[0];\n" +
                "cx a[0],cin[0];\n" +
                "ccx cin[0],b[0],a[0];\n" +
                "cx a[1],b[1];\n" +
                "cx a[1],a[0];\n" +
                "ccx a[0],b[1],a[1];\n" +
                "cx a[2],b[2];\n" +
                "cx a[2],a[1];\n" +
                "ccx a[1],b[2],a[2];\n" +
                "cx a[3],b[3];\n" +
                "cx a[3],a[2];\n" +
                "ccx a[2],b[3],a[3];\n" +
                "cx a[3],cout[0];\n" +
                "ccx a[2],b[3],a[3];\n" +
                "cx a[3],a[2];\n" +
                "cx a[2],b[3];\n" +
                "ccx a[1],b[2],a[2];\n" +
                "cx a[2],a[1];\n" +
                "cx a[1],b[2];\n" +
                "ccx a[0],b[1],a[1];\n" +
                "cx a[1],a[0];\n" +
                "cx a[0],b[1];\n" +
                "ccx cin[0],b[0],a[0];\n" +
                "cx a[0],cin[0];\n" +
                "cx cin[0],b[0];\n" +
                "measure b[0] -> ans[0];\n" +
                "measure b[1] -> ans[1];\n" +
                "measure b[2] -> ans[2];\n" +
                "measure b[3] -> ans[3];\n" +
                "measure cout[0] -> ans[4];"

        do {
            let parser = Qasm(data: qasmProgram)
            let root = try parser.parse()
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = root.qasm(15).components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testParserRippleAdd () {
        let qasmProgram: String =
            "OPENQASM 2.0;" +
                "qreg a[2];" +
                "qreg b[2];" +
                "qreg cin[1];" +
                "qreg cout[1];" +
                "creg ans[3];" +
                "x a[0];" +
                "x b[0];" +
                "x b[1];" +
                "cx a[0],b[0];" +
                "cx a[0],cin[0];" +
                "ccx cin[0],b[0],a[0];" +
                "cx a[1],b[1];" +
                "cx a[1],a[0];" +
                "ccx a[0],b[1],a[1];" +
                "cx a[1],cout[0];" +
                "ccx a[0],b[1],a[1];" +
                "cx a[1],a[0];" +
                "cx a[0],b[1];" +
                "ccx cin[0],b[0],a[0];" +
                "cx a[0],cin[0];" +
                "cx cin[0],b[0];" +
                "measure b[0] -> ans[0];" +
                "measure b[1] -> ans[1];" +
                "measure cout[0] -> ans[2];"
        do {
            let parser = Qasm(data: qasmProgram)
            let root = try parser.parse()
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = root.qasm(15).components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testParserExpressionList () {

        let qasmProgram: String =
                "OPENQASM 2.0;\n" +
                "qreg qr[4];\n" +
                "creg cr[4];\n" +
                "h qr[0];\n" +
                "x qr[1];\n" +
                "y qr[2];\n" +
                "z qr[3];\n" +
                "cx qr[0],qr[2];\n" +
                "barrier qr[0],qr[1],qr[2],qr[3];\n" +
                "u1(0.300000000000000) qr[0];\n" +
                "u2(0.300000000000000,0.200000000000000) qr[1];\n" +
                "u3(0.300000000000000,0.200000000000000,0.100000000000000) qr[2];\n" +
                "s qr[0];\n" +
                "t qr[1];\n" +
                "id qr[1];\n" +
                "measure qr[0] -> cr[0];"
        do {
            let parser = Qasm(data: qasmProgram)
            let root = try parser.parse()
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = root.qasm(15).components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }

    func testParserQPT () {

        let qasmProgram: String =
        "OPENQASM 2.0;\n" +
        "gate pre q { }\n" +
        "gate post q { }\n" +
        "qreg q[1];\n" +
        "creg c[1];\n" +
        "pre q[0];\n" +
        "barrier q;\n" +
        "h q[0];\n" +
        "barrier q;\n" +
        "post q[0];\n" +
        "measure q[0] -> c[0];\n"
        do {
            let parser = Qasm(data: qasmProgram)
            let root = try parser.parse()
            let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines
            let emittedQasm = root.qasm(15).components(separatedBy: whitespaceCharacterSet).joined()
            let targetQasm = qasmProgram.components(separatedBy: whitespaceCharacterSet).joined()
            XCTAssertEqual(emittedQasm, targetQasm)
        } catch let error {
            XCTFail("\(error)")
        }
    }
}
