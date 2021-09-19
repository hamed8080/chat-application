//
//  AuthorizeRequest.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct AuthorizeRequest:Encodable{
    
    let identity      : String
    let keyId         : String
    
    private enum CodingKeys : String,CodingKey{
        case identity = "identity"
    }
}
