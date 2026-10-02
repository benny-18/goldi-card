import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/customer.dart';
import '../models/discount_record.dart';
import '../models/store_config.dart';
import '../services/nfc_service.dart';
import '../services/supabase_service.dart';
import '../services/store_config_service.dart';
import 'registration_screen.dart';

/// Main home screen of the Goldi Card app.
///
/// Default state: NFC scan prompt.
/// After scan: Shows customer profile (if registered) or navigates
/// to registration (if unregistered).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────────
  bool _isLoading = false;
  bool _nfcAvailable = true;
  Customer? _currentCustomer;
  List<DiscountRecord> _discountHistory = [];
  StoreConfig? _storeConfig;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    _storeConfig = await StoreConfigService.getConfig();
    final nfcAvailable = await NfcService.isNfcAvailable();
    setState(() => _nfcAvailable = nfcAvailable);
    if (nfcAvailable) {
      _startNfcScan();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    NfcService.stopScanning();
    super.dispose();
  }

  // ── NFC Scanning ────────────────────────────────────────────

  void _startNfcScan() {
    setState(() {
      _currentCustomer = null;
      _discountHistory = [];
    });
    _fadeController.reset();

    NfcService.startScanning(
      onSerialFound: (serial) => _lookupCard(serial),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: GoldiTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );
  }

  // ── Manual Entry ────────────────────────────────────────────

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.keyboard_rounded, color: GoldiTheme.goldiGold),
            const SizedBox(width: 12),
            Text('Enter Card Serial', style: GoldiTheme.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Type the serial number printed on the card.',
              style: GoldiTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. A1B2-C3D4',
                prefixIcon: Icon(Icons.credit_card_rounded,
                    color: GoldiTheme.goldiGold),
              ),
              style: GoldiTheme.bodyLarge.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoldiTheme.bodyMedium
                    .copyWith(color: GoldiTheme.lightBrown)),
          ),
          ElevatedButton(
            onPressed: () {
              final serial = controller.text.trim().toUpperCase();
              Navigator.pop(ctx);
              if (serial.isNotEmpty) {
                _lookupCard(serial);
              }
            },
            child: const Text('Look Up'),
          ),
        ],
      ),
    );
  }

  // ── Card Lookup ─────────────────────────────────────────────

  Future<void> _lookupCard(String serial) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customer = await SupabaseService.getCustomerBySerial(serial);

      if (customer != null) {
        // Card is registered — show customer profile
        final history =
            await SupabaseService.getDiscountHistory(customer.id);
        setState(() {
          _currentCustomer = customer;
          _discountHistory = history;
          _isLoading = false;
        });
        _fadeController.forward();
      } else {
        // Card is not registered — go to registration
        setState(() => _isLoading = false);
        if (mounted) {
          final result = await Navigator.push<Customer>(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrationScreen(cardSerial: serial),
            ),
          );
          if (result != null) {
            // Registration successful — show the new customer
            final history =
                await SupabaseService.getDiscountHistory(result.id);
            setState(() {
              _currentCustomer = result;
              _discountHistory = history;
            });
            _fadeController.forward();
          } else {
            // Registration cancelled — restart scanning
            if (_nfcAvailable) _startNfcScan();
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error looking up card: $e'),
            backgroundColor: GoldiTheme.errorRed,
          ),
        );
        if (_nfcAvailable) _startNfcScan();
      }
    }
  }

  // ── Discount Redemption ─────────────────────────────────────

  void _showRedeemDialog() {
    final passcodeController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GoldiTheme.goldiYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: GoldiTheme.goldiGold, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Enter Passcode', style: GoldiTheme.headingSmall),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AM/ASM/Store Crew passcode required to apply the 5% discount.',
                style: GoldiTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passcodeController,
                obscureText: obscure,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoldiTheme.headingMedium.copyWith(
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '• • • •',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: GoldiTheme.lightBrown,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoldiTheme.bodyMedium
                      .copyWith(color: GoldiTheme.lightBrown)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passcodeController.text == '1234') {
                  Navigator.pop(ctx);
                  await _applyDiscount();
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Incorrect passcode'),
                      backgroundColor: GoldiTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyDiscount() async {
    if (_currentCustomer == null || _storeConfig == null) return;

    try {
      final record = await SupabaseService.logDiscountRedemption(
        customerId: _currentCustomer!.id,
        discountPercent: 5.0,
        branchName: _storeConfig!.branchName,
        clusterNumber: _storeConfig!.clusterNumber,
        processedBy: _storeConfig!.staffName,
      );

      setState(() {
        _discountHistory.insert(0, record);
      });

      if (mounted) {
        // Show success overlay
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: GoldiTheme.successGreen,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Discount Applied!',
                    style: GoldiTheme.headingMedium
                        .copyWith(color: GoldiTheme.successGreen)),
                const SizedBox(height: 8),
                Text(
                  '5% discount for ${_currentCustomer!.fullName}',
                  style: GoldiTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Please apply in the POS.',
                  style: GoldiTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply discount: $e'),
            backgroundColor: GoldiTheme.errorRed,
          ),
        );
      }
    }
  }

  // ── Reset to scan mode ──────────────────────────────────────

  void _resetToScan() {
    setState(() {
      _currentCustomer = null;
      _discountHistory = [];
    });
    _fadeController.reset();
    if (_nfcAvailable) {
      _startNfcScan();
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_rounded, size: 24),
            const SizedBox(width: 8),
            const Text('Goldi Card'),
          ],
        ),
        actions: [
          if (_currentCustomer != null)
            IconButton(
              icon: const Icon(Icons.contactless_rounded),
              tooltip: 'Scan another card',
              onPressed: _resetToScan,
            ),
          if (!_nfcAvailable || _currentCustomer != null)
            IconButton(
              icon: const Icon(Icons.keyboard_rounded),
              tooltip: 'Manual entry',
              onPressed: _showManualEntryDialog,
            ),
        ],
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
        child: _isLoading
            ? _buildLoadingState()
            : _currentCustomer != null
                ? _buildCustomerProfile()
                : _buildScanPrompt(),
      ),
    );
  }

  // ── Loading State ───────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: GoldiTheme.goldiYellow,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text('Looking up card...', style: GoldiTheme.bodyLarge),
        ],
      ),
    );
  }

  // ── Scan Prompt State ───────────────────────────────────────

  Widget _buildScanPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated NFC icon
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      GoldiTheme.goldiYellowLight,
                      GoldiTheme.goldiYellow,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GoldiTheme.goldiYellow.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.contactless_rounded,
                  size: 72,
                  color: GoldiTheme.darkBrown,
                ),
              ),
            ),
            const SizedBox(height: 40),

            Text(
              'Ready to scan your\nGoldi Card',
              style: GoldiTheme.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _nfcAvailable
                  ? 'Put your Goldi Card on the\nphone\'s NFC reader'
                  : 'NFC not available on this device.\nUse manual entry instead.',
              style: GoldiTheme.bodyMedium.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),

            if (!_nfcAvailable) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard_rounded),
                label: const Text('Enter Serial Manually'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Customer Profile State ──────────────────────────────────

  Widget _buildCustomerProfile() {
    final customer = _currentCustomer!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Profile Card ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: GoldiTheme.cardDecoration,
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: GoldiTheme.goldiYellow, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: GoldiTheme.goldiYellowDark
                              .withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: customer.profilePictureUrl != null &&
                              customer.profilePictureUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: customer.profilePictureUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: GoldiTheme.warmCream,
                                child: const Icon(Icons.person_rounded,
                                    size: 48,
                                    color: GoldiTheme.lightBrown),
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: GoldiTheme.warmCream,
                                child: const Icon(Icons.person_rounded,
                                    size: 48,
                                    color: GoldiTheme.lightBrown),
                              ),
                            )
                          : Container(
                              color: GoldiTheme.warmCream,
                              child: const Icon(Icons.person_rounded,
                                  size: 48, color: GoldiTheme.lightBrown),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    customer.fullName,
                    style: GoldiTheme.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Birthdate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cake_rounded,
                          size: 18, color: GoldiTheme.goldiGold),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM d, y')
                            .format(customer.birthdate),
                        style: GoldiTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Serial Number Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          GoldiTheme.goldiYellow,
                          GoldiTheme.goldiYellowLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.credit_card_rounded,
                            size: 18, color: GoldiTheme.darkBrown),
                        const SizedBox(width: 8),
                        Text(
                          customer.cardSerial,
                          style: GoldiTheme.labelBold.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Redeem Discount Button ──────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showRedeemDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoldiTheme.goldiYellow,
                  foregroundColor: GoldiTheme.darkBrown,
                  elevation: 4,
                  shadowColor: GoldiTheme.goldiYellowDark.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.discount_rounded, size: 24),
                    const SizedBox(width: 10),
                    Text('Redeem my Discount',
                        style: GoldiTheme.buttonText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Discount History ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: GoldiTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: GoldiTheme.goldiGold, size: 22),
                      const SizedBox(width: 8),
                      Text('Discount History',
                          style: GoldiTheme.headingSmall),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GoldiTheme.goldiYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_discountHistory.length}',
                          style: GoldiTheme.labelBold.copyWith(
                              color: GoldiTheme.goldiGold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_discountHistory.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 40,
                                color: GoldiTheme.lightBrown
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'No discounts redeemed yet',
                              style: GoldiTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_discountHistory.map((record) =>
                        _buildDiscountHistoryItem(record))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Scan Another Card ───────────────────────
            TextButton.icon(
              onPressed: _resetToScan,
              icon: const Icon(Icons.contactless_rounded,
                  color: GoldiTheme.goldiGold),
              label: Text('Scan Another Card',
                  style: GoldiTheme.bodyMedium
                      .copyWith(color: GoldiTheme.goldiGold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountHistoryItem(DiscountRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GoldiTheme.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GoldiTheme.goldiYellowDark.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GoldiTheme.goldiYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.discount_rounded,
                color: GoldiTheme.goldiGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.discountPercent.toStringAsFixed(0)}% Discount',
                  style: GoldiTheme.labelBold.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.branchName} • Cluster ${record.clusterNumber}',
                  style: GoldiTheme.bodySmall.copyWith(fontSize: 11),
                ),
                Text(
                  'By: ${record.processedBy}',
                  style: GoldiTheme.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d, y\nh:mm a').format(record.redeemedAt.toLocal()),
            style: GoldiTheme.bodySmall.copyWith(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
