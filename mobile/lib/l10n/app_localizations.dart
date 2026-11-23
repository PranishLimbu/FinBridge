import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FinBridge Agent'**
  String get appTitle;

  /// No description provided for @logoName.
  ///
  /// In en, this message translates to:
  /// **'FinBridge'**
  String get logoName;

  /// No description provided for @logoTagline.
  ///
  /// In en, this message translates to:
  /// **'AGENT BANKING'**
  String get logoTagline;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get languageNepali;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusPendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Pending OTP'**
  String get statusPendingOtp;

  /// No description provided for @statusKycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC pending'**
  String get statusKycPending;

  /// No description provided for @statusKycVerified.
  ///
  /// In en, this message translates to:
  /// **'KYC verified'**
  String get statusKycVerified;

  /// No description provided for @statusKycRejected.
  ///
  /// In en, this message translates to:
  /// **'KYC rejected'**
  String get statusKycRejected;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get statusBalanced;

  /// No description provided for @statusMismatch.
  ///
  /// In en, this message translates to:
  /// **'Mismatch'**
  String get statusMismatch;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your FinBridge counter'**
  String get loginSubtitle;

  /// No description provided for @agentId.
  ///
  /// In en, this message translates to:
  /// **'Agent ID'**
  String get agentId;

  /// No description provided for @agentIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AGT-98412'**
  String get agentIdHint;

  /// No description provided for @agentIdError.
  ///
  /// In en, this message translates to:
  /// **'Enter your agent ID'**
  String get agentIdError;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get pinHint;

  /// No description provided for @pinSixDigits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 6 digits'**
  String get pinSixDigits;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your supervisor to reset your PIN.'**
  String get forgotPinBody;

  /// No description provided for @showPin.
  ///
  /// In en, this message translates to:
  /// **'Show PIN'**
  String get showPin;

  /// No description provided for @hidePin.
  ///
  /// In en, this message translates to:
  /// **'Hide PIN'**
  String get hidePin;

  /// No description provided for @neverSharePin.
  ///
  /// In en, this message translates to:
  /// **'Never share your PIN or a customer’s OTP.'**
  String get neverSharePin;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @triesLeft.
  ///
  /// In en, this message translates to:
  /// **'{message}. {count, plural, =1{1 try left.} other{{count} tries left.}}'**
  String triesLeft(String message, int count);

  /// No description provided for @demoLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Demo login: AGT-98412 / PIN 123456'**
  String get demoLoginHint;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @idleLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out after 5 minutes without activity.'**
  String get idleLoggedOut;

  /// No description provided for @tabCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get tabCounter;

  /// No description provided for @tabCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get tabCustomers;

  /// No description provided for @tabJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get tabJournal;

  /// No description provided for @tabTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get tabTerminal;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'नमस्ते, {name}'**
  String greeting(String name);

  /// No description provided for @cashInHand.
  ///
  /// In en, this message translates to:
  /// **'CASH IN HAND'**
  String get cashInHand;

  /// No description provided for @openingAmount.
  ///
  /// In en, this message translates to:
  /// **'Opening {amount}'**
  String openingAmount(String amount);

  /// No description provided for @usedPercent.
  ///
  /// In en, this message translates to:
  /// **'Used: {percent}%'**
  String usedPercent(String percent);

  /// No description provided for @limitAmount.
  ///
  /// In en, this message translates to:
  /// **'Limit: {amount}'**
  String limitAmount(String amount);

  /// No description provided for @minReserveAmount.
  ///
  /// In en, this message translates to:
  /// **'Min reserve {amount}'**
  String minReserveAmount(String amount);

  /// No description provided for @rebalance.
  ///
  /// In en, this message translates to:
  /// **'Rebalance'**
  String get rebalance;

  /// No description provided for @todaysCash.
  ///
  /// In en, this message translates to:
  /// **'Today’s cash'**
  String get todaysCash;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceived;

  /// No description provided for @cashPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Cash paid out'**
  String get cashPaidOut;

  /// No description provided for @txnCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 txn} other{{count} txns}}'**
  String txnCount(int count);

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @cashDeposit.
  ///
  /// In en, this message translates to:
  /// **'Cash deposit'**
  String get cashDeposit;

  /// No description provided for @cashDepositSub.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cashDepositSub;

  /// No description provided for @cashWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Cash withdrawal'**
  String get cashWithdrawal;

  /// No description provided for @cashWithdrawalSub.
  ///
  /// In en, this message translates to:
  /// **'Cash out with OTP'**
  String get cashWithdrawalSub;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @newCustomerSub.
  ///
  /// In en, this message translates to:
  /// **'Open an account'**
  String get newCustomerSub;

  /// No description provided for @findCustomer.
  ///
  /// In en, this message translates to:
  /// **'Find customer'**
  String get findCustomer;

  /// No description provided for @findCustomerSub.
  ///
  /// In en, this message translates to:
  /// **'Mobile, account or name'**
  String get findCustomerSub;

  /// No description provided for @todaysTransactions.
  ///
  /// In en, this message translates to:
  /// **'Today’s transactions'**
  String get todaysTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noTransactionsToday.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet today.'**
  String get noTransactionsToday;

  /// No description provided for @alertKycPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new account waiting for bank approval} other{{count} new accounts waiting for bank approval}}'**
  String alertKycPending(int count);

  /// No description provided for @alertEodDue.
  ///
  /// In en, this message translates to:
  /// **'End-of-day cash count not done yet'**
  String get alertEodDue;

  /// No description provided for @alertPendingOtp.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 withdrawal is waiting for OTP} other{{count} withdrawals are waiting for OTP}}'**
  String alertPendingOtp(int count);

  /// No description provided for @alertLowFloat.
  ///
  /// In en, this message translates to:
  /// **'Cash is near the minimum reserve'**
  String get alertLowFloat;

  /// No description provided for @alertHighFloat.
  ///
  /// In en, this message translates to:
  /// **'Cash is near the limit'**
  String get alertHighFloat;

  /// No description provided for @startEod.
  ///
  /// In en, this message translates to:
  /// **'Start EOD'**
  String get startEod;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @findCustomerStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Find customer'**
  String get findCustomerStepTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile, account, citizenship no. or name'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by mobile, account, citizenship no. or name.'**
  String get searchPrompt;

  /// No description provided for @noCustomerFound.
  ///
  /// In en, this message translates to:
  /// **'No customer found.'**
  String get noCustomerFound;

  /// No description provided for @citizenshipMasked.
  ///
  /// In en, this message translates to:
  /// **'Citizenship {number}'**
  String citizenshipMasked(String number);

  /// No description provided for @kycNotVerified.
  ///
  /// In en, this message translates to:
  /// **'KYC not verified yet. Cash transactions are not allowed.'**
  String get kycNotVerified;

  /// No description provided for @stepCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get stepCustomer;

  /// No description provided for @stepAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get stepAccount;

  /// No description provided for @stepAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get stepAmount;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get stepReview;

  /// No description provided for @stepOfFour.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4: {name}'**
  String stepOfFour(int step, String name);

  /// No description provided for @numberedStep.
  ///
  /// In en, this message translates to:
  /// **'{step}. {name}'**
  String numberedStep(int step, String name);

  /// No description provided for @searchForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search for the customer.'**
  String get searchForCustomer;

  /// No description provided for @searchCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search customer'**
  String get searchCustomer;

  /// No description provided for @chooseAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose the account'**
  String get chooseAccount;

  /// No description provided for @chooseDifferentCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose a different customer'**
  String get chooseDifferentCustomer;

  /// No description provided for @depositTo.
  ///
  /// In en, this message translates to:
  /// **'DEPOSIT TO'**
  String get depositTo;

  /// No description provided for @withdrawFrom.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW FROM'**
  String get withdrawFrom;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get typeLabel;

  /// No description provided for @cashInTag.
  ///
  /// In en, this message translates to:
  /// **'CASH IN'**
  String get cashInTag;

  /// No description provided for @cashOutTag.
  ///
  /// In en, this message translates to:
  /// **'CASH OUT'**
  String get cashOutTag;

  /// No description provided for @currencyCode.
  ///
  /// In en, this message translates to:
  /// **'NPR'**
  String get currencyCode;

  /// No description provided for @enterTheAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount'**
  String get enterTheAmount;

  /// No description provided for @minMax.
  ///
  /// In en, this message translates to:
  /// **'Min {min} • Max {max}'**
  String minMax(String min, String max);

  /// No description provided for @amountMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum is {amount}'**
  String amountMinimum(String amount);

  /// No description provided for @amountMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum is {amount} per transaction'**
  String amountMaximum(String amount);

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'QUICK ADD'**
  String get quickAdd;

  /// No description provided for @fees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get fees;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit amount'**
  String get depositAmount;

  /// No description provided for @cashToHandOver.
  ///
  /// In en, this message translates to:
  /// **'Cash to hand over'**
  String get cashToHandOver;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @totalCredited.
  ///
  /// In en, this message translates to:
  /// **'Total credited'**
  String get totalCredited;

  /// No description provided for @totalDebited.
  ///
  /// In en, this message translates to:
  /// **'Total debited'**
  String get totalDebited;

  /// No description provided for @continueToReview.
  ///
  /// In en, this message translates to:
  /// **'Continue to review'**
  String get continueToReview;

  /// No description provided for @confirmWithCustomer.
  ///
  /// In en, this message translates to:
  /// **'Confirm the details with the customer.'**
  String get confirmWithCustomer;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @otpWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'The customer will get an OTP by SMS.'**
  String get otpWillBeSent;

  /// No description provided for @countCashFirst.
  ///
  /// In en, this message translates to:
  /// **'Count the cash before you confirm.'**
  String get countCashFirst;

  /// No description provided for @retrySafe.
  ///
  /// In en, this message translates to:
  /// **'{error}\nRetry is safe: it won’t create a second transaction.'**
  String retrySafe(String error);

  /// No description provided for @confirmDeposit.
  ///
  /// In en, this message translates to:
  /// **'Confirm deposit'**
  String get confirmDeposit;

  /// No description provided for @sendOtpToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Send OTP to customer'**
  String get sendOtpToCustomer;

  /// No description provided for @backChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'Back: change amount'**
  String get backChangeAmount;

  /// No description provided for @deleteKey.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteKey;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer OTP'**
  String get otpTitle;

  /// No description provided for @cancelAndBack.
  ///
  /// In en, this message translates to:
  /// **'Cancel & Back'**
  String get cancelAndBack;

  /// No description provided for @otpAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer for the 6-digit OTP sent to their mobile.'**
  String get otpAsk;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP expired'**
  String get otpExpired;

  /// No description provided for @otpExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String otpExpiresIn(String time);

  /// No description provided for @demoOtp.
  ///
  /// In en, this message translates to:
  /// **'Demo OTP: {otp}'**
  String demoOtp(String otp);

  /// No description provided for @otpSixDigits.
  ///
  /// In en, this message translates to:
  /// **'The OTP has 6 digits'**
  String get otpSixDigits;

  /// No description provided for @attemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{message}. {count, plural, =1{1 attempt left.} other{{count} attempts left.}}'**
  String attemptsLeft(String message, int count);

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP and confirm'**
  String get verifyOtp;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @backToCounter.
  ///
  /// In en, this message translates to:
  /// **'Back to counter'**
  String get backToCounter;

  /// No description provided for @giveCashAfterConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Give cash only after you see “Confirmed”.'**
  String get giveCashAfterConfirmed;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @transactionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Transaction confirmed'**
  String get transactionConfirmed;

  /// No description provided for @transactionStatus.
  ///
  /// In en, this message translates to:
  /// **'Transaction {status}'**
  String transactionStatus(String status);

  /// No description provided for @partnerBankLine.
  ///
  /// In en, this message translates to:
  /// **'Partner bank: {bank}'**
  String partnerBankLine(String bank);

  /// No description provided for @receiptAgentLine.
  ///
  /// In en, this message translates to:
  /// **'{location} • Agent: {name} ({id})'**
  String receiptAgentLine(String location, String name, String id);

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @dateBs.
  ///
  /// In en, this message translates to:
  /// **'Date (BS)'**
  String get dateBs;

  /// No description provided for @dateAd.
  ///
  /// In en, this message translates to:
  /// **'Date (AD)'**
  String get dateAd;

  /// No description provided for @serviceDepositBranchless.
  ///
  /// In en, this message translates to:
  /// **'Cash deposit (branchless)'**
  String get serviceDepositBranchless;

  /// No description provided for @serviceWithdrawalBranchless.
  ///
  /// In en, this message translates to:
  /// **'Cash withdrawal (branchless)'**
  String get serviceWithdrawalBranchless;

  /// No description provided for @cashDeposited.
  ///
  /// In en, this message translates to:
  /// **'Cash deposited'**
  String get cashDeposited;

  /// No description provided for @inWords.
  ///
  /// In en, this message translates to:
  /// **'In words: {words}'**
  String inWords(String words);

  /// No description provided for @smsReceiptSentNote.
  ///
  /// In en, this message translates to:
  /// **'An SMS receipt was sent to the customer.'**
  String get smsReceiptSentNote;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get printReceipt;

  /// No description provided for @sendSmsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Send SMS receipt'**
  String get sendSmsReceipt;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @reportProblemHint.
  ///
  /// In en, this message translates to:
  /// **'What does the customer say went wrong?'**
  String get reportProblemHint;

  /// No description provided for @sendToSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Send to supervisor'**
  String get sendToSupervisor;

  /// No description provided for @receiptSmsSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to the customer by SMS.'**
  String get receiptSmsSent;

  /// No description provided for @disputeSent.
  ///
  /// In en, this message translates to:
  /// **'Problem sent to your bank supervisor.'**
  String get disputeSent;

  /// No description provided for @printError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the print dialog: {error}'**
  String printError(String error);

  /// No description provided for @pdfHeader.
  ///
  /// In en, this message translates to:
  /// **'FINBRIDGE AGENT BANKING'**
  String get pdfHeader;

  /// No description provided for @pdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt {reference}'**
  String pdfTitle(String reference);

  /// No description provided for @pdfCashDeposit.
  ///
  /// In en, this message translates to:
  /// **'CASH DEPOSIT'**
  String get pdfCashDeposit;

  /// No description provided for @pdfCashWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'CASH WITHDRAWAL'**
  String get pdfCashWithdrawal;

  /// No description provided for @pdfDepositDetails.
  ///
  /// In en, this message translates to:
  /// **'DEPOSIT DETAILS'**
  String get pdfDepositDetails;

  /// No description provided for @pdfWithdrawalDetails.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWAL DETAILS'**
  String get pdfWithdrawalDetails;

  /// No description provided for @pdfCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer:'**
  String get pdfCustomer;

  /// No description provided for @pdfAccount.
  ///
  /// In en, this message translates to:
  /// **'Account:'**
  String get pdfAccount;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get pdfDate;

  /// No description provided for @pdfAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent:'**
  String get pdfAgent;

  /// No description provided for @pdfAgentId.
  ///
  /// In en, this message translates to:
  /// **'Agent ID:'**
  String get pdfAgentId;

  /// No description provided for @pdfReference.
  ///
  /// In en, this message translates to:
  /// **'Ref #:'**
  String get pdfReference;

  /// No description provided for @pdfCashDeposited.
  ///
  /// In en, this message translates to:
  /// **'Cash deposited:'**
  String get pdfCashDeposited;

  /// No description provided for @pdfCashPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Cash paid out:'**
  String get pdfCashPaidOut;

  /// No description provided for @pdfServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee:'**
  String get pdfServiceFee;

  /// No description provided for @pdfTotalCredited.
  ///
  /// In en, this message translates to:
  /// **'Total credited:'**
  String get pdfTotalCredited;

  /// No description provided for @pdfTotalDebited.
  ///
  /// In en, this message translates to:
  /// **'Total debited:'**
  String get pdfTotalDebited;

  /// No description provided for @pdfPriorBalance.
  ///
  /// In en, this message translates to:
  /// **'Prior balance:'**
  String get pdfPriorBalance;

  /// No description provided for @pdfNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance:'**
  String get pdfNewBalance;

  /// No description provided for @pdfFooter.
  ///
  /// In en, this message translates to:
  /// **'Keep this receipt for your records.'**
  String get pdfFooter;

  /// No description provided for @pdfThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get pdfThankYou;

  /// No description provided for @eodTitle.
  ///
  /// In en, this message translates to:
  /// **'End-of-day cash count'**
  String get eodTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @openingCash.
  ///
  /// In en, this message translates to:
  /// **'Opening cash'**
  String get openingCash;

  /// No description provided for @cashInCount.
  ///
  /// In en, this message translates to:
  /// **'Cash in ({count})'**
  String cashInCount(int count);

  /// No description provided for @cashOutCount.
  ///
  /// In en, this message translates to:
  /// **'Cash out ({count})'**
  String cashOutCount(int count);

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected cash in hand'**
  String get expectedCash;

  /// No description provided for @eodPendingOtp.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 withdrawal is waiting for OTP. Don’t pay cash for it.} other{{count} withdrawals are waiting for OTP. Don’t pay cash for them.}}'**
  String eodPendingOtp(int count);

  /// No description provided for @countedCash.
  ///
  /// In en, this message translates to:
  /// **'Cash you counted (Rs)'**
  String get countedCash;

  /// No description provided for @currencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rs. '**
  String get currencyPrefix;

  /// No description provided for @matchesExpected.
  ///
  /// In en, this message translates to:
  /// **'Matches the expected amount.'**
  String get matchesExpected;

  /// No description provided for @differenceOver.
  ///
  /// In en, this message translates to:
  /// **'Difference: {amount} over'**
  String differenceOver(String amount);

  /// No description provided for @differenceShort.
  ///
  /// In en, this message translates to:
  /// **'Difference: {amount} short'**
  String differenceShort(String amount);

  /// No description provided for @notesForSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Notes for supervisor (optional)'**
  String get notesForSupervisor;

  /// No description provided for @submitEod.
  ///
  /// In en, this message translates to:
  /// **'Submit end-of-day report'**
  String get submitEod;

  /// No description provided for @enterCountedCash.
  ///
  /// In en, this message translates to:
  /// **'Enter the cash you counted'**
  String get enterCountedCash;

  /// No description provided for @eodBalanced.
  ///
  /// In en, this message translates to:
  /// **'Cash balanced. Report sent to your supervisor.'**
  String get eodBalanced;

  /// No description provided for @eodOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over. Report sent to your supervisor for review.'**
  String eodOver(String amount);

  /// No description provided for @eodShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} short. Report sent to your supervisor for review.'**
  String eodShort(String amount);

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Customer name or reference'**
  String get journalSearchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterDeposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get filterDeposits;

  /// No description provided for @filterWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get filterWithdrawals;

  /// No description provided for @filterAnyStatus.
  ///
  /// In en, this message translates to:
  /// **'Any status'**
  String get filterAnyStatus;

  /// No description provided for @noTransactionsMatch.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get noTransactionsMatch;

  /// No description provided for @terminalTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminalTitle;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @partnerBank.
  ///
  /// In en, this message translates to:
  /// **'Partner bank'**
  String get partnerBank;

  /// No description provided for @rebalanceCash.
  ///
  /// In en, this message translates to:
  /// **'Rebalance cash'**
  String get rebalanceCash;

  /// No description provided for @rebalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send extra cash to the bank, or ask for more'**
  String get rebalanceSubtitle;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get confirmNewPin;

  /// No description provided for @pinsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The new PINs do not match'**
  String get pinsDontMatch;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get pinChanged;

  /// No description provided for @sendExtraCash.
  ///
  /// In en, this message translates to:
  /// **'Send extra cash to the bank'**
  String get sendExtraCash;

  /// No description provided for @askMoreCash.
  ///
  /// In en, this message translates to:
  /// **'Ask the bank for more cash'**
  String get askMoreCash;

  /// No description provided for @amountRs.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs)'**
  String get amountRs;

  /// No description provided for @enterAnAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get enterAnAmount;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to your supervisor'**
  String get requestSent;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @supervisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get supervisorTitle;

  /// No description provided for @customerApplications.
  ///
  /// In en, this message translates to:
  /// **'Customer applications ({count})'**
  String customerApplications(int count);

  /// No description provided for @noApplications.
  ///
  /// In en, this message translates to:
  /// **'No applications waiting for review'**
  String get noApplications;

  /// No description provided for @rebalanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Cash rebalance requests ({count})'**
  String rebalanceRequests(int count);

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @lockedAgents.
  ///
  /// In en, this message translates to:
  /// **'Locked agents ({count})'**
  String lockedAgents(int count);

  /// No description provided for @noLockedAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents are locked out'**
  String get noLockedAgents;

  /// No description provided for @byAgentAt.
  ///
  /// In en, this message translates to:
  /// **'By {agent} • {time}'**
  String byAgentAt(String agent, String time);

  /// No description provided for @cashToBank.
  ///
  /// In en, this message translates to:
  /// **'cash to bank'**
  String get cashToBank;

  /// No description provided for @cashFromBank.
  ///
  /// In en, this message translates to:
  /// **'cash from bank'**
  String get cashFromBank;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @rejectName.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}'**
  String rejectName(String name);

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @atLeastFiveChars.
  ///
  /// In en, this message translates to:
  /// **'At least 5 characters'**
  String get atLeastFiveChars;

  /// No description provided for @approvedActive.
  ///
  /// In en, this message translates to:
  /// **'{name} approved: account is now active'**
  String approvedActive(String name);

  /// No description provided for @rejectedName.
  ///
  /// In en, this message translates to:
  /// **'{name} rejected'**
  String rejectedName(String name);

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @unlockedName.
  ///
  /// In en, this message translates to:
  /// **'{name} unlocked'**
  String unlockedName(String name);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer onboarding'**
  String get onboardingTitle;

  /// No description provided for @stepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get stepPersonal;

  /// No description provided for @stepFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get stepFamily;

  /// No description provided for @stepAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get stepAddress;

  /// No description provided for @stepDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get stepDocuments;

  /// No description provided for @requiredNote.
  ///
  /// In en, this message translates to:
  /// **'Fields marked * are required.'**
  String get requiredNote;

  /// No description provided for @continueTo.
  ///
  /// In en, this message translates to:
  /// **'Continue to {step}'**
  String continueTo(String step);

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for bank review'**
  String get submitForReview;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @citizenship.
  ///
  /// In en, this message translates to:
  /// **'Citizenship'**
  String get citizenship;

  /// No description provided for @familyDetails.
  ///
  /// In en, this message translates to:
  /// **'Family details'**
  String get familyDetails;

  /// No description provided for @permanentAddress.
  ///
  /// In en, this message translates to:
  /// **'Permanent address'**
  String get permanentAddress;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @middleNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Middle name (optional)'**
  String get middleNameOptional;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @otherGender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGender;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get maritalStatus;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @married.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get married;

  /// No description provided for @widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowed;

  /// No description provided for @divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get divorced;

  /// No description provided for @dobBs.
  ///
  /// In en, this message translates to:
  /// **'Date of birth, BS'**
  String get dobBs;

  /// No description provided for @dobAd.
  ///
  /// In en, this message translates to:
  /// **'Date of birth, AD'**
  String get dobAd;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'Age {age}'**
  String ageYears(int age);

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @occupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Agriculture'**
  String get occupationHint;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @mobileError.
  ///
  /// In en, this message translates to:
  /// **'10 digits starting 97 or 98'**
  String get mobileError;

  /// No description provided for @citizenshipNo.
  ///
  /// In en, this message translates to:
  /// **'Citizenship certificate no.'**
  String get citizenshipNo;

  /// No description provided for @citizenshipFormatError.
  ///
  /// In en, this message translates to:
  /// **'Use the format printed on the certificate'**
  String get citizenshipFormatError;

  /// No description provided for @issueDateBs.
  ///
  /// In en, this message translates to:
  /// **'Issue date, BS'**
  String get issueDateBs;

  /// No description provided for @issueDistrict.
  ///
  /// In en, this message translates to:
  /// **'Issue district'**
  String get issueDistrict;

  /// No description provided for @panOptional.
  ///
  /// In en, this message translates to:
  /// **'PAN (optional)'**
  String get panOptional;

  /// No description provided for @panError.
  ///
  /// In en, this message translates to:
  /// **'PAN has 9 digits'**
  String get panError;

  /// No description provided for @fatherName.
  ///
  /// In en, this message translates to:
  /// **'Father’s name'**
  String get fatherName;

  /// No description provided for @motherName.
  ///
  /// In en, this message translates to:
  /// **'Mother’s name'**
  String get motherName;

  /// No description provided for @grandfatherName.
  ///
  /// In en, this message translates to:
  /// **'Grandfather’s name'**
  String get grandfatherName;

  /// No description provided for @spouseName.
  ///
  /// In en, this message translates to:
  /// **'Spouse’s name'**
  String get spouseName;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @municipality.
  ///
  /// In en, this message translates to:
  /// **'Municipality / rural municipality'**
  String get municipality;

  /// No description provided for @wardNo.
  ///
  /// In en, this message translates to:
  /// **'Ward no.'**
  String get wardNo;

  /// No description provided for @wardError.
  ///
  /// In en, this message translates to:
  /// **'Ward between 1 and 35'**
  String get wardError;

  /// No description provided for @toleOptional.
  ///
  /// In en, this message translates to:
  /// **'Tole / street (optional)'**
  String get toleOptional;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get typeToSearch;

  /// No description provided for @chooseDistrictFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose the district first'**
  String get chooseDistrictFirst;

  /// No description provided for @inThisDistrict.
  ///
  /// In en, this message translates to:
  /// **'{count} in this district — type to search'**
  String inThisDistrict(int count);

  /// No description provided for @tickDocuments.
  ///
  /// In en, this message translates to:
  /// **'Tick each document after checking the original.'**
  String get tickDocuments;

  /// No description provided for @citizenshipFront.
  ///
  /// In en, this message translates to:
  /// **'Citizenship certificate – front'**
  String get citizenshipFront;

  /// No description provided for @citizenshipBack.
  ///
  /// In en, this message translates to:
  /// **'Citizenship certificate – back'**
  String get citizenshipBack;

  /// No description provided for @customerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Customer photo'**
  String get customerPhoto;

  /// No description provided for @consentTerms.
  ///
  /// In en, this message translates to:
  /// **'Customer agrees to the account terms.'**
  String get consentTerms;

  /// No description provided for @chooseOccupation.
  ///
  /// In en, this message translates to:
  /// **'Choose an occupation'**
  String get chooseOccupation;

  /// No description provided for @chooseIssueDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose the issue district'**
  String get chooseIssueDistrict;

  /// No description provided for @chooseDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose a district'**
  String get chooseDistrict;

  /// No description provided for @chooseMunicipality.
  ///
  /// In en, this message translates to:
  /// **'Choose a municipality'**
  String get chooseMunicipality;

  /// No description provided for @chooseDob.
  ///
  /// In en, this message translates to:
  /// **'Choose the date of birth'**
  String get chooseDob;

  /// No description provided for @minAge16.
  ///
  /// In en, this message translates to:
  /// **'The customer must be at least 16 years old'**
  String get minAge16;

  /// No description provided for @chooseIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Choose the issue date'**
  String get chooseIssueDate;

  /// No description provided for @notBeforeDob.
  ///
  /// In en, this message translates to:
  /// **'Cannot be before the date of birth'**
  String get notBeforeDob;

  /// No description provided for @notInFuture.
  ///
  /// In en, this message translates to:
  /// **'Cannot be in the future'**
  String get notInFuture;

  /// No description provided for @tapToChoose.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get tapToChoose;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @lettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Use letters only'**
  String get lettersOnly;

  /// No description provided for @documentsMissing.
  ///
  /// In en, this message translates to:
  /// **'Capture both sides of the citizenship certificate and the customer’s photo'**
  String get documentsMissing;

  /// No description provided for @mustAgree.
  ///
  /// In en, this message translates to:
  /// **'The customer must agree to the terms'**
  String get mustAgree;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get applicationSubmitted;

  /// No description provided for @applicationSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Customer ID: {id}\nAccount: {account}\n\nThe bank will check the details. Cash transactions work after approval.'**
  String applicationSubmittedBody(String id, String account);

  /// No description provided for @dobBsPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (BS)'**
  String get dobBsPickerTitle;

  /// No description provided for @dobAdPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (AD)'**
  String get dobAdPickerTitle;

  /// No description provided for @issueDatePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Citizenship issue date (BS)'**
  String get issueDatePickerTitle;

  /// No description provided for @bsYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get bsYear;

  /// No description provided for @bsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get bsMonth;

  /// No description provided for @bsDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get bsDay;

  /// No description provided for @bsEqualsAd.
  ///
  /// In en, this message translates to:
  /// **'BS {bs}  =  AD {ad}'**
  String bsEqualsAd(String bs, String ad);

  /// No description provided for @chooseDateBs.
  ///
  /// In en, this message translates to:
  /// **'Choose date (BS)'**
  String get chooseDateBs;

  /// No description provided for @monthBaisakh.
  ///
  /// In en, this message translates to:
  /// **'Baisakh'**
  String get monthBaisakh;

  /// No description provided for @monthJestha.
  ///
  /// In en, this message translates to:
  /// **'Jestha'**
  String get monthJestha;

  /// No description provided for @monthAsar.
  ///
  /// In en, this message translates to:
  /// **'Asar'**
  String get monthAsar;

  /// No description provided for @monthShrawan.
  ///
  /// In en, this message translates to:
  /// **'Shrawan'**
  String get monthShrawan;

  /// No description provided for @monthBhadra.
  ///
  /// In en, this message translates to:
  /// **'Bhadra'**
  String get monthBhadra;

  /// No description provided for @monthAsoj.
  ///
  /// In en, this message translates to:
  /// **'Asoj'**
  String get monthAsoj;

  /// No description provided for @monthKartik.
  ///
  /// In en, this message translates to:
  /// **'Kartik'**
  String get monthKartik;

  /// No description provided for @monthMangsir.
  ///
  /// In en, this message translates to:
  /// **'Mangsir'**
  String get monthMangsir;

  /// No description provided for @monthPoush.
  ///
  /// In en, this message translates to:
  /// **'Poush'**
  String get monthPoush;

  /// No description provided for @monthMagh.
  ///
  /// In en, this message translates to:
  /// **'Magh'**
  String get monthMagh;

  /// No description provided for @monthFalgun.
  ///
  /// In en, this message translates to:
  /// **'Falgun'**
  String get monthFalgun;

  /// No description provided for @monthChaitra.
  ///
  /// In en, this message translates to:
  /// **'Chaitra'**
  String get monthChaitra;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Agent ID or PIN is incorrect'**
  String get errInvalidCredentials;

  /// No description provided for @errAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'This agent account is locked. Ask your supervisor to unlock it.'**
  String get errAccountLocked;

  /// No description provided for @errAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'This account is not active.'**
  String get errAccountInactive;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Try again in a few minutes.'**
  String get errTooManyAttempts;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get errNetwork;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'No response. Check the journal before trying again.'**
  String get errTimeout;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to do this.'**
  String get errForbidden;

  /// No description provided for @errConflict.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errConflict;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @errCustomerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found'**
  String get errCustomerNotFound;

  /// No description provided for @errAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'This account does not belong to the selected customer'**
  String get errAccountNotFound;

  /// No description provided for @errAccountPending.
  ///
  /// In en, this message translates to:
  /// **'This account is waiting for bank approval'**
  String get errAccountPending;

  /// No description provided for @errAmountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between {min} and {max}'**
  String errAmountRange(String min, String max);

  /// No description provided for @errInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'The customer’s balance is not enough for this amount plus the fee'**
  String get errInsufficientBalance;

  /// No description provided for @errInsufficientFloat.
  ///
  /// In en, this message translates to:
  /// **'Not enough cash in hand for this withdrawal'**
  String get errInsufficientFloat;

  /// No description provided for @errFloatLimit.
  ///
  /// In en, this message translates to:
  /// **'This deposit would take your cash above its limit. Rebalance first.'**
  String get errFloatLimit;

  /// No description provided for @errWrongOtp.
  ///
  /// In en, this message translates to:
  /// **'The OTP is incorrect'**
  String get errWrongOtp;

  /// No description provided for @errOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'The OTP has expired. Start the withdrawal again.'**
  String get errOtpExpired;

  /// No description provided for @errOtpAttempts.
  ///
  /// In en, this message translates to:
  /// **'Wrong OTP entered 3 times. The withdrawal has been cancelled.'**
  String get errOtpAttempts;

  /// No description provided for @errNotAwaitingOtp.
  ///
  /// In en, this message translates to:
  /// **'This withdrawal is no longer waiting for an OTP'**
  String get errNotAwaitingOtp;

  /// No description provided for @errResendTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Please wait before resending the OTP'**
  String get errResendTooSoon;

  /// No description provided for @errResendLimit.
  ///
  /// In en, this message translates to:
  /// **'OTP resend limit reached. Start a new withdrawal.'**
  String get errResendLimit;

  /// No description provided for @errCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'Only a withdrawal waiting for its OTP can be cancelled'**
  String get errCannotCancel;

  /// No description provided for @errTransactionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get errTransactionNotFound;

  /// No description provided for @errDuplicateCitizenship.
  ///
  /// In en, this message translates to:
  /// **'A customer with this citizenship number already exists'**
  String get errDuplicateCitizenship;

  /// No description provided for @errDuplicateMobile.
  ///
  /// In en, this message translates to:
  /// **'This mobile number is already registered'**
  String get errDuplicateMobile;

  /// No description provided for @errEodAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Today’s end-of-day report has already been submitted'**
  String get errEodAlreadySubmitted;

  /// No description provided for @errInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN is incorrect'**
  String get errInvalidPin;

  /// No description provided for @errSamePin.
  ///
  /// In en, this message translates to:
  /// **'New PIN must be different'**
  String get errSamePin;

  /// No description provided for @errNotPending.
  ///
  /// In en, this message translates to:
  /// **'This application has already been reviewed'**
  String get errNotPending;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up.'**
  String get allCaughtUp;

  /// No description provided for @sendGetCash.
  ///
  /// In en, this message translates to:
  /// **'Send / get cash'**
  String get sendGetCash;

  /// No description provided for @cashInHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get cashInHandLabel;

  /// No description provided for @limitUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of {limit} limit'**
  String limitUsedOf(String percent, String limit);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
