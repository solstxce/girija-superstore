import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class UpdateService {
  static const String updateUrl = 'https://raw.githubusercontent.com/solstxce/girija-superstore/refs/heads/main/release.json';
  
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(updateUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return UpdateInfo.fromJson(data);
      }
      
      return null;
    } catch (e) {
      // Return null if there's any error (network, parsing, etc.)
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
