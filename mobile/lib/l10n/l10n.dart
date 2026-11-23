import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../utils/format.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// All on-screen text, in the current language (lib/l10n/app_*.arb).
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// True while the app is shown in Nepali.
  bool get isNepali => Localizations.localeOf(this).languageCode == 'ne';
}

extension AppLocalizationsX on AppLocalizations {
  /// The message to show for an error. Known error codes are translated; anything else
  /// (form checks from the data layer, for example) falls back to the message as given.
  String error(ApiException e) => switch (e.code) {
        'INVALID_CREDENTIALS' => errInvalidCredentials,
        'ACCOUNT_LOCKED' => errAccountLocked,
        'ACCOUNT_INACTIVE' => errAccountInactive,
        'TOO_MANY_ATTEMPTS' => errTooManyAttempts,
        'NETWORK' => errNetwork,
        'TIMEOUT' => errTimeout,
        'FORBIDDEN' => errForbidden,
        'SESSION_EXPIRED' || 'UNAUTHENTICATED' => sessionExpired,
        'CONFLICT' => errConflict,
        'ERROR' || 'BAD_RESPONSE' => errGeneric,
        'CUSTOMER_NOT_FOUND' => errCustomerNotFound,
        'ACCOUNT_NOT_FOUND' => errAccountNotFound,
        'ACCOUNT_PENDING' => errAccountPending,
        'AMOUNT_OUT_OF_RANGE' => errAmountRange(formatNpr(AppConfig.minAmount), formatNpr(AppConfig.maxAmount)),
        'INSUFFICIENT_BALANCE' => errInsufficientBalance,
        'INSUFFICIENT_FLOAT' => errInsufficientFloat,
        'FLOAT_LIMIT_EXCEEDED' => errFloatLimit,
        'WRONG_OTP' => errWrongOtp,
        'OTP_EXPIRED' => errOtpExpired,
        'OTP_ATTEMPTS_EXCEEDED' => errOtpAttempts,
        'NOT_AWAITING_OTP' => errNotAwaitingOtp,
        'RESEND_TOO_SOON' => errResendTooSoon,
        'RESEND_LIMIT' => errResendLimit,
        'CANNOT_CANCEL' => errCannotCancel,
        'TRANSACTION_NOT_FOUND' => errTransactionNotFound,
        'DUPLICATE_CITIZENSHIP' => errDuplicateCitizenship,
        'DUPLICATE_MOBILE' => errDuplicateMobile,
        'EOD_ALREADY_SUBMITTED' => errEodAlreadySubmitted,
        'INVALID_PIN' => errInvalidPin,
        'SAME_PIN' => errSamePin,
        'NOT_PENDING' => errNotPending,
        'KYC_NOT_OPENED' => errKycNotOpened,
        'UNDER_AGE' => minAge16,
        _ => e.message,
      };

  /// Label for a transaction, KYC, account or end-of-day status.
  String status(String s) => switch (s) {
        'confirmed' => statusConfirmed,
        'awaiting_otp' => statusPendingOtp,
        'pending_review' => statusKycPending,
        'verified' => statusKycVerified,
        'rejected' => statusKycRejected,
        'pending' => statusPending,
        'active' => statusActive,
        'cancelled' => statusCancelled,
        'failed' => statusFailed,
        'balanced' => statusBalanced,
        'mismatch' => statusMismatch,
        _ => s,
      };

  /// Bikram Sambat month names, Baisakh first.
  List<String> get bsMonths => [
        monthBaisakh, monthJestha, monthAsar, monthShrawan, monthBhadra, monthAsoj,
        monthKartik, monthMangsir, monthPoush, monthMagh, monthFalgun, monthChaitra,
      ];
}
