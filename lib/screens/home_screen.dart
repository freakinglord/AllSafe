import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/safe_state.dart';
import 'unlock_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SafeState, bool>((s) => s.isDark);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<SafeState>().toggleTheme(),
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
              const _AllSafeLogo(),
              const SizedBox(height: 20),
              Text(
                'ALLSAFE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
                onPressed: () => _pick(context, UnlockMode.open),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('OPEN SAFE'),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _pick(context, UnlockMode.create),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CREATE NEW SAFE'),
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

  Future<void> _pick(BuildContext context, UnlockMode mode) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: mode == UnlockMode.open ? 'Select Safe Image' : 'Select Cover Image (PNG)',
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    final bytes =
        file.bytes ?? (path != null ? await File(path).readAsBytes() : null);
    if (bytes == null || (mode == UnlockMode.open && path == null)) return;
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnlockScreen(mode: mode, imagePath: path, imageBytes: bytes),
      ),
    );
  }
}

class _AllSafeLogo extends StatelessWidget {
  const _AllSafeLogo();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    const s = 72.0;
    const barH = s * 0.10;
    const barW = s * 0.54;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: s * 0.035),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(barW, barH, color),
            SizedBox(height: s * 0.05),
            _bar(barW, barH, color.withOpacity(0.35)),
            SizedBox(height: s * 0.05),
            _bar(barW, barH, color.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }

  Widget _bar(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
