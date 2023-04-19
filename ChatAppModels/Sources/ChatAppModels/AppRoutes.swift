public final class AppRoutes {
    public static var authBaseUrl = "https://podspace.pod.ir/api/oauth2/"
    public static var handshake = authBaseUrl + "otp/handshake"
    public static var authorize = authBaseUrl + "otp/authorize"
    public static var verify = authBaseUrl + "otp/verify"
    public static var otpToken = authBaseUrl + "accessToken/"
    public static var refreshToken = authBaseUrl + "refresh/"
}
