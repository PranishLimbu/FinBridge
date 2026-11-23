// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FinBridge Agent';

  @override
  String get logoName => 'FinBridge';

  @override
  String get logoTagline => 'AGENT BANKING';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get refresh => 'Refresh';

  @override
  String get clear => 'Clear';

  @override
  String get logOut => 'Log out';

  @override
  String get required => 'Required';

  @override
  String get submitting => 'Submitting…';

  @override
  String get checking => 'Checking…';

  @override
  String get processing => 'Processing…';

  @override
  String get retry => 'Retry';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusPendingOtp => 'Pending OTP';

  @override
  String get statusKycPending => 'KYC pending';

  @override
  String get statusKycVerified => 'KYC verified';

  @override
  String get statusKycRejected => 'KYC rejected';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusActive => 'Active';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusBalanced => 'Balanced';

  @override
  String get statusMismatch => 'Mismatch';

  @override
  String get loginTitle => 'Agent login';

  @override
  String get loginSubtitle => 'Log in to your FinBridge counter';

  @override
  String get agentId => 'Agent ID';

  @override
  String get agentIdHint => 'e.g. AGT-98412';

  @override
  String get agentIdError => 'Enter your agent ID';

  @override
  String get pin => 'PIN';

  @override
  String get pinHint => '6 digits';

  @override
  String get pinSixDigits => 'PIN must be 6 digits';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinTitle => 'Forgot PIN';

  @override
  String get forgotPinBody => 'Ask your supervisor to reset your PIN.';

  @override
  String get showPin => 'Show PIN';

  @override
  String get hidePin => 'Hide PIN';

  @override
  String get neverSharePin => 'Never share your PIN or a customer’s OTP.';

  @override
  String get logIn => 'Log in';

  @override
  String triesLeft(String message, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left.',
      one: '1 try left.',
    );
    return '$message. $_temp0';
  }

  @override
  String get demoLoginHint => 'Demo login: AGT-98412 / PIN 123456';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get idleLoggedOut => 'Logged out after 5 minutes without activity.';

  @override
  String get tabCounter => 'Counter';

  @override
  String get tabCustomers => 'Customers';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabTerminal => 'Terminal';

  @override
  String greeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get cashInHand => 'CASH IN HAND';

  @override
  String openingAmount(String amount) {
    return 'Opening $amount';
  }

  @override
  String usedPercent(String percent) {
    return 'Used: $percent%';
  }

  @override
  String limitAmount(String amount) {
    return 'Limit: $amount';
  }

  @override
  String minReserveAmount(String amount) {
    return 'Min reserve $amount';
  }

  @override
  String get rebalance => 'Rebalance';

  @override
  String get todaysCash => 'Today’s cash';

  @override
  String get cashReceived => 'Cash received';

  @override
  String get cashPaidOut => 'Cash paid out';

  @override
  String txnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count txns',
      one: '1 txn',
    );
    return '$_temp0';
  }

  @override
  String get services => 'Services';

  @override
  String get cashDeposit => 'Cash deposit';

  @override
  String get cashDepositSub => 'Cash in';

  @override
  String get cashWithdrawal => 'Cash withdrawal';

  @override
  String get cashWithdrawalSub => 'Cash out with OTP';

  @override
  String get newCustomer => 'New customer';

  @override
  String get newCustomerSub => 'Open an account';

  @override
  String get findCustomer => 'Find customer';

  @override
  String get findCustomerSub => 'Mobile, account or name';

  @override
  String get todaysTransactions => 'Today’s transactions';

  @override
  String get seeAll => 'See all';

  @override
  String get noTransactionsToday => 'No transactions yet today.';

  @override
  String alertKycPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new accounts waiting for bank approval',
      one: '1 new account waiting for bank approval',
    );
    return '$_temp0';
  }

  @override
  String get alertEodDue => 'End-of-day cash count not done yet';

  @override
  String alertPendingOtp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count withdrawals are waiting for OTP',
      one: '1 withdrawal is waiting for OTP',
    );
    return '$_temp0';
  }

  @override
  String get alertLowFloat => 'Cash is near the minimum reserve';

  @override
  String get alertHighFloat => 'Cash is near the limit';

  @override
  String get startEod => 'Start EOD';

  @override
  String get view => 'View';

  @override
  String get customersTitle => 'Customers';

  @override
  String get findCustomerStepTitle => 'Step 1: Find customer';

  @override
  String get searchHint => 'Mobile, account, citizenship no. or name';

  @override
  String get searchPrompt =>
      'Search by mobile, account, citizenship no. or name.';

  @override
  String get noCustomerFound => 'No customer found.';

  @override
  String citizenshipMasked(String number) {
    return 'Citizenship $number';
  }

  @override
  String get kycNotVerified =>
      'KYC not verified yet. Cash transactions are not allowed.';

  @override
  String get stepCustomer => 'Customer';

  @override
  String get stepAccount => 'Account';

  @override
  String get stepAmount => 'Amount';

  @override
  String get stepReview => 'Review';

  @override
  String stepOfFour(int step, String name) {
    return 'Step $step of 4: $name';
  }

  @override
  String numberedStep(int step, String name) {
    return '$step. $name';
  }

  @override
  String get searchForCustomer => 'Search for the customer.';

  @override
  String get searchCustomer => 'Search customer';

  @override
  String get chooseAccount => 'Choose the account';

  @override
  String get chooseDifferentCustomer => 'Choose a different customer';

  @override
  String get depositTo => 'DEPOSIT TO';

  @override
  String get withdrawFrom => 'WITHDRAW FROM';

  @override
  String get typeLabel => 'TYPE';

  @override
  String get cashInTag => 'CASH IN';

  @override
  String get cashOutTag => 'CASH OUT';

  @override
  String get currencyCode => 'NPR';

  @override
  String get enterTheAmount => 'Enter the amount';

  @override
  String minMax(String min, String max) {
    return 'Min $min • Max $max';
  }

  @override
  String amountMinimum(String amount) {
    return 'Minimum is $amount';
  }

  @override
  String amountMaximum(String amount) {
    return 'Maximum is $amount per transaction';
  }

  @override
  String get quickAdd => 'QUICK ADD';

  @override
  String get fees => 'Fees';

  @override
  String get depositAmount => 'Deposit amount';

  @override
  String get cashToHandOver => 'Cash to hand over';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get free => 'Free';

  @override
  String get totalCredited => 'Total credited';

  @override
  String get totalDebited => 'Total debited';

  @override
  String get continueToReview => 'Continue to review';

  @override
  String get confirmWithCustomer => 'Confirm the details with the customer.';

  @override
  String get review => 'Review';

  @override
  String get service => 'Service';

  @override
  String get customer => 'Customer';

  @override
  String get account => 'Account';

  @override
  String get amount => 'Amount';

  @override
  String get fee => 'Fee';

  @override
  String get otpWillBeSent => 'The customer will get an OTP by SMS.';

  @override
  String get countCashFirst => 'Count the cash before you confirm.';

  @override
  String retrySafe(String error) {
    return '$error\nRetry is safe: it won’t create a second transaction.';
  }

  @override
  String get confirmDeposit => 'Confirm deposit';

  @override
  String get sendOtpToCustomer => 'Send OTP to customer';

  @override
  String get backChangeAmount => 'Back: change amount';

  @override
  String get deleteKey => 'Delete';

  @override
  String get otpTitle => 'Customer OTP';

  @override
  String get cancelAndBack => 'Cancel & Back';

  @override
  String get otpAsk =>
      'Ask the customer for the 6-digit OTP sent to their mobile.';

  @override
  String get otpExpired => 'OTP expired';

  @override
  String otpExpiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String demoOtp(String otp) {
    return 'Demo OTP: $otp';
  }

  @override
  String get otpSixDigits => 'The OTP has 6 digits';

  @override
  String attemptsLeft(String message, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts left.',
      one: '1 attempt left.',
    );
    return '$message. $_temp0';
  }

  @override
  String get verifyOtp => 'Verify OTP and confirm';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get backToCounter => 'Back to counter';

  @override
  String get giveCashAfterConfirmed =>
      'Give cash only after you see “Confirmed”.';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get transactionConfirmed => 'Transaction confirmed';

  @override
  String transactionStatus(String status) {
    return 'Transaction $status';
  }

  @override
  String partnerBankLine(String bank) {
    return 'Partner bank: $bank';
  }

  @override
  String receiptAgentLine(String location, String name, String id) {
    return '$location • Agent: $name ($id)';
  }

  @override
  String get reference => 'Reference';

  @override
  String get dateBs => 'Date (BS)';

  @override
  String get dateAd => 'Date (AD)';

  @override
  String get serviceDepositBranchless => 'Cash deposit (branchless)';

  @override
  String get serviceWithdrawalBranchless => 'Cash withdrawal (branchless)';

  @override
  String get cashDeposited => 'Cash deposited';

  @override
  String inWords(String words) {
    return 'In words: $words';
  }

  @override
  String get smsReceiptSentNote => 'An SMS receipt was sent to the customer.';

  @override
  String get printReceipt => 'Print receipt';

  @override
  String get sendSmsReceipt => 'Send SMS receipt';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get reportProblemHint => 'What does the customer say went wrong?';

  @override
  String get sendToSupervisor => 'Send to supervisor';

  @override
  String get receiptSmsSent => 'Receipt sent to the customer by SMS.';

  @override
  String get disputeSent => 'Problem sent to your bank supervisor.';

  @override
  String printError(String error) {
    return 'Could not open the print dialog: $error';
  }

  @override
  String get pdfHeader => 'FINBRIDGE AGENT BANKING';

  @override
  String pdfTitle(String reference) {
    return 'Receipt $reference';
  }

  @override
  String get pdfCashDeposit => 'CASH DEPOSIT';

  @override
  String get pdfCashWithdrawal => 'CASH WITHDRAWAL';

  @override
  String get pdfDepositDetails => 'DEPOSIT DETAILS';

  @override
  String get pdfWithdrawalDetails => 'WITHDRAWAL DETAILS';

  @override
  String get pdfCustomer => 'Customer:';

  @override
  String get pdfAccount => 'Account:';

  @override
  String get pdfDate => 'Date:';

  @override
  String get pdfAgent => 'Agent:';

  @override
  String get pdfAgentId => 'Agent ID:';

  @override
  String get pdfReference => 'Ref #:';

  @override
  String get pdfCashDeposited => 'Cash deposited:';

  @override
  String get pdfCashPaidOut => 'Cash paid out:';

  @override
  String get pdfServiceFee => 'Service fee:';

  @override
  String get pdfTotalCredited => 'Total credited:';

  @override
  String get pdfTotalDebited => 'Total debited:';

  @override
  String get pdfPriorBalance => 'Prior balance:';

  @override
  String get pdfNewBalance => 'New balance:';

  @override
  String get pdfFooter => 'Keep this receipt for your records.';

  @override
  String get pdfThankYou => 'Thank you';

  @override
  String get eodTitle => 'End-of-day cash count';

  @override
  String get today => 'Today';

  @override
  String get openingCash => 'Opening cash';

  @override
  String cashInCount(int count) {
    return 'Cash in ($count)';
  }

  @override
  String cashOutCount(int count) {
    return 'Cash out ($count)';
  }

  @override
  String get expectedCash => 'Expected cash in hand';

  @override
  String eodPendingOtp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count withdrawals are waiting for OTP. Don’t pay cash for them.',
      one: '1 withdrawal is waiting for OTP. Don’t pay cash for it.',
    );
    return '$_temp0';
  }

  @override
  String get countedCash => 'Cash you counted (Rs)';

  @override
  String get currencyPrefix => 'Rs. ';

  @override
  String get matchesExpected => 'Matches the expected amount.';

  @override
  String differenceOver(String amount) {
    return 'Difference: $amount over';
  }

  @override
  String differenceShort(String amount) {
    return 'Difference: $amount short';
  }

  @override
  String get notesForSupervisor => 'Notes for supervisor (optional)';

  @override
  String get submitEod => 'Submit end-of-day report';

  @override
  String get enterCountedCash => 'Enter the cash you counted';

  @override
  String get eodBalanced => 'Cash balanced. Report sent to your supervisor.';

  @override
  String eodOver(String amount) {
    return '$amount over. Report sent to your supervisor for review.';
  }

  @override
  String eodShort(String amount) {
    return '$amount short. Report sent to your supervisor for review.';
  }

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalSearchHint => 'Customer name or reference';

  @override
  String get filterAll => 'All';

  @override
  String get filterDeposits => 'Deposits';

  @override
  String get filterWithdrawals => 'Withdrawals';

  @override
  String get filterAnyStatus => 'Any status';

  @override
  String get noTransactionsMatch => 'No transactions match these filters.';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get location => 'Location';

  @override
  String get terminal => 'Terminal';

  @override
  String get partnerBank => 'Partner bank';

  @override
  String get rebalanceCash => 'Rebalance cash';

  @override
  String get rebalanceSubtitle =>
      'Send extra cash to the bank, or ask for more';

  @override
  String get changePin => 'Change PIN';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get confirmNewPin => 'Confirm new PIN';

  @override
  String get pinsDontMatch => 'The new PINs do not match';

  @override
  String get pinChanged => 'PIN changed';

  @override
  String get sendExtraCash => 'Send extra cash to the bank';

  @override
  String get askMoreCash => 'Ask the bank for more cash';

  @override
  String get amountRs => 'Amount (Rs)';

  @override
  String get enterAnAmount => 'Enter an amount';

  @override
  String get requestSent => 'Request sent to your supervisor';

  @override
  String get sendRequest => 'Send request';

  @override
  String get supervisorTitle => 'Supervisor';

  @override
  String customerApplications(int count) {
    return 'Customer applications ($count)';
  }

  @override
  String get noApplications => 'No applications waiting for review';

  @override
  String rebalanceRequests(int count) {
    return 'Cash rebalance requests ($count)';
  }

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String lockedAgents(int count) {
    return 'Locked agents ($count)';
  }

  @override
  String get noLockedAgents => 'No agents are locked out';

  @override
  String byAgentAt(String agent, String time) {
    return 'By $agent • $time';
  }

  @override
  String get cashToBank => 'cash to bank';

  @override
  String get cashFromBank => 'cash from bank';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get unlock => 'Unlock';

  @override
  String rejectName(String name) {
    return 'Reject $name';
  }

  @override
  String get reason => 'Reason';

  @override
  String get atLeastFiveChars => 'At least 5 characters';

  @override
  String approvedActive(String name) {
    return '$name approved: account is now active';
  }

  @override
  String rejectedName(String name) {
    return '$name rejected';
  }

  @override
  String get requestApproved => 'Request approved';

  @override
  String get requestRejected => 'Request rejected';

  @override
  String unlockedName(String name) {
    return '$name unlocked';
  }

  @override
  String get onboardingTitle => 'Customer onboarding';

  @override
  String get stepPersonal => 'Personal';

  @override
  String get stepFamily => 'Family';

  @override
  String get stepAddress => 'Address';

  @override
  String get stepDocuments => 'Documents';

  @override
  String get requiredNote => 'Fields marked * are required.';

  @override
  String continueTo(String step) {
    return 'Continue to $step';
  }

  @override
  String get submitForReview => 'Submit for bank review';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get citizenship => 'Citizenship';

  @override
  String get familyDetails => 'Family details';

  @override
  String get permanentAddress => 'Permanent address';

  @override
  String get documents => 'Documents';

  @override
  String get firstName => 'First name';

  @override
  String get middleNameOptional => 'Middle name (optional)';

  @override
  String get lastName => 'Last name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get otherGender => 'Other';

  @override
  String get maritalStatus => 'Marital status';

  @override
  String get single => 'Single';

  @override
  String get married => 'Married';

  @override
  String get widowed => 'Widowed';

  @override
  String get divorced => 'Divorced';

  @override
  String get dobBs => 'Date of birth, BS';

  @override
  String get dobAd => 'Date of birth, AD';

  @override
  String ageYears(int age) {
    return 'Age $age';
  }

  @override
  String get occupation => 'Occupation';

  @override
  String get occupationHint => 'e.g. Agriculture';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get mobileError => '10 digits starting 97 or 98';

  @override
  String get citizenshipNo => 'Citizenship certificate no.';

  @override
  String get citizenshipFormatError =>
      'Use the format printed on the certificate';

  @override
  String get issueDateBs => 'Issue date, BS';

  @override
  String get issueDistrict => 'Issue district';

  @override
  String get panOptional => 'PAN (optional)';

  @override
  String get panError => 'PAN has 9 digits';

  @override
  String get fatherName => 'Father’s name';

  @override
  String get motherName => 'Mother’s name';

  @override
  String get grandfatherName => 'Grandfather’s name';

  @override
  String get spouseName => 'Spouse’s name';

  @override
  String get province => 'Province';

  @override
  String get district => 'District';

  @override
  String get municipality => 'Municipality / rural municipality';

  @override
  String get wardNo => 'Ward no.';

  @override
  String get wardError => 'Ward between 1 and 35';

  @override
  String get toleOptional => 'Tole / street (optional)';

  @override
  String get typeToSearch => 'Type to search';

  @override
  String get chooseDistrictFirst => 'Choose the district first';

  @override
  String inThisDistrict(int count) {
    return '$count in this district — type to search';
  }

  @override
  String get tickDocuments => 'Tick each document after checking the original.';

  @override
  String get citizenshipFront => 'Citizenship certificate – front';

  @override
  String get citizenshipBack => 'Citizenship certificate – back';

  @override
  String get customerPhoto => 'Customer photo';

  @override
  String get consentTerms => 'Customer agrees to the account terms.';

  @override
  String get chooseOccupation => 'Choose an occupation';

  @override
  String get chooseIssueDistrict => 'Choose the issue district';

  @override
  String get chooseDistrict => 'Choose a district';

  @override
  String get chooseMunicipality => 'Choose a municipality';

  @override
  String get chooseDob => 'Choose the date of birth';

  @override
  String get minAge16 => 'The customer must be at least 16 years old';

  @override
  String get chooseIssueDate => 'Choose the issue date';

  @override
  String get notBeforeDob => 'Cannot be before the date of birth';

  @override
  String get notInFuture => 'Cannot be in the future';

  @override
  String get tapToChoose => 'Tap to choose';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get lettersOnly => 'Use letters only';

  @override
  String get documentsMissing =>
      'Capture both sides of the citizenship certificate and the customer’s photo';

  @override
  String get mustAgree => 'The customer must agree to the terms';

  @override
  String get applicationSubmitted => 'Application submitted';

  @override
  String applicationSubmittedBody(String id, String account) {
    return 'Customer ID: $id\nAccount: $account\n\nThe bank will check the details. Cash transactions work after approval.';
  }

  @override
  String get dobBsPickerTitle => 'Date of birth (BS)';

  @override
  String get dobAdPickerTitle => 'Date of birth (AD)';

  @override
  String get issueDatePickerTitle => 'Citizenship issue date (BS)';

  @override
  String get bsYear => 'Year';

  @override
  String get bsMonth => 'Month';

  @override
  String get bsDay => 'Day';

  @override
  String bsEqualsAd(String bs, String ad) {
    return 'BS $bs  =  AD $ad';
  }

  @override
  String get chooseDateBs => 'Choose date (BS)';

  @override
  String get monthBaisakh => 'Baisakh';

  @override
  String get monthJestha => 'Jestha';

  @override
  String get monthAsar => 'Asar';

  @override
  String get monthShrawan => 'Shrawan';

  @override
  String get monthBhadra => 'Bhadra';

  @override
  String get monthAsoj => 'Asoj';

  @override
  String get monthKartik => 'Kartik';

  @override
  String get monthMangsir => 'Mangsir';

  @override
  String get monthPoush => 'Poush';

  @override
  String get monthMagh => 'Magh';

  @override
  String get monthFalgun => 'Falgun';

  @override
  String get monthChaitra => 'Chaitra';

  @override
  String get errInvalidCredentials => 'Agent ID or PIN is incorrect';

  @override
  String get errAccountLocked =>
      'This agent account is locked. Ask your supervisor to unlock it.';

  @override
  String get errAccountInactive => 'This account is not active.';

  @override
  String get errTooManyAttempts =>
      'Too many wrong PINs. Try again in a few minutes.';

  @override
  String get errNetwork => 'No internet connection. Please try again.';

  @override
  String get errTimeout =>
      'No response. Check the journal before trying again.';

  @override
  String get errForbidden => 'You don’t have permission to do this.';

  @override
  String get errConflict => 'Something went wrong. Please try again.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errCustomerNotFound => 'Customer not found';

  @override
  String get errAccountNotFound =>
      'This account does not belong to the selected customer';

  @override
  String get errAccountPending => 'This account is waiting for bank approval';

  @override
  String errAmountRange(String min, String max) {
    return 'Amount must be between $min and $max';
  }

  @override
  String get errInsufficientBalance =>
      'The customer’s balance is not enough for this amount plus the fee';

  @override
  String get errInsufficientFloat =>
      'Not enough cash in hand for this withdrawal';

  @override
  String get errFloatLimit =>
      'This deposit would take your cash above its limit. Rebalance first.';

  @override
  String get errWrongOtp => 'The OTP is incorrect';

  @override
  String get errOtpExpired =>
      'The OTP has expired. Start the withdrawal again.';

  @override
  String get errOtpAttempts =>
      'Wrong OTP entered 3 times. The withdrawal has been cancelled.';

  @override
  String get errNotAwaitingOtp =>
      'This withdrawal is no longer waiting for an OTP';

  @override
  String get errResendTooSoon => 'Please wait before resending the OTP';

  @override
  String get errResendLimit =>
      'OTP resend limit reached. Start a new withdrawal.';

  @override
  String get errCannotCancel =>
      'Only a withdrawal waiting for its OTP can be cancelled';

  @override
  String get errTransactionNotFound => 'Transaction not found';

  @override
  String get errDuplicateCitizenship =>
      'A customer with this citizenship number already exists';

  @override
  String get errDuplicateMobile => 'This mobile number is already registered';

  @override
  String get errEodAlreadySubmitted =>
      'Today’s end-of-day report has already been submitted';

  @override
  String get errInvalidPin => 'Current PIN is incorrect';

  @override
  String get errSamePin => 'New PIN must be different';

  @override
  String get errNotPending => 'This application has already been reviewed';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get allCaughtUp => 'You’re all caught up.';

  @override
  String get sendGetCash => 'Send / get cash';

  @override
  String get cashInHandLabel => 'Cash in hand';

  @override
  String limitUsedOf(String percent, String limit) {
    return '$percent% of $limit limit';
  }

  @override
  String get customerDetailsTitle => 'Customer details';

  @override
  String get viewDetails => 'View details';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get identity => 'Identity';

  @override
  String get middleName => 'Middle name';

  @override
  String get mobile => 'Mobile';

  @override
  String get pan => 'PAN';

  @override
  String get father => 'Father';

  @override
  String get mother => 'Mother';

  @override
  String get grandfather => 'Grandfather';

  @override
  String get spouse => 'Spouse';

  @override
  String get ward => 'Ward';

  @override
  String wardNumber(String number) {
    return 'Ward $number';
  }

  @override
  String get tole => 'Tole';

  @override
  String get fullAddress => 'Full address';

  @override
  String get accounts => 'Accounts';

  @override
  String get noAccounts => 'No accounts';

  @override
  String get reviewApplication => 'Review';

  @override
  String get reviewApplicationTitle => 'Review application';

  @override
  String get decision => 'Decision';

  @override
  String get reviewCheckFirst =>
      'Check the customer’s details and documents above, then approve or reject.';

  @override
  String get reviewChecked =>
      'I have checked the customer’s details and documents';

  @override
  String get docNoFile =>
      'Checked by the agent at onboarding. No scan uploaded yet.';

  @override
  String get docMissing => 'Not provided';

  @override
  String get docLoadError => 'Couldn’t load this file';

  @override
  String get errKycNotOpened =>
      'Open the application and check the details and documents first';
}
