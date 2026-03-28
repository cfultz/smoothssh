import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import '../models/identity.dart';
import '../services/identity_service.dart';

class IdentityEditScreen extends StatefulWidget {
  final Identity? existingIdentity;
  const IdentityEditScreen({super.key, this.existingIdentity});

  @override
  State<IdentityEditScreen> createState() => _IdentityEditScreenState();
}

class _IdentityEditScreenState extends State<IdentityEditScreen> {
  final _service = IdentityService();
  
  late TextEditingController _nickController;
  late TextEditingController _userController;
  late TextEditingController _passwordController;
  late TextEditingController _keyController;
  
  bool _useKey = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nickController = TextEditingController(text: widget.existingIdentity?.nickname ?? '');
    _userController = TextEditingController(text: widget.existingIdentity?.username ?? '');
    
    _useKey = widget.existingIdentity?.privateKey != null;
    
    if (_useKey) {
      _keyController = TextEditingController(text: widget.existingIdentity?.privateKey ?? '');
      _passwordController = TextEditingController(text: widget.existingIdentity?.password ?? '');
    } else {
      _keyController = TextEditingController();
      _passwordController = TextEditingController(text: widget.existingIdentity?.password ?? '');
    }
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        setState(() {
          _keyController.text = contents;
          _errorText = null;
        });
      }
    } catch (e) {
      setState(() => _errorText = 'Could not read file.');
    }
  }

  void _save() async {
    setState(() => _errorText = null);
    
    if (_nickController.text.isEmpty || _userController.text.isEmpty) {
      setState(() => _errorText = 'Nickname and Username are required.');
      return;
    }

    String cleanedKey = _keyController.text.trim();
    String? passphrase = _passwordController.text.isNotEmpty ? _passwordController.text : null;

    if (_useKey) {
      if (cleanedKey.isEmpty) {
        setState(() => _errorText = 'Private Key cannot be empty if switch is on.');
        return;
      }
      cleanedKey = cleanedKey.replaceAll(RegExp(r'\r\n'), '\n');
      cleanedKey = cleanedKey.replaceAllMapped(RegExp(r'(-----BEGIN[^-]+-----)([A-Za-z0-9+/=])'), (m) => '${m.group(1)}\n${m.group(2)}');
      cleanedKey = cleanedKey.replaceAllMapped(RegExp(r'([A-Za-z0-9+/=])(-----END)'), (m) => '${m.group(1)}\n${m.group(2)}');

      try {
        SSHKeyPair.fromPem(cleanedKey, passphrase);
      } catch (e) {
        setState(() => _errorText = 'Crypto Error: ${e.toString()}');
        return;
      }
    }

    final iden = Identity(
      id: widget.existingIdentity?.id ?? const Uuid().v4(),
      nickname: _nickController.text,
      username: _userController.text,
      password: _useKey ? passphrase : _passwordController.text,
      privateKey: _useKey ? cleanedKey : null,
    );
    
    await _service.saveIdentity(iden);
    if (mounted) Navigator.pop(context, true);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingIdentity == null ? 'New Identity' : 'Edit Identity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: ListView(
        children: [
          if (_errorText != null)
            Container(
              color: Colors.red[900],
              padding: const EdgeInsets.all(12),
              child: Text(_errorText!, style: const TextStyle(color: Colors.white)),
            ),

          _buildSectionHeader('IDENTITY'),
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                ListTile(
                  title: TextField(
                    controller: _nickController,
                    decoration: const InputDecoration(labelText: 'Nickname', border: InputBorder.none),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: TextField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Username', border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader('AUTHENTICATION'),
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use Private Key'),
                  value: _useKey,
                  onChanged: (val) {
                    setState(() {
                      _useKey = val;
                      _passwordController.clear();
                      _keyController.clear();
                    });
                  },
                ),
                const Divider(height: 1),
                if (!_useKey)
                  ListTile(
                    title: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', border: InputBorder.none),
                    ),
                  ),
                if (_useKey) ...[
                  ListTile(
                    title: const Text('Private Key Data', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: TextField(
                      controller: _keyController,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Paste PEM data here...', border: InputBorder.none),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: _importFile,
                      child: const Text('IMPORT FILE'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Passphrase (Optional)', border: InputBorder.none),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}