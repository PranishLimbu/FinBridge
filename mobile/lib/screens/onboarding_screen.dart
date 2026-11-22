import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/bs_date.dart';
import '../widgets/bs_date_picker.dart';
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
  // Date of birth: the BS and AD fields are two views of one date and always stay in sync.
  final _dobBs = TextEditingController();
  final _dobAdText = TextEditingController();
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

  // Occupation master data (code + name). Until it loads, the plain text field is used.
  List<Place>? _occupations;
  String? _occupationCode, _occupationError;

  bool get _useOccupationList => _occupations != null && _occupations!.isNotEmpty;

  static const _provinces = ['Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim'];
  static const _steps = ['Personal', 'Family', 'Address', 'Documents'];

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadOccupations();
  }

  Future<void> _loadOccupations() async {
    try {
      final res = await context.read<Session>().api.get('/occupations') as Map<String, dynamic>;
      final list = [
        for (final o in (res['results'] as List).cast<Map<String, dynamic>>())
          Place(o['code'] as String, o['name'] as String, '', null),
      ];
      if (mounted) setState(() => _occupations = list);
    } on ApiException {/* keep the text field */}
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
    if (_step == 0 && _useOccupationList) {
      setState(() => _occupationError = _occupationCode == null ? 'Choose an occupation' : null);
      if (_occupationError != null) {
        if (_useLists) setState(() => _issueDistrictError = _issueDistrictId == null ? 'Choose the issue district' : null);
        return false;
      }
    }
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
      _first, _middle, _last, _dobBs, _dobAdText, _occupation, _mobile, _citizenship, _issueBs, _issueDistrict, _pan,
      _father, _mother, _grandfather, _spouse, _district, _municipality, _ward, _tole,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _name(String? v) =>
      _req(v) ?? (RegExp(r"^[A-Za-z .'-]+$").hasMatch(v!.trim()) ? null : 'Use letters only');
  /// Label for a mandatory field: "First name (पहिलो नाम) *".
  String _m(String en, String ne) => '${bi(en, ne)} *';

  String? _dobValidator(String? _) {
    if (_dobAd == null) return 'Choose the date of birth';
    if ((_age ?? 0) < 16) return 'The customer must be at least 16 years old';
    return null;
  }

  String? _issueDateValidator(String? v) {
    final d = NepaliDateTime.tryParse(v ?? '');
    if (v == null || v.isEmpty || d == null) return 'Choose the issue date';
    final dob = _dobAd == null ? null : adToBs(_dobAd!);
    if (dob != null && d.isBefore(dob)) return 'Cannot be before the date of birth';
    if (d.isAfter(todayBs())) return 'Cannot be in the future';
    return null;
  }

  /// Sets the date of birth and fills both the AD and the BS field.
  void _setDob(DateTime ad) => setState(() {
        _dobAd = DateTime(ad.year, ad.month, ad.day);
        _dobAdText.text = _iso(_dobAd!);
        _dobBs.text = formatBs(adToBs(_dobAd!));
      });

  Future<void> _pickDobBs() async {
    final today = todayBs();
    final d = await showBsDatePicker(
      context: context,
      initialDate: _dobAd == null ? NepaliDateTime(today.year - 30) : adToBs(_dobAd!),
      firstDate: NepaliDateTime(1975),
      lastDate: today,
      title: 'Date of birth (BS)',
    );
    if (d != null) _setDob(bsToAd(d));
  }

  Future<void> _pickDobAd() async {
    final today = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dobAd ?? DateTime(today.year - 30),
      firstDate: DateTime(1918),
      lastDate: today,
      helpText: 'Date of birth (AD)',
    );
    if (d != null) _setDob(d);
  }

  Future<void> _pickIssueDate() async {
    final today = todayBs();
    final first = _dobAd == null ? NepaliDateTime(1975) : adToBs(_dobAd!);
    var initial = NepaliDateTime.tryParse(_issueBs.text) ?? today;
    if (initial.isBefore(first)) initial = first;
    final d = await showBsDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
      title: 'Citizenship issue date (BS)',
    );
    if (d != null) setState(() => _issueBs.text = formatBs(d));
  }

  int? get _age {
    if (_dobAd == null) return null;
    final now = DateTime.now();
    var a = now.year - _dobAd!.year;
    if (now.month < _dobAd!.month || (now.month == _dobAd!.month && now.day < _dobAd!.day)) a--;
    return a;
  }

  void _next() {
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
      'occupation': _useOccupationList
          ? _occupations!.firstWhere((o) => o.id == _occupationCode).name
          : _occupation.text.trim(),
      if (_useOccupationList) 'occupationCode': _occupationCode,
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
              'The bank will check the details. Cash transactions work after approval.'),
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Fields marked * are required.',
                        style: TextStyle(fontSize: 12, color: FbColors.textMuted)),
                  ),
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

  /// A date field: tapping it (or the calendar icon) opens the date picker. Not typed by hand.
  Widget _dateField(TextEditingController c, String label, VoidCallback onPick,
          {String? Function(String?)? validator, String? helper}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          readOnly: true,
          onTap: onPick,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Tap to choose',
            helperText: helper,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Choose date',
              onPressed: onPick,
            ),
          ),
          validator: validator,
        ),
      );

  Widget _personal() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Personal details',
            child: Column(children: [
              _field(_first, _m('First name', 'पहिलो नाम'), validator: _name),
              _field(_middle, bi('Middle name (optional)', 'बीचको नाम')),
              _field(_last, _m('Last name', 'थर'), validator: _name),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(labelText: _m('Gender', 'लिङ्ग')),
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
                  decoration: InputDecoration(labelText: _m('Marital status', 'वैवाहिक स्थिति')),
                  items: const [
                    DropdownMenuItem(value: 'single', child: Text('Single (अविवाहित)')),
                    DropdownMenuItem(value: 'married', child: Text('Married (विवाहित)')),
                    DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                    DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                  ],
                  onChanged: (v) => setState(() => _marital = v!),
                ),
              ),
              _dateField(_dobBs, _m('Date of birth, BS', 'जन्म मिति वि.सं.'), _pickDobBs, validator: _dobValidator),
              _dateField(_dobAdText, _m('Date of birth, AD', 'जन्म मिति ई.सं.'), _pickDobAd,
                  validator: _dobValidator, helper: _dobAd == null ? null : 'Age ${_age ?? '-'}'),
              if (_useOccupationList)
                _placeMenu(
                  key: const ValueKey('occupation'),
                  label: _m('Occupation', 'पेशा'),
                  places: _occupations!,
                  selected: _occupationCode,
                  error: _occupationError,
                  onSelected: (code) => setState(() {
                    _occupationCode = code;
                    _occupationError = null;
                  }),
                )
              else
                _field(_occupation, _m('Occupation', 'पेशा'), validator: _req, hint: 'e.g. Agriculture / Farmer'),
              _field(_mobile, _m('Mobile number', 'मोबाइल नम्बर'),
                  keyboard: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) => RegExp(r'^9[78]\d{8}$').hasMatch(v ?? '') ? null : '10 digits starting 97 or 98'),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Citizenship',
            child: Column(children: [
              _field(_citizenship, _m('Citizenship certificate no.', 'नागरिकता नं.'),
                  hint: '27-01-78-04912',
                  validator: (v) => RegExp(r'^\d{1,3}(-\d{1,6}){1,4}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Use the format printed on the certificate'),
              _dateField(_issueBs, _m('Issue date, BS', 'जारी मिति वि.सं.'), _pickIssueDate,
                  validator: _issueDateValidator),
              if (_useLists)
                _placeMenu(
                  key: const ValueKey('issue-district'),
                  label: _m('Issue district', 'जारी जिल्ला'),
                  places: _locs!.districts,
                  selected: _issueDistrictId,
                  error: _issueDistrictError,
                  onSelected: (id) => setState(() {
                    _issueDistrictId = id;
                    _issueDistrictError = null;
                  }),
                )
              else
                _field(_issueDistrict, _m('Issue district', 'जारी जिल्ला'), validator: _req),
              _field(_pan, bi('PAN (optional)', 'स्थायी लेखा नं.'),
                  keyboard: TextInputType.number,
                  maxLength: 9,
                  validator: (v) => (v == null || v.isEmpty || RegExp(r'^\d{9}$').hasMatch(v)) ? null : 'PAN has 9 digits'),
            ]),
          ),
        ],
      );

  Widget _family() => SectionCard(
        title: 'Family details',
        child: Column(children: [
          _field(_father, _m('Father’s name', 'बुबाको नाम'), validator: _name),
          _field(_mother, _m('Mother’s name', 'आमाको नाम'), validator: _name),
          _field(_grandfather, _m('Grandfather’s name', 'हजुरबुबाको नाम'), validator: _name),
          if (_marital == 'married') _field(_spouse, _m('Spouse’s name', 'पति/पत्नीको नाम'), validator: _name),
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
          _field(_ward, _m('Ward no.', 'वडा नं.'),
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
          decoration: InputDecoration(labelText: _m('Province', 'प्रदेश')),
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
        label: _m('District', 'जिल्ला'),
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
        label: _m('Municipality / rural municipality', 'नगरपालिका / गाउँपालिका'),
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
            decoration: InputDecoration(labelText: _m('Province', 'प्रदेश')),
            items: [for (final p in _provinces) DropdownMenuItem(value: p, child: Text(p))],
            onChanged: (v) => setState(() => _province = v!),
          ),
        ),
        _field(_district, _m('District', 'जिल्ला'), validator: _req),
        _field(_municipality, _m('Municipality / rural municipality', 'नगरपालिका / गाउँपालिका'), validator: _req),
      ];

  Widget _documents() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Documents',
            child: Column(children: [
              const Text(
                'Tick each document after checking the original.',
                style: TextStyle(fontSize: 12, color: FbColors.textMuted),
              ),
              CheckboxListTile(
                value: _front,
                onChanged: (v) => setState(() => _front = v!),
                title: const Text('Citizenship certificate – front *'),
              ),
              CheckboxListTile(
                value: _back,
                onChanged: (v) => setState(() => _back = v!),
                title: const Text('Citizenship certificate – back *'),
              ),
              CheckboxListTile(
                value: _photo,
                onChanged: (v) => setState(() => _photo = v!),
                title: const Text('Customer photo *'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v!),
              title: const Text('Customer agrees to the account terms. *'),
            ),
          ),
        ],
      );
}
