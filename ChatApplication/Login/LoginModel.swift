//
//  LoginModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct LoginModel {
    
    enum LoginState:String{
        case HANDSHAKE                   = "HANDSHAKE"
        case LOGIN                       = "LOGIN"
        case VERIFY                      = "VERIFY"
        case FAILED                      = "FAILED"
        case REFRESH_TOKEN               = "REFRESH_TOKEN"
        case SUCCESS_LOGGED_IN           = "SUCCESS_LOGGED_IN"
        case VERIFICATION_CODE_INCORRECT = "VERIFICATION_CODE_INCORRECT"
    }
    
    
    //this two variable need to be set from Binding so public setter needed
    var phoneNumber                                :String = ""
    var verifyCode                                 :String = ""
    private (set) var isValidPhoneNumber           :Bool?  = nil
    private (set) var state                        :LoginState?  = nil
    private (set) var isInVerifyState              :Bool  = false
    private (set) var keyId                        :String? = nil
    
    mutating func isPhoneNumberValid(){
        
    }
    
    
    mutating func setIsInVerifyState(_ isInVerifyState:Bool){
        self.isInVerifyState  = isInVerifyState
    }
    
    mutating func setState(_ state:LoginState){
        self.state  = state
    }
    
    mutating func setKeyId(_ keyId:String){
        self.keyId  = keyId
    }
}
