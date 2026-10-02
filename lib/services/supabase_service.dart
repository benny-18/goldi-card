import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/customer.dart';
import '../models/discount_record.dart';

/// Service for all Supabase database and storage operations.
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ── Customer Operations ─────────────────────────────────────

  /// Look up a customer by their RFID card serial number.
  /// Returns null if the card is not registered.
  static Future<Customer?> getCustomerBySerial(String cardSerial) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('card_serial', cardSerial)
        .maybeSingle();

    if (response == null) return null;
    return Customer.fromJson(response);
  }

  /// Register a new customer with their card serial and personal details.
  /// Returns the newly created Customer.
  static Future<Customer> registerCustomer({
    required String cardSerial,
    required String fullName,
    required DateTime birthdate,
    required String address,
    String? profilePictureUrl,
  }) async {
    final data = {
      'card_serial': cardSerial,
      'full_name': fullName,
      'birthdate': birthdate.toIso8601String().split('T').first,
      'address': address,
      'profile_picture_url': profilePictureUrl,
    };

    final response =
        await _client.from('customers').insert(data).select().single();

    return Customer.fromJson(response);
  }

  // ── Profile Picture Operations ──────────────────────────────

  /// Upload a profile picture to Supabase Storage.
  /// Returns the public URL of the uploaded image.
  static Future<String> uploadProfilePicture({
    required String cardSerial,
    required Uint8List imageBytes,
  }) async {
    final fileName =
        '${cardSerial.replaceAll('-', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from(SupabaseConfig.profileBucket).uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage
        .from(SupabaseConfig.profileBucket)
        .getPublicUrl(fileName);

    return publicUrl;
  }

  // ── Discount History Operations ─────────────────────────────

  /// Log a discount redemption for a customer.
  static Future<DiscountRecord> logDiscountRedemption({
    required String customerId,
    required double discountPercent,
    required String branchName,
    required int clusterNumber,
    required String processedBy,
  }) async {
    final data = {
      'customer_id': customerId,
      'discount_percent': discountPercent,
      'branch_name': branchName,
      'cluster_number': clusterNumber,
      'processed_by': processedBy,
    };

    final response = await _client
        .from('discount_history')
        .insert(data)
        .select()
        .single();

    return DiscountRecord.fromJson(response);
  }

  /// Get all discount history for a specific customer, most recent first.
  static Future<List<DiscountRecord>> getDiscountHistory(
      String customerId) async {
    final response = await _client
        .from('discount_history')
        .select()
        .eq('customer_id', customerId)
        .order('redeemed_at', ascending: false);

    return (response as List)
        .map((json) => DiscountRecord.fromJson(json))
        .toList();
  }
}
