import 'package:flutter/material.dart';
import '../models/identity.dart';
import '../services/identity_service.dart';
import 'identity_edit_screen.dart';

class IdentityListScreen extends StatefulWidget {
  const IdentityListScreen({super.key});

  @override
  State<IdentityListScreen> createState() => _IdentityListScreenState();
}

class _IdentityListScreenState extends State<IdentityListScreen> {
  final _service = IdentityService();
  List<Identity> _identities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await _service.getIdentities();
    setState(() {
      _identities = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MANAGE IDENTITIES')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _identities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_outlined, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      const Text('No identities saved.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _identities.length,
                  itemBuilder: (context, index) {
                    final iden = _identities[index];
                    final hasKey = iden.privateKey != null && iden.privateKey!.isNotEmpty;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (hasKey ? Colors.amber : Colors.green).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasKey ? Icons.key : Icons.password, 
                            color: hasKey ? Colors.amber : Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(iden.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(iden.username, style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            await _service.deleteIdentity(iden.id);
                            _load();
                          },
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => IdentityEditScreen(existingIdentity: iden)),
                          );
                          if (result == true) _load();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IdentityEditScreen()),
          );
          if (result == true) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}