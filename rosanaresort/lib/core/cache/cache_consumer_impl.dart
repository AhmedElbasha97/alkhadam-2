import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_consumer.dart';
import 'cache_consumer.dart';
import 'cache_keys.dart';

class CryptoConfig {
  static const String appSalt = "T!reS_App_2026#Secure";
  static const String keyStorage = "__enc_install_key__";
  static const String ivStorage = "__enc_install_iv__";
}

class InstallKey {
  static List<int> generate() {
    final random = Random.secure();
    final seed = List<int>.generate(32, (_) => random.nextInt(256));
    final combined = seed + utf8.encode(CryptoConfig.appSalt);
    final digest = sha256.convert(combined);
    return digest.bytes;
  }
}

class EncryptedCacheConsumerImpl implements CacheConsumer {
  final SharedPreferences _prefs;


  final Encrypter _encrypter;
  final IV _iv;

  EncryptedCacheConsumerImpl._(this._prefs, this._encrypter, this._iv,);

  static Future<EncryptedCacheConsumerImpl> init() async {
    final prefs = await SharedPreferences.getInstance();

    String? storedKey = prefs.getString(CryptoConfig.keyStorage);
    String? storedIv = prefs.getString(CryptoConfig.ivStorage);

    List<int> keyBytes;
    IV iv;

    if (storedKey == null || storedIv == null) {
      keyBytes = InstallKey.generate();
      iv = IV.fromSecureRandom(16);

      await prefs.setString(CryptoConfig.keyStorage, base64Encode(keyBytes));
      await prefs.setString(CryptoConfig.ivStorage, base64Encode(iv.bytes));
    } else {
      keyBytes = base64Decode(storedKey);
      iv = IV(Uint8List.fromList(base64Decode(storedIv)));
    }

    final key = Key(Uint8List.fromList(keyBytes));
    final encrypter = Encrypter(AES(key));

    return EncryptedCacheConsumerImpl._(prefs, encrypter, iv);
  }

  String _encrypt(dynamic value) {
    final json = value is String ? value : jsonEncode(value);
    final encrypted = _encrypter.encrypt(json, iv: _iv).base64;
    return encrypted;
  }
  Future<void> saveLocaleCode(String code) async {
    await _prefs.setString(CacheKeys.activeLocaleKey, code);
  }

  String getSavedLocaleCode()  {
    return _prefs.getString(CacheKeys.activeLocaleKey)??"";
  }
  dynamic _decrypt(String? value) {
    try {
      final decrypted = _encrypter.decrypt64(value??"", iv: _iv);
      try {
        final parsed = jsonDecode(decrypted);
        return parsed;
      } catch (_) {
        return decrypted;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    /// Encrypt only String values
    if (value is String) {
      final encrypted = _encrypt(value);

      return await _prefs.setString(
        key,
        encrypted,
      );
    }

    /// Save everything else without encryption
    if (value is int) {
      return await _prefs.setInt(key, value);
    }

    if (value is double) {
      return await _prefs.setDouble(key, value);
    }

    if (value is bool) {
      return await _prefs.setBool(key, value);
    }

    if (value is List<String>) {
      return await _prefs.setStringList(key, value);
    }

    /// Save Map/List/Object as JSON string without encryption
    return await _prefs.setString(
      key,
      jsonEncode(value),
    );
  }
  @override
  bool checkForData({required String key}) {
    final exists = _prefs.containsKey(key);
    return exists;
  }

  @override
  dynamic getData({
    required String key,
  }) {
    final value = _prefs.get(key);

    if (value == null) {
      return null;
    }

    /// Handle encrypted/plain strings
    if (value is String) {
      return _decrypt(value);
    }

    /// Return native values directly
    return value;
  }

  @override
  Future<bool> removeData({required String key}) async {
    return _prefs.remove(key);
  }

  @override
  Future<bool> clearData() async {
    final savedKey = _prefs.getString(CryptoConfig.keyStorage);
    final savedIv = _prefs.getString(CryptoConfig.ivStorage);

    await _prefs.clear();

    if (savedKey != null) {
      await _prefs.setString(CryptoConfig.keyStorage, savedKey);
    }
    if (savedIv != null) {
      await _prefs.setString(CryptoConfig.ivStorage, savedIv);
    }

    return true;
  }
}