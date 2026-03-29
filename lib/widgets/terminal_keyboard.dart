import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:xterm/xterm.dart';
import '../models/snippet.dart';
import '../services/snippet_service.dart';

class TerminalKeyboard extends StatefulWidget {
  final Terminal terminal;

  const TerminalKeyboard({super.key, required this.terminal});

  @override
  State<TerminalKeyboard> createState() => _TerminalKeyboardState();
}

class _TerminalKeyboardState extends State<TerminalKeyboard> {
  final _snippetService = SnippetService();
  List<Snippet> _snippets = [];
  
  bool _isCtrlActive = false;
  bool _isAltActive = false;

  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }

  Future<void> _loadSnippets() async {
    final list = await _snippetService.getSnippets();
    if (mounted) {
      setState(() => _snippets = list);
    }
  }

  void _sendKey(TerminalKey key) {
    widget.terminal.keyInput(key, alt: _isAltActive);
    if (_isAltActive) {
      setState(() => _isAltActive = false);
    }
  }

  void _sendCtrlByte(String char) {
    final code = char.toUpperCase().codeUnitAt(0) - 64;
    widget.terminal.textInput(String.fromCharCode(code));
    setState(() => _isCtrlActive = false);
  }

  void _sendText(String text) {
    widget.terminal.paste(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: _isCtrlActive ? _buildCtrlActiveRow() : _buildNormalRow(),
    );
  }

  Widget _buildNormalRow() {
    final theme = Theme.of(context);
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        _buildToggleKey('CTRL', _isCtrlActive, () => setState(() => _isCtrlActive = true)),
        _buildToggleKey('ALT', _isAltActive, () => setState(() => _isAltActive = !_isAltActive)),
        _buildVerticalDivider(),

        _buildTerminalKey('ESC', TerminalKey.escape),
        _buildTerminalKey('TAB', TerminalKey.tab),
        _buildTerminalKey('↑', TerminalKey.arrowUp),
        _buildTerminalKey('↓', TerminalKey.arrowDown),
        _buildTerminalKey('←', TerminalKey.arrowLeft),
        _buildTerminalKey('→', TerminalKey.arrowRight),
        _buildVerticalDivider(),

        _buildTerminalKey('HOME', TerminalKey.home),
        _buildTerminalKey('END', TerminalKey.end),
        _buildTerminalKey('PGUP', TerminalKey.pageUp),
        _buildTerminalKey('PGDN', TerminalKey.pageDown),
        _buildTerminalKey('DEL', TerminalKey.delete),
        _buildVerticalDivider(),

        _buildTerminalKey('F1', TerminalKey.f1),
        _buildTerminalKey('F2', TerminalKey.f2),
        _buildTerminalKey('F3', TerminalKey.f3),
        _buildTerminalKey('F4', TerminalKey.f4),
        _buildTerminalKey('F5', TerminalKey.f5),
        _buildTerminalKey('F6', TerminalKey.f6),
        _buildTerminalKey('F7', TerminalKey.f7),
        _buildTerminalKey('F8', TerminalKey.f8),
        _buildTerminalKey('F9', TerminalKey.f9),
        _buildTerminalKey('F10', TerminalKey.f10),
        _buildVerticalDivider(),

        ..._snippets.map((snippet) => _buildSnippetKey(snippet)),

        Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 16.0),
          child: TextButton(
            focusNode: FocusNode(canRequestFocus: false),
            style: TextButton.styleFrom(
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              minimumSize: const Size(40, 35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _showAddSnippetDialog,
            child: Icon(Icons.add, color: theme.primaryColor, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildCtrlActiveRow() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        _buildToggleKey('CANCEL', true, () => setState(() => _isCtrlActive = false), isCancel: true),
        _buildVerticalDivider(),
        
        _buildActionKey('C', 'SIGINT', () => _sendCtrlByte('C')),
        _buildActionKey('D', 'EOF', () => _sendCtrlByte('D')),
        _buildActionKey('Z', 'SUSPEND', () => _sendCtrlByte('Z')),
        _buildActionKey('L', 'CLEAR', () => _sendCtrlByte('L')),
        _buildActionKey('A', 'HOME', () => _sendCtrlByte('A')),
        _buildActionKey('E', 'END', () => _sendCtrlByte('E')),
        _buildActionKey('W', 'DEL WORD', () => _sendCtrlByte('W')),
        _buildActionKey('U', 'DEL LINE', () => _sendCtrlByte('U')),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1, 
      color: Theme.of(context).dividerColor, 
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
    );
  }

  Widget _buildToggleKey(String label, bool isActive, VoidCallback onPressed, {bool isCancel = false}) {
    final theme = Theme.of(context);
    final bgColor = isCancel ? Colors.red.withOpacity(0.8) : (isActive ? theme.primaryColor : theme.dividerColor.withOpacity(0.5));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: TextButton(
        focusNode: FocusNode(canRequestFocus: false),
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          minimumSize: const Size(45, 35),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: isActive || isCancel ? theme.colorScheme.surface : theme.textTheme.bodyMedium?.color, 
            fontWeight: FontWeight.bold, 
            fontSize: 12
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalKey(String label, TerminalKey key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: TextButton(
        focusNode: FocusNode(canRequestFocus: false),
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          minimumSize: const Size(45, 35),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        onPressed: () => _sendKey(key),
        child: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildActionKey(String letter, String subtitle, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: TextButton(
        focusNode: FocusNode(canRequestFocus: false),
        style: TextButton.styleFrom(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          minimumSize: const Size(55, 35),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: theme.primaryColor.withOpacity(0.5)),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              letter,
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14, height: 1.0),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 8, height: 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetKey(Snippet snippet) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: TextButton(
        focusNode: FocusNode(canRequestFocus: false),
        style: TextButton.styleFrom(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          minimumSize: const Size(60, 35),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
          ),
        ),
        onPressed: () {
          String toSend = snippet.command;
          if (snippet.autoEnter) toSend += '\r';
          _sendText(toSend);
        },
        onLongPress: () => _confirmDeleteSnippet(snippet),
        child: Text(
          snippet.label,
          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _showAddSnippetDialog() {
    final labelController = TextEditingController();
    final commandController = TextEditingController();
    bool autoEnter = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Snippet', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Button Label (e.g. Logs)'),
              ),
              TextField(
                controller: commandController,
                decoration: const InputDecoration(labelText: 'Command (e.g. tail -f /var/log/syslog)'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
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
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                if (labelController.text.isEmpty || commandController.text.isEmpty) return;

                final snip = Snippet(
                  id: const Uuid().v4(),
                  label: labelController.text,
                  command: commandController.text,
                  autoEnter: autoEnter,
                );

                await _snippetService.saveSnippet(snip);
                if (context.mounted) Navigator.pop(context);
                _loadSnippets(); 
              },
              child: Text('SAVE', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSnippet(Snippet snippet) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snippet?'),
        content: Text('Remove the "${snippet.label}" snippet?'),
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
      await _snippetService.deleteSnippet(snippet.id);
      _loadSnippets();
    }
  }
}