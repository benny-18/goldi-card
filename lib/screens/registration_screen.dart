import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../services/image_service.dart';

/// Registration screen for linking a new Goldi Card to a customer.
class RegistrationScreen extends StatefulWidget {
  final String cardSerial;

  const RegistrationScreen({super.key, required this.cardSerial});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _birthdate;
  Uint8List? _profileImageBytes;
  bool _isSubmitting = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: GoldiTheme.themeData.copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: GoldiTheme.goldiYellow,
              headerForegroundColor: GoldiTheme.darkBrown,
              todayForegroundColor:
                  WidgetStateProperty.all(GoldiTheme.darkBrown),
              todayBackgroundColor: WidgetStateProperty.all(
                  GoldiTheme.goldiYellow.withValues(alpha: 0.3)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _capturePhoto() async {
    final bytes = await ImageService.captureProfilePicture();
    if (bytes != null) {
      setState(() => _profileImageBytes = bytes);
    }
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: GoldiTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GoldiTheme.lightBrown.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Profile Picture', style: GoldiTheme.headingSmall),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GoldiTheme.goldiYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: GoldiTheme.darkBrown),
              ),
              title: Text('Take a Photo', style: GoldiTheme.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _capturePhoto();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GoldiTheme.goldiYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: GoldiTheme.darkBrown),
              ),
              title:
                  Text('Choose from Gallery', style: GoldiTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(ctx);
                final bytes = await ImageService.pickProfilePicture();
                if (bytes != null) {
                  setState(() => _profileImageBytes = bytes);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer\'s birthdate'),
          backgroundColor: GoldiTheme.errorRed,
        ),
      );
      return;
    }
    if (_profileImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a profile picture'),
          backgroundColor: GoldiTheme.errorRed,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload profile picture
      final pictureUrl = await SupabaseService.uploadProfilePicture(
        cardSerial: widget.cardSerial,
        imageBytes: _profileImageBytes!,
      );

      // Register customer
      final customer = await SupabaseService.registerCustomer(
        cardSerial: widget.cardSerial,
        fullName: _nameController.text.trim(),
        birthdate: _birthdate!,
        address: _addressController.text.trim(),
        profilePictureUrl: pictureUrl,
      );

      if (mounted) {
        // Show success and pop back with the new customer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${customer.fullName} has been registered successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: GoldiTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(customer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: GoldiTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: GoldiTheme.goldiGold, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Confirm Registration',
                  style: GoldiTheme.headingSmall),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoldiTheme.goldiYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: GoldiTheme.goldiYellow.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          size: 20, color: GoldiTheme.goldiGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This Goldi Card will be permanently linked to this customer.',
                          style: GoldiTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.block_rounded,
                          size: 20, color: GoldiTheme.goldiRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The card is non-transferable and cannot be reassigned.',
                          style: GoldiTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Customer Details:', style: GoldiTheme.labelBold),
            const SizedBox(height: 8),
            _detailRow('Name', _nameController.text.trim()),
            _detailRow('Birthdate',
                DateFormat('MMMM d, y').format(_birthdate!)),
            _detailRow('Address', _addressController.text.trim()),
            _detailRow('Card S/N', widget.cardSerial),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoldiTheme.bodyMedium
                    .copyWith(color: GoldiTheme.lightBrown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Register'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child:
                Text('$label:', style: GoldiTheme.bodySmall),
          ),
          Expanded(
            child: Text(value,
                style:
                    GoldiTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Goldi Card'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GoldiTheme.warmCream, GoldiTheme.surfaceWhite],
            stops: [0.0, 0.3],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Card Serial Badge ──────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: GoldiTheme.accentCardDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card_rounded,
                            color: GoldiTheme.darkBrown),
                        const SizedBox(width: 12),
                        Text(
                          widget.cardSerial,
                          style: GoldiTheme.headingMedium.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This card is not yet registered',
                    style: GoldiTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Profile Picture ────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GoldiTheme.warmCream,
                              border: Border.all(
                                color: GoldiTheme.goldiYellow,
                                width: 3,
                              ),
                              image: _profileImageBytes != null
                                  ? DecorationImage(
                                      image:
                                          MemoryImage(_profileImageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: GoldiTheme.goldiYellowDark
                                      .withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _profileImageBytes == null
                                ? const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 48,
                                    color: GoldiTheme.lightBrown,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: GoldiTheme.goldiYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: GoldiTheme.darkBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add profile picture',
                    style: GoldiTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Form Fields ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: GoldiTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Customer Details',
                            style: GoldiTheme.headingSmall),
                        const SizedBox(height: 20),

                        // Full Name
                        Text('Full Name', style: GoldiTheme.labelBold),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Maria Santos',
                            prefixIcon: Icon(Icons.person_rounded,
                                color: GoldiTheme.goldiGold),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter the customer\'s full name'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Birthdate
                        Text('Birthdate', style: GoldiTheme.labelBold),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickBirthdate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: GoldiTheme.warmWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: GoldiTheme.goldiYellowDark
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_rounded,
                                    color: GoldiTheme.goldiGold),
                                const SizedBox(width: 12),
                                Text(
                                  _birthdate != null
                                      ? DateFormat('MMMM d, y')
                                          .format(_birthdate!)
                                      : 'Select birthdate',
                                  style: _birthdate != null
                                      ? GoldiTheme.bodyLarge
                                      : GoldiTheme.bodyMedium.copyWith(
                                          color: GoldiTheme.lightBrown
                                              .withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Address
                        Text('Current Address',
                            style: GoldiTheme.labelBold),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          textCapitalization: TextCapitalization.words,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 123 Rizal Street, Tacloban City',
                            prefixIcon: Icon(Icons.home_rounded,
                                color: GoldiTheme.goldiGold),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter the customer\'s address'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Submit Button ──────────────────────────
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRegistration,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: GoldiTheme.darkBrown,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.how_to_reg_rounded),
                                const SizedBox(width: 8),
                                Text('Register Customer',
                                    style: GoldiTheme.buttonText),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
