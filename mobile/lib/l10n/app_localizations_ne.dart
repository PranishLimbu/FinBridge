// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'फिनब्रिज एजेन्ट';

  @override
  String get logoName => 'FinBridge';

  @override
  String get logoTagline => 'एजेन्ट बैंकिङ';

  @override
  String get back => 'पछाडि';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get ok => 'ठीक छ';

  @override
  String get done => 'सकियो';

  @override
  String get save => 'सेभ गर्नुहोस्';

  @override
  String get refresh => 'रिफ्रेस';

  @override
  String get clear => 'हटाउनुहोस्';

  @override
  String get logOut => 'लग आउट';

  @override
  String get required => 'अनिवार्य';

  @override
  String get submitting => 'पठाउँदै…';

  @override
  String get checking => 'जाँच गर्दै…';

  @override
  String get processing => 'प्रक्रिया हुँदै…';

  @override
  String get retry => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get language => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get statusConfirmed => 'पुष्टि भयो';

  @override
  String get statusPendingOtp => 'OTP बाँकी';

  @override
  String get statusKycPending => 'KYC बाँकी';

  @override
  String get statusKycVerified => 'KYC प्रमाणित';

  @override
  String get statusKycRejected => 'KYC अस्वीकृत';

  @override
  String get statusPending => 'बाँकी';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusCancelled => 'रद्द भयो';

  @override
  String get statusFailed => 'असफल';

  @override
  String get statusBalanced => 'मिल्यो';

  @override
  String get statusMismatch => 'मिलेन';

  @override
  String get loginTitle => 'एजेन्ट लगइन';

  @override
  String get loginSubtitle => 'आफ्नो फिनब्रिज काउन्टरमा लगइन गर्नुहोस्';

  @override
  String get agentId => 'एजेन्ट आईडी';

  @override
  String get agentIdHint => 'जस्तै AGT-98412';

  @override
  String get agentIdError => 'आफ्नो एजेन्ट आईडी लेख्नुहोस्';

  @override
  String get pin => 'पिन';

  @override
  String get pinHint => '६ अङ्क';

  @override
  String get pinSixDigits => 'पिन ६ अङ्कको हुनुपर्छ';

  @override
  String get forgotPin => 'पिन बिर्सनुभयो?';

  @override
  String get forgotPinTitle => 'पिन बिर्सनुभयो';

  @override
  String get forgotPinBody => 'पिन रिसेट गर्न आफ्नो सुपरभाइजरलाई भन्नुहोस्।';

  @override
  String get showPin => 'पिन देखाउनुहोस्';

  @override
  String get hidePin => 'पिन लुकाउनुहोस्';

  @override
  String get neverSharePin => 'आफ्नो पिन वा ग्राहकको OTP कसैलाई नदिनुहोस्।';

  @override
  String get logIn => 'लगइन';

  @override
  String triesLeft(String message, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अब $count पटक प्रयास बाँकी।',
      one: 'अब १ पटक मात्र प्रयास बाँकी।',
    );
    return '$message। $_temp0';
  }

  @override
  String get demoLoginHint => 'डेमो लगइन: AGT-98412 / पिन 123456';

  @override
  String get sessionExpired => 'तपाईंको सत्र सकियो। फेरि लगइन गर्नुहोस्।';

  @override
  String get idleLoggedOut => '५ मिनेट केही नगरेकाले लग आउट भयो।';

  @override
  String get tabCounter => 'काउन्टर';

  @override
  String get tabCustomers => 'ग्राहक';

  @override
  String get tabJournal => 'कारोबार';

  @override
  String get tabTerminal => 'टर्मिनल';

  @override
  String greeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get cashInHand => 'हातमा नगद';

  @override
  String openingAmount(String amount) {
    return 'सुरुको $amount';
  }

  @override
  String usedPercent(String percent) {
    return 'प्रयोग: $percent%';
  }

  @override
  String limitAmount(String amount) {
    return 'सीमा: $amount';
  }

  @override
  String minReserveAmount(String amount) {
    return 'न्यूनतम मौज्दात $amount';
  }

  @override
  String get rebalance => 'सन्तुलन';

  @override
  String get todaysCash => 'आजको नगद';

  @override
  String get cashReceived => 'प्राप्त नगद';

  @override
  String get cashPaidOut => 'भुक्तानी नगद';

  @override
  String txnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कारोबार',
      one: '१ कारोबार',
    );
    return '$_temp0';
  }

  @override
  String get services => 'सेवाहरू';

  @override
  String get cashDeposit => 'नगद जम्मा';

  @override
  String get cashDepositSub => 'नगद भित्र';

  @override
  String get cashWithdrawal => 'नगद झिकाइ';

  @override
  String get cashWithdrawalSub => 'OTP सहित नगद बाहिर';

  @override
  String get newCustomer => 'नयाँ ग्राहक';

  @override
  String get newCustomerSub => 'खाता खोल्नुहोस्';

  @override
  String get findCustomer => 'ग्राहक खोज्नुहोस्';

  @override
  String get findCustomerSub => 'मोबाइल, खाता वा नाम';

  @override
  String get todaysTransactions => 'आजका कारोबार';

  @override
  String get seeAll => 'सबै हेर्नुहोस्';

  @override
  String get noTransactionsToday => 'आज अहिलेसम्म कुनै कारोबार छैन।';

  @override
  String alertKycPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नयाँ खाता बैंकको स्वीकृति कुर्दै',
      one: '१ नयाँ खाता बैंकको स्वीकृति कुर्दै',
    );
    return '$_temp0';
  }

  @override
  String get alertEodDue => 'दिनको अन्त्यको नगद गणना बाँकी छ';

  @override
  String alertPendingOtp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count झिकाइ OTP कुर्दै छन्',
      one: '१ झिकाइ OTP कुर्दै छ',
    );
    return '$_temp0';
  }

  @override
  String get alertLowFloat => 'नगद न्यूनतम मौज्दात नजिक छ';

  @override
  String get alertHighFloat => 'नगद सीमा नजिक छ';

  @override
  String get startEod => 'EOD सुरु';

  @override
  String get view => 'हेर्नुहोस्';

  @override
  String get customersTitle => 'ग्राहकहरू';

  @override
  String get findCustomerStepTitle => 'चरण १: ग्राहक खोज्नुहोस्';

  @override
  String get searchHint => 'मोबाइल, खाता, नागरिकता नं. वा नाम';

  @override
  String get searchPrompt => 'मोबाइल, खाता, नागरिकता नं. वा नामबाट खोज्नुहोस्।';

  @override
  String get noCustomerFound => 'कुनै ग्राहक भेटिएन।';

  @override
  String citizenshipMasked(String number) {
    return 'नागरिकता $number';
  }

  @override
  String get kycNotVerified =>
      'KYC प्रमाणित भएको छैन। नगद कारोबार गर्न मिल्दैन।';

  @override
  String get stepCustomer => 'ग्राहक';

  @override
  String get stepAccount => 'खाता';

  @override
  String get stepAmount => 'रकम';

  @override
  String get stepReview => 'जाँच';

  @override
  String stepOfFour(int step, String name) {
    return 'चरण $step / ४: $name';
  }

  @override
  String numberedStep(int step, String name) {
    return '$step. $name';
  }

  @override
  String get searchForCustomer => 'ग्राहक खोज्नुहोस्।';

  @override
  String get searchCustomer => 'ग्राहक खोज्नुहोस्';

  @override
  String get chooseAccount => 'खाता छान्नुहोस्';

  @override
  String get chooseDifferentCustomer => 'अर्को ग्राहक छान्नुहोस्';

  @override
  String get depositTo => 'जम्मा हुने खाता';

  @override
  String get withdrawFrom => 'झिकिने खाता';

  @override
  String get typeLabel => 'प्रकार';

  @override
  String get cashInTag => 'नगद भित्र';

  @override
  String get cashOutTag => 'नगद बाहिर';

  @override
  String get currencyCode => 'NPR';

  @override
  String get enterTheAmount => 'रकम लेख्नुहोस्';

  @override
  String minMax(String min, String max) {
    return 'न्यूनतम $min • अधिकतम $max';
  }

  @override
  String amountMinimum(String amount) {
    return 'न्यूनतम रकम $amount हो';
  }

  @override
  String amountMaximum(String amount) {
    return 'एक कारोबारमा अधिकतम $amount';
  }

  @override
  String get quickAdd => 'छिटो थप्नुहोस्';

  @override
  String get fees => 'शुल्क';

  @override
  String get depositAmount => 'जम्मा रकम';

  @override
  String get cashToHandOver => 'दिने नगद';

  @override
  String get serviceFee => 'सेवा शुल्क';

  @override
  String get free => 'निःशुल्क';

  @override
  String get totalCredited => 'जम्मा भएको कुल';

  @override
  String get totalDebited => 'कटौती भएको कुल';

  @override
  String get continueToReview => 'जाँचमा जानुहोस्';

  @override
  String get confirmWithCustomer => 'ग्राहकसँग विवरण पक्का गर्नुहोस्।';

  @override
  String get review => 'जाँच';

  @override
  String get service => 'सेवा';

  @override
  String get customer => 'ग्राहक';

  @override
  String get account => 'खाता';

  @override
  String get amount => 'रकम';

  @override
  String get fee => 'शुल्क';

  @override
  String get otpWillBeSent => 'ग्राहकलाई SMS मार्फत OTP आउनेछ।';

  @override
  String get countCashFirst => 'पक्का गर्नुअघि नगद गन्नुहोस्।';

  @override
  String retrySafe(String error) {
    return '$error\nफेरि प्रयास गर्दा दोस्रो कारोबार बन्दैन।';
  }

  @override
  String get confirmDeposit => 'जम्मा पक्का गर्नुहोस्';

  @override
  String get sendOtpToCustomer => 'ग्राहकलाई OTP पठाउनुहोस्';

  @override
  String get backChangeAmount => 'पछाडि: रकम बदल्नुहोस्';

  @override
  String get deleteKey => 'मेटाउनुहोस्';

  @override
  String get otpTitle => 'ग्राहकको OTP';

  @override
  String get cancelAndBack => 'रद्द गरी पछाडि';

  @override
  String get otpAsk => 'ग्राहकको मोबाइलमा आएको ६ अङ्कको OTP सोध्नुहोस्।';

  @override
  String get otpExpired => 'OTP को समय सकियो';

  @override
  String otpExpiresIn(String time) {
    return '$time मा समय सकिन्छ';
  }

  @override
  String demoOtp(String otp) {
    return 'डेमो OTP: $otp';
  }

  @override
  String get otpSixDigits => 'OTP ६ अङ्कको हुन्छ';

  @override
  String attemptsLeft(String message, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अब $count पटक प्रयास बाँकी।',
      one: 'अब १ पटक मात्र प्रयास बाँकी।',
    );
    return '$message। $_temp0';
  }

  @override
  String get verifyOtp => 'OTP जाँची पक्का गर्नुहोस्';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकेन्डपछि फेरि पठाउनुहोस्';
  }

  @override
  String get resendOtp => 'OTP फेरि पठाउनुहोस्';

  @override
  String get backToCounter => 'काउन्टरमा फर्कनुहोस्';

  @override
  String get giveCashAfterConfirmed =>
      '“पुष्टि भयो” देखेपछि मात्र नगद दिनुहोस्।';

  @override
  String get receiptTitle => 'रसिद';

  @override
  String get transactionConfirmed => 'कारोबार पुष्टि भयो';

  @override
  String transactionStatus(String status) {
    return 'कारोबार $status';
  }

  @override
  String partnerBankLine(String bank) {
    return 'साझेदार बैंक: $bank';
  }

  @override
  String receiptAgentLine(String location, String name, String id) {
    return '$location • एजेन्ट: $name ($id)';
  }

  @override
  String get reference => 'सन्दर्भ नं.';

  @override
  String get dateBs => 'मिति (वि.सं.)';

  @override
  String get dateAd => 'मिति (ई.सं.)';

  @override
  String get serviceDepositBranchless => 'नगद जम्मा (शाखारहित)';

  @override
  String get serviceWithdrawalBranchless => 'नगद झिकाइ (शाखारहित)';

  @override
  String get cashDeposited => 'जम्मा भएको नगद';

  @override
  String inWords(String words) {
    return 'अक्षरमा: $words';
  }

  @override
  String get smsReceiptSentNote => 'ग्राहकलाई SMS रसिद पठाइयो।';

  @override
  String get printReceipt => 'रसिद प्रिन्ट गर्नुहोस्';

  @override
  String get sendSmsReceipt => 'SMS रसिद पठाउनुहोस्';

  @override
  String get reportProblem => 'समस्या रिपोर्ट गर्नुहोस्';

  @override
  String get reportProblemHint => 'ग्राहकका अनुसार के गल्ती भयो?';

  @override
  String get sendToSupervisor => 'सुपरभाइजरलाई पठाउनुहोस्';

  @override
  String get receiptSmsSent => 'ग्राहकलाई SMS मार्फत रसिद पठाइयो।';

  @override
  String get disputeSent => 'समस्या तपाईंको बैंक सुपरभाइजरलाई पठाइयो।';

  @override
  String printError(String error) {
    return 'प्रिन्ट खोल्न सकिएन: $error';
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
  String get eodTitle => 'दिनको अन्त्यको नगद गणना';

  @override
  String get today => 'आज';

  @override
  String get openingCash => 'सुरुको नगद';

  @override
  String cashInCount(int count) {
    return 'नगद भित्र ($count)';
  }

  @override
  String cashOutCount(int count) {
    return 'नगद बाहिर ($count)';
  }

  @override
  String get expectedCash => 'हातमा हुनुपर्ने नगद';

  @override
  String eodPendingOtp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count झिकाइ OTP कुर्दै छन्। तिनको नगद नदिनुहोस्।',
      one: '१ झिकाइ OTP कुर्दै छ। यसको नगद नदिनुहोस्।',
    );
    return '$_temp0';
  }

  @override
  String get countedCash => 'गनिएको नगद (रु)';

  @override
  String get currencyPrefix => 'रु. ';

  @override
  String get matchesExpected => 'हुनुपर्ने रकमसँग मिल्यो।';

  @override
  String differenceOver(String amount) {
    return 'फरक: $amount बढी';
  }

  @override
  String differenceShort(String amount) {
    return 'फरक: $amount कम';
  }

  @override
  String get notesForSupervisor => 'सुपरभाइजरका लागि टिप्पणी (ऐच्छिक)';

  @override
  String get submitEod => 'दिनको अन्त्यको रिपोर्ट पठाउनुहोस्';

  @override
  String get enterCountedCash => 'गनिएको नगद लेख्नुहोस्';

  @override
  String get eodBalanced => 'नगद मिल्यो। रिपोर्ट सुपरभाइजरलाई पठाइयो।';

  @override
  String eodOver(String amount) {
    return '$amount बढी। जाँचका लागि रिपोर्ट सुपरभाइजरलाई पठाइयो।';
  }

  @override
  String eodShort(String amount) {
    return '$amount कम। जाँचका लागि रिपोर्ट सुपरभाइजरलाई पठाइयो।';
  }

  @override
  String get journalTitle => 'कारोबार';

  @override
  String get journalSearchHint => 'ग्राहकको नाम वा सन्दर्भ नं.';

  @override
  String get filterAll => 'सबै';

  @override
  String get filterDeposits => 'जम्मा';

  @override
  String get filterWithdrawals => 'झिकाइ';

  @override
  String get filterAnyStatus => 'जुनसुकै स्थिति';

  @override
  String get noTransactionsMatch => 'यी फिल्टरसँग मिल्ने कारोबार छैन।';

  @override
  String get terminalTitle => 'टर्मिनल';

  @override
  String get location => 'स्थान';

  @override
  String get terminal => 'टर्मिनल';

  @override
  String get partnerBank => 'साझेदार बैंक';

  @override
  String get rebalanceCash => 'नगद सन्तुलन';

  @override
  String get rebalanceSubtitle => 'बढी नगद बैंकमा पठाउनुहोस्, वा थप माग्नुहोस्';

  @override
  String get changePin => 'पिन बदल्नुहोस्';

  @override
  String get currentPin => 'हालको पिन';

  @override
  String get newPin => 'नयाँ पिन';

  @override
  String get confirmNewPin => 'नयाँ पिन फेरि लेख्नुहोस्';

  @override
  String get pinsDontMatch => 'नयाँ पिन मिलेनन्';

  @override
  String get pinChanged => 'पिन बदलियो';

  @override
  String get sendExtraCash => 'बढी नगद बैंकमा पठाउनुहोस्';

  @override
  String get askMoreCash => 'बैंकसँग थप नगद माग्नुहोस्';

  @override
  String get amountRs => 'रकम (रु)';

  @override
  String get enterAnAmount => 'रकम लेख्नुहोस्';

  @override
  String get requestSent => 'अनुरोध सुपरभाइजरलाई पठाइयो';

  @override
  String get sendRequest => 'अनुरोध पठाउनुहोस्';

  @override
  String get supervisorTitle => 'सुपरभाइजर';

  @override
  String customerApplications(int count) {
    return 'ग्राहक आवेदन ($count)';
  }

  @override
  String get noApplications => 'जाँच कुर्दै गरेको कुनै आवेदन छैन';

  @override
  String rebalanceRequests(int count) {
    return 'नगद सन्तुलन अनुरोध ($count)';
  }

  @override
  String get noPendingRequests => 'कुनै अनुरोध बाँकी छैन';

  @override
  String lockedAgents(int count) {
    return 'लक भएका एजेन्ट ($count)';
  }

  @override
  String get noLockedAgents => 'कुनै एजेन्ट लक भएको छैन';

  @override
  String byAgentAt(String agent, String time) {
    return '$agent द्वारा • $time';
  }

  @override
  String get cashToBank => 'बैंकमा नगद';

  @override
  String get cashFromBank => 'बैंकबाट नगद';

  @override
  String get approve => 'स्वीकृत';

  @override
  String get reject => 'अस्वीकृत';

  @override
  String get unlock => 'अनलक';

  @override
  String rejectName(String name) {
    return '$name अस्वीकृत गर्नुहोस्';
  }

  @override
  String get reason => 'कारण';

  @override
  String get atLeastFiveChars => 'कम्तीमा ५ अक्षर';

  @override
  String approvedActive(String name) {
    return '$name स्वीकृत: खाता अब सक्रिय छ';
  }

  @override
  String rejectedName(String name) {
    return '$name अस्वीकृत भयो';
  }

  @override
  String get requestApproved => 'अनुरोध स्वीकृत भयो';

  @override
  String get requestRejected => 'अनुरोध अस्वीकृत भयो';

  @override
  String unlockedName(String name) {
    return '$name अनलक भयो';
  }

  @override
  String get onboardingTitle => 'ग्राहक दर्ता';

  @override
  String get stepPersonal => 'व्यक्तिगत';

  @override
  String get stepFamily => 'परिवार';

  @override
  String get stepAddress => 'ठेगाना';

  @override
  String get stepDocuments => 'कागजात';

  @override
  String get requiredNote => '* चिन्ह भएका विवरण अनिवार्य छन्।';

  @override
  String continueTo(String step) {
    return '$step मा जानुहोस्';
  }

  @override
  String get submitForReview => 'बैंकको जाँचका लागि पठाउनुहोस्';

  @override
  String get personalDetails => 'व्यक्तिगत विवरण';

  @override
  String get citizenship => 'नागरिकता';

  @override
  String get familyDetails => 'पारिवारिक विवरण';

  @override
  String get permanentAddress => 'स्थायी ठेगाना';

  @override
  String get documents => 'कागजात';

  @override
  String get firstName => 'पहिलो नाम';

  @override
  String get middleNameOptional => 'बीचको नाम (ऐच्छिक)';

  @override
  String get lastName => 'थर';

  @override
  String get gender => 'लिङ्ग';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get otherGender => 'अन्य';

  @override
  String get maritalStatus => 'वैवाहिक स्थिति';

  @override
  String get single => 'अविवाहित';

  @override
  String get married => 'विवाहित';

  @override
  String get widowed => 'विधवा/विधुर';

  @override
  String get divorced => 'सम्बन्धविच्छेद';

  @override
  String get dobBs => 'जन्म मिति, वि.सं.';

  @override
  String get dobAd => 'जन्म मिति, ई.सं.';

  @override
  String ageYears(int age) {
    return 'उमेर $age';
  }

  @override
  String get occupation => 'पेशा';

  @override
  String get occupationHint => 'जस्तै कृषि';

  @override
  String get mobileNumber => 'मोबाइल नम्बर';

  @override
  String get mobileError => '९७ वा ९८ बाट सुरु हुने १० अङ्क';

  @override
  String get citizenshipNo => 'नागरिकता नं.';

  @override
  String get citizenshipFormatError => 'प्रमाणपत्रमा छापिएअनुसार लेख्नुहोस्';

  @override
  String get issueDateBs => 'जारी मिति, वि.सं.';

  @override
  String get issueDistrict => 'जारी जिल्ला';

  @override
  String get panOptional => 'स्थायी लेखा नं. (ऐच्छिक)';

  @override
  String get panError => 'स्थायी लेखा नं. ९ अङ्कको हुन्छ';

  @override
  String get fatherName => 'बुबाको नाम';

  @override
  String get motherName => 'आमाको नाम';

  @override
  String get grandfatherName => 'हजुरबुबाको नाम';

  @override
  String get spouseName => 'पति/पत्नीको नाम';

  @override
  String get province => 'प्रदेश';

  @override
  String get district => 'जिल्ला';

  @override
  String get municipality => 'नगरपालिका / गाउँपालिका';

  @override
  String get wardNo => 'वडा नं.';

  @override
  String get wardError => 'वडा १ देखि ३५ सम्म';

  @override
  String get toleOptional => 'टोल (ऐच्छिक)';

  @override
  String get typeToSearch => 'खोज्न लेख्नुहोस्';

  @override
  String get chooseDistrictFirst => 'पहिले जिल्ला छान्नुहोस्';

  @override
  String inThisDistrict(int count) {
    return 'यो जिल्लामा $count — खोज्न लेख्नुहोस्';
  }

  @override
  String get tickDocuments =>
      'सक्कल हेरेपछि प्रत्येक कागजातमा चिन्ह लगाउनुहोस्।';

  @override
  String get citizenshipFront => 'नागरिकता – अगाडि';

  @override
  String get citizenshipBack => 'नागरिकता – पछाडि';

  @override
  String get customerPhoto => 'ग्राहकको फोटो';

  @override
  String get consentTerms => 'ग्राहक खाताका सर्तहरूमा सहमत हुनुहुन्छ।';

  @override
  String get chooseOccupation => 'पेशा छान्नुहोस्';

  @override
  String get chooseIssueDistrict => 'जारी जिल्ला छान्नुहोस्';

  @override
  String get chooseDistrict => 'जिल्ला छान्नुहोस्';

  @override
  String get chooseMunicipality => 'नगरपालिका छान्नुहोस्';

  @override
  String get chooseDob => 'जन्म मिति छान्नुहोस्';

  @override
  String get minAge16 => 'ग्राहक कम्तीमा १६ वर्षको हुनुपर्छ';

  @override
  String get chooseIssueDate => 'जारी मिति छान्नुहोस्';

  @override
  String get notBeforeDob => 'जन्म मितिभन्दा अघि हुन सक्दैन';

  @override
  String get notInFuture => 'भविष्यको मिति हुन सक्दैन';

  @override
  String get tapToChoose => 'छान्न थिच्नुहोस्';

  @override
  String get chooseDate => 'मिति छान्नुहोस्';

  @override
  String get lettersOnly => 'अक्षर मात्र प्रयोग गर्नुहोस्';

  @override
  String get documentsMissing => 'नागरिकताका दुवै भाग र ग्राहकको फोटो लिनुहोस्';

  @override
  String get mustAgree => 'ग्राहक सर्तहरूमा सहमत हुनुपर्छ';

  @override
  String get applicationSubmitted => 'आवेदन पठाइयो';

  @override
  String applicationSubmittedBody(String id, String account) {
    return 'ग्राहक आईडी: $id\nखाता: $account\n\nबैंकले विवरण जाँच गर्नेछ। स्वीकृतिपछि नगद कारोबार गर्न मिल्छ।';
  }

  @override
  String get dobBsPickerTitle => 'जन्म मिति (वि.सं.)';

  @override
  String get dobAdPickerTitle => 'जन्म मिति (ई.सं.)';

  @override
  String get issueDatePickerTitle => 'नागरिकता जारी मिति (वि.सं.)';

  @override
  String get bsYear => 'साल';

  @override
  String get bsMonth => 'महिना';

  @override
  String get bsDay => 'गते';

  @override
  String bsEqualsAd(String bs, String ad) {
    return 'वि.सं. $bs  =  ई.सं. $ad';
  }

  @override
  String get chooseDateBs => 'मिति छान्नुहोस् (वि.सं.)';

  @override
  String get monthBaisakh => 'बैशाख';

  @override
  String get monthJestha => 'जेठ';

  @override
  String get monthAsar => 'असार';

  @override
  String get monthShrawan => 'साउन';

  @override
  String get monthBhadra => 'भदौ';

  @override
  String get monthAsoj => 'असोज';

  @override
  String get monthKartik => 'कार्तिक';

  @override
  String get monthMangsir => 'मंसिर';

  @override
  String get monthPoush => 'पुस';

  @override
  String get monthMagh => 'माघ';

  @override
  String get monthFalgun => 'फागुन';

  @override
  String get monthChaitra => 'चैत';

  @override
  String get errInvalidCredentials => 'एजेन्ट आईडी वा पिन मिलेन';

  @override
  String get errAccountLocked =>
      'यो एजेन्ट खाता लक भएको छ। अनलक गर्न सुपरभाइजरलाई भन्नुहोस्।';

  @override
  String get errAccountInactive => 'यो खाता सक्रिय छैन।';

  @override
  String get errTooManyAttempts =>
      'धेरै पटक गलत पिन। केही मिनेटपछि प्रयास गर्नुहोस्।';

  @override
  String get errNetwork => 'इन्टरनेट जडान छैन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get errTimeout =>
      'जवाफ आएन। फेरि प्रयास गर्नुअघि कारोबार सूची हेर्नुहोस्।';

  @override
  String get errForbidden => 'तपाईंलाई यो गर्ने अनुमति छैन।';

  @override
  String get errConflict => 'केही गडबड भयो। फेरि प्रयास गर्नुहोस्।';

  @override
  String get errGeneric => 'केही गडबड भयो। फेरि प्रयास गर्नुहोस्।';

  @override
  String get errCustomerNotFound => 'ग्राहक भेटिएन';

  @override
  String get errAccountNotFound => 'यो खाता छानिएको ग्राहकको होइन';

  @override
  String get errAccountPending => 'यो खाता बैंकको स्वीकृति कुर्दै छ';

  @override
  String errAmountRange(String min, String max) {
    return 'रकम $min देखि $max सम्म हुनुपर्छ';
  }

  @override
  String get errInsufficientBalance =>
      'यो रकम र शुल्कका लागि ग्राहकको मौज्दात पुग्दैन';

  @override
  String get errInsufficientFloat => 'यो झिकाइका लागि हातमा पर्याप्त नगद छैन';

  @override
  String get errFloatLimit =>
      'यो जम्मापछि नगद सीमाभन्दा बढी हुन्छ। पहिले सन्तुलन गर्नुहोस्।';

  @override
  String get errWrongOtp => 'OTP मिलेन';

  @override
  String get errOtpExpired => 'OTP को समय सकियो। झिकाइ फेरि सुरु गर्नुहोस्।';

  @override
  String get errOtpAttempts => '३ पटक गलत OTP। झिकाइ रद्द भयो।';

  @override
  String get errNotAwaitingOtp => 'यो झिकाइ अब OTP कुर्दै छैन';

  @override
  String get errResendTooSoon => 'OTP फेरि पठाउन केही पर्खनुहोस्';

  @override
  String get errResendLimit =>
      'OTP फेरि पठाउने सीमा सकियो। नयाँ झिकाइ सुरु गर्नुहोस्।';

  @override
  String get errCannotCancel => 'OTP कुर्दै गरेको झिकाइ मात्र रद्द गर्न मिल्छ';

  @override
  String get errTransactionNotFound => 'कारोबार भेटिएन';

  @override
  String get errDuplicateCitizenship =>
      'यो नागरिकता नं. भएका ग्राहक पहिल्यै छन्';

  @override
  String get errDuplicateMobile => 'यो मोबाइल नम्बर पहिल्यै दर्ता छ';

  @override
  String get errEodAlreadySubmitted =>
      'आजको दिनको अन्त्यको रिपोर्ट पहिल्यै पठाइसकियो';

  @override
  String get errInvalidPin => 'हालको पिन मिलेन';

  @override
  String get errSamePin => 'नयाँ पिन फरक हुनुपर्छ';

  @override
  String get errNotPending => 'यो आवेदन पहिल्यै जाँच भइसक्यो';

  @override
  String get notificationsTitle => 'सूचनाहरू';

  @override
  String get allCaughtUp => 'सबै हेरिसकियो।';

  @override
  String get sendGetCash => 'नगद पठाउनुहोस् / लिनुहोस्';

  @override
  String get cashInHandLabel => 'हातमा नगद';

  @override
  String limitUsedOf(String percent, String limit) {
    return '$limit सीमाको $percent%';
  }
}
