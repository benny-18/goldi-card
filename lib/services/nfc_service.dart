import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

/// Service for NFC/RFID card scanning operations.
class NfcService {
  /// Check if NFC is available on this device.
  static Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC availability check failed: $e');
      return false;
    }
  }

  /// Start an NFC scanning session.
  /// Calls [onSerialFound] with the card serial formatted as XXXX-XXXX.
  /// Calls [onError] if scanning fails.
  static Future<void> startScanning({
    required Function(String serial) onSerialFound,
    required Function(String error) onError,
  }) async {
    try {
      final isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        onError('NFC is not available on this device.');
        return;
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final serial = _extractSerial(tag);
            if (serial != null) {
              onSerialFound(serial);
            } else {
              onError('Could not read serial from this card.');
            }
            // Stop session after one successful read
            NfcManager.instance.stopSession();
          } catch (e) {
            onError('Error reading card: $e');
            NfcManager.instance.stopSession(errorMessage: e.toString());
          }
        },
        onError: (error) async {
          onError('NFC Error: ${error.message}');
        },
      );
    } catch (e) {
      onError('Failed to start NFC session: $e');
    }
  }

  /// Stop the current NFC scanning session.
  static Future<void> stopScanning() async {
    try {
      NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Error stopping NFC session: $e');
    }
  }

  /// Extract the card serial from an NFC tag and format it as XXXX-XXXX.
  /// Uses tag.data to access platform-specific tag information.
  static String? _extractSerial(NfcTag tag) {
    List<int>? identifier;
    final tagData = tag.data;

    // Try various NFC technology types to find the identifier
    if (tagData.containsKey('nfca')) {
      final nfca = tagData['nfca'] as Map<String, dynamic>?;
      if (nfca != null && nfca.containsKey('identifier')) {
        identifier = (nfca['identifier'] as List?)?.cast<int>();
      }
    }

    if (identifier == null && tagData.containsKey('nfcb')) {
      final nfcb = tagData['nfcb'] as Map<String, dynamic>?;
      if (nfcb != null && nfcb.containsKey('identifier')) {
        identifier = (nfcb['identifier'] as List?)?.cast<int>();
      }
    }

    if (identifier == null && tagData.containsKey('nfcf')) {
      final nfcf = tagData['nfcf'] as Map<String, dynamic>?;
      if (nfcf != null && nfcf.containsKey('identifier')) {
        identifier = (nfcf['identifier'] as List?)?.cast<int>();
      }
    }

    if (identifier == null && tagData.containsKey('nfcv')) {
      final nfcv = tagData['nfcv'] as Map<String, dynamic>?;
      if (nfcv != null && nfcv.containsKey('identifier')) {
        identifier = (nfcv['identifier'] as List?)?.cast<int>();
      }
    }

    // iOS: try MiFare / ISO 7816
    if (identifier == null && tagData.containsKey('mifare')) {
      final mifare = tagData['mifare'] as Map<String, dynamic>?;
      if (mifare != null && mifare.containsKey('identifier')) {
        identifier = (mifare['identifier'] as List?)?.cast<int>();
      }
    }

    if (identifier == null && tagData.containsKey('iso7816')) {
      final iso7816 = tagData['iso7816'] as Map<String, dynamic>?;
      if (iso7816 != null && iso7816.containsKey('identifier')) {
        identifier = (iso7816['identifier'] as List?)?.cast<int>();
      }
    }

    if (identifier == null || identifier.isEmpty) {
      return null;
    }

    // Convert bytes to hex string and format as XXXX-XXXX
    final hex = identifier
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('');

    return _formatSerial(hex);
  }

  /// Format a hex string into XXXX-XXXX format (taking first 8 characters).
  static String _formatSerial(String hex) {
    // Pad to at least 8 characters
    final padded = hex.padRight(8, '0');
    // Take first 8 and split into two groups of 4
    final part1 = padded.substring(0, 4);
    final part2 = padded.substring(4, 8);
    return '$part1-$part2';
  }
}
