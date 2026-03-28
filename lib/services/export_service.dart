import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/identity.dart';
import '../models/connection.dart';
import '../models/snippet.dart';
import '../theme/app_theme.dart';
import 'connection_service.dart';
import 'identity_service.dart';
import 'snippet_service.dart';
import 'settings_service.dart';

class ExportService {
  Future<void> exportVault(String password) async {
    final identities = await IdentityService().getIdentities();
    final connections = await ConnectionService().getConnections();
    final snippets = await SnippetService().getSnippets();
    final theme = await SettingsService().getThemeConfig();

    final rawData = jsonEncode({
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'identities': identities.map((e) => e.toJson()).toList(),
      'connections': connections.map((e) => e.toJson()).toList(),
      'snippets': snippets.map((e) => e.toJson()).toList(),
      'theme': {'base': theme.baseTheme, 'accent': theme.accentColor},
    });

    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(rawData, iv: iv);

    final exportData = jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
    });

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/smoothssh_backup_$timestamp.smoothvault');
    await file.writeAsString(exportData);

    await Share.shareXFiles([XFile(file.path)], text: 'SmoothSSH Encrypted Backup');
  }

  Future<void> importVault(String filePath, String password) async {
    final file = File(filePath);
    final rawString = await file.readAsString();
    final exportData = jsonDecode(rawString);

    final iv = enc.IV.fromBase64(exportData['iv']);
    final encrypted = enc.Encrypted.fromBase64(exportData['data']);

    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decryptedRaw = encrypter.decrypt(encrypted, iv: iv);
    
    final data = jsonDecode(decryptedRaw);

    final idService = IdentityService();
    for (var i in data['identities'] ?? []) {
      await idService.saveIdentity(Identity.fromJson(i));
    }

    final connService = ConnectionService();
    for (var c in data['connections'] ?? []) {
      await connService.saveConnection(Connection.fromJson(c));
    }

    final snipService = SnippetService();
    for (var s in data['snippets'] ?? []) {
      await snipService.saveSnippet(Snippet.fromJson(s));
    }

    if (data['theme'] != null) {
      await SettingsService().saveThemeConfig(ThemeConfig(
        baseTheme: data['theme']['base'] ?? 'dark',
        accentColor: data['theme']['accent'] ?? 'blue',
      ));
    }
  }
}