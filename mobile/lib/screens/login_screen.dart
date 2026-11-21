import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// UC1 Log in (Figure 6 in the report).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _agentId = TextEditingController();
  final _pin = TextEditingController();
  String _terminal = 'KTM-WARD-32';
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<Session>().login(_agentId.text.trim(), _pin.text, _terminal);
    } on ApiException catch (e) {
      final left = e.details?['attemptsRemaining'];
      setState(() => _error = left != null ? '${e.message}. $left attempt(s) left before the account locks.' : e.message);
      _pin.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = context.watch<Session>().logoutReason;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SimulatedBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Icon(Icons.account_balance, size: 56, color: FbColors.primary),
                      const SizedBox(height: 8),
                      const Text('FinBridge',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: FbColors.primary)),
                      const Text('Banking Without Boundaries',
                          textAlign: TextAlign.center, style: TextStyle(color: FbColors.textMuted)),
                      const Text('Authorised agent login',
                          textAlign: TextAlign.center, style: TextStyle(color: FbColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 24),
                      if (reason != null) ...[MessageBox(reason), const SizedBox(height: 12)],
                      DropdownButtonFormField<String>(
                        value: _terminal,
                        decoration: const InputDecoration(labelText: 'Assigned terminal'),
                        items: const [
                          DropdownMenuItem(value: 'KTM-WARD-32', child: Text('Koteshwor Point, Ward 32')),
                          DropdownMenuItem(value: 'KAV-DHU-01', child: Text('Dhulikhel Bazaar')),
                        ],
                        onChanged: (v) => setState(() => _terminal = v ?? _terminal),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _agentId,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Agent ID', hintText: 'e.g. AGT-98412'),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your agent ID' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pin,
                        obscureText: !_showPin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: '6-digit PIN',
                          counterText: '',
                          suffixIcon: IconButton(
                            tooltip: _showPin ? 'Hide PIN' : 'Show PIN',
                            icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPin = !_showPin),
                          ),
                        ),
                        validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'PIN must be 6 digits',
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 4),
                      const Text('Never share your PIN or a customer’s OTP with anyone.',
                          style: TextStyle(fontSize: 12, color: FbColors.textMuted)),
                      const SizedBox(height: 16),
                      if (_error != null) ...[MessageBox(_error!), const SizedBox(height: 12)],
                      FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock_outline),
                        label: Text(_busy ? 'Checking…' : 'Secure agent login'),
                      ),
                      const SizedBox(height: 24),
                      const Text('Demo login: AGT-98412 / PIN 123456',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: FbColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
