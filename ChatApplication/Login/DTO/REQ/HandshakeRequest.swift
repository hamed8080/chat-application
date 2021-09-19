//
//  HandshakeRequest.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
struct HandshakeRequest:Encodable{
    
    let deviceName      : String
    let deviceOs        : String
    let deviceOsVersion : String
    let deviceType      : String
    let deviceUID       : String
    
}
