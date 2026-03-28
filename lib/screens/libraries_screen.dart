import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryInfo {
  final String name;
  final String description;
  final String url;

  LibraryInfo({required this.name, required this.description, required this.url});
}

class LibrariesScreen extends StatelessWidget {
  LibrariesScreen({super.key});

  final List<LibraryInfo> _libraries = [
    LibraryInfo(
      name: 'xterm.dart',
      description: 'The core terminal emulator engine powering the SSH view.',
      url: 'https://github.com/TerminalStudio/xterm.dart',
    ),
    LibraryInfo(
      name: 'dartssh2',
      description: 'Pure Dart SSH client handling the secure socket layers and cryptography.',
      url: 'https://github.com/TerminalStudio/dartssh2',
    ),
    LibraryInfo(
      name: 'flutter_secure_storage',
      description: 'Hardware-backed Android Keystore integration for the identity vault.',
      url: 'https://pub.dev/packages/flutter_secure_storage',
    ),
    LibraryInfo(
      name: 'flutter_background',
      description: 'Persistent background execution and foreground service notifications.',
      url: 'https://pub.dev/packages/flutter_background',
    ),
    LibraryInfo(
      name: 'local_auth',
      description: 'Native Android biometric and device PIN authentication.',
      url: 'https://pub.dev/packages/local_auth',
    ),
    LibraryInfo(
      name: 'encrypt',
      description: 'AES-CBC encryption for secure vault exports.',
      url: 'https://pub.dev/packages/encrypt',
    ),
  ];

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the web browser.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPEN SOURCE'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _libraries.length,
        itemBuilder: (context, index) {
          final lib = _libraries[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.code, color: Theme.of(context).primaryColor),
              ),
              title: Text(lib.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(lib.description, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 18),
              onTap: () => _launchUrl(context, lib.url),
            ),
          );
        },
      ),
    );
  }
}