public final class AppRoutes {
//    public static let authBaseUrl = "https://talkotp-d.fanapsoft.ir/"
//    public static let authBaseUrl = "https://talkotp-s.fanapsoft.ir/"
    public static let authBaseUrl = "https://talkback.pod.ir/"
    public static let api = "api/"
    public static let oauth = "oauth2/"
    public static let otp = authBaseUrl + api + oauth + "otp/"
    public static let handshake = otp + "handshake"
    public static let authorize = otp + "authorize"
    public static let verify = otp + "verify"
    public static let refreshToken = otp + "refresh"
    public static let updateProfileImage = authBaseUrl + api + "/uploadImage"
}
