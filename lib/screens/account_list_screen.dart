import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../state/safe_state.dart';
import 'account_detail_screen.dart';
import 'add_edit_account_screen.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SafeState>();

    final accounts = state.accounts
        .where((a) =>
            _query.isEmpty ||
            a.name.toLowerCase().contains(_query) ||
            a.email.toLowerCase().contains(_query) ||
            a.username.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 16),
            const SizedBox(width: 8),
            const Text('SAFE'),
            if (state.isDirty)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text('●',
                    style: TextStyle(color: Color(0xFFFF8800), fontSize: 10)),
              ),
          ],
        ),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.save_outlined,
                color: state.isDirty
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: 'Save Safe',
              onPressed: state.isDirty ? () => _saveSafe(context) : null,
            ),
          IconButton(
            icon: const Icon(Icons.lock_outlined),
            tooltip: 'Lock Safe',
            onPressed: () => _lockSafe(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: accounts.isEmpty
                ? _buildEmptyState(state)
                : ListView.separated(
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) => _AccountTile(account: accounts[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditAccountScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(SafeState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.key_off_outlined,
              size: 44, color: Color(0xFF222222)),
          const SizedBox(height: 14),
          const Text('No accounts stored yet',
              style: TextStyle(color: Color(0xFF444444))),
          const SizedBox(height: 6),
          if (state.needsSavePath)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Add accounts, then save the safe image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF333333), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveSafe(BuildContext context) async {
    final state = context.read<SafeState>();

    if (state.needsSavePath) {
      // New safe — ask where to save the stego image
      String? savePath;
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/safe.png';
      } else {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Safe Image As',
          fileName: 'safe.png',
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (savePath == null) return;
        if (!savePath.endsWith('.png')) savePath = '$savePath.png';
      }

      final ok = await state.saveToPath(savePath);
      if (!context.mounted) return;
      _snack(context, ok ? 'Safe saved to $savePath' : state.error ?? 'Save failed', ok);
    } else {
      final ok = await state.saveToPath(state.imagePath!);
      if (!context.mounted) return;
      _snack(context, ok ? 'Safe saved' : state.error ?? 'Save failed', ok);
    }
  }

  Future<void> _lockSafe(BuildContext context) async {
    final state = context.read<SafeState>();
    if (state.isDirty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Lock the safe and discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Colors.white),
              child: const Text('Lock & Discard'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    state.lockSafe();
    if (!context.mounted) return;
    // Pop back to HomeScreen (the first route on the stack)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _snack(BuildContext context, String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          success ? const Color(0xFF1A1A1A) : const Color(0xFF3D0000),
    ));
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final initial =
        account.name.isNotEmpty ? account.name[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF1A1A1A),
        child: Text(
          initial,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(account.name),
      subtitle: Text(
        account.email.isNotEmpty ? account.email : account.username,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: Color(0xFF2A2A2A), size: 20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AccountDetailScreen(accountId: account.id)),
      ),
    );
  }
}
