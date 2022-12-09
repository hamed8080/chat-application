//
//  VerifyRequest.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct VerifyRequest: Encodable {
    let identity: String
    let keyId: String
    let otp: String

    private enum CodingKeys: String, CodingKey {
        case otp, identity
    }
}
