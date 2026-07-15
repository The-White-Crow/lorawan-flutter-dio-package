/// Error codes returned by the LoRaWAN backend.
///
/// Keep these values aligned with `pkg/error/status_code_mapping.go` in the
/// backend repository. Unknown codes are still handled through HTTP status
/// fallbacks by `DioErrorHandler`.
abstract final class ApiResultCode {
  static const badRequest = 'BAD_REQUEST';
  static const validationError = 'VALIDATION_ERROR';
  static const authError = 'AUTH_ERROR';
  static const unauthorizedError = 'UNAUTHORIZED_ERROR';
  static const forbiddenError = 'FORBIDDEN_ERROR';
  static const notFoundError = 'NOT_FOUND_ERROR';
  static const methodNotAllowedError = 'METHOD_NOT_ALLOWED_ERROR';
  static const conflictError = 'CONFLICT_ERROR';
  static const limiterError = 'LIMITER_ERROR';
  static const customRecovery = 'CUSTOM_RECOVERY';
  static const internalError = 'INTERNAL_ERROR';
  static const networkError = 'NETWORK_ERROR';

  static const invalidPhoneNumber = 'INVALID_PHONE_NUMBER';
  static const otpAlreadySent = 'OTP_ALREADY_SENT';
  static const otpExpired = 'OTP_EXPIRED';
  static const otpInvalid = 'OTP_INVALID';
  static const otpMaxAttempts = 'OTP_MAX_ATTEMPTS';
  static const otpRateLimited = 'OTP_RATE_LIMITED';
  static const verifyTokenInvalid = 'VERIFY_TOKEN_INVALID';
  static const accountSuspended = 'ACCOUNT_SUSPENDED';
  static const tokenExpired = 'TOKEN_EXPIRED';

  static const gatewayNotFound = 'GATEWAY_NOT_FOUND';
  static const gatewayAlreadyClaimed = 'GATEWAY_ALREADY_CLAIMED';
  static const gatewayAlreadyOwned = 'GATEWAY_ALREADY_OWNED';
  static const gatewayClaimFailed = 'GATEWAY_CLAIM_FAILED';
  static const gatewayUpdateFailed = 'GATEWAY_UPDATE_FAILED';
  static const gatewayRemoveFailed = 'GATEWAY_REMOVE_FAILED';
  static const chirpstackSyncPending = 'CHIRPSTACK_SYNC_PENDING';
  static const unauthorizedTopic = 'UNAUTHORIZED_TOPIC';

  static const deviceNotFound = 'DEVICE_NOT_FOUND';
  static const deviceAlreadyClaimed = 'DEVICE_ALREADY_CLAIMED';
  static const deviceAlreadyOwned = 'DEVICE_ALREADY_OWNED';
  static const deviceClaimFailed = 'DEVICE_CLAIM_FAILED';
  static const deviceUpdateFailed = 'DEVICE_UPDATE_FAILED';
  static const deviceRemoveFailed = 'DEVICE_REMOVE_FAILED';

  static const deviceProfileNotFound = 'DEVICE_PROFILE_NOT_FOUND';
  static const profileNotSynced = 'PROFILE_NOT_SYNCED';
  static const profileSyncFailed = 'PROFILE_SYNC_FAILED';
  static const profileInUse = 'PROFILE_IN_USE';

  static const dashboardNameTaken = 'DASHBOARD_NAME_TAKEN';
  static const dashboardNotFound = 'DASHBOARD_NOT_FOUND';
  static const widgetNotFound = 'WIDGET_NOT_FOUND';
  static const widgetDeviceNotOwned = 'WIDGET_DEVICE_NOT_OWNED';
}
