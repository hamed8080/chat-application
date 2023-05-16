//
//  InviteeTypes+.swift
//  ChatApplication
//
//  Created by hamed on 3/29/23.
//

import ChatModels
extension InviteeTypes: Identifiable {}
public extension InviteeTypes {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .ssoId:
            return "SSO ID"
        case .contactId:
            return "Contact ID"
        case .cellphoneNumber:
            return "Cell Phone Number"
        case .username:
            return "UserName"
        case .userId:
            return "User ID"
        case .coreUserId:
            return "Core User ID"
        case .unknown:
            return ""
        }
    }
}
