import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/age.dart';
import '../utils/picked_doc.dart';
import 'money.dart';

/// Largest KYC image accepted. A Firestore document is limited to 1 MiB, so keep well under it
/// (matches firestore.rules).
const _maxDocBytes = 600 * 1024;

/// An error from a FinBridge request: a broken business rule, a refused permission, or a
/// network problem. [code] matches the codes the old Node API used, so screens are unchanged.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status, this.details});

  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic>? details;

  /// True when the request may or may not have reached the server.
  bool get isNetwork => code == 'NETWORK' || code == 'TIMEOUT';

  @override
  String toString() => message;
}

/// Business rules, in paisa. Firestore security rules (backend/firestore.rules) enforce the
/// money ones again on the server, so a modified app cannot get round them.
class _Rules {
  static const minTransaction = 100 * 100;
  static const maxTransaction = 25000 * 100;
  static const withdrawalFee = 10 * 100;
  static const depositFee = 0;
  static const otpLength = 6;
  static const otpTtl = Duration(minutes: 5);
  static const otpMaxAttempts = 3;
  static const otpResendAfter = Duration(seconds: 60);
  static const otpMaxResends = 3;
  // There is no SMS gateway in this prototype, so the OTP is shown on the agent's screen.
  static const exposeDevOtp = true;
}

/// FinBridge "API" running inside the app, straight on Firebase.
///
/// Screens call `get('/path')` and `post('/path', body)` exactly as they did with the old Node
/// server, and get the same JSON-shaped maps back. Each request is carried out here with
/// Firebase Authentication and Cloud Firestore (transactions where money moves).
class ApiClient {
  ApiClient({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _auth.authStateChanges().listen((user) {
      if (user == null && token != null) onUnauthorised?.call();
    });
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// The signed-in agent ID while a session is open (kept for the Session class).
  String? token;

  /// Called when Firebase says the session is no longer valid.
  void Function()? onUnauthorised;

  Map<String, dynamic>? _me; // the signed-in agent's document
  static Map<String, dynamic>? _locationsCache;
  static List<Map<String, dynamic>>? _occupationsCache;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _run(() => _get(_segments(path), query ?? const {}));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _run(() => _post(_segments(path), body ?? const {}));

  Future<void> signOut() async {
    token = null;
    _me = null;
    await _auth.signOut();
  }

  // ------------------------------------------------------------------ plumbing

  List<String> _segments(String path) => path.split('/').where((s) => s.isNotEmpty).toList();

  Future<dynamic> _run(Future<dynamic> Function() fn) async {
    try {
      return await fn().timeout(const Duration(seconds: 25));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'No response. Check the journal before trying again.');
    } on FirebaseException catch (e) {
      throw _fromFirebase(e);
    }
  }

  ApiException _fromFirebase(FirebaseException e) => switch (e.code) {
        'permission-denied' =>
          ApiException('FORBIDDEN', 'You don’t have permission to do this.', status: 403),
        'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
          ApiException('NETWORK', 'No internet connection. Please try again.'),
        'unauthenticated' => () {
            onUnauthorised?.call();
            return ApiException('SESSION_EXPIRED', 'Your session has expired. Please log in again.', status: 401);
          }(),
        'aborted' => ApiException('CONFLICT', 'Someone else changed this record at the same time. Please try again.'),
        _ => ApiException('ERROR', 'Something went wrong (${e.code}). Please try again.'),
      };

  Future<dynamic> _get(List<String> s, Map<String, String> q) async {
    switch (s) {
      case ['auth', 'me']:
        return {'user': _publicAgent(_uid, await _agentDoc())};
      case ['occupations']:
        return {'results': await _occupations()};
      case ['locations']:
        return _locations();
      case ['dashboard']:
        _requireRole('agent');
        return _dashboard();
      case ['customers']:
        _requireRole('agent');
        final term = (q['q'] ?? '').trim();
        if (term.isEmpty) return {'results': await _myCustomers()};
        return {'results': term.length < 2 ? [] : await _searchCustomers(term)};
      case ['customers', final id]:
        return _customer(id);
      case ['supervisor', 'customers', final id]:
        _requireRole('supervisor');
        return _openForReview(id);
      case ['transactions']:
        _requireRole('agent');
        return {'results': await _listTransactions(q)};
      case ['transactions', final id]:
        return _receipt(await _ownTxn(id, allowSupervisor: true));
      case ['eod', 'preview']:
        _requireRole('agent');
        return _eodPreview();
      case ['supervisor', 'overview']:
        _requireRole('supervisor');
        return _supervisorOverview();
    }
    throw ApiException('NOT_FOUND', 'Unknown request: /${s.join('/')}');
  }

  Future<dynamic> _post(List<String> s, Map<String, dynamic> b) async {
    switch (s) {
      case ['auth', 'login']:
        return _login(b);
      case ['auth', 'logout']:
        await _audit('LOGOUT');
        await signOut();
        return null;
      case ['auth', 'change-pin']:
        await _changePin(b);
        return {'message': 'PIN changed'};
      case ['customers']:
        _requireRole('agent');
        return _onboard(b);
      case ['transactions', 'deposits']:
        _requireRole('agent');
        return _deposit(b);
      case ['transactions', 'withdrawals']:
        _requireRole('agent');
        return _startWithdrawal(b);
      case ['transactions', final id, 'confirm-otp']:
        _requireRole('agent');
        return _confirmWithdrawal(id, '${b['otp'] ?? ''}');
      case ['transactions', final id, 'resend-otp']:
        _requireRole('agent');
        return _resendOtp(id);
      case ['transactions', final id, 'cancel']:
        _requireRole('agent');
        await _cancel(id);
        return {'message': 'Withdrawal cancelled'};
      case ['transactions', final id, 'receipt', 'sms']:
        _requireRole('agent');
        await _resendReceipt(id);
        return {'message': 'Receipt sent by SMS'};
      case ['transactions', final id, 'disputes']:
        _requireRole('agent');
        return _reportDispute(id, '${b['reason'] ?? ''}'.trim());
      case ['eod']:
        _requireRole('agent');
        return _submitEod(b);
      case ['float', 'rebalance']:
        _requireRole('agent');
        return _requestRebalance(b);
      case ['supervisor', 'customers', final id, 'kyc']:
        _requireRole('supervisor');
        await _reviewKyc(id, b);
        return {'message': 'Decision saved'};
      case ['supervisor', 'agents', final id, 'unlock']:
        _requireRole('supervisor');
        await _unlockAgent(id);
        return {'message': 'Agent unlocked'};
      case ['supervisor', 'float-requests', final id]:
        _requireRole('supervisor');
        return _decideRebalance(id, b['approve'] == true);
    }
    throw ApiException('NOT_FOUND', 'Unknown request: /${s.join('/')}');
  }

  // ------------------------------------------------------------------ helpers

  String get _uid {
    final u = _auth.currentUser;
    if (u == null || token == null) throw ApiException('UNAUTHENTICATED', 'Please log in', status: 401);
    return u.uid;
  }

  void _requireRole(String role) {
    _uid;
    if (_me?['role'] != role) {
      throw ApiException('FORBIDDEN', 'You do not have permission for this action', status: 403);
    }
  }

  DocumentReference<Map<String, dynamic>> _doc(String collection, String id) => _db.collection(collection).doc(id);

  Future<Map<String, dynamic>> _agentDoc([String? id]) async {
    final snap = await _doc('agents', id ?? _uid).get();
    final d = snap.data();
    if (d == null) throw ApiException('AGENT_NOT_FOUND', 'Agent not found', status: 404);
    return d;
  }

  static final _random = Random.secure();
  static String _digits(int n) => List.generate(n, (_) => _random.nextInt(10)).join();
  static String _hex(int bytes) =>
      List.generate(bytes, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join().toUpperCase();

  /// ISO-8601 UTC with milliseconds, the same format the Node API stored.
  static String _iso([DateTime? d]) =>
      DateTime.fromMillisecondsSinceEpoch((d ?? DateTime.now()).millisecondsSinceEpoch, isUtc: true)
          .toIso8601String();

  /// Start of the current day in Nepal Time (UTC+05:45).
  static String _startOfNepalDay() {
    const offset = Duration(hours: 5, minutes: 45);
    final local = DateTime.now().toUtc().add(offset);
    return _iso(DateTime.utc(local.year, local.month, local.day).subtract(offset));
  }

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
  static String _maskAccount(String? a) => a == null ? '' : '••••${a.substring(max(0, a.length - 4))}';
  static String? _maskMobile(String? m) => m == null ? null : '${m.substring(0, min(5, m.length))}****${m.substring(m.length - 1)}';
  static String? _maskCitizenship(String? c) =>
      c == null ? null : '${'*' * max(0, c.length - 4)}${c.substring(max(0, c.length - 4))}';
  static String _fullName(Map<String, dynamic> c) =>
      [c['firstName'], c['middleName'], c['lastName']].where((p) => p != null && '$p'.isNotEmpty).join(' ');
  static String _otpHash(String txnId, String code) => sha256.convert(utf8.encode('$txnId:$code')).toString();

  static ApiException _invalid(String field, String message) => ApiException(
        'VALIDATION_ERROR',
        '$field: $message',
        status: 400,
        details: {
          'fields': [
            {'field': field, 'message': message},
          ],
        },
      );

  Map<String, dynamic> _auditEntry(String action, [Map<String, dynamic> details = const {}]) =>
      {'actorId': _auth.currentUser?.uid ?? 'anonymous', 'action': action, 'details': details, 'at': _iso()};

  Future<void> _audit(String action, [Map<String, dynamic> details = const {}]) async {
    if (_auth.currentUser == null) return;
    await _db.collection('auditLogs').add(_auditEntry(action, details));
  }

  /// No SMS gateway: messages go to the smsOutbox collection for the demo.
  Future<void> _sms(String? to, String message, Map<String, dynamic> meta) =>
      _db.collection('smsOutbox').add({'to': to, 'message': message, ...meta, 'status': 'simulated', 'at': _iso()});

  static Map<String, dynamic> _publicAgent(String id, Map<String, dynamic> a) => {
        'agentId': id,
        'name': a['name'],
        'role': a['role'],
        'location': a['location'],
        'terminalId': a['terminalId'],
        'partnerBank': a['partnerBank'],
        'status': a['status'],
      };

  /// The agent's float, with the opening float reset at the start of each Nepal day.
  static ({Map<String, dynamic> float, String floatDate}) _currentFloat(Map<String, dynamic> agent) {
    final today = _startOfNepalDay();
    final f = Map<String, dynamic>.from(agent['float'] as Map? ?? {});
    final date = agent['floatDate'] as String?;
    if (date == null || date.compareTo(today) < 0) return (float: {...f, 'opening': f['cash']}, floatDate: today);
    return (float: f, floatDate: date);
  }

  static Map<String, dynamic> _rupeesFloat(Map<String, dynamic> f) {
    final cash = _int(f['cash']), limit = _int(f['limit']);
    return {
      'cash': paisaToRupees(cash),
      'opening': paisaToRupees(_int(f['opening'])),
      'limit': paisaToRupees(limit),
      'minReserve': paisaToRupees(_int(f['minReserve'])),
      'utilisation': limit == 0 ? 0 : (cash / limit * 1000).round() / 10,
    };
  }

  // ------------------------------------------------------------------ auth

  static String _email(String agentId) => '${agentId.toLowerCase()}@finbridge.test';

  Future<Map<String, dynamic>> _login(Map<String, dynamic> b) async {
    final id = '${b['agentId'] ?? ''}'.trim().toUpperCase();
    final pin = '${b['pin'] ?? ''}';
    if (id.length < 3) throw _invalid('agentId', 'Enter your agent ID');
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) throw _invalid('pin', 'PIN must be 6 digits');
    try {
      await _auth.signInWithEmailAndPassword(email: _email(id), password: pin);
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'too-many-requests' => ApiException(
            'TOO_MANY_ATTEMPTS', 'Too many wrong PINs. Try again in a few minutes.',
            status: 429),
        'user-disabled' => ApiException('ACCOUNT_INACTIVE', 'This agent account is not active.', status: 403),
        'network-request-failed' => ApiException('NETWORK', 'No internet connection. Please try again.'),
        'operation-not-allowed' || 'configuration-not-found' => ApiException('AUTH_NOT_ENABLED',
            'Email/Password sign-in is not enabled in Firebase Authentication for this project.'),
        _ => ApiException('INVALID_CREDENTIALS', 'Agent ID or PIN is incorrect', status: 401),
      };
    }
    token = id;
    final Map<String, dynamic> agent;
    try {
      agent = await _agentDoc(id);
    } catch (_) {
      await signOut();
      throw ApiException('INVALID_CREDENTIALS', 'Agent ID or PIN is incorrect', status: 401);
    }
    if (agent['status'] == 'locked') {
      await signOut();
      throw ApiException('ACCOUNT_LOCKED', 'This agent account is locked. Ask your bank supervisor to unlock it.', status: 423);
    }
    if (agent['status'] != 'active') {
      await signOut();
      throw ApiException('ACCOUNT_INACTIVE', 'This agent account is not active.', status: 403);
    }
    _me = agent;
    // The terminal is part of the agent's profile; its name comes from the `terminals` collection.
    final terminalId = agent['terminalId'] as String?;
    final terminalName = await _terminalName(terminalId);
    await _doc('agents', id).update({'lastLoginAt': _iso(), 'lastTerminalId': terminalId});
    await _audit('LOGIN_SUCCESS', {'terminalId': terminalId});
    return {
      'token': id,
      'agent': {..._publicAgent(id, agent), 'terminalName': terminalName},
    };
  }

  /// Name of a terminal, e.g. "Koteshwor Point, Ward 32"; null if it isn't in Firebase.
  Future<String?> _terminalName(String? terminalId) async {
    if (terminalId == null || terminalId.isEmpty) return null;
    try {
      return (await _doc('terminals', terminalId).get()).data()?['name'] as String?;
    } on FirebaseException {
      return null; // the terminal row is informational; never block a login on it
    }
  }

  Future<void> _changePin(Map<String, dynamic> b) async {
    final current = '${b['currentPin'] ?? ''}', next = '${b['newPin'] ?? ''}';
    if (!RegExp(r'^\d{6}$').hasMatch(current)) throw _invalid('currentPin', 'PIN must be 6 digits');
    if (!RegExp(r'^\d{6}$').hasMatch(next)) throw _invalid('newPin', 'PIN must be 6 digits');
    if (current == next) throw ApiException('SAME_PIN', 'New PIN must be different', status: 400);
    final user = _auth.currentUser!;
    try {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: current));
    } on FirebaseAuthException {
      await _audit('PIN_CHANGE_FAILED');
      throw ApiException('INVALID_PIN', 'Current PIN is incorrect', status: 400);
    }
    await user.updatePassword(next);
    await _audit('PIN_CHANGED');
  }

  // ------------------------------------------------------------------ locations

  Future<Map<String, dynamic>> _locations() async {
    if (_locationsCache != null) return _locationsCache!;
    final results = await Future.wait(['provinces', 'districts', 'localBodies'].map((c) => _db.collection(c).get()));
    List<Map<String, dynamic>> rows(int i) => results[i].docs.map((d) => {'id': d.id, ...d.data()}).toList();
    int byName(Map a, Map b) => '${a['name']}'.compareTo('${b['name']}');
    final data = {
      'provinces': rows(0)..sort((a, b) => int.parse('${a['id']}').compareTo(int.parse('${b['id']}'))),
      'districts': rows(1)..sort(byName),
      'localBodies': [
        for (final l in rows(2)..sort(byName))
          {'id': l['id'], 'name': l['name'], 'nameNe': l['nameNe'], 'districtId': l['districtId'], 'type': l['type']},
      ],
    };
    if ((data['localBodies'] as List).isNotEmpty) _locationsCache = data;
    return data;
  }

  // ------------------------------------------------------------------ occupations

  /// Occupation master data: [{code, name}] in the order of backend/reference-data/occupations.csv.
  Future<List<Map<String, dynamic>>> _occupations() async {
    if (_occupationsCache != null) return _occupationsCache!;
    final snap = await _db.collection('occupations').get();
    final rows = [
      for (final d in snap.docs)
        if (d.data()['active'] != false) {'code': d.id, 'name': d.data()['name'], 'order': _int(d.data()['order'])},
    ]..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    final list = [for (final r in rows) {'code': r['code'], 'name': r['name']}];
    if (list.isNotEmpty) _occupationsCache = list;
    return list;
  }

  /// The official code and name for the chosen occupation (by code, or by exact name).
  Future<({String? code, String name})> _resolveOccupation(String? code, String name) async {
    final list = await _occupations();
    if (list.isEmpty) return (code: code, name: name);
    final wanted = code?.trim().toUpperCase();
    final found = list.where((o) => wanted != null && wanted.isNotEmpty && o['code'] == wanted).firstOrNull ??
        list.where((o) => (wanted == null || wanted.isEmpty) && '${o['name']}'.toLowerCase() == name.toLowerCase()).firstOrNull;
    if (found == null) {
      throw _invalid(wanted == null || wanted.isEmpty ? 'occupation' : 'occupationCode', 'Choose an occupation from the list');
    }
    return (code: found['code'] as String, name: found['name'] as String);
  }

  /// Checks the address against the location lists and returns the official names and IDs.
  Future<({Map<String, dynamic> address, String issueDistrict})> _resolveAddress(
      Map<String, dynamic> address, String issueDistrict) async {
    final l = await _locations();
    final provinces = (l['provinces'] as List).cast<Map<String, dynamic>>();
    final districts = (l['districts'] as List).cast<Map<String, dynamic>>();
    final bodies = (l['localBodies'] as List).cast<Map<String, dynamic>>();
    if (bodies.isEmpty) return (address: address, issueDistrict: issueDistrict);
    String norm(dynamic s) => '${s ?? ''}'.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    final p = provinces.where((x) => norm(x['name']) == norm(address['province'])).firstOrNull;
    if (p == null) throw _invalid('address.province', 'Choose a province from the list');
    final d = districts
        .where((x) => x['provinceId'] == p['id'] && norm(x['name']) == norm(address['district']))
        .firstOrNull;
    if (d == null) throw _invalid('address.district', 'Choose a district in ${p['name']} Province');
    final body = bodies
        .where((x) => x['districtId'] == d['id'] && norm(x['name']) == norm(address['municipality']))
        .firstOrNull;
    if (body == null) throw _invalid('address.municipality', 'Choose a municipality in ${d['name']} district');
    final issue = districts.where((x) => norm(x['name']) == norm(issueDistrict)).firstOrNull;
    if (issue == null) throw _invalid('citizenshipIssueDistrict', 'Choose the issue district from the list');
    return (
      address: {
        ...address,
        'province': p['name'],
        'district': d['name'],
        'municipality': body['name'],
        'districtId': d['id'],
        'localBodyId': body['id'],
      },
      issueDistrict: issue['name'] as String,
    );
  }

  // ------------------------------------------------------------------ customers

  Future<List<Map<String, dynamic>>> _accountsFor(String customerId) async {
    final q = await _db.collection('accounts').where('customerId', isEqualTo: customerId).get();
    return q.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Map<String, dynamic> _summary(String id, Map<String, dynamic> c, List<Map<String, dynamic>> accounts) => {
        'customerId': id,
        'name': _fullName(c),
        'mobileMasked': _maskMobile(c['mobile'] as String?),
        'citizenshipMasked': _maskCitizenship(c['citizenshipNo'] as String?),
        'kycStatus': c['kycStatus'],
        'photoUrl': c['photoUrl'],
        'accounts': [
          for (final a in accounts)
            {
              'accountNo': a['id'],
              'accountMasked': _maskAccount(a['id'] as String?),
              'productName': a['productName'],
              'status': a['status'],
            },
        ],
      };

  static final _nameTermRe = RegExp(r"^[\p{L} .'-]{2,}$", unicode: true);

  /// The customers this agent onboarded (newest first), shown when the search box is empty.
  Future<List<Map<String, dynamic>>> _myCustomers() async {
    // No orderBy in the query: that would need a composite index. Up to 50 rows are sorted here.
    final docs = (await _db.collection('customers').where('createdByAgent', isEqualTo: _uid).limit(50).get()).docs
      ..sort((x, y) => '${y.data()['createdAt'] ?? ''}'.compareTo('${x.data()['createdAt'] ?? ''}'));
    return [for (final d in docs) _summary(d.id, d.data(), await _accountsFor(d.id))];
  }

  /// One search box for everything; the kind of text decides what is looked up, so the agent
  /// never types a label, and part of a value is enough:
  ///  - letters       -> any part of the name ("hari", "thap", "bahadur t")
  ///  - CUST-123456   -> customer ID
  ///  - digits        -> any part of a mobile number (also +977 98..., 98 4123, 98-4123), of a
  ///                     citizenship number (27-01 or 0491) or of the customer ID; a whole
  ///                     account number finds that account's customer
  Future<List<Map<String, dynamic>>> _searchCustomers(String term) async {
    final found = <String, Map<String, dynamic>>{};
    void add(QuerySnapshot<Map<String, dynamic>> q) {
      for (final d in q.docs) {
        found[d.id] = d.data();
      }
    }

    final customers = _db.collection('customers');
    term = term.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Customer ID, e.g. CUST-123456 (the dash and the case are optional).
    final idMatch = RegExp(r'^cust-?(\d{3,})$', caseSensitive: false).firstMatch(term);
    if (idMatch != null) {
      final c = await _doc('customers', 'CUST-${idMatch.group(1)}').get();
      if (c.exists) found[c.id] = c.data()!;
    }

    // Numbers: ignore spaces, brackets and a leading +; a typed +977 country code is dropped.
    var digits = term.replaceAll(RegExp(r'[\s+()]'), '');
    final isNumeric = RegExp(r'^\d[\d-]*$').hasMatch(digits);
    if (isNumeric) {
      if (term.startsWith('+') && RegExp(r'^977\d{7,}$').hasMatch(digits)) digits = digits.substring(3);
      final plain = digits.replaceAll('-', '');
      // Exact matches first (indexed, so found however many customers there are).
      if (RegExp(r'^\d{10}$').hasMatch(plain)) add(await customers.where('mobile', isEqualTo: plain).get());
      if (plain.length >= 6) add(await customers.where('citizenshipNo', isEqualTo: digits).get());
      if (RegExp(r'^\d{8,}$').hasMatch(plain)) {
        final acc = (await _doc('accounts', plain).get()).data();
        if (acc != null) {
          final c = await _doc('customers', acc['customerId'] as String).get();
          if (c.exists) found[c.id] = c.data()!;
        }
      }
      // Part of a number: at least 3 digits, matched anywhere in the value.
      if (plain.length >= 3) {
        for (final d in (await customers.limit(500).get()).docs) {
          final c = d.data();
          final mobile = '${c['mobile'] ?? ''}';
          final cit = '${c['citizenshipNo'] ?? ''}';
          if (mobile.contains(plain) ||
              cit.contains(digits) ||
              cit.replaceAll('-', '').contains(plain) ||
              d.id.replaceAll(RegExp(r'\D'), '').contains(plain)) {
            found.putIfAbsent(d.id, () => c);
          }
        }
      }
    }

    // Names: every word typed must appear in the name, so "har", "thapa" and "hari thapa" all
    // find Hari Bahadur Thapa.
    if (!isNumeric && _nameTermRe.hasMatch(term)) {
      final lower = term.toLowerCase();
      // Start of the full name, using the index (finds customers beyond the first 500).
      add(await customers
          .where('nameLower', isGreaterThanOrEqualTo: lower)
          .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(20)
          .get());
      // Any part of the name. Firestore cannot search inside text, so look through the
      // customers here; fine for a branch-sized list, capped at 500.
      final words = lower.split(RegExp(r'[\s.]+')).where((w) => w.isNotEmpty).toList();
      if (words.isNotEmpty) {
        for (final d in (await customers.limit(500).get()).docs) {
          final name = '${d.data()['nameLower'] ?? ''}';
          if (words.every(name.contains)) found.putIfAbsent(d.id, () => d.data());
        }
      }
    }
    return [for (final e in found.entries.take(30)) _summary(e.key, e.value, await _accountsFor(e.key))];
  }

  Future<Map<String, dynamic>> _customer(String id) async {
    final c = (await _doc('customers', id).get()).data();
    if (c == null) throw ApiException('CUSTOMER_NOT_FOUND', 'Customer not found', status: 404);
    return {
      ..._summary(id, c, await _accountsFor(id)),
      'firstName': c['firstName'],
      'middleName': c['middleName'] ?? '',
      'lastName': c['lastName'],
      'gender': c['gender'],
      'maritalStatus': c['maritalStatus'],
      'dobBs': c['dobBs'],
      'dobAd': c['dobAd'],
      'occupation': c['occupation'],
      'occupationCode': c['occupationCode'],
      'citizenshipIssueDateBs': c['citizenshipIssueDateBs'],
      'citizenshipIssueDistrict': c['citizenshipIssueDistrict'],
      'pan': c['pan'],
      'family': c['family'] ?? {},
      'address': c['address'],
      'documents': {for (final k in documentKinds) k: _documentRecord((c['documents'] as Map?)?[k])},
      'createdByAgent': c['createdByAgent'],
      'createdAt': c['createdAt']?.toString(),
      'kycViewedBy': List<String>.from(c['kycViewedBy'] as List? ?? const []),
      'kycRejectReason': c['kycRejectReason'],
    };
  }

  /// The documents collected at onboarding, as keys of the customer's `documents` map.
  static const documentKinds = ['citizenshipFront', 'citizenshipBack', 'photo'];

  /// One document as stored on the customer:
  /// `{captured, storagePath, url, contentType, uploadedAt}`.
  /// `captured` is the agent's confirmation that the original was checked. The file fields
  /// stay null until the scan or photo is uploaded (Firebase Storage path and download URL).
  /// Older customers stored a plain `true`; that reads as captured with no file.
  static Map<String, dynamic> _documentRecord(dynamic v) {
    String? text(dynamic x) => x is String && x.trim().isNotEmpty ? x.trim() : null;
    final m = v is Map ? v : const {};
    final url = text(m['url']), storagePath = text(m['storagePath']), ref = text(m['ref']);
    return {
      'captured': v == true || m['captured'] == true || url != null || storagePath != null || ref != null,
      // `ref` points at the image stored in the customerDocuments collection (see documentBytes).
      'ref': ref,
      'size': m['size'] is num ? (m['size'] as num).toInt() : null,
      'storagePath': storagePath,
      'url': url,
      'contentType': text(m['contentType']),
      'uploadedAt': text(m['uploadedAt']),
    };
  }

  /// A supervisor opens an application to review it. Opening it is recorded on the customer
  /// (`kycViewedBy`), and approve or reject is refused, here and in firestore.rules, until the
  /// deciding supervisor has opened it.
  Future<Map<String, dynamic>> _openForReview(String customerId) async {
    final c = (await _doc('customers', customerId).get()).data();
    if (c == null) throw ApiException('CUSTOMER_NOT_FOUND', 'Customer not found', status: 404);
    final viewers = List<String>.from(c['kycViewedBy'] as List? ?? const []);
    if (c['kycStatus'] == 'pending_review' && !viewers.contains(_uid)) {
      final batch = _db.batch()
        ..update(_doc('customers', customerId), {
          'kycViewedBy': FieldValue.arrayUnion([_uid]),
          'kycViewedAt': _iso(),
        })
        ..set(_db.collection('auditLogs').doc(), _auditEntry('KYC_OPENED', {'customerId': customerId}));
      await batch.commit();
    }
    return _customer(customerId);
  }

  static final _nameRe = RegExp(r"^[\p{L} .'-]+$", unicode: true);
  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Same checks the Node API made with zod (backend/src/schemas.js).
  Map<String, dynamic> _validateOnboarding(Map<String, dynamic> b) {
    String str(String key, Map<String, dynamic> m) => '${m[key] ?? ''}'.trim();
    String name(String field, Map<String, dynamic> m, String key) {
      final v = str(key, m);
      if (v.isEmpty) throw _invalid(field, 'Required');
      if (v.length > 50 || !_nameRe.hasMatch(v)) throw _invalid(field, 'Letters only');
      return v;
    }

    String? optional(String field, Map<String, dynamic> m, String key) {
      final v = str(key, m);
      if (v.isEmpty) return null;
      if (v.length > 50) throw _invalid(field, 'Too long');
      return v;
    }

    final family = Map<String, dynamic>.from(b['family'] as Map? ?? {});
    final address = Map<String, dynamic>.from(b['address'] as Map? ?? {});
    final documents = Map<String, dynamic>.from(b['documents'] as Map? ?? {});

    final gender = str('gender', b), marital = str('maritalStatus', b);
    if (!['male', 'female', 'other'].contains(gender)) throw _invalid('gender', 'Choose a gender');
    if (!['single', 'married', 'widowed', 'divorced'].contains(marital)) {
      throw _invalid('maritalStatus', 'Choose a marital status');
    }
    for (final k in ['dobBs', 'dobAd', 'citizenshipIssueDateBs']) {
      if (!_dateRe.hasMatch(str(k, b))) throw _invalid(k, 'Use YYYY-MM-DD');
    }
    final dob = DateTime.tryParse(str('dobAd', b));
    if (dob == null) throw _invalid('dobAd', 'Use YYYY-MM-DD');
    // Exact age by calendar date in Nepal; firestore.rules repeats this check.
    if (!oldEnoughToOnboard(dob)) {
      throw ApiException('UNDER_AGE', 'The customer must be at least $minCustomerAge years old',
          status: 400, details: {'field': 'dobAd'});
    }
    if (ageInYears(dob, nepalToday()) > 110) throw _invalid('dobAd', 'Check the date of birth');
    final occupation = str('occupation', b);
    if ('${b['occupationCode'] ?? ''}'.trim().isEmpty && (occupation.length < 2 || occupation.length > 60)) {
      throw _invalid('occupation', 'Choose an occupation');
    }
    final mobile = str('mobile', b);
    if (!RegExp(r'^9[78]\d{8}$').hasMatch(mobile)) {
      throw _invalid('mobile', 'Enter a 10-digit Nepali mobile number starting 97 or 98');
    }
    final citizenship = str('citizenshipNo', b);
    if (!RegExp(r'^\d{1,3}(-\d{1,6}){1,4}$').hasMatch(citizenship)) {
      throw _invalid('citizenshipNo', 'Use the format shown on the certificate, e.g. 27-01-78-04912');
    }
    final pan = str('pan', b);
    if (pan.isNotEmpty && !RegExp(r'^\d{9}$').hasMatch(pan)) throw _invalid('pan', 'PAN must be 9 digits');
    final ward = address['ward'];
    if (ward is! int || ward < 1 || ward > 35) throw _invalid('address.ward', 'Ward between 1 and 35');
    for (final (key, message) in [
      ('citizenshipFront', 'Add the front of the citizenship certificate'),
      ('citizenshipBack', 'Add the back of the citizenship certificate'),
      ('photo', 'Add the customer’s photo'),
    ]) {
      final f = documents[key];
      if (f is! PickedDoc) throw _invalid('documents.$key', message);
      if (f.bytes.isEmpty) throw _invalid('documents.$key', 'This file is empty');
      if (f.bytes.length > _maxDocBytes) {
        throw _invalid('documents.$key', 'This image is too large (over 600 KB). Retake it or choose a smaller file');
      }
    }
    if (b['consent'] != true) throw _invalid('consent', 'The customer must agree to the terms');

    final tole = str('tole', address);
    final data = <String, dynamic>{
      'firstName': name('firstName', b, 'firstName'),
      'middleName': optional('middleName', b, 'middleName'),
      'lastName': name('lastName', b, 'lastName'),
      'gender': gender,
      'maritalStatus': marital,
      'dobBs': str('dobBs', b),
      'dobAd': str('dobAd', b),
      'occupation': occupation,
      'mobile': mobile,
      'citizenshipNo': citizenship,
      'citizenshipIssueDateBs': str('citizenshipIssueDateBs', b),
      'citizenshipIssueDistrict': str('citizenshipIssueDistrict', b),
      'pan': pan.isEmpty ? null : pan,
      'family': {
        'fatherName': name('family.fatherName', family, 'fatherName'),
        'motherName': name('family.motherName', family, 'motherName'),
        'grandfatherName': name('family.grandfatherName', family, 'grandfatherName'),
        'spouseName': optional('family.spouseName', family, 'spouseName'),
      },
      'address': {
        'province': str('province', address),
        'district': str('district', address),
        'municipality': str('municipality', address),
        'ward': ward,
        if (tole.isNotEmpty) 'tole': tole,
      },
      // The picked files, replaced by records of the stored images (see _onboard).
      'documents': documents,
    };
    data.removeWhere((_, v) => v == null);
    (data['family'] as Map).removeWhere((_, v) => v == null);
    return data;
  }

  Future<Map<String, dynamic>> _onboard(Map<String, dynamic> b) async {
    final agentId = _uid;
    var input = _validateOnboarding(b);
    final job = await _resolveOccupation(b['occupationCode'] as String?, input['occupation'] as String);
    input = {...input, 'occupation': job.name, if (job.code != null) 'occupationCode': job.code};
    final customers = _db.collection('customers');
    if ((await customers.where('citizenshipNo', isEqualTo: input['citizenshipNo']).limit(1).get()).docs.isNotEmpty) {
      throw ApiException('DUPLICATE_CITIZENSHIP', 'A customer with this citizenship number already exists', status: 409);
    }
    if ((await customers.where('mobile', isEqualTo: input['mobile']).limit(1).get()).docs.isNotEmpty) {
      throw ApiException('DUPLICATE_MOBILE', 'This mobile number is already registered', status: 409);
    }
    final resolved = await _resolveAddress(
        Map<String, dynamic>.from(input['address'] as Map), input['citizenshipIssueDistrict'] as String);
    input = {...input, 'address': resolved.address, 'citizenshipIssueDistrict': resolved.issueDistrict};

    final customerId = 'CUST-${100000 + _random.nextInt(900000)}';
    final accountNo = '0102${10000000 + _random.nextInt(90000000)}';
    final now = _iso();

    // The three images are saved in the same transaction as the customer, in their own
    // collection (kept separate so customer lists stay small and only the agent and supervisors
    // can read the images). Either everything is saved or nothing is.
    final files = Map<String, PickedDoc>.from(input['documents'] as Map);
    final refs = <String, Map<String, dynamic>>{
      for (final e in files.entries)
        e.key: {
          'captured': true,
          'ref': 'customerDocuments/${customerId}_${e.key}',
          'contentType': e.value.contentType,
          'size': e.value.bytes.length,
          'uploadedAt': now,
        },
    };
    input = {...input, 'documents': refs};

    await _db.runTransaction((tx) async {
      // IDs are random; make sure neither is taken (the rules also refuse to overwrite).
      if ((await tx.get(_doc('customers', customerId))).exists || (await tx.get(_doc('accounts', accountNo))).exists) {
        throw ApiException('CONFLICT', 'Something went wrong. Please submit again.');
      }
      tx.set(_doc('customers', customerId), {
        ...input,
        'nameLower': _fullName(input).toLowerCase(),
        'kycStatus': 'pending_review',
        'createdByAgent': agentId,
        'createdAt': now,
      });
      for (final e in files.entries) {
        tx.set(_doc('customerDocuments', '${customerId}_${e.key}'), {
          'customerId': customerId,
          'agentId': agentId,
          'kind': e.key,
          'contentType': e.value.contentType,
          'size': e.value.bytes.length,
          'data': Blob(e.value.bytes),
          'createdAt': now,
        });
      }
      tx.set(_doc('accounts', accountNo), {
        'customerId': customerId,
        'productName': 'Bachat Khata (Savings)',
        'type': 'savings',
        'balance': 0,
        'status': 'pending',
        'openedAt': now,
      });
      tx.set(_db.collection('auditLogs').doc(),
          _auditEntry('CUSTOMER_ONBOARDED', {'customerId': customerId, 'accountNo': accountNo}));
    });
    return {
      'customerId': customerId,
      'accountNo': accountNo,
      'accountMasked': _maskAccount(accountNo),
      'kycStatus': 'pending_review',
    };
  }

  /// The stored bytes of a customer's KYC image (the agent who onboarded them, or a supervisor).
  Future<Uint8List?> documentBytes(String ref) async {
    try {
      final id = ref.split('/').last;
      final data = (await _doc('customerDocuments', id).get()).data()?['data'];
      return data is Blob ? data.bytes : null;
    } on FirebaseException {
      return null;
    }
  }

  Future<void> _reviewKyc(String customerId, Map<String, dynamic> b) async {
    final decision = b['decision'];
    final reason = '${b['reason'] ?? ''}'.trim();
    if (decision != 'approve' && decision != 'reject') throw _invalid('decision', 'Choose approve or reject');
    if (decision == 'reject' && reason.length < 5) throw _invalid('reason', 'Give a reason when rejecting');
    final c = (await _doc('customers', customerId).get()).data();
    if (c == null) throw ApiException('CUSTOMER_NOT_FOUND', 'Customer not found', status: 404);
    if (c['kycStatus'] != 'pending_review') {
      throw ApiException('NOT_PENDING', 'This application has already been reviewed', status: 409);
    }
    if (!List<String>.from(c['kycViewedBy'] as List? ?? const []).contains(_uid)) {
      throw ApiException('KYC_NOT_OPENED', 'Open the application and check the details and documents first',
          status: 409);
    }
    final accounts = await _accountsFor(customerId);
    final batch = _db.batch();
    batch.update(_doc('customers', customerId), {
      'kycStatus': decision == 'approve' ? 'verified' : 'rejected',
      'kycReviewedBy': _uid,
      'kycReviewedAt': _iso(),
      'kycRejectReason': decision == 'reject' ? reason : null,
    });
    if (decision == 'approve') {
      for (final a in accounts) {
        batch.update(_doc('accounts', a['id'] as String), {'status': 'active'});
      }
    }
    batch.set(_db.collection('auditLogs').doc(), _auditEntry(decision == 'approve' ? 'KYC_APPROVED' : 'KYC_REJECTED', {
      'customerId': customerId,
      if (reason.isNotEmpty) 'reason': reason,
    }));
    await batch.commit();
  }

  // ------------------------------------------------------------------ transactions

  Map<String, dynamic> _publicTxn(String id, Map<String, dynamic> t) {
    final otp = t['otp'] as Map?;
    final waiting = t['status'] == 'awaiting_otp';
    return {
      'id': id,
      'reference': t['reference'],
      'type': t['type'],
      'status': t['status'],
      'customerId': t['customerId'],
      'customerName': t['customerName'],
      'accountMasked': _maskAccount(t['accountNo'] as String?),
      'amount': paisaToRupees(_int(t['amount'])),
      'fee': paisaToRupees(_int(t['fee'])),
      'total': paisaToRupees(_int(t['total'])),
      'amountInWords': amountInWords(_int(t['amount'])),
      'createdAt': t['createdAt'],
      'confirmedAt': t['confirmedAt'],
      'failureReason': t['failureReason'],
      if (waiting && otp != null) 'otpExpiresAt': otp['expiresAt'],
      if (waiting && otp != null) 'otpAttemptsRemaining': _Rules.otpMaxAttempts - _int(otp['attempts']),
    };
  }

  Map<String, dynamic> _receipt(({String id, Map<String, dynamic> data}) t) => {
        ..._publicTxn(t.id, t.data),
        'service': t.data['type'] == 'deposit' ? 'Cash deposit (branchless)' : 'Cash withdrawal (branchless)',
        'totalLabel': t.data['type'] == 'deposit' ? 'Total credited' : 'Total debited',
        'agent': {'agentId': t.data['agentId'], 'name': t.data['agentName'], 'location': t.data['agentLocation']},
        'partnerBank': t.data['partnerBank'],
        if (t.data['balanceBefore'] != null) 'balanceBefore': paisaToRupees(_int(t.data['balanceBefore'])),
        if (t.data['balanceAfter'] != null) 'balanceAfter': paisaToRupees(_int(t.data['balanceAfter'])),
        'simulated': true,
      };

  Future<({String id, Map<String, dynamic> data})> _ownTxn(String id, {bool allowSupervisor = false}) async {
    final uid = _uid;
    Map<String, dynamic>? t;
    try {
      t = (await _doc('transactions', id).get()).data();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    final mine = t != null && (t['agentId'] == uid || (allowSupervisor && _me?['role'] == 'supervisor'));
    if (!mine) throw ApiException('TRANSACTION_NOT_FOUND', 'Transaction not found', status: 404);
    return (id: id, data: t);
  }

  ({int amount, String customerId, String accountNo, String key}) _cashInput(Map<String, dynamic> b) {
    final rupees = b['amount'];
    if (rupees is! num || rupees <= 0) throw _invalid('amount', 'Amount must be more than zero');
    if (!hasTwoDecimals(rupees)) throw _invalid('amount', 'At most two decimal places');
    final amount = rupeesToPaisa(rupees);
    if (amount < _Rules.minTransaction || amount > _Rules.maxTransaction) {
      throw ApiException('AMOUNT_OUT_OF_RANGE',
          'Amount must be between ${formatNpr(_Rules.minTransaction)} and ${formatNpr(_Rules.maxTransaction)}',
          status: 400);
    }
    final accountNo = '${b['accountNo'] ?? ''}';
    if (!RegExp(r'^\d{8,16}$').hasMatch(accountNo)) throw _invalid('accountNo', 'Invalid account number');
    final key = '${b['idempotencyKey'] ?? ''}';
    if (key.length < 8 || key.length > 64) throw _invalid('idempotencyKey', 'Invalid request key');
    return (amount: amount, customerId: '${b['customerId'] ?? ''}', accountNo: accountNo, key: key);
  }

  static ApiException? _checkAccount(Map<String, dynamic>? account, Map<String, dynamic>? customer, String customerId) {
    if (customer == null) return ApiException('CUSTOMER_NOT_FOUND', 'Customer not found', status: 404);
    if (account == null || account['customerId'] != customerId) {
      return ApiException('ACCOUNT_NOT_FOUND', 'This account does not belong to the selected customer', status: 404);
    }
    if (account['status'] == 'pending') {
      return ApiException('ACCOUNT_PENDING', 'This account is waiting for KYC approval by the bank', status: 409);
    }
    if (account['status'] != 'active') {
      return ApiException('ACCOUNT_INACTIVE', 'This account cannot be used for transactions', status: 409);
    }
    return null;
  }

  static String _reference() {
    final d = DateTime.now().toUtc();
    final date = '${d.year}${'${d.month}'.padLeft(2, '0')}${'${d.day}'.padLeft(2, '0')}';
    return 'TXN-$date-${_hex(3)}';
  }

  Map<String, dynamic> _baseTxn(String type, Map<String, dynamic> agent, String customerId,
          Map<String, dynamic> customer, String accountNo, int amount, int fee, String key) =>
      {
        'reference': _reference(),
        'type': type,
        'agentId': _uid,
        'agentName': agent['name'],
        'agentLocation': agent['location'],
        'partnerBank': agent['partnerBank'],
        'customerId': customerId,
        'customerName': _fullName(customer),
        'customerMobile': customer['mobile'],
        'accountNo': accountNo,
        'amount': amount,
        'fee': fee,
        'total': type == 'deposit' ? amount - fee : amount + fee,
        'idempotencyKey': key,
        'createdAt': _iso(),
      };

  /// Looks up an earlier attempt with the same key, so a retry never makes a second transaction.
  Future<({String id, Map<String, dynamic> data})?> _replay(Transaction tx, String idemId) async {
    final idem = await tx.get(_doc('idempotency', idemId));
    if (!idem.exists) return null;
    final txnId = idem.data()!['transactionId'] as String;
    final t = await tx.get(_doc('transactions', txnId));
    return (id: txnId, data: t.data()!);
  }

  /// UC4 deposit: credits the account and adds the cash to the agent's drawer, atomically.
  Future<Map<String, dynamic>> _deposit(Map<String, dynamic> b) async {
    final input = _cashInput(b);
    final agentId = _uid;
    final id = _db.collection('transactions').doc().id;
    final idemId = '$agentId:${input.key}';

    final outcome = await _db.runTransaction<({ApiException? error, String? id, Map<String, dynamic>? txn, bool replayed})>(
        (tx) async {
      final earlier = await _replay(tx, idemId);
      if (earlier != null) return (error: null, id: earlier.id, txn: earlier.data, replayed: true);

      final agent = (await tx.get(_doc('agents', agentId))).data()!;
      final customer = (await tx.get(_doc('customers', input.customerId))).data();
      final account = (await tx.get(_doc('accounts', input.accountNo))).data();
      final bad = _checkAccount(account, customer, input.customerId);
      if (bad != null) return (error: bad, id: null, txn: null, replayed: false);

      final (:float, :floatDate) = _currentFloat(agent);
      final cash = _int(float['cash']), limit = _int(float['limit']);
      if (cash + input.amount > limit) {
        return (
          error: ApiException('FLOAT_LIMIT_EXCEEDED',
              'This deposit would take your cash drawer above its ${formatNpr(limit)} limit. Request a float rebalance first.',
              status: 409, details: {'cash': paisaToRupees(cash), 'limit': paisaToRupees(limit)}),
          id: null,
          txn: null,
          replayed: false,
        );
      }
      final txn = {
        ..._baseTxn('deposit', agent, input.customerId, customer!, input.accountNo, input.amount, _Rules.depositFee,
            input.key),
        'status': 'confirmed',
        'floatBefore': cash,
        'floatAfter': cash + input.amount,
        'balanceBefore': _int(account!['balance']),
        'balanceAfter': _int(account['balance']) + input.amount,
      };
      txn['confirmedAt'] = txn['createdAt'];

      tx.set(_doc('transactions', id), txn);
      tx.update(_doc('agents', agentId), {
        'float': {...float, 'cash': cash + input.amount},
        'floatDate': floatDate,
        'lastTxnId': id,
      });
      tx.update(_doc('accounts', input.accountNo), {
        'balance': _int(account['balance']) + _int(txn['total']),
        'lastTxnId': id,
      });
      tx.set(_doc('idempotency', idemId), {'transactionId': id, 'at': txn['createdAt']});
      tx.set(_db.collection('auditLogs').doc(),
          _auditEntry('DEPOSIT_CONFIRMED', {'transactionId': id, 'reference': txn['reference'], 'amount': input.amount}));
      return (error: null, id: id, txn: txn, replayed: false);
    });

    if (outcome.error != null) throw outcome.error!;
    final t = outcome.txn!;
    if (!outcome.replayed) {
      await _sms(
          t['customerMobile'] as String?,
          'FinBridge: ${formatNpr(_int(t['total']))} deposited to A/C ${_maskAccount(t['accountNo'] as String?)} '
          'via agent ${t['agentId']}. Ref ${t['reference']}.',
          {'transactionId': outcome.id, 'kind': 'deposit_receipt'});
    }
    return {..._receipt((id: outcome.id!, data: t)), 'replayed': outcome.replayed};
  }

  /// UC5 withdrawal, step 1: checks balance and float, then sends the customer an OTP.
  Future<Map<String, dynamic>> _startWithdrawal(Map<String, dynamic> b) async {
    final input = _cashInput(b);
    final agentId = _uid;
    final id = _db.collection('transactions').doc().id;
    final idemId = '$agentId:${input.key}';
    final code = _digits(_Rules.otpLength);

    final outcome = await _db.runTransaction<({ApiException? error, String? id, Map<String, dynamic>? txn, bool replayed})>(
        (tx) async {
      final earlier = await _replay(tx, idemId);
      if (earlier != null) return (error: null, id: earlier.id, txn: earlier.data, replayed: true);

      final agent = (await tx.get(_doc('agents', agentId))).data()!;
      final customer = (await tx.get(_doc('customers', input.customerId))).data();
      final account = (await tx.get(_doc('accounts', input.accountNo))).data();
      final bad = _checkAccount(account, customer, input.customerId);
      if (bad != null) return (error: bad, id: null, txn: null, replayed: false);

      const fee = _Rules.withdrawalFee;
      if (_int(account!['balance']) < input.amount + fee) {
        return (
          error: ApiException(
              'INSUFFICIENT_BALANCE', 'The customer’s balance is not enough for this amount plus the fee',
              status: 409),
          id: null,
          txn: null,
          replayed: false,
        );
      }
      final (:float, floatDate: _) = _currentFloat(agent);
      final cash = _int(float['cash']), reserve = _int(float['minReserve']);
      if (cash - input.amount < reserve) {
        return (
          error: ApiException(
              'INSUFFICIENT_FLOAT',
              'Your cash drawer has ${formatNpr(cash)}. Paying ${formatNpr(input.amount)} would leave less than the '
                  '${formatNpr(reserve)} minimum reserve.',
              status: 409,
              details: {'cash': paisaToRupees(cash), 'minReserve': paisaToRupees(reserve)}),
          id: null,
          txn: null,
          replayed: false,
        );
      }
      final sentAt = _iso();
      final txn = {
        ..._baseTxn('withdrawal', agent, input.customerId, customer!, input.accountNo, input.amount, fee, input.key),
        'status': 'awaiting_otp',
        'otp': {
          'hash': _otpHash(id, code),
          'expiresAt': _iso(DateTime.now().add(_Rules.otpTtl)),
          'attempts': 0,
          'sentAt': sentAt,
          'resends': 0,
        },
      };
      tx.set(_doc('transactions', id), txn);
      tx.set(_doc('idempotency', idemId), {'transactionId': id, 'at': sentAt});
      tx.set(_db.collection('auditLogs').doc(),
          _auditEntry('WITHDRAWAL_STARTED', {'transactionId': id, 'amount': input.amount}));
      return (error: null, id: id, txn: txn, replayed: false);
    });

    if (outcome.error != null) throw outcome.error!;
    final t = outcome.txn!;
    if (!outcome.replayed) {
      await _sms(
          t['customerMobile'] as String?,
          'FinBridge: your OTP to withdraw ${formatNpr(_int(t['amount']))} at agent ${t['agentId']} is $code. '
          'Valid 5 minutes. Never share it with anyone except at the counter.',
          {'transactionId': outcome.id, 'kind': 'otp'});
    }
    return {
      'transaction': _publicTxn(outcome.id!, t),
      'replayed': outcome.replayed,
      if (_Rules.exposeDevOtp && !outcome.replayed) 'devOtp': code,
    };
  }

  /// UC5 withdrawal, step 2: checks the OTP, then debits the account and pays out from the drawer.
  Future<Map<String, dynamic>> _confirmWithdrawal(String txnId, String otp) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) throw _invalid('otp', 'OTP must be 6 digits');
    final agentId = _uid;
    await _ownTxn(txnId); // clear "not found" before starting the transaction

    // The transaction returns an outcome instead of throwing, so failed attempts are saved.
    final outcome = await _db.runTransaction<({ApiException? error, Map<String, dynamic>? txn, bool already})>((tx) async {
      final ref = _doc('transactions', txnId);
      final t = (await tx.get(ref)).data()!;
      if (t['type'] != 'withdrawal') {
        return (error: ApiException('TRANSACTION_NOT_FOUND', 'Transaction not found', status: 404), txn: null, already: false);
      }
      final agent = (await tx.get(_doc('agents', agentId))).data()!;
      final account = (await tx.get(_doc('accounts', t['accountNo'] as String))).data()!;

      if (t['status'] == 'confirmed') return (error: null, txn: t, already: true);
      if (t['status'] != 'awaiting_otp') {
        return (
          error: ApiException('NOT_AWAITING_OTP', 'This withdrawal is ${t['status']}', status: 409),
          txn: null,
          already: false,
        );
      }
      final otpData = Map<String, dynamic>.from(t['otp'] as Map);
      void audit(String action, [Map<String, dynamic> extra = const {}]) => tx.set(
          _db.collection('auditLogs').doc(), _auditEntry(action, {'transactionId': txnId, ...extra}));

      if (DateTime.parse(otpData['expiresAt'] as String).isBefore(DateTime.now())) {
        tx.update(ref, {'status': 'cancelled', 'failureReason': 'otp_expired'});
        audit('WITHDRAWAL_OTP_EXPIRED');
        return (
          error: ApiException('OTP_EXPIRED', 'The OTP has expired. Start the withdrawal again.', status: 410),
          txn: null,
          already: false,
        );
      }
      if (_otpHash(txnId, otp) != otpData['hash']) {
        final attempts = _int(otpData['attempts']) + 1;
        if (attempts >= _Rules.otpMaxAttempts) {
          tx.update(ref, {
            'status': 'cancelled',
            'failureReason': 'otp_attempts_exceeded',
            'otp': {...otpData, 'attempts': attempts},
          });
          audit('WITHDRAWAL_OTP_LOCKED');
          return (
            error: ApiException(
                'OTP_ATTEMPTS_EXCEEDED', 'Wrong OTP entered 3 times. The withdrawal has been cancelled.', status: 423),
            txn: null,
            already: false,
          );
        }
        tx.update(ref, {'otp': {...otpData, 'attempts': attempts}});
        audit('WITHDRAWAL_OTP_WRONG', {'attempts': attempts});
        return (
          error: ApiException('WRONG_OTP', 'The OTP is incorrect',
              status: 400, details: {'attemptsRemaining': _Rules.otpMaxAttempts - attempts}),
          txn: null,
          already: false,
        );
      }

      // Re-check balance and float at the moment of payout: they may have changed since the OTP was sent.
      final (:float, :floatDate) = _currentFloat(agent);
      final cash = _int(float['cash']), amount = _int(t['amount']), total = _int(t['total']);
      ({ApiException? error, Map<String, dynamic>? txn, bool already}) fail(String code, String message) {
        tx.update(ref, {'status': 'failed', 'failureReason': code});
        audit('WITHDRAWAL_FAILED', {'reason': code});
        return (error: ApiException(code, message, status: 409), txn: null, already: false);
      }

      if (account['status'] != 'active') return fail('ACCOUNT_INACTIVE', 'This account cannot be used for transactions');
      if (_int(account['balance']) < total) return fail('INSUFFICIENT_BALANCE', 'The customer’s balance is no longer enough');
      if (cash - amount < _int(float['minReserve'])) {
        return fail('INSUFFICIENT_FLOAT', 'Your cash drawer no longer has enough cash');
      }

      final confirmedAt = _iso();
      final update = {
        'status': 'confirmed',
        'confirmedAt': confirmedAt,
        'floatBefore': cash,
        'floatAfter': cash - amount,
        'balanceBefore': _int(account['balance']),
        'balanceAfter': _int(account['balance']) - total,
        'otp': {...otpData, 'usedAt': confirmedAt},
      };
      tx.update(ref, update);
      tx.update(_doc('agents', agentId), {
        'float': {...float, 'cash': cash - amount},
        'floatDate': floatDate,
        'lastTxnId': txnId,
      });
      tx.update(_doc('accounts', t['accountNo'] as String), {
        'balance': _int(account['balance']) - total,
        'lastTxnId': txnId,
      });
      audit('WITHDRAWAL_CONFIRMED', {'reference': t['reference'], 'amount': amount});
      return (error: null, txn: {...t, ...update}, already: false);
    });

    if (outcome.error != null) throw outcome.error!;
    final t = outcome.txn!;
    if (!outcome.already) {
      await _sms(
          t['customerMobile'] as String?,
          'FinBridge: ${formatNpr(_int(t['amount']))} withdrawn from A/C ${_maskAccount(t['accountNo'] as String?)} '
          'via agent ${t['agentId']} (fee ${formatNpr(_int(t['fee']))}). Ref ${t['reference']}.',
          {'transactionId': txnId, 'kind': 'withdrawal_receipt'});
    }
    return _receipt((id: txnId, data: t));
  }

  Future<Map<String, dynamic>> _resendOtp(String txnId) async {
    final t = (await _ownTxn(txnId)).data;
    if (t['status'] != 'awaiting_otp') {
      throw ApiException('TRANSACTION_NOT_FOUND', 'No withdrawal is waiting for an OTP', status: 404);
    }
    final otp = Map<String, dynamic>.from(t['otp'] as Map);
    final wait = DateTime.parse(otp['sentAt'] as String).add(_Rules.otpResendAfter).difference(DateTime.now());
    if (wait > Duration.zero) {
      throw ApiException('RESEND_TOO_SOON', 'Wait ${wait.inSeconds + 1} seconds before resending', status: 429);
    }
    if (_int(otp['resends']) >= _Rules.otpMaxResends) {
      throw ApiException('RESEND_LIMIT', 'OTP resend limit reached. Start a new withdrawal.', status: 429);
    }
    final code = _digits(_Rules.otpLength);
    // Attempts are not reset, so resending cannot be used to get more guesses.
    await _doc('transactions', txnId).update({
      'otp': {
        ...otp,
        'hash': _otpHash(txnId, code),
        'sentAt': _iso(),
        'resends': _int(otp['resends']) + 1,
        'expiresAt': _iso(DateTime.now().add(_Rules.otpTtl)),
      },
    });
    await _sms(t['customerMobile'] as String?, 'FinBridge: your new OTP is $code. Valid 5 minutes.',
        {'transactionId': txnId, 'kind': 'otp'});
    await _audit('WITHDRAWAL_OTP_RESENT', {'transactionId': txnId});
    return _Rules.exposeDevOtp ? {'devOtp': code} : {};
  }

  Future<void> _cancel(String txnId) async {
    final t = (await _ownTxn(txnId)).data;
    if (t['status'] != 'awaiting_otp') {
      throw ApiException('CANNOT_CANCEL', 'Only a withdrawal waiting for its OTP can be cancelled', status: 409);
    }
    await _doc('transactions', txnId).update({'status': 'cancelled', 'failureReason': 'cancelled_by_agent'});
    await _audit('WITHDRAWAL_CANCELLED', {'transactionId': txnId});
  }

  /// All of this agent's transactions, newest first. Filtering happens here, so Firestore needs
  /// no composite index.
  Future<List<({String id, Map<String, dynamic> data})>> _agentTransactions(String agentId) async {
    final q = await _db.collection('transactions').where('agentId', isEqualTo: agentId).get();
    final rows = [for (final d in q.docs) (id: d.id, data: d.data())];
    rows.sort((a, b) => '${b.data['createdAt']}'.compareTo('${a.data['createdAt']}'));
    return rows;
  }

  Future<List<Map<String, dynamic>>> _listTransactions(Map<String, String> q) async {
    final needle = q['q']?.toLowerCase();
    final limit = int.tryParse(q['limit'] ?? '')?.clamp(1, 200) ?? 50;
    return (await _agentTransactions(_uid))
        .where((t) => q['type'] == null || t.data['type'] == q['type'])
        .where((t) => q['status'] == null || t.data['status'] == q['status'])
        .where((t) => q['from'] == null || '${t.data['createdAt']}'.compareTo(q['from']!) >= 0)
        .where((t) => q['to'] == null || '${t.data['createdAt']}'.compareTo(q['to']!) <= 0)
        .where((t) =>
            needle == null ||
            '${t.data['customerName']}'.toLowerCase().contains(needle) ||
            '${t.data['reference']}'.toLowerCase().contains(needle))
        .take(limit)
        .map((t) => _publicTxn(t.id, t.data))
        .toList();
  }

  Future<void> _resendReceipt(String txnId) async {
    final t = (await _ownTxn(txnId)).data;
    if (t['status'] != 'confirmed') {
      throw ApiException('NOT_CONFIRMED', 'Only confirmed transactions have a receipt', status: 409);
    }
    await _sms(
        t['customerMobile'] as String?,
        'FinBridge receipt: ${t['type']} ${formatNpr(_int(t['amount']))}, fee ${formatNpr(_int(t['fee']))}, '
        'A/C ${_maskAccount(t['accountNo'] as String?)}. Ref ${t['reference']}.',
        {'transactionId': txnId, 'kind': 'receipt_resend'});
    await _audit('RECEIPT_RESENT', {'transactionId': txnId});
  }

  Future<Map<String, dynamic>> _reportDispute(String txnId, String reason) async {
    if (reason.length < 10) throw _invalid('reason', 'Describe the problem in at least 10 characters');
    if (reason.length > 500) throw _invalid('reason', 'Keep it under 500 characters');
    final t = (await _ownTxn(txnId)).data;
    final ref = await _db.collection('disputes').add({
      'transactionId': txnId,
      'reference': t['reference'],
      'agentId': _uid,
      'customerId': t['customerId'],
      'reason': reason,
      'status': 'open',
      'createdAt': _iso(),
    });
    await _audit('DISPUTE_REPORTED', {'transactionId': txnId, 'disputeId': ref.id});
    return {'disputeId': ref.id, 'status': 'open'};
  }

  // ------------------------------------------------------------------ dashboard and end of day

  static Map<String, dynamic> _totals(List<Map<String, dynamic>> txns) {
    final confirmed = txns.where((t) => t['status'] == 'confirmed').toList();
    int sum(String type) => confirmed.where((t) => t['type'] == type).fold(0, (s, t) => s + _int(t['amount']));
    int count(String type) => confirmed.where((t) => t['type'] == type).length;
    return {
      'inflows': paisaToRupees(sum('deposit')),
      'inflowCount': count('deposit'),
      'outflows': paisaToRupees(sum('withdrawal')),
      'outflowCount': count('withdrawal'),
      'feesEarned': paisaToRupees(confirmed.fold<int>(0, (s, t) => s + _int(t['fee']))),
    };
  }

  Future<List<({String id, Map<String, dynamic> data})>> _todaysTransactions(String agentId) async {
    final today = _startOfNepalDay();
    return (await _agentTransactions(agentId)).where((t) => '${t.data['createdAt']}'.compareTo(today) >= 0).toList();
  }

  Future<Map<String, dynamic>> _dashboard() async {
    final agentId = _uid;
    final agent = await _agentDoc();
    final (:float, floatDate: _) = _currentFloat(agent);
    final txns = await _todaysTransactions(agentId);
    final pendingKyc = await _db
        .collection('customers')
        .where('createdByAgent', isEqualTo: agentId)
        .where('kycStatus', isEqualTo: 'pending_review')
        .get();
    final eodToday = await _db
        .collection('eodReports')
        .where('agentId', isEqualTo: agentId)
        .where('date', isEqualTo: _startOfNepalDay())
        .get();

    final cash = _int(float['cash']), reserve = _int(float['minReserve']), limit = _int(float['limit']);
    final awaitingOtp = txns.where((t) => t.data['status'] == 'awaiting_otp').length;
    final alerts = [
      if (pendingKyc.docs.isNotEmpty)
        {
          'type': 'kyc_pending',
          'count': pendingKyc.docs.length,
          'message': pendingKyc.docs.length == 1
              ? '1 new account waiting for bank approval'
              : '${pendingKyc.docs.length} new accounts waiting for bank approval',
        },
      if (eodToday.docs.isEmpty) {'type': 'eod_due', 'message': 'End-of-day cash count not done yet'},
      if (awaitingOtp > 0)
        {
          'type': 'pending_otp',
          'count': awaitingOtp,
          'message': awaitingOtp == 1 ? '1 withdrawal is waiting for OTP' : '$awaitingOtp withdrawals are waiting for OTP',
        },
      if (cash - reserve < 5000 * 100) {'type': 'low_float', 'message': 'Cash is near the minimum reserve'},
      if (limit - cash < 5000 * 100) {'type': 'high_float', 'message': 'Cash is near the limit'},
    ];
    return {
      'agent': _publicAgent(agentId, agent),
      'float': _rupeesFloat(float),
      'today': _totals(txns.map((t) => t.data).toList()),
      'alerts': alerts,
      'recent': txns.take(5).map((t) => _publicTxn(t.id, t.data)).toList(),
      'eodSubmitted': eodToday.docs.isNotEmpty,
    };
  }

  Future<Map<String, dynamic>> _eodPreview() async {
    final agent = await _agentDoc();
    final (:float, floatDate: _) = _currentFloat(agent);
    final txns = await _todaysTransactions(_uid);
    return {
      'date': _startOfNepalDay(),
      'openingFloat': paisaToRupees(_int(float['opening'])),
      ..._totals(txns.map((t) => t.data).toList()),
      'expectedCash': paisaToRupees(_int(float['cash'])),
      'pending': txns.where((t) => t.data['status'] == 'awaiting_otp').map((t) => _publicTxn(t.id, t.data)).toList(),
    };
  }

  Future<Map<String, dynamic>> _submitEod(Map<String, dynamic> b) async {
    final countedCash = b['countedCash'];
    if (countedCash is! num || countedCash < 0 || countedCash > 10000000) {
      throw _invalid('countedCash', 'Enter the cash you counted');
    }
    final notes = '${b['notes'] ?? ''}'.trim();
    final agentId = _uid;
    final preview = await _eodPreview();
    final counted = rupeesToPaisa(countedCash);
    final expected = rupeesToPaisa(preview['expectedCash'] as num);
    final difference = counted - expected;
    final date = preview['date'] as String;
    final id = '${agentId}_${date.substring(0, 10)}';
    final report = {
      'agentId': agentId,
      'date': date,
      'openingFloat': preview['openingFloat'],
      'inflows': preview['inflows'],
      'outflows': preview['outflows'],
      'expectedCash': preview['expectedCash'],
      'countedCash': paisaToRupees(counted),
      'difference': paisaToRupees(difference),
      'status': difference == 0 ? 'balanced' : 'mismatch',
      'pendingTransactionIds': [for (final t in preview['pending'] as List) (t as Map)['id']],
      'notes': notes.isEmpty ? null : notes,
      'submittedAt': _iso(),
    };
    final created = await _db.runTransaction((tx) async {
      if ((await tx.get(_doc('eodReports', id))).exists) return false;
      tx.set(_doc('eodReports', id), report);
      tx.set(_db.collection('auditLogs').doc(), _auditEntry('EOD_SUBMITTED',
          {'reportId': id, 'status': report['status'], 'difference': report['difference']}));
      return true;
    });
    if (!created) {
      throw ApiException('EOD_ALREADY_SUBMITTED', 'Today’s end-of-day report has already been submitted', status: 409);
    }
    return {
      'reportId': id,
      ...report,
      'message': difference == 0
          ? 'Cash balanced. Report sent to your supervisor.'
          : 'Difference of ${formatNpr(difference.abs())} (${difference > 0 ? 'over' : 'short'}). '
              'Report sent to your supervisor for review.',
    };
  }

  Future<Map<String, dynamic>> _requestRebalance(Map<String, dynamic> b) async {
    final direction = b['direction'];
    if (direction != 'cash_to_bank' && direction != 'cash_from_bank') throw _invalid('direction', 'Choose a direction');
    final amount = b['amount'];
    if (amount is! num || amount <= 0 || !hasTwoDecimals(amount)) throw _invalid('amount', 'Enter a valid amount');
    final notes = '${b['notes'] ?? ''}'.trim();
    final ref = await _db.collection('floatRequests').add({
      'agentId': _uid,
      'direction': direction,
      'amount': rupeesToPaisa(amount),
      'notes': notes.isEmpty ? null : notes,
      'status': 'pending',
      'createdAt': _iso(),
    });
    await _audit('FLOAT_REBALANCE_REQUESTED', {'requestId': ref.id, 'direction': direction, 'amount': amount});
    return {'requestId': ref.id, 'status': 'pending'};
  }

  // ------------------------------------------------------------------ supervisor

  Future<Map<String, dynamic>> _supervisorOverview() async {
    Future<List<Map<String, dynamic>>> rows(Query<Map<String, dynamic>> q) async =>
        (await q.get()).docs.map((d) => {'id': d.id, ...d.data()}).toList();
    final agents = await rows(_db.collection('agents').where('role', isEqualTo: 'agent'));
    final pending = await rows(_db.collection('customers').where('kycStatus', isEqualTo: 'pending_review'));
    return {
      'agents': [
        for (final a in agents)
          {
            ..._publicAgent(a['id'] as String, a),
            'float': _rupeesFloat(_currentFloat(a).float),
            'failedPinAttempts': _int(a['failedPinAttempts']),
          },
      ],
      'pendingKyc': [
        for (final c in pending)
          {
            'customerId': c['id'],
            'name': _fullName(c),
            'createdByAgent': c['createdByAgent'],
            'createdAt': c['createdAt'],
            // References to the KYC images (absent on customers made before uploads existed).
            'documents': c['documents'],
          },
      ],
      'eodMismatches': await rows(_db.collection('eodReports').where('status', isEqualTo: 'mismatch')),
      'openDisputes': await rows(_db.collection('disputes').where('status', isEqualTo: 'open')),
      'floatRequests': [
        for (final r in await rows(_db.collection('floatRequests').where('status', isEqualTo: 'pending')))
          {...r, 'amount': paisaToRupees(_int(r['amount']))},
      ],
    };
  }

  Future<void> _unlockAgent(String agentId) async {
    if (!(await _doc('agents', agentId).get()).exists) {
      throw ApiException('AGENT_NOT_FOUND', 'Agent not found', status: 404);
    }
    await _doc('agents', agentId)
        .update({'status': 'active', 'failedPinAttempts': 0, 'unlockedBy': _uid, 'unlockedAt': _iso()});
    await _audit('AGENT_UNLOCKED', {'agentId': agentId});
  }

  Future<Map<String, dynamic>> _decideRebalance(String requestId, bool approve) async {
    final supervisorId = _uid;
    final outcome = await _db.runTransaction<({ApiException? error, Map<String, dynamic>? result})>((tx) async {
      final r = (await tx.get(_doc('floatRequests', requestId))).data();
      if (r == null || r['status'] != 'pending') {
        return (error: ApiException('REQUEST_NOT_FOUND', 'No pending request with this ID', status: 404), result: null);
      }
      final agentRef = _doc('agents', r['agentId'] as String);
      final agent = (await tx.get(agentRef)).data()!;
      final decided = {'decidedBy': supervisorId, 'decidedAt': _iso()};
      if (!approve) {
        tx.update(_doc('floatRequests', requestId), {'status': 'rejected', ...decided});
        return (error: null, result: <String, dynamic>{'status': 'rejected'});
      }
      final (:float, :floatDate) = _currentFloat(agent);
      final amount = _int(r['amount']), now = _int(float['cash']);
      // cash_to_bank: the agent hands excess cash to the bank; cash_from_bank: the bank tops the drawer up.
      final cash = r['direction'] == 'cash_to_bank' ? now - amount : now + amount;
      if (cash < 0 || cash > _int(float['limit'])) {
        return (
          error: ApiException('INVALID_REBALANCE', 'This rebalance would put the drawer outside its limits', status: 409),
          result: null,
        );
      }
      tx.update(agentRef, {'float': {...float, 'cash': cash}, 'floatDate': floatDate});
      tx.update(_doc('floatRequests', requestId), {'status': 'approved', ...decided});
      return (error: null, result: <String, dynamic>{'status': 'approved', 'newCash': paisaToRupees(cash)});
    });
    if (outcome.error != null) throw outcome.error!;
    await _audit('FLOAT_REBALANCE_DECIDED', {'requestId': requestId, ...outcome.result!});
    return outcome.result!;
  }
}
