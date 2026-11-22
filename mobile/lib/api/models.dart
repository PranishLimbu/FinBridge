double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

class Agent {
  Agent.fromJson(Map<String, dynamic> j)
      : id = j['agentId'] as String,
        name = j['name'] as String,
        role = j['role'] as String,
        location = j['location'] as String? ?? '',
        terminalId = j['terminalId'] as String?,
        partnerBank = j['partnerBank'] as String? ?? '';

  final String id;
  final String name;
  final String role;
  final String location;
  final String? terminalId;
  final String partnerBank;
}

/// A province, district or municipality. [parentId] is the province of a district, or the
/// district of a municipality.
class Place {
  Place(this.id, this.name, this.nameNe, this.parentId);

  final String id, name, nameNe;
  final String? parentId;
}

/// Nepal's administrative divisions from GET /locations, for the address dropdowns.
class Locations {
  Locations.fromJson(Map<String, dynamic> j)
      : provinces = _list(j['provinces'], null),
        districts = _list(j['districts'], 'provinceId'),
        localBodies = _list(j['localBodies'], 'districtId');

  final List<Place> provinces, districts, localBodies;

  bool get isEmpty => districts.isEmpty || localBodies.isEmpty;
  List<Place> districtsOf(String? provinceId) => districts.where((d) => d.parentId == provinceId).toList();
  List<Place> localBodiesOf(String? districtId) => localBodies.where((l) => l.parentId == districtId).toList();
  Place? byId(List<Place> list, String? id) => list.where((p) => p.id == id).firstOrNull;

  static List<Place> _list(dynamic raw, String? parentKey) => [
        for (final m in (raw as List? ?? []).cast<Map<String, dynamic>>())
          Place(m['id'] as String, m['name'] as String, m['nameNe'] as String? ?? '',
              parentKey == null ? null : m[parentKey] as String?),
      ];
}

class Float {
  Float.fromJson(Map<String, dynamic> j)
      : cash = _d(j['cash']),
        opening = _d(j['opening']),
        limit = _d(j['limit']),
        minReserve = _d(j['minReserve']),
        utilisation = _d(j['utilisation']);

  final double cash, opening, limit, minReserve, utilisation;
}

class Account {
  Account.fromJson(Map<String, dynamic> j)
      : accountNo = j['accountNo'] as String,
        masked = j['accountMasked'] as String,
        productName = j['productName'] as String? ?? 'Savings',
        status = j['status'] as String;

  final String accountNo, masked, productName, status;
  bool get isActive => status == 'active';
}

class CustomerSummary {
  CustomerSummary.fromJson(Map<String, dynamic> j)
      : id = j['customerId'] as String,
        name = j['name'] as String,
        mobileMasked = j['mobileMasked'] as String? ?? '',
        citizenshipMasked = j['citizenshipMasked'] as String? ?? '',
        kycStatus = j['kycStatus'] as String,
        accounts = ((j['accounts'] as List?) ?? [])
            .map((a) => Account.fromJson(a as Map<String, dynamic>))
            .toList();

  final String id, name, mobileMasked, citizenshipMasked, kycStatus;
  final List<Account> accounts;
  bool get verified => kycStatus == 'verified';
}

class Txn {
  Txn.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        reference = j['reference'] as String,
        type = j['type'] as String,
        status = j['status'] as String,
        customerName = j['customerName'] as String? ?? '',
        accountMasked = j['accountMasked'] as String? ?? '',
        amount = _d(j['amount']),
        fee = _d(j['fee']),
        total = _d(j['total']),
        amountInWords = j['amountInWords'] as String? ?? '',
        createdAt = j['createdAt'] as String?,
        confirmedAt = j['confirmedAt'] as String?,
        failureReason = j['failureReason'] as String?,
        otpAttemptsRemaining = j['otpAttemptsRemaining'] as int?,
        raw = j;

  final String id, reference, type, status, customerName, accountMasked, amountInWords;
  final double amount, fee, total;
  final String? createdAt, confirmedAt, failureReason;
  final int? otpAttemptsRemaining;
  final Map<String, dynamic> raw;

  bool get isDeposit => type == 'deposit';
  String get typeLabel => isDeposit ? 'Cash deposit' : 'Cash withdrawal';
  String get statusLabel => switch (status) {
        'confirmed' => 'Confirmed',
        'awaiting_otp' => 'Pending OTP',
        'cancelled' => 'Cancelled',
        'failed' => 'Failed',
        _ => status,
      };

  // Receipt-only fields (present on GET /transactions/:id and after confirmation).
  String get service => raw['service'] as String? ?? typeLabel;
  String get totalLabel => raw['totalLabel'] as String? ?? 'Total';
  String get partnerBank => raw['partnerBank'] as String? ?? '';
  Map<String, dynamic> get agent => (raw['agent'] as Map<String, dynamic>?) ?? {};
}
