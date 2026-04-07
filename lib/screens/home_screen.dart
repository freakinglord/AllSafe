import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/vault_state.dart';
import 'unlock_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<VaultState, bool>((s) => s.isDark);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<VaultState>().toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Icon(Icons.lock_outline, size: 56, color: Color(0xFF00FF41)),
              const SizedBox(height: 20),
              Text(
                'STEGAN VAULT',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF00FF41),
                      letterSpacing: 5,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'ENCRYPT · HIDE · RETRIEVE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  fontSize: 11,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 52),

              // Actions
              ElevatedButton.icon(
                onPressed: () => _openVault(context),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('OPEN VAULT'),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _createVault(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CREATE NEW VAULT'),
              ),

              const SizedBox(height: 52),
              Text(
                'Passwords are encrypted with AES-256-GCM\n'
                'and hidden inside PNG images using steganography.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  fontSize: 11,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVault(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Vault Image',
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    final bytes =
        file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
    if (bytes == null || path == null) return;
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnlockScreen(
          mode: UnlockMode.open,
          imagePath: path,
          imageBytes: bytes,
        ),
      ),
    );
  }

  Future<void> _createVault(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Cover Image (PNG)',
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    final bytes =
        file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
    if (bytes == null) return;
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnlockScreen(
          mode: UnlockMode.create,
          imagePath: path,
          imageBytes: bytes,
        ),
      ),
    );
  }
}
