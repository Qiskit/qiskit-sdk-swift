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

final class SessionDelegate : NSObject, URLSessionDelegate {

    let credentials: Credentials

    init(_ credentials: Credentials) {
        self.credentials = credentials
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        SDKLogger.logInfo("Did receive challenge")

        guard let username = self.credentials.ntlm_credentials["username"],
            let password = self.credentials.ntlm_credentials["password"] else {
            SDKLogger.logInfo("Challenge missing username password")
            #if os(Linux)
                challenge.sender?.performDefaultHandling(for: challenge)
            #else
                challenge.sender?.performDefaultHandling?(for: challenge)
            #endif
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard challenge.previousFailureCount == 0 else {
            SDKLogger.logInfo("Challeng too many failures")
            #if os(Linux)
                challenge.sender?.performDefaultHandling(for: challenge)
            #else
                challenge.sender?.performDefaultHandling?(for: challenge)
            #endif
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM else {
            SDKLogger.logInfo("Unknown authentication method \(challenge.protectionSpace.authenticationMethod)")
            #if os(Linux)
                challenge.sender?.performDefaultHandling(for: challenge)
            #else
                challenge.sender?.performDefaultHandling?(for: challenge)
            #endif
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let credentials = URLCredential(user: username, password: password, persistence: .forSession)
        challenge.sender?.use(credentials, for: challenge)
        completionHandler(.useCredential, credentials)
    }
}
