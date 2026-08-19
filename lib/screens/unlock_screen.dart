import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/safe_state.dart';
import '../widgets/password_field.dart';
import 'account_list_screen.dart';

enum UnlockMode { open, create }

class UnlockScreen extends StatefulWidget {
  final UnlockMode mode;
  final String? imagePath;
  final Uint8List imageBytes;

  const UnlockScreen({
    super.key,
    required this.mode,
    this.imagePath,
    required this.imageBytes,
  });

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isWorking = false;

  bool get _isCreate => widget.mode == UnlockMode.create;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = context.select<SafeState, String?>((s) => s.error);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? 'CREATE SAFE' : 'OPEN SAFE'),
        leading: const BackButton(),
      ),
      body: Center(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selected image path display
                if (widget.imagePath != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined,
                            color: Theme.of(context).colorScheme.primary, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.imagePath!,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                PasswordField(
                  controller: _passwordCtrl,
                  label: 'Master Password',
                  autofocus: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (_isCreate && v.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),

                if (_isCreate) ...[
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _confirmCtrl,
                    label: 'Confirm Password',
                    validator: (v) {
                      if (v != _passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                // Error banner
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      error,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 20),

                if (_isWorking)
                  const Column(
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        'Deriving key — this takes a moment...',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Color(0xFF444444), fontSize: 12),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isCreate ? 'CREATE SAFE' : 'UNLOCK'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isWorking = true);
    final state = context.read<SafeState>()..clearError();

    bool success;

    if (_isCreate) {
      state.createSafe(widget.imageBytes, _passwordCtrl.text, imagePath: widget.imagePath);
      success = true;
    } else {
      await state.openSafe(
        widget.imagePath ?? '',
        widget.imageBytes,
        _passwordCtrl.text,
      );
      success = state.isUnlocked;
    }

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountListScreen()),
      );
    } else {
      setState(() => _isWorking = false);
    }
  }
}
