//
//  URLSession.swift
//  DarkMaps
//
//  Created by Matthew Roche on 10/01/2021.
//

import SwiftUI

//extension URLSessionDelegate {
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        // `NSURLAuthenticationMethodClientCertificate`
//        // indicates the server requested a client certificate.
//        if challenge.protectionSpace.authenticationMethod != NSURLAuthenticationMethodClientCertificate {
//            completionHandler(.performDefaultHandling, nil)
//            return
//        }
//        
//        let filePath = Bundle.main.path(forResource: "clientCeritificate", ofType: "der")!
//        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
//        let certificate = SecCertificateCreateWithData(nil, data as CFData)!
//        print(certificate)
//        var identity: SecIdentity?
//        let status = sec_identity_create_with_certificates(identity, [certificate])
//        guard status == errSecSuccess else {
//            
//        }
//        guard let unwrappedIdentity = identity else {
//            
//        }
//        
//
//        // In my case, and as Apple recommends,
//        // we do not pass the certificate chain into
//        // the URLCredential used to respond to the challenge.
//        let credential = URLCredential(identity: unwrappedIdentity,
//                                   certificates: nil,
//                                    persistence: .none)
//        challenge.sender?.use(credential, for: challenge)
//        completionHandler(.useCredential, credential)
//    }
//}
