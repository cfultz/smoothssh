import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import '../models/connection.dart';
import '../services/connection_service.dart';
import '../services/session_manager.dart'; 
import 'terminal_screen.dart';
import 'add_connection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _connectionService = ConnectionService();
  List<Connection> _connections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    final list = await _connectionService.getConnections();
    setState(() {
      _connections = list;
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(Connection conn) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Remove "${conn.label}"?'),
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
      await _connectionService.deleteConnection(conn.id);
      _loadConnections();
    }
  }

  Future<void> _editConnection(Connection conn) async {
    final updatedConn = await Navigator.push<Connection>(
      context,
      CupertinoPageRoute(
        builder: (_) => AddConnectionScreen(existingConnection: conn),
      ),
    );

    if (updatedConn != null) {
      await _connectionService.saveConnection(updatedConn);
      _loadConnections();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALL SERVERS')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _connections.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dns_outlined, size: 64, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text('No connections saved.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadConnections,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _connections.length,
                itemBuilder: (context, index) {
                  final conn = _connections[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                        child: Icon(Icons.dns, color: Theme.of(context).primaryColor, size: 20),
                      ),
                      title: Text(conn.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${conn.host}:${conn.port}', style: const TextStyle(color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _editConnection(conn),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () => _confirmDelete(conn),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await _connectionService.incrementUsage(conn.id);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => const TerminalScreen()),
                          ).then((_) => _loadConnections());
                          
                          Future.delayed(const Duration(milliseconds: 350), () {
                            SessionManager().startSession(conn);
                          });
                        }
                      },
                      onLongPress: () => _editConnection(conn),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const AddConnectionScreen()),
          );
          if (result is Connection) {
            await _connectionService.saveConnection(result);
            _loadConnections();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}