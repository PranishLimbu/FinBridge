import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../utils/age.dart';
import '../utils/picked_doc.dart';
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
  PickedDoc? _front, _back, _photo;
  bool _consent = false;
  final _picker = ImagePicker();

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

  // Fallback province names (sent to the server as data) if the location lists cannot load.
  static const _provinces = ['Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim'];

  AppLocalizations get l10n => context.l10n;
  List<String> get _steps => [l10n.stepPersonal, l10n.stepFamily, l10n.stepAddress, l10n.stepDocuments];

  /// Place name in the app's language: the Nepali name when shown in Nepali and one exists.
  String _placeName(Place p) => context.isNepali && p.nameNe.isNotEmpty ? p.nameNe : p.name;

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
      setState(() => _occupationError = _occupationCode == null ? l10n.chooseOccupation : null);
      if (_occupationError != null) {
        if (_useLists) setState(() => _issueDistrictError = _issueDistrictId == null ? l10n.chooseIssueDistrict : null);
        return false;
      }
    }
    if (!_useLists) return true;
    setState(() {
      if (_step == 0) _issueDistrictError = _issueDistrictId == null ? l10n.chooseIssueDistrict : null;
      if (_step == 2) {
        _districtError = _districtId == null ? l10n.chooseDistrict : null;
        _localBodyError = _localBodyId == null ? l10n.chooseMunicipality : null;
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

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? l10n.required : null;
  String? _name(String? v) => _req(v) ?? (RegExp(r"^[A-Za-z .'-]+$").hasMatch(v!.trim()) ? null : l10n.lettersOnly);

  /// Label for a mandatory field: "First name *".
  String _m(String label) => '$label *';

  String? _dobValidator(String? _) {
    if (_dobAd == null) return l10n.chooseDob;
    if (!oldEnoughToOnboard(_dobAd!)) return l10n.minAge16;
    return null;
  }

  String? _issueDateValidator(String? v) {
    final d = NepaliDateTime.tryParse(v ?? '');
    if (v == null || v.isEmpty || d == null) return l10n.chooseIssueDate;
    final dob = _dobAd == null ? null : adToBs(_dobAd!);
    if (dob != null && d.isBefore(dob)) return l10n.notBeforeDob;
    if (d.isAfter(todayBs())) return l10n.notInFuture;
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
      title: context.l10n.dobBsPickerTitle,
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
      helpText: context.l10n.dobAdPickerTitle,
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
      title: context.l10n.issueDatePickerTitle,
    );
    if (d != null) setState(() => _issueBs.text = formatBs(d));
  }

  int? get _age => _dobAd == null ? null : ageInYears(_dobAd!, nepalToday());

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
    if (_front == null || _back == null || _photo == null) {
      setState(() => _error = l10n.documentsMissing);
      return;
    }
    if (!_consent) {
      setState(() => _error = l10n.mustAgree);
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
          title: Text(l10n.applicationSubmitted),
          content: Text(l10n.applicationSubmittedBody('${res['customerId']}', '${res['accountMasked']}')),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = l10n.error(e));
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
          title: Text(l10n.onboardingTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.back,
            onPressed: _stepBack,
          ),
        ),
        body: Column(
          children: [
            _stepper(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l10n.requiredNote, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
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
                    child: Text(_busy
                        ? l10n.submitting
                        : _step < 3
                            ? l10n.continueTo(_steps[_step + 1])
                            : l10n.submitForReview),
                  ),
                  if (_step > 0) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : _stepBack,
                      child: Text(l10n.back),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
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
            hintText: context.l10n.tapToChoose,
            helperText: helper,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: context.l10n.chooseDate,
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
            title: l10n.personalDetails,
            child: Column(children: [
              _field(_first, _m(l10n.firstName), validator: _name),
              _field(_middle, l10n.middleNameOptional),
              _field(_last, _m(l10n.lastName), validator: _name),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(labelText: _m(l10n.gender)),
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(l10n.male)),
                    DropdownMenuItem(value: 'female', child: Text(l10n.female)),
                    DropdownMenuItem(value: 'other', child: Text(l10n.otherGender)),
                  ],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _marital,
                  decoration: InputDecoration(labelText: _m(l10n.maritalStatus)),
                  items: [
                    DropdownMenuItem(value: 'single', child: Text(l10n.single)),
                    DropdownMenuItem(value: 'married', child: Text(l10n.married)),
                    DropdownMenuItem(value: 'widowed', child: Text(l10n.widowed)),
                    DropdownMenuItem(value: 'divorced', child: Text(l10n.divorced)),
                  ],
                  onChanged: (v) => setState(() => _marital = v!),
                ),
              ),
              _dateField(_dobBs, _m(l10n.dobBs), _pickDobBs, validator: _dobValidator),
              _dateField(_dobAdText, _m(l10n.dobAd), _pickDobAd,
                  validator: _dobValidator, helper: _dobAd == null ? null : l10n.ageYears(_age ?? 0)),
              if (_useOccupationList)
                _placeMenu(
                  key: const ValueKey('occupation'),
                  label: _m(l10n.occupation),
                  places: _occupations!,
                  selected: _occupationCode,
                  error: _occupationError,
                  onSelected: (code) => setState(() {
                    _occupationCode = code;
                    _occupationError = null;
                  }),
                )
              else
                _field(_occupation, _m(l10n.occupation), validator: _req, hint: l10n.occupationHint),
              _field(_mobile, _m(l10n.mobileNumber),
                  keyboard: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) => RegExp(r'^9[78]\d{8}$').hasMatch(v ?? '') ? null : l10n.mobileError),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.citizenship,
            child: Column(children: [
              _field(_citizenship, _m(l10n.citizenshipNo),
                  hint: '27-01-78-04912',
                  validator: (v) => RegExp(r'^\d{1,3}(-\d{1,6}){1,4}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : l10n.citizenshipFormatError),
              _dateField(_issueBs, _m(l10n.issueDateBs), _pickIssueDate,
                  validator: _issueDateValidator),
              if (_useLists)
                _placeMenu(
                  key: const ValueKey('issue-district'),
                  label: _m(l10n.issueDistrict),
                  places: _locs!.districts,
                  selected: _issueDistrictId,
                  error: _issueDistrictError,
                  onSelected: (id) => setState(() {
                    _issueDistrictId = id;
                    _issueDistrictError = null;
                  }),
                )
              else
                _field(_issueDistrict, _m(l10n.issueDistrict), validator: _req),
              _field(_pan, l10n.panOptional,
                  keyboard: TextInputType.number,
                  maxLength: 9,
                  validator: (v) => (v == null || v.isEmpty || RegExp(r'^\d{9}$').hasMatch(v)) ? null : l10n.panError),
            ]),
          ),
        ],
      );

  Widget _family() => SectionCard(
        title: l10n.familyDetails,
        child: Column(children: [
          _field(_father, _m(l10n.fatherName), validator: _name),
          _field(_mother, _m(l10n.motherName), validator: _name),
          _field(_grandfather, _m(l10n.grandfatherName), validator: _name),
          if (_marital == 'married') _field(_spouse, _m(l10n.spouseName), validator: _name),
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
          hintText: hint ?? context.l10n.typeToSearch,
          errorText: error,
          dropdownMenuEntries: [
            for (final p in places)
              DropdownMenuEntry(value: p.id, label: _placeName(p)),
          ],
          onSelected: onSelected,
        ),
      );

  Widget _address() => SectionCard(
        title: l10n.permanentAddress,
        child: Column(children: [
          if (_useLists) ..._addressLists() else ..._addressText(),
          _field(_ward, _m(l10n.wardNo),
              keyboard: TextInputType.number,
              maxLength: 2,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1 || n > 35) ? l10n.wardError : null;
              }),
          _field(_tole, l10n.toleOptional),
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
          decoration: InputDecoration(labelText: _m(l10n.province)),
          items: [
            for (final p in locs.provinces) DropdownMenuItem(value: p.id, child: Text(_placeName(p))),
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
        label: _m(l10n.district),
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
        label: _m(l10n.municipality),
        places: bodies,
        selected: _localBodyId,
        error: _localBodyError,
        hint: _districtId == null ? l10n.chooseDistrictFirst : l10n.inThisDistrict(bodies.length),
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
            decoration: InputDecoration(labelText: _m(l10n.province)),
            items: [for (final p in _provinces) DropdownMenuItem(value: p, child: Text(p))],
            onChanged: (v) => setState(() => _province = v!),
          ),
        ),
        _field(_district, _m(l10n.district), validator: _req),
        _field(_municipality, _m(l10n.municipality), validator: _req),
      ];

  /// Lets the agent take a photo with the camera or choose an existing image file.
  Future<void> _pickDoc(ImageSource source, void Function(PickedDoc) assign) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 55,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final mime = x.mimeType ?? _mimeFromName(x.name);
      if (!mounted) return;
      setState(() {
        _error = null;
        assign(PickedDoc(bytes: bytes, name: x.name, contentType: mime));
      });
    } catch (e) {
      if (mounted) setState(() => _error = l10n.imageError('$e'));
    }
  }

  String _mimeFromName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Widget _docTile(String title, PickedDoc? doc, void Function(PickedDoc?) set) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (doc != null)
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(doc.bytes, width: 88, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${doc.name}\n${(doc.bytes.length / 1024).round()} KB',
                  style: const TextStyle(fontSize: 12, color: FbColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            IconButton(tooltip: l10n.removeFile, onPressed: _busy ? null : () => setState(() => set(null)), icon: const Icon(Icons.close)),
          ])
        else
          Text(l10n.notAddedYet, style: TextStyle(fontSize: 12, color: FbColors.danger)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _pickDoc(ImageSource.camera, set),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(doc == null ? l10n.takePhoto : l10n.retakePhoto),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _pickDoc(ImageSource.gallery, set),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.uploadFile),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _documents() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: l10n.documents,
            child: Column(children: [
              Text(l10n.documentsHelp, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
              _docTile(_m(l10n.citizenshipFront), _front, (d) => _front = d),
              const Divider(height: 8),
              _docTile(_m(l10n.citizenshipBack), _back, (d) => _back = d),
              const Divider(height: 8),
              _docTile(_m(l10n.customerPhoto), _photo, (d) => _photo = d),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v!),
              title: Text(_m(l10n.consentTerms)),
            ),
          ),
        ],
      );
}
