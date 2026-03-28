import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/snippet.dart';
import '../services/snippet_service.dart';

class SnippetListScreen extends StatefulWidget {
  const SnippetListScreen({super.key});

  @override
  State<SnippetListScreen> createState() => _SnippetListScreenState();
}

class _SnippetListScreenState extends State<SnippetListScreen> {
  final _service = SnippetService();
  List<Snippet> _snippets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await _service.getSnippets();
    setState(() {
      _snippets = list;
      _isLoading = false;
    });
  }

  void _showEditDialog([Snippet? existing]) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final commandController = TextEditingController(text: existing?.command ?? '');
    bool autoEnter = existing?.autoEnter ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'New Snippet' : 'Edit Snippet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Button Label (e.g. Logs)'),
              ),
              TextField(
                controller: commandController,
                decoration: const InputDecoration(labelText: 'Command'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-Execute', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Presses enter automatically', style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: autoEnter,
                onChanged: (val) => setDialogState(() => autoEnter = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isEmpty || commandController.text.isEmpty) return;
                final snip = Snippet(
                  id: existing?.id ?? const Uuid().v4(),
                  label: labelController.text,
                  command: commandController.text,
                  autoEnter: autoEnter,
                );
                await _service.saveSnippet(snip);
                if (context.mounted) Navigator.pop(context);
                _load();
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Snippet snippet) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snippet'),
        content: Text('Remove "${snippet.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteSnippet(snippet.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MANAGE SNIPPETS')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _snippets.length,
              itemBuilder: (context, index) {
                final snippet = _snippets[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.code, color: Theme.of(context).primaryColor),
                    ),
                    title: Text(snippet.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      snippet.command,
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          onPressed: () => _showEditDialog(snippet),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _confirmDelete(snippet),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}