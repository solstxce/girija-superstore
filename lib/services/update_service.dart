import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class UpdateService {
  static const String updateUrl = 'https://raw.githubusercontent.com/solstxce/girija-superstore/refs/heads/main/release.json';
  
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      debugPrint('🔍 Checking for updates from: $updateUrl');
      final response = await http.get(Uri.parse(updateUrl));
      
      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('📦 Response body: ${response.body}');
        final data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(data);
        debugPrint('✅ Update info parsed: version=${updateInfo.version}, required=${updateInfo.required}');
        return updateInfo;
      }
      
      debugPrint('❌ Failed to fetch update info');
      return null;
    } catch (e) {
      // Return null if there's any error (network, parsing, etc.)
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }
  
  bool isUpdateAvailable(String currentVersion, String latestVersion) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);
    
    // Compare major, minor, patch
    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    
    return false;
  }
  
  bool isUpdateRequired(String currentVersion, UpdateInfo updateInfo) {
    // If required flag is true, update is mandatory
    if (updateInfo.required) {
      return true;
    }
    
    // If current version is in accepted previous versions, update is optional
    if (updateInfo.acceptedPreviousVersions.contains(currentVersion)) {
      return false;
    }
    
    // Otherwise, update is required
    return true;
  }
  
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0,
    ];
  }
}
