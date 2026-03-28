import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/identity.dart';

class IdentityService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  final String _storageKey = 'smooth_ssh_identities_vault';

  Future<List<Identity>> getIdentities() async {
    final String? data = await _storage.read(key: _storageKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Identity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveIdentity(Identity identity) async {
    final all = await getIdentities();
    
    final index = all.indexWhere((element) => element.id == identity.id);
    if (index != -1) {
      all[index] = identity;
    } else {
      all.add(identity);
    }

    final String encoded = jsonEncode(all.map((e) => e.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }

  Future<void> deleteIdentity(String id) async {
    final all = await getIdentities();
    all.removeWhere((element) => element.id == id);
    final String encoded = jsonEncode(all.map((e) => e.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }
}