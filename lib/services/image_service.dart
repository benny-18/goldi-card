import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Service for capturing and compressing profile pictures.
class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Maximum dimension for profile pictures (width or height).
  static const int maxDimension = 512;

  /// JPEG compression quality (0-100).
  static const int jpegQuality = 75;

  /// Capture a profile picture using the device camera.
  /// Returns the compressed image bytes, or null if cancelled.
  static Future<Uint8List?> captureProfilePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: maxDimension.toDouble(),
        maxHeight: maxDimension.toDouble(),
        imageQuality: jpegQuality,
      );

      if (photo == null) return null;

      // Additional compression with flutter_image_compress
      final bytes = await _compressImage(File(photo.path));
      return bytes;
    } catch (e) {
      debugPrint('Error capturing profile picture: $e');
      return null;
    }
  }

  /// Pick a profile picture from the device gallery.
  /// Returns the compressed image bytes, or null if cancelled.
  static Future<Uint8List?> pickProfilePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxDimension.toDouble(),
        maxHeight: maxDimension.toDouble(),
        imageQuality: jpegQuality,
      );

      if (photo == null) return null;

      final bytes = await _compressImage(File(photo.path));
      return bytes;
    } catch (e) {
      debugPrint('Error picking profile picture: $e');
      return null;
    }
  }

  /// Compress an image file to JPEG with max 512x512 dimensions.
  /// Target output: ~50-150KB per image.
  static Future<Uint8List?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint('Image compression failed, using original: $e');
      // Fallback: return original bytes
      return await file.readAsBytes();
    }
  }
}
