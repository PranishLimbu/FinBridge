import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../l10n/l10n.dart';
import '../theme.dart';
import '../utils/bs_date.dart';

/// Shows a Bikram Sambat (BS) date picker: year, month and day lists, with the real number of
/// days in each Nepali month and the matching AD date underneath. Returns null on cancel.
Future<NepaliDateTime?> showBsDatePicker({
  required BuildContext context,
  required NepaliDateTime firstDate,
  required NepaliDateTime lastDate,
  NepaliDateTime? initialDate,
  String? title,
}) =>
    showDialog<NepaliDateTime>(
      context: context,
      builder: (_) => _BsDateDialog(
        first: _dateOnly(firstDate),
        last: _dateOnly(lastDate),
        initial: _dateOnly(initialDate ?? lastDate),
        title: title ?? context.l10n.chooseDateBs,
      ),
    );

NepaliDateTime _dateOnly(NepaliDateTime d) => NepaliDateTime(d.year, d.month, d.day);

class _BsDateDialog extends StatefulWidget {
  const _BsDateDialog({required this.first, required this.last, required this.initial, required this.title});

  final NepaliDateTime first, last, initial;
  final String title;

  @override
  State<_BsDateDialog> createState() => _BsDateDialogState();
}

class _BsDateDialogState extends State<_BsDateDialog> {
  late int _year, _month, _day;

  @override
  void initState() {
    super.initState();
    var d = widget.initial;
    if (d.isBefore(widget.first)) d = widget.first;
    if (d.isAfter(widget.last)) d = widget.last;
    _year = d.year;
    _month = d.month;
    _day = d.day;
  }

  int get _daysInMonth => NepaliDateTime(_year, _month).totalDays;

  int get _firstMonth => _year == widget.first.year ? widget.first.month : 1;
  int get _lastMonth => _year == widget.last.year ? widget.last.month : 12;
  int get _firstDay => _year == widget.first.year && _month == widget.first.month ? widget.first.day : 1;
  int get _lastDay => _year == widget.last.year && _month == widget.last.month ? widget.last.day : _daysInMonth;

  /// Keeps month and day inside the allowed range after the year or month changes.
  void _clamp() {
    _month = _month.clamp(_firstMonth, _lastMonth);
    _day = _day.clamp(_firstDay, _lastDay);
  }

  NepaliDateTime get _selected => NepaliDateTime(_year, _month, _day);

  String _ad(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _dropdown(String label, int value, Iterable<int> values, String Function(int) text, ValueChanged<int> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<int>(
          key: ValueKey('$label-$_year-$_month'),
          initialValue: value,
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: InputDecoration(labelText: label),
          items: [for (final v in values) DropdownMenuItem(value: v, child: Text(text(v)))],
          onChanged: (v) => setState(() {
            onChanged(v!);
            _clamp();
          }),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final months = l10n.bsMonths;
    final years = [for (var y = widget.last.year; y >= widget.first.year; y--) y]; // newest first
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dropdown(l10n.bsYear, _year, years, (y) => '$y', (y) => _year = y),
            _dropdown(l10n.bsMonth, _month, [for (var m = _firstMonth; m <= _lastMonth; m++) m],
                (m) => months[m - 1], (m) => _month = m),
            _dropdown(l10n.bsDay, _day, [for (var d = _firstDay; d <= _lastDay; d++) d], (d) => '$d', (d) => _day = d),
            Text(
              l10n.bsEqualsAd(formatBs(_selected), _ad(bsToAd(_selected))),
              style: const TextStyle(fontSize: 13, color: FbColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _selected), child: Text(l10n.ok)),
      ],
    );
  }
}
