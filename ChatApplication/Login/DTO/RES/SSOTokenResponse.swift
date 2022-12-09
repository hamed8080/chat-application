//
//  SSOTokenResponse.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct SSOTokenResponse: Codable {
    let result: SSOTokenResponseResult?
}

struct SSOTokenResponseResult: Codable {
    let accessToken: String?
    let expiresIn: Int
    let idToken: String?
    let refreshToken: String?
    let scope: String?
    let tokenType: String?

    internal init(accessToken: String? = nil, expiresIn: Int, idToken: String? = nil, refreshToken: String? = nil, scope: String? = nil, tokenType: String? = nil) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case scope
    }
}
