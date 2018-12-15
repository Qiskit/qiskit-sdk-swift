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
#if os(macOS) || os(iOS)
import os
#endif

public enum LogType: Int, CustomStringConvertible {
    case typeDefault = 1
    case typeInfo = 2
    case typeDebug = 3
    case typeError = 4
    case typeFault = 5

    public var description: String {
        switch self {
        case .typeDefault :
            return "DEFAULT"
        case .typeInfo :
            return "INFO"
        case .typeDebug :
            return "DEBUG"
        case .typeError :
            return "ERROR"
        case .typeFault :
            return "FAULT"
        }
    }
}

public final class SDKLogger {

    #if os(macOS) || os(iOS)
    @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    static public let SUBSYSTEM = "com.ibm.research.qiskit"

    @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    static public let CATEGORY = "SDK"

    @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    static private let logger = OSLog(subsystem: SUBSYSTEM, category: CATEGORY)

    @available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    static private func logTypeToOSLogType(_ type: LogType) -> OSLogType {
        switch type {
        case .typeDefault :
            return OSLogType.default
        case .typeInfo :
            return OSLogType.info
        case .typeDebug :
            return OSLogType.debug
        case .typeError :
            return OSLogType.error
        case .typeFault :
            return OSLogType.fault
        }
    }
    #endif

    @available(OSX, deprecated:10.12)
    @available(iOS, deprecated:10.0)
    @available(watchOS, deprecated:3.0)
    @available(tvOS, deprecated:10.0)
    static public var type: LogType = .typeDefault

    static public func isEnabled(type: LogType) -> Bool {
        #if os(Linux)
            return type.rawValue >= SDKLogger.type.rawValue
        #else
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return logger.isEnabled(type:SDKLogger.logTypeToOSLogType(type))
            }
            else {
                return type.rawValue >= SDKLogger.type.rawValue
            }
        #endif
    }

    static public func log(_ message: String, type: LogType = .typeDefault) {
        if isEnabled(type: type) {
            #if os(Linux)
                debugPrint(message)
            #else
                if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    os_log("%@", log: logger, type: SDKLogger.logTypeToOSLogType(type), message)
                }
                else {
                    debugPrint(message)
                }
            #endif
        }
    }

    static public func log(_ message: CustomStringConvertible, type: LogType = .typeDefault) {
        log(message.description, type: type)
    }

    static public func logInfo(_ message: String) {
        log(message, type: .typeInfo)
    }

    static public func logInfo(_ message: CustomStringConvertible) {
        log(message, type: .typeInfo)
    }

    static public func logDebug(_ message: String) {
        log(message, type: .typeDebug)
    }

    static public func logDebug(_ message: CustomStringConvertible) {
        log(message, type: .typeDebug)
    }

    static public func logError(_ message: String) {
        log(message, type: .typeError)
    }

    static public func logError(_ message: CustomStringConvertible) {
        log(message, type: .typeError)
    }

    static public func logFault(_ message: String) {
        log(message, type: .typeFault)
    }

    static public func logFault(_ message: CustomStringConvertible) {
        log(message, type: .typeFault)
    }

    static public func debugString(_ items: Any..., separator: String = "", terminator: String = "") -> String {
        var text = ""
        debugPrint(items, separator: separator, terminator: terminator, to: &text)
        return text
    }

    private init() {
    }
}
