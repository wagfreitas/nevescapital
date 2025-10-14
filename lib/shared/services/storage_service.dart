import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar armazenamento local
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  
  StorageService._();
  
  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  /// Salva uma string
  Future<bool> saveString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }
  
  /// Obtém uma string
  String? getString(String key) {
    return _prefs!.getString(key);
  }
  
  /// Salva um inteiro
  Future<bool> saveInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }
  
  /// Obtém um inteiro
  int? getInt(String key) {
    return _prefs!.getInt(key);
  }
  
  /// Salva um double
  Future<bool> saveDouble(String key, double value) async {
    return await _prefs!.setDouble(key, value);
  }
  
  /// Obtém um double
  double? getDouble(String key) {
    return _prefs!.getDouble(key);
  }
  
  /// Salva um boolean
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }
  
  /// Obtém um boolean
  bool? getBool(String key) {
    return _prefs!.getBool(key);
  }
  
  /// Salva uma lista de strings
  Future<bool> saveStringList(String key, List<String> value) async {
    return await _prefs!.setStringList(key, value);
  }
  
  /// Obtém uma lista de strings
  List<String>? getStringList(String key) {
    return _prefs!.getStringList(key);
  }
  
  /// Salva um objeto JSON
  Future<bool> saveJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await saveString(key, jsonString);
  }
  
  /// Obtém um objeto JSON
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Remove uma chave
  Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }
  
  /// Remove todas as chaves
  Future<bool> clear() async {
    return await _prefs!.clear();
  }
  
  /// Verifica se uma chave existe
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }
  
  /// Obtém todas as chaves
  Set<String> getKeys() {
    return _prefs!.getKeys();
  }
}
