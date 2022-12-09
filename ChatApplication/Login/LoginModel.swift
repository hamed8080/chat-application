//
//  LoginModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import Foundation

struct LoginModel {
    enum LoginState: String {
        case handshake
        case login
        case verify
        case failed
        case refreshToken
        case successLoggedIn
        case verificationCodeIncorrect
    }

    // this two variable need to be set from Binding so public setter needed
    var phoneNumber: String = ""
    var verifyCode: String = ""
    private(set) var isValidPhoneNumber: Bool?
    private(set) var state: LoginState?
    private(set) var isInVerifyState: Bool = false
    private(set) var keyId: String?

    mutating func isPhoneNumberValid() -> Bool {
        isValidPhoneNumber = !phoneNumber.isEmpty
        return !phoneNumber.isEmpty
    }

    mutating func setIsInVerifyState(_ isInVerifyState: Bool) {
        self.isInVerifyState = isInVerifyState
    }

    mutating func setState(_ state: LoginState) {
        self.state = state
    }

    mutating func setKeyId(_ keyId: String) {
        self.keyId = keyId
    }
}
