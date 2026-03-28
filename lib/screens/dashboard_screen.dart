import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:uuid/uuid.dart';
import '../models/connection.dart';
import '../models/identity.dart';
import '../services/connection_service.dart';
import '../services/identity_service.dart';
import '../services/session_manager.dart'; 
import 'home_screen.dart'; 
import 'identity_list_screen.dart';
import 'snippet_list_screen.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';
import 'add_connection_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _connectionService = ConnectionService();
  Map<String, List<Connection>> _groupedConnections = {}; 
  List<Connection> _frequentConnections = [];

  @override
  void initState() {
    super.initState();
    _loadAndGroup();
  }

  Future<void> _loadAndGroup() async {
    final all = await _connectionService.getConnections();
    final Map<String, List<Connection>> groups = {};
    
    for (var conn in all) {
      groups.putIfAbsent(conn.group, () => []).add(conn);
    }

    all.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    setState(() {
      _groupedConnections = groups;
      _frequentConnections = all.where((c) => c.usageCount > 0).take(4).toList();
    });
  }

  void _connect(Connection conn) {
    _connectionService.incrementUsage(conn.id);
    
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const TerminalScreen()),
    ).then((_) => _loadAndGroup()); 

    Future.delayed(const Duration(milliseconds: 350), () {
      SessionManager().startSession(conn);
    });
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
      _loadAndGroup();
    }
  }

  void _showQuickConnectDialog() async {
    final identities = await IdentityService().getIdentities();
    final inputController = TextEditingController();
    Identity? selectedIdentity;
    String oneTimePassword = '';
    bool useOneTimeAuth = true;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Quick Connect', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: inputController,
                    decoration: const InputDecoration(
                      labelText: 'Target',
                      hintText: 'user@192.168.1.50:22',
                      prefixIcon: Icon(Icons.terminal),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  const Text('AUTHENTICATION', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  DropdownButtonFormField<Identity?>(
                    decoration: const InputDecoration(labelText: 'Saved Identity'),
                    value: selectedIdentity,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('One-Time Password / None')),
                      ...identities.map((i) => DropdownMenuItem(value: i, child: Text(i.nickname))).toList(),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedIdentity = val;
                        useOneTimeAuth = val == null;
                      });
                    },
                  ),
                  if (useOneTimeAuth) ...[
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (Optional)',
                        hintText: 'Leave blank for public keys',
                      ),
                      onChanged: (val) => oneTimePassword = val,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final input = inputController.text.trim();
                  if (input.isEmpty) return;

                  String user = 'root'; 
                  String host = input;
                  int port = 22;

                  if (host.contains('@')) {
                    final parts = host.split('@');
                    user = parts[0];
                    host = parts[1];
                  }

                  if (host.contains(':')) {
                    final parts = host.split(':');
                    host = parts[0];
                    port = int.tryParse(parts[1]) ?? 22;
                  }

                  final tempConn = Connection(
                    id: 'quick_connect',
                    label: 'Quick: $host',
                    host: host,
                    port: port,
                    identityId: 'temp', 
                  );

                  final tempIden = selectedIdentity ?? Identity(
                    id: 'temp',
                    nickname: 'One Time',
                    username: user,
                    password: oneTimePassword,
                  );

                  Navigator.pop(context);
                  
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const TerminalScreen()),
                  );

                  Future.delayed(const Duration(milliseconds: 350), () {
                    SessionManager().startSession(tempConn, directIdentity: tempIden);
                  });
                },
                child: const Text('CONNECT'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmoothSSH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAndGroup,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            children: [
              InkWell(
                onTap: _showQuickConnectDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.terminal, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 16),
                      const Text(
                        '> quick connect...',
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolButton(Icons.dns, 'Servers', () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => const HomeScreen())).then((_) => _loadAndGroup());
                  }),
                  _buildToolButton(Icons.vpn_key, 'Identities', () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => const IdentityListScreen()));
                  }),
                  _buildToolButton(Icons.code, 'Snippets', () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => const SnippetListScreen()));
                  }),
                  _buildToolButton(Icons.settings, 'Settings', () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),

              const SizedBox(height: 40),

              if (_frequentConnections.isNotEmpty) ...[
                const Text(
                  'RECENT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _frequentConnections.length,
                  itemBuilder: (context, index) {
                    final conn = _frequentConnections[index];
                    return InkWell(
                      onTap: () => _connect(conn),
                      onLongPress: () => _editConnection(conn),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    conn.label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              conn.host,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],

              const Text(
                'FOLDERS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 16),
              
              if (_groupedConnections.isEmpty)
                _buildEmptyState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _groupedConnections.keys.length,
                  itemBuilder: (context, index) {
                    String groupName = _groupedConnections.keys.elementAt(index);
                    List<Connection> members = _groupedConnections[groupName]!;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => _buildGroupDetailView(groupName, members),
                          ),
                        ).then((_) => _loadAndGroup());
                      },
                      child: _buildFolderTile(groupName, members),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      
      floatingActionButton: ListenableBuilder(
        listenable: SessionManager(),
        builder: (context, _) {
          if (SessionManager().sessions.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const TerminalScreen()),
              );
            },
            icon: const Icon(Icons.terminal),
            label: Text('${SessionManager().sessions.length} Active'),
          );
        },
      ),
    );
  }

  Widget _buildFolderTile(String name, List<Connection> members) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.folder, color: theme.primaryColor, size: 32),
          const Spacer(),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${members.length} Servers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGroupDetailView(String name, List<Connection> members) {
    return Scaffold(
      appBar: AppBar(title: Text(name.toUpperCase())),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final conn = members[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListTile(
              leading: Icon(Icons.dns, color: Theme.of(context).primaryColor),
              title: Text(conn.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(conn.host),
              onTap: () {
                Navigator.pop(context);
                _connect(conn);
              },
              onLongPress: () async {
                Navigator.pop(context);
                await _editConnection(conn);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(
        child: Text(
          'Your servers will appear here organized by group.\nTap Servers to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}