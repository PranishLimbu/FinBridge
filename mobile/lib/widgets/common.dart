import 'package:flutter/material.dart';

import '../theme.dart';

/// Red strip shown on every screen so nobody mistakes the prototype for a real service (NFR-10).
class SimulatedBanner extends StatelessWidget {
  const SimulatedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: FbColors.danger,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: const Text(
        'DEMO – NO REAL MONEY',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

/// FinBridge logo: navy tile with a bridge icon, the name, and "AGENT BANKING" in mint.
class FbLogo extends StatelessWidget {
  const FbLogo({super.key, this.compact = false});

  /// Smaller version for app bars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tile = compact ? 32.0 : 46.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tile,
          height: tile,
          decoration: BoxDecoration(color: FbColors.primary, borderRadius: BorderRadius.circular(compact ? 8 : 12)),
          child: Icon(Icons.account_balance, color: FbColors.accent, size: tile * 0.55),
        ),
        SizedBox(width: compact ? 8 : 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FinBridge',
                style: TextStyle(
                    fontSize: compact ? 15 : 22, fontWeight: FontWeight.w800, color: FbColors.primary, height: 1.1)),
            Text('AGENT BANKING',
                style: TextStyle(
                    fontSize: compact ? 8 : 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: FbColors.accentDark)),
          ],
        ),
      ],
    );
  }
}

/// Small label with an icon, shown above a form field (Figma style).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: FbColors.primary), const SizedBox(width: 6)],
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FbColors.primary)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.title, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: FbColors.primary)),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      'confirmed' || 'verified' || 'active' || 'balanced' => (_label(status), FbColors.success, FbColors.successBg),
      'awaiting_otp' || 'pending_review' || 'pending' => (_label(status), FbColors.warning, FbColors.warningBg),
      _ => (_label(status), FbColors.danger, FbColors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  static String _label(String s) => switch (s) {
        'confirmed' => 'Confirmed',
        'awaiting_otp' => 'Pending OTP',
        'pending_review' => 'KYC pending',
        'verified' => 'KYC verified',
        'rejected' => 'KYC rejected',
        'pending' => 'Pending',
        'active' => 'Active',
        'cancelled' => 'Cancelled',
        'failed' => 'Failed',
        'balanced' => 'Balanced',
        'mismatch' => 'Mismatch',
        _ => s,
      };
}

class MessageBox extends StatelessWidget {
  const MessageBox(this.message, {super.key, this.error = true});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? FbColors.dangerBg : FbColors.successBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline,
              color: error ? FbColors.danger : FbColors.success, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: error ? FbColors.danger : FbColors.success))),
        ],
      ),
    );
  }
}

/// Label with a Nepali translation underneath, e.g. "First name (पहिलो नाम)".
String bi(String en, String ne) => '$en ($ne)';

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: FbColors.textMuted))),
          Expanded(
            flex: 6,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          ),
        ],
      ),
    );
  }
}

/// Large on-screen keypad for amounts, easier to use at a counter than the system keyboard.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});

  /// Receives '0'–'9', 'C' (clear) or '<' (backspace).
  final void Function(String key) onKey;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '<'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final k in keys)
          Material(
            color: k == 'C' ? FbColors.dangerBg : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onKey(k),
              child: Center(
                child: k == '<'
                    ? const Icon(Icons.backspace_outlined, semanticLabel: 'Delete')
                    : Text(k,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: k == 'C' ? FbColors.danger : FbColors.primary)),
              ),
            ),
          ),
      ],
    );
  }
}
