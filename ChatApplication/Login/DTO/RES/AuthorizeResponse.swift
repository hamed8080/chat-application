//
//  AuthorizeResponse.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct AuthorizeResponse: Codable {
    let result: AuthorizeResponseResult?
}

struct AuthorizeResponseResult: Codable {
    let identity: String?
    let type: String?
    let userId: String?
    let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case expiresIn = "expires_in"
        case userId = "user_id"
        case type, identity
    }
}
