import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../services/session_manager.dart';
import '../services/settings_service.dart';
import '../widgets/terminal_keyboard.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _sessionManager = SessionManager();
  
  late PageController _pageController;
  int _currentPage = 0;

  double _terminalFontSize = 14.0;
  TerminalCursorType _cursorType = TerminalCursorType.block;
  static const _volumeChannel = MethodChannel('smoothssh/volume');

  @override
  void initState() {
    super.initState();
    _loadCursorPreference();
    _setupVolumeListener();
    _sessionManager.addListener(_onSessionUpdate);

    final initialIndex = _sessionManager.sessions.indexWhere(
      (s) => s.id == _sessionManager.activeSessionId
    );
    _currentPage = initialIndex >= 0 ? initialIndex : 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _sessionManager.removeListener(_onSessionUpdate);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCursorPreference() async {
    final style = await SettingsService().getCursorStyle();
    if (mounted) {
      setState(() {
        switch (style) {
          case 'Underline': 
            _cursorType = TerminalCursorType.underline; 
            break;
          case 'Bar': 
            _cursorType = TerminalCursorType.verticalBar; 
            break;
          case 'Block':
          default: 
            _cursorType = TerminalCursorType.block; 
            break;
        }
      });
    }
  }

  void _onSessionUpdate() {
    if (_sessionManager.sessions.isEmpty) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); 
      }
    } else {
      final activeIndex = _sessionManager.sessions.indexWhere((s) => s.id == _sessionManager.activeSessionId);
      if (activeIndex >= 0 && activeIndex != _currentPage) {
        _currentPage = activeIndex;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(activeIndex);
        }
      }
      setState(() {});
    }
  }

  void _setupVolumeListener() {
    _volumeChannel.setMethodCallHandler((call) async {
      setState(() {
        if (call.method == 'volumeUp') {
          _terminalFontSize = (_terminalFontSize + 1.0).clamp(8.0, 48.0);
        } else if (call.method == 'volumeDown') {
          _terminalFontSize = (_terminalFontSize - 1.0).clamp(8.0, 48.0);
        }
      });
    });
  }

  void _showCopyBufferModal(Terminal terminal) {
    final buffer = StringBuffer();
    for (var i = 0; i < terminal.buffer.lines.length; i++) {
      final line = terminal.buffer.lines[i].getText();
      if (line.trim().isNotEmpty || i < terminal.buffer.cursorY) {
        buffer.writeln(line);
      }
    }
    final transcript = buffer.toString().trimRight();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'SESSION TRANSCRIPT', 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  transcript.isEmpty ? "Session buffer is empty." : transcript,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    icon: Icon(Icons.copy_all, color: Theme.of(context).colorScheme.surface),
                    label: Text(
                      'COPY ENTIRE SESSION', 
                      style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: transcript));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Session copied to clipboard!')),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard(Terminal terminal) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      terminal.paste(data.text!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasted from clipboard'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = _sessionManager.activeSession;
    final theme = Theme.of(context);

    if (activeSession == null && _sessionManager.sessions.isNotEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: SizedBox(
          height: kToolbarHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sessionManager.sessions.length,
            itemBuilder: (context, index) {
              final session = _sessionManager.sessions[index];
              final isActive = index == _currentPage;

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 160),
                  margin: const EdgeInsets.only(top: 8, right: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black : theme.primaryColor.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border.all(
                      color: isActive ? theme.primaryColor : Colors.transparent,
                      width: isActive ? 1 : 0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 6.0),
                        child: Icon(
                          session.isConnected ? Icons.bolt : Icons.sync,
                          size: 14,
                          color: session.isConnected ? Colors.greenAccent : Colors.white54,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          session.connection.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? theme.primaryColor : Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        onPressed: () => _sessionManager.closeSession(session.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            tooltip: 'Paste from Clipboard',
            onPressed: () {
              if (activeSession != null) {
                _pasteFromClipboard(activeSession.terminal);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View / Copy Transcript',
            onPressed: () {
              if (activeSession != null) {
                _showCopyBufferModal(activeSession.terminal);
              }
            },
          ),
        ],
      ),
      body: activeSession == null
          ? const SizedBox.shrink()
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _sessionManager.setActiveSession(_sessionManager.sessions[index].id);
              },
              itemCount: _sessionManager.sessions.length,
              itemBuilder: (context, index) {
                final session = _sessionManager.sessions[index];
                
                return Column(
                  children: [
                    Expanded(
                      key: ValueKey(session.id),
                      child: TerminalView(
                        session.terminal,
                        autofocus: true,
                        cursorType: _cursorType,
                        textStyle: TerminalStyle(fontSize: _terminalFontSize),
                      ),
                    ),
                    TerminalKeyboard(terminal: session.terminal),
                  ],
                );
              },
            ),
    );
  }
}