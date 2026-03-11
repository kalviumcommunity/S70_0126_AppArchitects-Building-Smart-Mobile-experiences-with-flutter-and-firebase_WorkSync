class AppSecurity {
  static bool isAuthenticating = false;
  static DateTime? lastAuthenticateTime;
  static bool pauseLifecycleLock = false;
}
