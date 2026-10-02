import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_config.dart';

/// Service for managing the one-time store/device configuration
/// stored locally via SharedPreferences.
class StoreConfigService {
  static const String _keyBranchName = 'store_branch_name';
  static const String _keyClusterNumber = 'store_cluster_number';
  static const String _keyStaffName = 'store_staff_name';
  static const String _keyIsConfigured = 'store_is_configured';

  /// Check if the store has been configured (one-time setup completed).
  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsConfigured) ?? false;
  }

  /// Save the store configuration.
  static Future<void> saveConfig(StoreConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBranchName, config.branchName);
    await prefs.setInt(_keyClusterNumber, config.clusterNumber);
    await prefs.setString(_keyStaffName, config.staffName);
    await prefs.setBool(_keyIsConfigured, true);
  }

  /// Get the saved store configuration.
  /// Returns null if not configured yet.
  static Future<StoreConfig?> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final isConfigured = prefs.getBool(_keyIsConfigured) ?? false;
    if (!isConfigured) return null;

    return StoreConfig(
      branchName: prefs.getString(_keyBranchName) ?? '',
      clusterNumber: prefs.getInt(_keyClusterNumber) ?? 1,
      staffName: prefs.getString(_keyStaffName) ?? '',
    );
  }

  /// Clear the store configuration (for reconfiguration).
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBranchName);
    await prefs.remove(_keyClusterNumber);
    await prefs.remove(_keyStaffName);
    await prefs.setBool(_keyIsConfigured, false);
  }
}
