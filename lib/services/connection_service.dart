import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/connection.dart';

class ConnectionService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  final String _key = 'smooth_ssh_connections_list';

  Future<List<Connection>> getConnections() async {
    final data = await _storage.read(key: _key);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Connection.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveConnection(Connection conn) async {
    final all = await getConnections();
    
    final index = all.indexWhere((element) => element.id == conn.id);
    if (index != -1) {
      all[index] = conn;
    } else {
      all.add(conn);
    }

    await _storage.write(key: _key, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteConnection(String id) async {
    final all = await getConnections();
    all.removeWhere((element) => element.id == id);
    await _storage.write(key: _key, value: jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> incrementUsage(String id) async {
    final all = await getConnections();
    final index = all.indexWhere((element) => element.id == id);
    if (index != -1) {
      final old = all[index];
      final Map<String, dynamic> json = old.toJson();
      json['usageCount'] = (json['usageCount'] as int? ?? 0) + 1;
      all[index] = Connection.fromJson(json);
      await _storage.write(key: _key, value: jsonEncode(all.map((e) => e.toJson()).toList()));
    }
  }
}