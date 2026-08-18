import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../state/safe_state.dart';
import '../widgets/password_field.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? account; // null = create mode

  const AddEditAccountScreen({super.key, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _notesCtrl;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _emailCtrl = TextEditingController(text: a?.email ?? '');
    _usernameCtrl = TextEditingController(text: a?.username ?? '');
    _passwordCtrl = TextEditingController(text: a?.password ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'EDIT ACCOUNT' : 'NEW ACCOUNT'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Account Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username / Login ID'),
            ),
            const SizedBox(height: 12),
            // Password field + generator button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PasswordField(
                    controller: _passwordCtrl,
                    label: 'Password *',
                    validator: (v) => v == null || v.isEmpty
                        ? 'Password is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Generate strong password',
                  child: InkWell(
                    onTap: _generatePassword,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: const Icon(Icons.casino_outlined,
                          color: Color(0xFF00FF41), size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? 'UPDATE ACCOUNT' : 'ADD ACCOUNT'),
            ),
          ],
        ),
      ),
    );
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '0123456789'
        r'!@#$%^&*()-_=+[]{}|;:,.<>?';
    final rng = Random.secure();
    final password =
        List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    _passwordCtrl.text = password;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<SafeState>();

    if (_isEdit) {
      final updated = widget.account!.copyWith(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        notes: _notesCtrl.text.trim(),
      );
      state.updateAccount(updated);
    } else {
      final account = Account.create(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        notes: _notesCtrl.text.trim(),
      );
      state.addAccount(account);
    }

    Navigator.pop(context);
  }
}
