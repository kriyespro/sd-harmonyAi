import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const RegisterScreen({super.key, required this.onRegister, required this.onLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _passCtrl, _passConfirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _passConfirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final err = await auth.register(_emailCtrl.text.trim(), _passCtrl.text, _firstCtrl.text.trim(), _lastCtrl.text.trim());
    if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFf43f5e), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 24),
                const Text('Create account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Already have one? ', style: TextStyle(color: Color(0xFF6B7280))),
                  GestureDetector(onTap: widget.onLogin, child: const Text('Sign in', style: TextStyle(color: Color(0xFFf43f5e), fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14)),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(children: [
                  Expanded(child: TextFormField(controller: _firstCtrl, decoration: const InputDecoration(labelText: 'First Name'), validator: (v) => v?.isNotEmpty == true ? null : 'Required')),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _lastCtrl, decoration: const InputDecoration(labelText: 'Last Name'))),
                ]),
                const SizedBox(height: 16),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v?.contains('@') == true ? null : 'Valid email required'),
                const SizedBox(height: 16),
                TextFormField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (v) => (v?.length ?? 0) >= 8 ? null : 'Min 8 characters'),
                const SizedBox(height: 16),
                TextFormField(controller: _passConfirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password'), validator: (v) => v?.isNotEmpty == true ? null : 'Required'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 16),
                const Text('AI provides observations only — never diagnoses or accusations.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
