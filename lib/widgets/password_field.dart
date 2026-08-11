import 'package:flutter/material.dart';

/// A text field that obscures its content by default, with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool autofocus;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.autofocus = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
          color: const Color(0xFF555555),
        ),
      ),
      validator: widget.validator,
    );
  }
}
