import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_identifierController.text.trim().isEmpty) {
      _showMessage('Entrez votre email ou nom utilisateur.', false);
      return;
    }
    setState(() => _loading = true);
    final result = await context
        .read<AuthService>()
        .requestPasswordReset(_identifierController.text);
    setState(() {
      _loading = false;
      _codeSent = result['success'] == true;
    });
    final debugCode = result['debug_code'];
    _showMessage(
      debugCode == null
          ? result['message']
          : '${result['message']} Code test: $debugCode',
      result['success'] == true,
    );
  }

  Future<void> _confirmReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await context.read<AuthService>().confirmPasswordReset(
          _identifierController.text,
          _codeController.text,
          _passwordController.text,
        );
    setState(() => _loading = false);
    _showMessage(result['message'], result['success'] == true);
    if (result['success'] == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(dynamic message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message?.toString() ?? ''),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublie')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 72, color: Colors.deepPurple),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email ou nom utilisateur',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value != null && value.trim().isNotEmpty
                          ? null
                          : 'Ce champ est requis',
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _requestCode,
                  icon: const Icon(Icons.mail_outline),
                  label: Text(_codeSent ? 'Renvoyer le code' : 'Recevoir le code'),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Code recu',
                      prefixIcon: Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value != null && value.trim().length >= 4
                            ? null
                            : 'Code invalide',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) =>
                        value != null && value.length >= 8
                            ? null
                            : 'Minimum 8 caracteres',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _confirmReset,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Reinitialiser'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
