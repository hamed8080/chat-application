public final class AppRoutes {
    //    public static var authBaseUrl = "https://talkotp-d.fanapsoft.ir/api/oauth2/"
    //    public static var authBaseUrl = "https://talkotp-s.fanapsoft.ir/api/oauth2/"
    public static var authBaseUrl = "https://talkotp.fanapsoft.ir/api/oauth2/"
    public static var handshake = authBaseUrl + "otp/handshake"
    public static var authorize = authBaseUrl + "otp/authorize"
    public static var verify = authBaseUrl + "otp/verify"
    public static var refreshToken = authBaseUrl + "otp/refresh"
}
