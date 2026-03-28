import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import '../models/connection.dart';
import '../models/identity.dart';
import '../services/identity_service.dart';

class AddConnectionScreen extends StatefulWidget {
  final Connection? existingConnection;

  const AddConnectionScreen({super.key, this.existingConnection});

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _groupController;
  
  Identity? _selectedIdentity;
  List<Identity> _identities = [];

  @override
  void initState() {
    super.initState();
    
    _labelController = TextEditingController(text: widget.existingConnection?.label ?? '');
    _hostController = TextEditingController(text: widget.existingConnection?.host ?? '');
    _portController = TextEditingController(text: widget.existingConnection?.port.toString() ?? '22');
    _groupController = TextEditingController(text: widget.existingConnection?.group ?? 'Default');

    _loadIdentities();
  }

  Future<void> _loadIdentities() async {
    final list = await IdentityService().getIdentities();
    setState(() {
      _identities = list;
      
      if (widget.existingConnection != null && _selectedIdentity == null) {
        try {
          _selectedIdentity = _identities.firstWhere((id) => id.id == widget.existingConnection!.identityId);
        } catch (e) {
          _selectedIdentity = null;
        }
      } 
      else if (_selectedIdentity != null) {
        try {
          _selectedIdentity = _identities.firstWhere((id) => id.id == _selectedIdentity!.id);
        } catch (e) {
          _selectedIdentity = null;
        }
      }
    });
  }

  void _showAddIdentityDialog() {
    final formKey = GlobalKey<FormState>();
    final nicknameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController(text: 'root');
    final passwordCtrl = TextEditingController();
    final privateKeyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Identity', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nicknameCtrl,
                  decoration: const InputDecoration(labelText: 'Nickname (e.g. Prod Keys)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  autofocus: true,
                ),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password (Optional)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: privateKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Private Key (PEM)',
                    hintText: '-----BEGIN PRIVATE KEY-----\n...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newIdentity = Identity(
                  id: const Uuid().v4(),
                  nickname: nicknameCtrl.text.trim(),
                  username: usernameCtrl.text.trim(),
                  password: passwordCtrl.text.isNotEmpty ? passwordCtrl.text : null,
                  privateKey: privateKeyCtrl.text.isNotEmpty ? privateKeyCtrl.text.trim() : null,
                );

                await IdentityService().saveIdentity(newIdentity);
                
                if (context.mounted) {
                  Navigator.pop(context); 
                  
                  setState(() => _selectedIdentity = newIdentity);
                  await _loadIdentities();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Identity "${newIdentity.nickname}" created!')),
                  );
                }
              }
            },
            child: Text('SAVE', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingConnection != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'EDIT CONNECTION' : 'NEW CONNECTION')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Nickname (e.g. Pi Cluster)'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Hostname or IP'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: 'Group / Folder',
                hintText: 'e.g. Home, Work, Docker Hosts',
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<Identity>(
                    value: _selectedIdentity,
                    hint: const Text('Select Identity'),
                    isExpanded: true, 
                    items: _identities.map((i) => DropdownMenuItem(
                      value: i, 
                      child: Text('${i.nickname} (${i.username})', overflow: TextOverflow.ellipsis)
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedIdentity = val),
                    validator: (v) => v == null ? 'Select an identity' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0), 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
                      onPressed: _showAddIdentityDialog,
                      tooltip: 'Quick Add Identity',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'UPDATE CONNECTION' : 'SAVE CONNECTION'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final conn = Connection(
        id: widget.existingConnection?.id ?? const Uuid().v4(),
        label: _labelController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        identityId: _selectedIdentity!.id,
        group: _groupController.text.trim(),
        usageCount: widget.existingConnection?.usageCount ?? 0,
      );
      Navigator.pop(context, conn);
    }
  }
}