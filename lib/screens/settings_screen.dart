import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart'; 
import '../services/settings_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../main.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _keepAwake = true;
  bool _requireAppLock = false;
  String _cursorStyle = 'Block'; 

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isLocked = await SettingsService().isAppLockEnabled();
    final cursor = await SettingsService().getCursorStyle();
    setState(() {
      _requireAppLock = isLocked;
      _cursorStyle = cursor;
    });
  }

  void _updateBaseTheme(String base) async {
    final current = themeNotifier.value;
    final newConfig = ThemeConfig(baseTheme: base, accentColor: current.accentColor);
    themeNotifier.value = newConfig;
    await SettingsService().saveThemeConfig(newConfig);
  }

  void _updateAccentColor(String accent) async {
    final current = themeNotifier.value;
    final newConfig = ThemeConfig(baseTheme: current.baseTheme, accentColor: accent);
    themeNotifier.value = newConfig;
    await SettingsService().saveThemeConfig(newConfig);
  }

  void _showExportDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Vault', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will create a highly encrypted AES backup of all your servers, keys, and snippets.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'WARNING: If you forget this password, your backup cannot be recovered by anyone.',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Backup Password', errorText: errorText),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  setDialogState(() => errorText = 'Password cannot be empty');
                  return;
                }
                if (passwordController.text != confirmController.text) {
                  setDialogState(() => errorText = 'Passwords do not match');
                  return;
                }

                Navigator.pop(context); 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Encrypting vault...')),
                );

                try {
                  await ExportService().exportVault(passwordController.text);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              },
              child: Text('ENCRYPT & EXPORT', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
      );

      if (result != null && result.files.single.path != null) {
        if (!mounted) return;
        _showImportPasswordDialog(result.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selection failed: $e')),
      );
    }
  }

  void _showImportPasswordDialog(String filePath) {
    final passwordController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Decrypt Vault', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the password used to encrypt this backup.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Backup Password', errorText: errorText),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  setDialogState(() => errorText = 'Password required');
                  return;
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Decrypting and restoring...')),
                );

                try {
                  await ExportService().importVault(filePath, passwordController.text);
                  
                  final restoredTheme = await SettingsService().getThemeConfig();
                  themeNotifier.value = restoredTheme;

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restore complete!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Decryption failed. Incorrect password or corrupt file.')),
                    );
                  }
                }
              },
              child: Text('RESTORE', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAppLock(bool desiredState) async {
    final LocalAuthentication auth = LocalAuthentication();
    
    try {
      final String reason = desiredState 
          ? 'Authenticate to enable SmoothSSH App Lock' 
          : 'Authenticate to disable SmoothSSH App Lock';

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        setState(() => _requireAppLock = desiredState);
        globalIsAppLocked = desiredState; 
        await SettingsService().setAppLockEnabled(desiredState);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(desiredState ? 'App Lock Enabled.' : 'App Lock Disabled.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed or canceled. Setting unchanged.')),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
      ),
    );
  }

  Widget _buildSettingsBlock({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          
          _buildSectionHeader('BASE THEME'),
          _buildSettingsBlock(
            children: [
              _buildBaseTile('Light Mode', 'light', Icons.light_mode),
              const Divider(height: 1),
              _buildBaseTile('Dark Mode (Default)', 'dark', Icons.dark_mode),
              const Divider(height: 1),
              _buildBaseTile('Pure OLED', 'oled', Icons.contrast),
            ],
          ),

          _buildSectionHeader('ACCENT COLOR'),
          _buildSettingsBlock(
            children: [
              _buildAccentTile('Modern Blue', 'blue', Colors.blueAccent),
              const Divider(height: 1),
              _buildAccentTile('Classic Gold', 'gold', const Color(0xFFEBC137)),
              const Divider(height: 1),
              _buildAccentTile('Terminal Green', 'green', Colors.greenAccent),
              const Divider(height: 1),
              _buildAccentTile('Alert Red', 'red', Colors.redAccent),
            ],
          ),

          _buildSectionHeader('TERMINAL'),
          _buildSettingsBlock(
            children: [
              SwitchListTile(
                title: const Text('Keep Screen Awake'),
                subtitle: const Text('Prevent display from sleeping during sessions', style: TextStyle(color: Colors.grey, fontSize: 12)),
                value: _keepAwake,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) => setState(() => _keepAwake = val),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Cursor Style'),
                subtitle: Text(_cursorStyle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Block', 'Underline', 'Bar'].map((style) => ListTile(
                          title: Text(style),
                          trailing: _cursorStyle == style 
                              ? Icon(Icons.check, color: Theme.of(context).primaryColor) 
                              : null,
                          onTap: () async {
                            await SettingsService().setCursorStyle(style);
                            setState(() => _cursorStyle = style);
                            if (context.mounted) Navigator.pop(context);
                          },
                        )).toList(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Font Size Scaling'),
                subtitle: const Text('Use device volume buttons', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Icon(Icons.volume_up, color: Theme.of(context).primaryColor),
              ),
            ],
          ),

          _buildSectionHeader('SECURITY & VAULT'),
          _buildSettingsBlock(
            children: [
              SwitchListTile(
                title: const Text('App Lock'),
                subtitle: const Text('Require PIN or Biometrics to open SmoothSSH', style: TextStyle(color: Colors.grey, fontSize: 12)),
                value: _requireAppLock,
                activeColor: Theme.of(context).primaryColor,
                onChanged: _toggleAppLock,
              ),
              if (_requireAppLock) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield, color: Colors.grey),
                  title: const Text('Secure Lock Active'),
                  subtitle: const Text('Using Android native device credentials'),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.grey),
                title: const Text('Export Encrypted Vault'),
                subtitle: const Text('Backup connections and identities', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: _showExportDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.grey),
                title: const Text('Import Vault'),
                subtitle: const Text('Restore from a .smoothvault backup', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: _handleImport,
              ),
            ],
          ),

          _buildSectionHeader('ABOUT'),
          _buildSettingsBlock(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline, color: Colors.grey),
                title: Text('SmoothSSH'),
                subtitle: Text('Version 0.1.5 - Atomic Axolotl', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.grey),
                title: const Text('Open Source Licenses'),
                subtitle: const Text('The amazing tech powering this app', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'SmoothSSH',
                    applicationVersion: '0.1.5-alpha - Atomic Axolotl',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(Icons.terminal, size: 48, color: Theme.of(context).primaryColor),
                    ),
                    applicationLegalese: '© 2026 SmoothSSH\nBuilt for sysadmins, by sysadmins.',
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.grey),
                title: const Text('View Source on GitHub'),
                trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 16),
                onTap: () {},
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildBaseTile(String title, String baseKey, IconData icon) {
    return ValueListenableBuilder<ThemeConfig>(
      valueListenable: themeNotifier,
      builder: (context, currentConfig, _) {
        return RadioListTile<String>(
          title: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
          value: baseKey,
          groupValue: currentConfig.baseTheme,
          activeColor: Theme.of(context).primaryColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          onChanged: (String? value) {
            if (value != null) _updateBaseTheme(value);
          },
        );
      },
    );
  }

  Widget _buildAccentTile(String title, String accentKey, Color previewColor) {
    return ValueListenableBuilder<ThemeConfig>(
      valueListenable: themeNotifier,
      builder: (context, currentConfig, _) {
        return RadioListTile<String>(
          title: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: previewColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
          value: accentKey,
          groupValue: currentConfig.accentColor,
          activeColor: previewColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          onChanged: (String? value) {
            if (value != null) _updateAccentColor(value);
          },
        );
      },
    );
  }
}