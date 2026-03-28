import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:uuid/uuid.dart';
import '../models/connection.dart';
import '../models/identity.dart';
import 'identity_service.dart';

class ActiveSession {
  final String id;
  final Connection connection;
  final Terminal terminal;
  SSHClient? client;
  SSHSession? shell;
  bool isConnected = false;

  ActiveSession({
    required this.id,
    required this.connection,
    required this.terminal,
  });
}

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final List<ActiveSession> sessions = [];
  String? activeSessionId;
  bool _isBgActive = false;

  ActiveSession? get activeSession {
    if (activeSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == activeSessionId);
    } catch (e) {
      return null;
    }
  }

  void setActiveSession(String id) {
    activeSessionId = id;
    notifyListeners();
  }

  Future<void> _enableBg(String label) async {
    if (!_isBgActive) {
      try {
        final androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "SmoothSSH Active",
          notificationText: "Background sessions running...",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: const AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );
        bool initialized = await FlutterBackground.initialize(androidConfig: androidConfig);
        if (initialized) {
          _isBgActive = await FlutterBackground.enableBackgroundExecution();
        }
      } catch (e) {
        debugPrint('BG Error: $e');
      }
    }
  }

  void _disableBg() {
    if (_isBgActive && sessions.isEmpty) {
      try {
        FlutterBackground.disableBackgroundExecution();
      } catch (e) {} finally {
        _isBgActive = false;
      }
    }
  }

  Future<void> startSession(Connection conn, {Identity? directIdentity}) async {
    final sessionId = const Uuid().v4();
    final terminal = Terminal(maxLines: 10000);

    final session = ActiveSession(id: sessionId, connection: conn, terminal: terminal);
    sessions.add(session);
    activeSessionId = sessionId;
    notifyListeners(); 

    terminal.write('\x1B[1;32m[SmoothSSH]\x1B[0m Initializing...\r\n');

    try {
      await _enableBg(conn.label);

      late final Identity identity;
      if (directIdentity != null) {
        identity = directIdentity;
      } else {
        final identities = await IdentityService().getIdentities();
        identity = identities.firstWhere(
          (i) => i.id == conn.identityId,
          orElse: () => throw Exception('Identity not found in vault'),
        );
      }

      terminal.write('\x1B[1;32m[SmoothSSH]\x1B[0m Connecting to ${conn.host}...\r\n');

      final socket = await SSHSocket.connect(conn.host, conn.port, timeout: const Duration(seconds: 15));

      List<SSHKeyPair>? keyPairs;
      if (identity.privateKey != null && identity.privateKey!.isNotEmpty) {
        keyPairs = SSHKeyPair.fromPem(identity.privateKey!, identity.password);
      }

      session.client = SSHClient(
        socket,
        username: identity.username,
        onPasswordRequest: () => identity.password ?? '',
        identities: keyPairs,
      );

      session.shell = await session.client!.shell(
        pty: SSHPtyConfig(width: terminal.viewWidth, height: terminal.viewHeight),
      );

      session.isConnected = true;
      notifyListeners();

      session.shell!.stdout.listen((data) => terminal.write(utf8.decode(data, allowMalformed: true)));
      session.shell!.stderr.listen((data) => terminal.write(utf8.decode(data, allowMalformed: true)));

      terminal.onOutput = (data) {
        session.shell!.write(Uint8List.fromList(utf8.encode(data)));
      };

      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.shell!.resizeTerminal(width, height);
      };

      await session.shell!.done;
      terminal.write('\r\n\x1B[1;31m[SmoothSSH]\x1B[0m Session ended.\r\n');

    } catch (e) {
      terminal.write('\r\n\x1B[1;31m[Error]\x1B[0m ${e.toString()}\r\n');
    } finally {
      session.isConnected = false;
      notifyListeners();
    }
  }

  void closeSession(String id) {
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;

    sessions[idx].client?.close();
    sessions.removeAt(idx);

    if (sessions.isEmpty) {
      activeSessionId = null;
      _disableBg();
    } else if (activeSessionId == id) {
      activeSessionId = sessions.last.id;
    }
    notifyListeners();
  }
}