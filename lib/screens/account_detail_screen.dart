import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../state/safe_state.dart';
import 'add_edit_account_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    // Reactively read the account from state so edits are reflected immediately
    final account = context
        .watch<SafeState>()
        .accounts
        .where((a) => a.id == widget.accountId)
        .firstOrNull;

    if (account == null) {
      // Account was deleted — go back
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.of(context).pop());
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditAccountScreen(account: account)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF453A)),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, account),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (account.email.isNotEmpty)
            _FieldCard(label: 'EMAIL', value: account.email),
          if (account.username.isNotEmpty)
            _FieldCard(label: 'USERNAME', value: account.username),
          _FieldCard(
            label: 'PASSWORD',
            value: _showPassword
                ? account.password
                : '•' * account.password.length.clamp(0, 24),
            copyValue: account.password,
            monospace: true,
            trailing: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 17,
              ),
              onPressed: () =>
                  setState(() => _showPassword = !_showPassword),
              color: const Color(0xFF555555),
              tooltip: _showPassword ? 'Hide' : 'Reveal',
            ),
          ),
          if (account.notes.isNotEmpty)
            _FieldCard(
                label: 'NOTES', value: account.notes, multiline: true),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete "${account.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SafeState>().deleteAccount(account.id);
      Navigator.pop(context);
    }
  }
}

// ── Field card widget ───────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final String? copyValue; // actual value to copy (defaults to [value])
  final bool monospace;
  final bool multiline;
  final Widget? trailing;

  const _FieldCard({
    required this.label,
    required this.value,
    this.copyValue,
    this.monospace = false,
    this.multiline = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: monospace ? 'monospace' : null,
                    fontSize: 14,
                    color: const Color(0xFFE0E0E0),
                    height: 1.4,
                  ),
                  maxLines: multiline ? null : 1,
                  overflow: multiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy, size: 15),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyValue ?? value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$label copied to clipboard'),
                duration: const Duration(seconds: 1),
              ));
            },
            color: const Color(0xFF333333),
            tooltip: 'Copy',
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
