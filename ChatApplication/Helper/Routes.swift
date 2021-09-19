//
//  Routes.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/19/21.
//

import Foundation

class Routes{

    static var AUTH_BASE_URL = "https://podspace.pod.ir/api/oauth2/"
    static var HANDSHAKE     = AUTH_BASE_URL + "otp/handshake"
    static var AUTHORIZE     = AUTH_BASE_URL + "otp/authorize"
    static var VERIFY        = AUTH_BASE_URL + "otp/verify"
    static var OTP_TOKEN     = AUTH_BASE_URL + "accessToken/"
    static var REFRESH_TOKEN = AUTH_BASE_URL + "refresh/"
}
