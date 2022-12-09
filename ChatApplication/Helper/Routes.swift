//
//  Routes.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/19/21.
//

import Foundation

class Routes {
    static var authBaseUrl = "https://podspace.pod.ir/api/oauth2/"
    static var handshake = authBaseUrl + "otp/handshake"
    static var authorize = authBaseUrl + "otp/authorize"
    static var verify = authBaseUrl + "otp/verify"
    static var otpToken = authBaseUrl + "accessToken/"
    static var refreshToken = authBaseUrl + "refresh/"
}
