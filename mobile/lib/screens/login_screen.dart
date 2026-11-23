import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../l10n/l10n.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/language_switch.dart';

/// UC1 Log in (Figure 6 in the report). The agent's terminal comes from their profile in Firebase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _agentId = TextEditingController();
  final _pin = TextEditingController();
  bool _showPin = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _agentId.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<Session>().login(_agentId.text.trim(), _pin.text);
    } on ApiException catch (e) {
      final left = e.details?['attemptsRemaining'];
      setState(() => _error = left is int ? l10n.triesLeft(l10n.error(e), left) : l10n.error(e));
      _pin.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _forgotPin() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.forgotPinTitle),
        content: Text(l10n.forgotPinBody),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = switch (context.watch<Session>().logoutReason) {
      LogoutReason.sessionExpired => l10n.sessionExpired,
      LogoutReason.idle => l10n.idleLoggedOut,
      null => null,
    };
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(alignment: Alignment.centerRight, child: LanguageSwitch()),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: FbColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: FbColors.border),
                    ),
                    child: const FbLogo(),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: FbColors.primary)),
                const SizedBox(height: 4),
                Text(l10n.loginSubtitle,
                    textAlign: TextAlign.center, style: const TextStyle(color: FbColors.textMuted)),
                const SizedBox(height: 20),
                if (reason != null) ...[MessageBox(reason), const SizedBox(height: 12)],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FieldLabel(l10n.agentId, icon: Icons.badge_outlined),
                        TextFormField(
                          controller: _agentId,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(hintText: l10n.agentIdHint),
                          validator: (v) => (v == null || v.trim().length < 3) ? l10n.agentIdError : null,
                        ),
                        const SizedBox(height: 14),
                        FieldLabel(
                          l10n.pin,
                          icon: Icons.pin_outlined,
                          trailing: InkWell(
                            onTap: _forgotPin,
                            child: Text(l10n.forgotPin,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: FbColors.primary)),
                          ),
                        ),
                        TextFormField(
                          controller: _pin,
                          obscureText: !_showPin,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: l10n.pinHint,
                            counterText: '',
                            suffixIcon: IconButton(
                              tooltip: _showPin ? l10n.hidePin : l10n.showPin,
                              icon: Icon(_showPin ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showPin = !_showPin),
                            ),
                          ),
                          validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : l10n.pinSixDigits,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.neverSharePin, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
                        const SizedBox(height: 16),
                        if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                        FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.lock_outline),
                          label: Text(_busy ? l10n.checking : l10n.logIn),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.demoLoginHint,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: FbColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
