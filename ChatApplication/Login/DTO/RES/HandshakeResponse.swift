//
//  HandshakeResponse.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct HandshakeResponse: Codable {
    let result: HandshakeResponseResult?
    let reference: String?
    let status: Int
    let error: String?
    let message: String?
    let timestamp: String?
    let path: String?
}

struct HandshakeResponseResult: Codable {
    let keyId: String?
    let expiresIn: Int
}
