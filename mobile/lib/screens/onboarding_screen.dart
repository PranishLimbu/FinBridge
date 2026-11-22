import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// UC3 Onboard new customer (Figures 8–9): Personal → Family → Address → Documents.
/// No real identity check happens; the application goes to the bank supervisor for review.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  int _step = 0;
  bool _busy = false;
  String? _error;

  // Section A: personal
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  String _gender = 'male';
  String _marital = 'single';
  final _dobBs = TextEditingController();
  DateTime? _dobAd;
  final _occupation = TextEditingController();
  final _mobile = TextEditingController();
  // Section B: citizenship and PAN
  final _citizenship = TextEditingController();
  final _issueBs = TextEditingController();
  final _issueDistrict = TextEditingController();
  final _pan = TextEditingController();
  // Family
  final _father = TextEditingController();
  final _mother = TextEditingController();
  final _grandfather = TextEditingController();
  final _spouse = TextEditingController();
  // Address
  String _province = 'Bagmati';
  final _district = TextEditingController();
  final _municipality = TextEditingController();
  final _ward = TextEditingController();
  final _tole = TextEditingController();
  // Documents
  bool _front = false, _back = false, _photo = false, _consent = false;

  // Address lists from the server. Until they load (or if they cannot), the plain text fields
  // above are used instead, so onboarding never gets stuck.
  Locations? _locs;
  bool _locsFailed = false;
  String? _provinceId = '3'; // Bagmati
  String? _districtId, _localBodyId, _issueDistrictId;
  String? _districtError, _localBodyError, _issueDistrictError;

  bool get _useLists => _locs != null && !_locs!.isEmpty;

  static const _provinces = ['Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim'];
  static const _steps = ['Personal', 'Family', 'Address', 'Documents'];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final res = await context.read<Session>().api.get('/locations') as Map<String, dynamic>;
      if (mounted) setState(() => _locs = Locations.fromJson(res));
    } on ApiException {
      if (mounted) setState(() => _locsFailed = true);
    }
  }

  /// Checks the dropdowns on the current step; they are not form fields, so Form.validate misses them.
  bool _listsValid() {
    if (!_useLists) return true;
    setState(() {
      if (_step == 0) _issueDistrictError = _issueDistrictId == null ? 'Choose the issue district' : null;
      if (_step == 2) {
        _districtError = _districtId == null ? 'Choose a district' : null;
        _localBodyError = _localBodyId == null ? 'Choose a municipality' : null;
      }
    });
    return _step == 0 ? _issueDistrictError == null : _step != 2 || (_districtError == null && _localBodyError == null);
  }

  @override
  void dispose() {
    for (final c in [
      _first, _middle, _last, _dobBs, _occupation, _mobile, _citizenship, _issueBs, _issueDistrict, _pan,
      _father, _mother, _grandfather, _spouse, _district, _municipality, _ward, _tole,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _name(String? v) =>
      _req(v) ?? (RegExp(r"^[A-Za-z .'-]+$").hasMatch(v!.trim()) ? null : 'Use letters only');
  String? _bsDate(String? v) =>
      RegExp(r'^20\d{2}-\d{2}-\d{2}$').hasMatch(v?.trim() ?? '') ? null : 'Use BS format YYYY-MM-DD, e.g. 2042-05-14';

  int? get _age {
    if (_dobAd == null) return null;
    final now = DateTime.now();
    var a = now.year - _dobAd!.year;
    if (now.month < _dobAd!.month || (now.month == _dobAd!.month && now.day < _dobAd!.day)) a--;
    return a;
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dobAd ?? DateTime(1990),
      firstDate: DateTime(1915),
      lastDate: DateTime.now(),
      helpText: 'Date of birth (AD)',
    );
    if (d != null) setState(() => _dobAd = d);
  }

  void _next() {
    if (_step == 0 && _dobAd == null) {
      setState(() => _error = 'Choose the date of birth in AD as well');
      return;
    }
    if (_step == 0 && (_age ?? 0) < 16) {
      setState(() => _error = 'The customer must be at least 16 years old');
      return;
    }
    final listsOk = _listsValid();
    if (!_forms[_step].currentState!.validate() || !listsOk) return;
    setState(() {
      _error = null;
      _step++;
    });
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_front && _back && _photo)) {
      setState(() => _error = 'Capture both sides of the citizenship certificate and the customer’s photo');
      return;
    }
    if (!_consent) {
      setState(() => _error = 'The customer must agree to the terms');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final locs = _useLists ? _locs! : null;
    String name(List<Place> list, String? id) => locs!.byId(list, id)?.name ?? '';
    final body = {
      'firstName': _first.text.trim(),
      'middleName': _middle.text.trim(),
      'lastName': _last.text.trim(),
      'gender': _gender,
      'maritalStatus': _marital,
      'dobBs': _dobBs.text.trim(),
      'dobAd': _iso(_dobAd!),
      'occupation': _occupation.text.trim(),
      'mobile': _mobile.text.trim(),
      'citizenshipNo': _citizenship.text.trim(),
      'citizenshipIssueDateBs': _issueBs.text.trim(),
      'citizenshipIssueDistrict': locs != null ? name(locs.districts, _issueDistrictId) : _issueDistrict.text.trim(),
      'pan': _pan.text.trim(),
      'family': {
        'fatherName': _father.text.trim(),
        'motherName': _mother.text.trim(),
        'grandfatherName': _grandfather.text.trim(),
        'spouseName': _spouse.text.trim(),
      },
      'address': {
        'province': locs != null ? name(locs.provinces, _provinceId) : _province,
        'district': locs != null ? name(locs.districts, _districtId) : _district.text.trim(),
        'municipality': locs != null ? name(locs.localBodies, _localBodyId) : _municipality.text.trim(),
        'ward': int.tryParse(_ward.text.trim()) ?? 0,
        'tole': _tole.text.trim(),
      },
      'documents': {'citizenshipFront': _front, 'citizenshipBack': _back, 'photo': _photo},
      'consent': _consent,
    };
    try {
      final res = await context.read<Session>().api.post('/customers', body) as Map<String, dynamic>;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Application submitted'),
          content: Text('Customer ID: ${res['customerId']}\nAccount: ${res['accountMasked']}\n\n'
              'The bank will review the KYC. Deposits and withdrawals become available once it is verified.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stepBack() {
    if (_busy) return;
    if (_step > 0) {
      setState(() {
        _step--;
        _error = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy && _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stepBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer onboarding'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _stepBack,
          ),
        ),
        body: Column(
          children: [
            const SimulatedBanner(),
            _stepper(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _forms[_step],
                    child: switch (_step) {
                      0 => _personal(),
                      1 => _family(),
                      2 => _address(),
                      _ => _documents(),
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                  FilledButton(
                    onPressed: _busy ? null : (_step < 3 ? _next : _submit),
                    child: Text(_busy ? 'Submitting…' : _step < 3 ? 'Continue to ${_steps[_step + 1]}' : 'Submit for bank review'),
                  ),
                  if (_step > 0) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : _stepBack,
                      child: const Text('Back'),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: i <= _step ? FbColors.primary : FbColors.border,
                      child: Text('${i + 1}', style: TextStyle(color: i <= _step ? Colors.white : FbColors.textMuted, fontSize: 12)),
                    ),
                    const SizedBox(height: 4),
                    Text(_steps[i], style: TextStyle(fontSize: 12, fontWeight: i == _step ? FontWeight.w700 : FontWeight.w400)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _field(TextEditingController c, String label,
          {String? Function(String?)? validator, TextInputType? keyboard, String? hint, int? maxLength}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: keyboard,
          maxLength: maxLength,
          decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
          validator: validator,
        ),
      );

  Widget _personal() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Section A: Personal information',
            child: Column(children: [
              _field(_first, bi('First name', 'पहिलो नाम'), validator: _name),
              _field(_middle, bi('Middle name (optional)', 'बीचको नाम')),
              _field(_last, bi('Last name', 'थर'), validator: _name),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(labelText: bi('Gender', 'लिङ्ग')),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male (पुरुष)')),
                    DropdownMenuItem(value: 'female', child: Text('Female (महिला)')),
                    DropdownMenuItem(value: 'other', child: Text('Other (अन्य)')),
                  ],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _marital,
                  decoration: InputDecoration(labelText: bi('Marital status', 'वैवाहिक स्थिति')),
                  items: const [
                    DropdownMenuItem(value: 'single', child: Text('Single (अविवाहित)')),
                    DropdownMenuItem(value: 'married', child: Text('Married (विवाहित)')),
                    DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                    DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                  ],
                  onChanged: (v) => setState(() => _marital = v!),
                ),
              ),
              _field(_dobBs, bi('Date of birth, BS', 'जन्म मिति'), hint: '2042-05-14', validator: _bsDate),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: _pickDob,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_dobAd == null
                      ? 'Date of birth, AD (choose)'
                      : 'AD: ${_iso(_dobAd!)}  •  Age ${_age ?? '-'}'),
                ),
              ),
              _field(_occupation, bi('Occupation', 'पेशा'), validator: _req, hint: 'e.g. Agriculture / Farmer'),
              _field(_mobile, bi('Mobile number', 'मोबाइल नम्बर'),
                  keyboard: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) => RegExp(r'^9[78]\d{8}$').hasMatch(v ?? '') ? null : '10 digits starting 97 or 98'),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Section B: Citizenship and PAN',
            child: Column(children: [
              _field(_citizenship, bi('Citizenship certificate no.', 'नागरिकता नं.'),
                  hint: '27-01-78-04912',
                  validator: (v) => RegExp(r'^\d{1,3}(-\d{1,6}){1,4}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Use the format printed on the certificate'),
              _field(_issueBs, bi('Issue date, BS', 'जारी मिति'), hint: '2060-03-22', validator: _bsDate),
              if (_useLists)
                _placeMenu(
                  key: const ValueKey('issue-district'),
                  label: bi('Issue district', 'जारी जिल्ला'),
                  places: _locs!.districts,
                  selected: _issueDistrictId,
                  error: _issueDistrictError,
                  onSelected: (id) => setState(() {
                    _issueDistrictId = id;
                    _issueDistrictError = null;
                  }),
                )
              else
                _field(_issueDistrict, bi('Issue district', 'जारी जिल्ला'), validator: _req),
              _field(_pan, bi('PAN (optional)', 'स्थायी लेखा नं.'),
                  keyboard: TextInputType.number,
                  maxLength: 9,
                  validator: (v) => (v == null || v.isEmpty || RegExp(r'^\d{9}$').hasMatch(v)) ? null : 'PAN has 9 digits'),
              const Text('The format check does not verify the document with any government system.',
                  style: TextStyle(fontSize: 12, color: FbColors.textMuted)),
            ]),
          ),
        ],
      );

  Widget _family() => SectionCard(
        title: 'Family details',
        child: Column(children: [
          _field(_father, bi('Father’s name', 'बुबाको नाम'), validator: _name),
          _field(_mother, bi('Mother’s name', 'आमाको नाम'), validator: _name),
          _field(_grandfather, bi('Grandfather’s name', 'हजुरबुबाको नाम'), validator: _name),
          if (_marital == 'married') _field(_spouse, bi('Spouse’s name', 'पति/पत्नीको नाम'), validator: _name),
        ]),
      );

  /// Searchable dropdown: tap to scroll the list, or type to filter it.
  Widget _placeMenu({
    required Key key,
    required String label,
    required List<Place> places,
    required String? selected,
    required String? error,
    required ValueChanged<String?> onSelected,
    String? hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownMenu<String>(
          key: key,
          initialSelection: selected,
          enabled: places.isNotEmpty,
          expandedInsets: EdgeInsets.zero,
          menuHeight: 320,
          enableFilter: true,
          requestFocusOnTap: true,
          label: Text(label),
          hintText: hint ?? 'Type to search',
          errorText: error,
          dropdownMenuEntries: [
            for (final p in places)
              DropdownMenuEntry(
                value: p.id,
                label: p.name,
                labelWidget: Text(p.nameNe.isEmpty ? p.name : '${p.name}  (${p.nameNe})'),
              ),
          ],
          onSelected: onSelected,
        ),
      );

  Widget _address() => SectionCard(
        title: 'Permanent address',
        child: Column(children: [
          if (_useLists) ..._addressLists() else ..._addressText(),
          _field(_ward, bi('Ward no.', 'वडा नं.'),
              keyboard: TextInputType.number,
              maxLength: 2,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1 || n > 35) ? 'Ward between 1 and 35' : null;
              }),
          _field(_tole, bi('Tole / street (optional)', 'टोल')),
        ]),
      );

  List<Widget> _addressLists() {
    final locs = _locs!;
    final districts = locs.districtsOf(_provinceId);
    final bodies = locs.localBodiesOf(_districtId);
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: _provinceId,
          decoration: InputDecoration(labelText: bi('Province', 'प्रदेश')),
          items: [
            for (final p in locs.provinces) DropdownMenuItem(value: p.id, child: Text('${p.name}  (${p.nameNe})')),
          ],
          onChanged: (v) => setState(() {
            if (v == _provinceId) return;
            _provinceId = v;
            _districtId = null;
            _localBodyId = null;
          }),
        ),
      ),
      // Keys include the parent so a child list starts empty whenever its parent changes.
      _placeMenu(
        key: ValueKey('district-$_provinceId'),
        label: bi('District', 'जिल्ला'),
        places: districts,
        selected: _districtId,
        error: _districtError,
        onSelected: (id) => setState(() {
          if (id != _districtId) _localBodyId = null;
          _districtId = id;
          _districtError = null;
        }),
      ),
      _placeMenu(
        key: ValueKey('local-body-$_districtId'),
        label: bi('Municipality / rural municipality', 'नगरपालिका / गाउँपालिका'),
        places: bodies,
        selected: _localBodyId,
        error: _localBodyError,
        hint: _districtId == null ? 'Choose the district first' : '${bodies.length} in this district — type to search',
        onSelected: (id) => setState(() {
          _localBodyId = id;
          _localBodyError = null;
        }),
      ),
    ];
  }

  List<Widget> _addressText() => [
        if (_locs == null && !_locsFailed)
          const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(minHeight: 2)),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: _province,
            decoration: InputDecoration(labelText: bi('Province', 'प्रदेश')),
            items: [for (final p in _provinces) DropdownMenuItem(value: p, child: Text(p))],
            onChanged: (v) => setState(() => _province = v!),
          ),
        ),
        _field(_district, bi('District', 'जिल्ला'), validator: _req),
        _field(_municipality, bi('Municipality / rural municipality', 'नगरपालिका / गाउँपालिका'), validator: _req),
      ];

  Widget _documents() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Documents',
            child: Column(children: [
              const Text(
                'Camera capture is simulated in this prototype: tick each item once you have checked the original.',
                style: TextStyle(fontSize: 12, color: FbColors.textMuted),
              ),
              CheckboxListTile(
                value: _front,
                onChanged: (v) => setState(() => _front = v!),
                title: const Text('Citizenship certificate – front'),
              ),
              CheckboxListTile(
                value: _back,
                onChanged: (v) => setState(() => _back = v!),
                title: const Text('Citizenship certificate – back'),
              ),
              CheckboxListTile(
                value: _photo,
                onChanged: (v) => setState(() => _photo = v!),
                title: const Text('Customer photo'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v!),
              title: const Text('The customer has read (or heard) the account terms and agrees to them.'),
            ),
          ),
        ],
      );
}
