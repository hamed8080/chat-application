//
//  SSOTokenResponse.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct SSOTokenResponse:Codable{
    
    let result          : Result?
    
    struct Result:Codable {
        
        let accessToken  : String?
        let expiresIn    : Int
        let idToken      : String?
        let refreshToken : String?
        let scope        : String?
        let tokenType    : String?
        
        
        private enum CodingKeys:String , CodingKey{
            
            case accessToken  = "access_token"
            case expiresIn    = "expires_in"
            case idToken      = "id_token"
            case refreshToken = "refresh_token"
            case tokenType    = "token_type"
            case scope
        }
    }
}
