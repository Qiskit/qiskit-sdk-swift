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
import CQasmParser
#if os(Linux)
import Dispatch
#endif

typealias NodeIdType = Int
typealias StringIdType = Int

final class Qasm {

    public let data: String
    static private var nodes: [Node] = []
    static private var strings: [String] = []
    static private var semaphore = DispatchSemaphore(value: 0)
    static private var root: NodeMainProgram? = nil
    static private var errorMsg: String? = nil
    static private let lock = NSRecursiveLock()

    init(filename: String) throws {
        do {
            self.data  = try String(contentsOfFile: filename, encoding: String.Encoding.utf8)
        } catch {
            throw QasmError.internalError(error: error)
        }
    }

    init(data: String) {
        self.data = data
    }

    func parse() throws -> NodeMainProgram {

        Qasm.lock.lock()
        Qasm.semaphore = DispatchSemaphore(value: 0)
        Qasm.root = nil
        Qasm.errorMsg = nil
        let buf: YY_BUFFER_STATE = yy_scan_string(self.data)

        ParseSuccess = { (index: NodeIdType) -> Void in
            defer {
                Qasm.semaphore.signal()
            }
            Qasm.root = Qasm.getNode(index) as? NodeMainProgram
        }
        ParseFail = { (line: Int32, message: UnsafePointer<Int8>?) -> Void in
            defer {
                Qasm.semaphore.signal()
            }
            if let msg = message {
                Qasm.errorMsg = "line \(line): \(String(cString: msg))"
            } else {
                Qasm.errorMsg = "line \(line): Unknown Error"
            }
        }
        GetIncludeContents = { (name: UnsafePointer<Int8>?,
                                contents: UnsafeMutablePointer<Int8>?,
                                size: Int) -> Int in
            return Qasm.getIncludeContents(name, contents, size)
        }
        AddString = { (str: UnsafePointer<Int8>?) -> StringIdType in
            return Qasm.addString(str!)
        }
        CreateBarrier = { (primarylist: NodeIdType) -> NodeIdType in
            return Qasm.createBarrier(primarylist: primarylist)
        }
        CreateBinaryOperation = { (op: UnsafePointer<Int8>?, operand1: NodeIdType, operand2: NodeIdType) -> NodeIdType in
            return Qasm.createBinaryOperation(op: op!, operand1: operand1, operand2: operand2)
        }
        CreateCX = { (arg1: NodeIdType, arg2: NodeIdType) -> NodeIdType in
             return Qasm.createCX(arg1: arg1, arg2: arg2)
        }
        CreateCReg = { (indexed_id: NodeIdType) -> NodeIdType in
            return Qasm.createCReg(indexed_id: indexed_id)
        }
        CreateCustomUnitary2 = { (identifier: NodeIdType, bitlist: NodeIdType) -> NodeIdType in
            return Qasm.createCustomUnitary(identifier: identifier, bitlist: bitlist)
        }
        CreateCustomUnitary3 = { (identifier: NodeIdType, arguments: NodeIdType, bitlist: NodeIdType) -> NodeIdType in
            return Qasm.createCustomUnitary(identifier: identifier, arguments: arguments, bitlist: bitlist)
        }
        CreateExpressionList1 = { (exp: NodeIdType) -> NodeIdType in
            return Qasm.createExpressionList(exp: exp)
        }
        CreateExpressionList2 = { (elist: NodeIdType, expression: NodeIdType) -> NodeIdType in
            return Qasm.createExpressionList(elist: elist, expression: expression)
        }
        CreateExternal = { (identifier: NodeIdType, external: StringIdType) -> NodeIdType in
            return Qasm.createExternal(identifier: identifier, external: external)
        }
        CreateGate3 = { (identifier: NodeIdType, list2: NodeIdType, list3: NodeIdType) -> NodeIdType in
            return Qasm.createGate(identifier: identifier, list2: list2, list3: list3)
        }
        CreateGate4 = { (identifier: NodeIdType, list1: NodeIdType, list2: NodeIdType, list3: NodeIdType) -> NodeIdType in
            return Qasm.createGate(identifier: identifier, list1: list1, list2: list2, list3: list3)
        }
        CreateGateBody0 = { () -> NodeIdType in
            return Qasm.createGateBody()
        }
        CreateGateBody1 = { (goplist: NodeIdType) -> NodeIdType in
            return Qasm.createGateBody(goplist: goplist)
        }
        CreateGopList1 = { (gop: NodeIdType) -> NodeIdType in
            return Qasm.createGopList(gop: gop)
        }
        CreateGopList2 = { (goplist: NodeIdType, gate_op: NodeIdType) -> NodeIdType in
            return Qasm.createGopList(goplist: goplist, gate_op: gate_op)
        }
        CreateId = { (identifier: StringIdType, line: Int) -> NodeIdType in
            return Qasm.createId(identifier: identifier, line: line)
        }
        CreateIdlist1 = { (identifier: NodeIdType) -> NodeIdType in
            return Qasm.createIdlist(identifier: identifier)
        }
        CreateIdlist2 = { (idlist: NodeIdType, identifier: NodeIdType) -> NodeIdType in
            return Qasm.createIdlist(idlist: idlist, identifier: identifier)
        }
        CreateIf = { (identifier: NodeIdType, nninteger: NodeIdType, quantum_op: NodeIdType) -> NodeIdType in
            return Qasm.createIf(identifier: identifier, nninteger: nninteger, quantum_op: quantum_op)
        }
        CreateInclude = { (file: StringIdType) -> NodeIdType in
            return Qasm.createInclude(file: file)
        }
        CreateIndexedId = { (identifier: NodeIdType, index: NodeIdType) -> NodeIdType in
            return Qasm.createIndexedId(identifier: identifier, index: index)
        }
        CreateInt = { (integer: Int) -> NodeIdType in
            return Qasm.createInt(integer: integer)
        }
        CreateMagic = { (real: NodeIdType) -> NodeIdType in
            return Qasm.createMagic(real: real)
        }
        CreateMainProgram2 = { (magic: NodeIdType, program: NodeIdType) -> NodeIdType in
            return Qasm.createMainProgram(magic: magic, program: program)
        }
        CreateMainProgram3 = { (magic: NodeIdType, incld: NodeIdType, program: NodeIdType) -> NodeIdType in
            return Qasm.createMainProgram(magic: magic, incld: incld, program: program)
        }
        CreateMeasure = { (argument1: NodeIdType, argument2: NodeIdType) -> NodeIdType in
            return Qasm.createMeasure(argument1: argument1, argument2: argument2)
        }
        CreateOpaque2 = { (identifier: NodeIdType, list1: NodeIdType) -> NodeIdType in
            return Qasm.createOpaque(identifier: identifier, list1: list1)
        }
        CreateOpaque3 = { (identifier: NodeIdType, list1: NodeIdType, list2: NodeIdType) -> NodeIdType in
            return Qasm.createOpaque(identifier: identifier, list1: list1, list2: list2)
        }
        CreatePrefixOperation = { (op: UnsafePointer<Int8>?,operand: NodeIdType) -> NodeIdType in
            return Qasm.createPrefixOperation(op: op!,operand: operand)
        }
        CreatePrimaryList1 = { (primary: NodeIdType) -> NodeIdType in
            return Qasm.createPrimaryList(primary: primary)
        }
        CreatePrimaryList2 = { (list: NodeIdType, primary: NodeIdType) -> NodeIdType in
            return Qasm.createPrimaryList(list: list, primary: primary)
        }
        CreateProgram1 = { (statement: NodeIdType) -> NodeIdType in
            return Qasm.createProgram(statement: statement)
        }
        CreateProgram2 = { (program: NodeIdType, statement: NodeIdType) -> NodeIdType in
            return Qasm.createProgram(program: program, statement: statement)
        }
        CreateQReg = { (indexed_id: NodeIdType) -> NodeIdType in
            return Qasm.createQReg(indexed_id: indexed_id)
        }
        CreateReal = { (real: Double) -> NodeIdType in
            return Qasm.createReal(real: real)
        }
        CreateRealPI = { () -> NodeIdType in
            return Qasm.createRealPI()
        }
        CreateReset = { (identifier: NodeIdType) -> NodeIdType in
            return Qasm.createReset(identifier: identifier)
        }
        CreateUniversalUnitary = { (list1: NodeIdType, list2: NodeIdType) -> NodeIdType in
            return Qasm.createUniversalUnitary(list1: list1, list2: list2)
        }

        yyparse()
        Qasm.semaphore.wait()
        Qasm.clearState()
        Qasm.lock.unlock()
        if let error = Qasm.errorMsg {
            throw QISKitError.parserError(msg: error)
        }
        if Qasm.root == nil {
            throw QISKitError.parserError(msg: "Missing root node")
        }
        return Qasm.root!
    }

    static private func getIncludeContents(_ n: UnsafePointer<Int8>?,
                                            _ c: UnsafeMutablePointer<Int8>?,
                                            _ size: Int) -> Int {
        guard let name = n, let contents = c else {
            return 0
        }
        var fileName = String(cString: name)
        fileName = fileName.replacingOccurrences(of: "\"", with: "")
        fileName = fileName.replacingOccurrences(of: ";", with: "")
        fileName = fileName.replacingOccurrences(of: " ", with: "").lowercased()
        if fileName != "qelib1.inc" {
            return 0
        }
        guard let bytes = QELib1.QASM.cString(using: .utf8) else {
            return 0
        }
        if bytes.count <= size {
            let p = UnsafeMutablePointer<Int8>(mutating:bytes)
            contents.moveAssign(from: p, count: bytes.count)
        }
        return bytes.count
    }

    static private func addNode(_ node: Node) -> NodeIdType {
        Qasm.nodes.append(node)
        return Qasm.nodes.count - 1
    }

    static private func clearState() {
        Qasm.nodes = []
        Qasm.strings = []
    }

    static private func addString(_ str: UnsafePointer<Int8>) -> StringIdType {
        Qasm.strings.append(String(cString: str))
        return Qasm.strings.count - 1
    }

    static private func getString(_ index: StringIdType) -> String {
        return Qasm.strings[index]
    }

    static private func getNode(_ index: NodeIdType) -> Node {
        return Qasm.nodes[index]
    }

    static private func createBarrier(primarylist: NodeIdType) -> NodeIdType {
        let node = NodeBarrier(list: Qasm.getNode(primarylist))
        return Qasm.addNode(node)
    }

    static private func createBinaryOperation(op: UnsafePointer<Int8>, operand1: NodeIdType, operand2: NodeIdType) -> NodeIdType {
        let node = NodeBinaryOp(op: String(cString: op), children: [Qasm.getNode(operand1), Qasm.getNode(operand2)])
        return Qasm.addNode(node)
    }

    static private func createCX(arg1: NodeIdType, arg2: NodeIdType) -> NodeIdType {
        let node = NodeCnot(arg1: Qasm.getNode(arg1), arg2: Qasm.getNode(arg2))
        return Qasm.addNode(node)
    }

    static private func createCReg(indexed_id: NodeIdType) -> NodeIdType {
        let node = NodeCreg(indexedid: Qasm.getNode(indexed_id), line: 0, file: "")
        return Qasm.addNode(node)
    }

    static private func createCustomUnitary(identifier: NodeIdType,bitlist: NodeIdType) -> NodeIdType {
        let node = NodeCustomUnitary(identifier: Qasm.getNode(identifier), bitlist: Qasm.getNode(bitlist))
        return Qasm.addNode(node)
    }

    static private func createCustomUnitary(identifier: NodeIdType, arguments: NodeIdType, bitlist: NodeIdType) -> NodeIdType {
        let node = NodeCustomUnitary(identifier: Qasm.getNode(identifier), arguments:Qasm.getNode(arguments), bitlist:Qasm.getNode(bitlist))
        return Qasm.addNode(node)
    }

    static private func createExpressionList(exp: NodeIdType) -> NodeIdType {
        let node = NodeExpressionList(expression: Qasm.getNode(exp))
        return Qasm.addNode(node)
    }

    static private func createExpressionList(elist: NodeIdType, expression: NodeIdType) -> NodeIdType {
        let node = Qasm.getNode(elist) as! NodeExpressionList
        node.addExpression(exp: Qasm.getNode(expression))
        return Qasm.addNode(node)
    }

    static private func createExternal(identifier: NodeIdType, external: StringIdType) -> NodeIdType {
        let node = NodeExternal(operation: Qasm.getString(external), expression: Qasm.getNode(identifier))
        return Qasm.addNode(node)
    }

    static private func createGate(identifier: NodeIdType, list2: NodeIdType, list3: NodeIdType) -> NodeIdType {
        let node = NodeGate(identifier: Qasm.getNode(identifier), bitlist:Qasm.getNode(list2), body:Qasm.getNode(list3))
        return Qasm.addNode(node)
    }

    static private func createGate(identifier: NodeIdType, list1: NodeIdType, list2: NodeIdType, list3: NodeIdType) -> NodeIdType {
        let node = NodeGate(identifier: Qasm.getNode(identifier), arguments:Qasm.getNode(list1), bitlist:Qasm.getNode(list2), body:Qasm.getNode(list3))
        return Qasm.addNode(node)
    }

    static private func createGateBody() -> NodeIdType {
        let node = NodeGateBody()
        return Qasm.addNode(node)
    }

    static private func createGateBody(goplist: NodeIdType) -> NodeIdType {
        let node = NodeGateBody(goplist: Qasm.getNode(goplist))
        return Qasm.addNode(node)
    }

    static private func createGopList(gop: NodeIdType) -> NodeIdType {
        let node = NodeGopList(gateop: Qasm.getNode(gop))
        return Qasm.addNode(node)
    }

    static private func createGopList(goplist: NodeIdType, gate_op: NodeIdType) -> NodeIdType {
        let node = Qasm.getNode(goplist) as! NodeGopList
        node.addIdentifier(gateop: Qasm.getNode(gate_op))
        return Qasm.addNode(node)
    }

    static private func createId(identifier: StringIdType, line: Int) -> NodeIdType {
        let node = NodeId(identifier: self.getString(identifier), line:line)
        return Qasm.addNode(node)
    }

    static private func createIdlist(identifier: NodeIdType) -> NodeIdType {
        let node = NodeIdList(identifier: Qasm.getNode(identifier))
        return Qasm.addNode(node)
    }

    static private func createIdlist(idlist: NodeIdType, identifier: NodeIdType) -> NodeIdType {
        let node = Qasm.getNode(idlist) as! NodeIdList
        node.addIdentifier(identifier:Qasm.getNode(identifier))
        return Qasm.addNode(node)
    }

    static private func createIf(identifier: NodeIdType, nninteger: NodeIdType, quantum_op: NodeIdType) -> NodeIdType {
        let node = NodeIf(identifier: Qasm.getNode(identifier), nninteger:Qasm.getNode(nninteger), qop:Qasm.getNode(quantum_op))
        return Qasm.addNode(node)
    }

    static private func createInclude(file: StringIdType) -> NodeIdType {
        let node = NodeInclude(file: self.getString(file))
        return Qasm.addNode(node)
    }

    static private func createIndexedId(identifier: NodeIdType, index: NodeIdType) -> NodeIdType {
        let node = NodeIndexedId(identifier: Qasm.getNode(identifier), index:Qasm.getNode(index))
        return Qasm.addNode(node)
    }

    static private func createInt(integer: Int) -> NodeIdType {
        let node = NodeNNInt(value: integer)
        return Qasm.addNode(node)
    }

    static private func createMagic(real: NodeIdType) -> NodeIdType {
        let node = NodeMagic(version: Qasm.getNode(real))
        return Qasm.addNode(node)
    }

    static private func createMainProgram(magic: NodeIdType, program: NodeIdType) -> NodeIdType {
        let node = NodeMainProgram(magic: Qasm.getNode(magic), program:Qasm.getNode(program))
        return Qasm.addNode(node)
    }

    static private func createMainProgram(magic: NodeIdType, incld: NodeIdType, program: NodeIdType) -> NodeIdType {
        let node = NodeMainProgram(magic: Qasm.getNode(magic), incld:Qasm.getNode(incld), program:Qasm.getNode(program))
        return Qasm.addNode(node)
    }

    static private func createMeasure(argument1: NodeIdType, argument2: NodeIdType) -> NodeIdType {
        let node = NodeMeasure(arg1: Qasm.getNode(argument1), arg2:Qasm.getNode(argument2))
        return Qasm.addNode(node)
    }

    static private func createOpaque(identifier: NodeIdType, list1: NodeIdType) -> NodeIdType {
        let node = NodeOpaque(identifier: Qasm.getNode(identifier), arguments:Qasm.getNode(list1))
        return Qasm.addNode(node)
    }

    static private func createOpaque(identifier: NodeIdType, list1: NodeIdType, list2: NodeIdType) -> NodeIdType {
        let node = NodeOpaque(identifier: Qasm.getNode(identifier), arguments:Qasm.getNode(list1), bitlist:Qasm.getNode(list2))
        return Qasm.addNode(node)
    }

    static private func createPrefixOperation(op: UnsafePointer<Int8>, operand: NodeIdType) -> NodeIdType {
        let node = NodePrefix(op: String(cString: op), children: [Qasm.getNode(operand)])
        return Qasm.addNode(node)
    }

    static private func createPrimaryList(primary: NodeIdType) -> NodeIdType {
        let node = NodePrimaryList(identifier: Qasm.getNode(primary))
        return Qasm.addNode(node)
    }

    static private func createPrimaryList(list: NodeIdType, primary: NodeIdType) -> NodeIdType {
        let node = Qasm.getNode(list) as! NodePrimaryList
        node.addIdentifier(identifier: Qasm.getNode(primary))
        return Qasm.addNode(node)
    }

    static private func createProgram(statement: NodeIdType) -> NodeIdType {
        let node = NodeProgram(statement: Qasm.getNode(statement))
        return Qasm.addNode(node)
    }

    static private func createProgram(program: NodeIdType, statement: NodeIdType) -> NodeIdType {
        let node = Qasm.getNode(program) as! NodeProgram
        node.addStatement(statement: Qasm.getNode(statement))
        return Qasm.addNode(node)
    }

    static private func createQReg(indexed_id: NodeIdType) -> NodeIdType {
        let node = NodeQreg(indexedid: Qasm.getNode(indexed_id), line:0, file:"") // FIXME line, file
        return Qasm.addNode(node)
    }

    static private func createReal(real: Double) -> NodeIdType {
        let node = NodeReal(id: real)
        return Qasm.addNode(node)
    }

    static private func createRealPI() -> NodeIdType {
        let node = NodeRealPI()
        return Qasm.addNode(node)
    }

    static private func createReset(identifier: NodeIdType) -> NodeIdType {
        let node = NodeReset(indexedid: Qasm.getNode(identifier))
        return Qasm.addNode(node)
    }

    static private func createUniversalUnitary(list1: NodeIdType, list2: NodeIdType) -> NodeIdType {
        let node = NodeUniversalUnitary(explist: Qasm.getNode(list1), indexedid:Qasm.getNode(list2))
        return Qasm.addNode(node)
    }
}
