import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/snippet.dart';

class SnippetService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  final String _key = 'smooth_ssh_snippets_vault';
  final String _initKey = 'smooth_ssh_snippets_initialized';

  Future<List<Snippet>> getSnippets() async {
    final String? isInit = await _storage.read(key: _initKey);
    
    if (isInit == null) {
      final defaultSnippets = [
        Snippet(id: const Uuid().v4(), label: 'Update OS', command: 'sudo apt update && sudo apt upgrade -y', autoEnter: true),
        Snippet(id: const Uuid().v4(), label: 'Docker PS', command: 'docker ps -a', autoEnter: true),
        Snippet(id: const Uuid().v4(), label: 'Syslog', command: 'tail -f /var/log/syslog', autoEnter: true),
        Snippet(id: const Uuid().v4(), label: 'Resources', command: 'htop', autoEnter: true),
      ];
      
      await _storage.write(key: _key, value: jsonEncode(defaultSnippets.map((e) => e.toJson()).toList()));
      await _storage.write(key: _initKey, value: 'true');
      return defaultSnippets;
    }

    final String? data = await _storage.read(key: _key);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Snippet.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSnippet(Snippet snippet) async {
    final all = await getSnippets();
    final index = all.indexWhere((element) => element.id == snippet.id);
    if (index != -1) {
      all[index] = snippet;
    } else {
      all.add(snippet);
    }
    await _storage.write(key: _key, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteSnippet(String id) async {
    final all = await getSnippets();
    all.removeWhere((element) => element.id == id);
    await _storage.write(key: _key, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }
}