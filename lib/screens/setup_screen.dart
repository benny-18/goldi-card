import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/store_config.dart';
import '../services/store_config_service.dart';
import 'home_screen.dart';

/// One-time store setup screen.
/// Asks for Branch Name, Cluster Number, and AM/ASM/SC full name.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _branchController = TextEditingController();
  final _staffNameController = TextEditingController();
  int _selectedCluster = 1;
  bool _isSubmitting = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _branchController.dispose();
    _staffNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final config = StoreConfig(
        branchName: _branchController.text.trim(),
        clusterNumber: _selectedCluster,
        staffName: _staffNameController.text.trim(),
      );

      await StoreConfigService.saveConfig(config);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: GoldiTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: GoldiTheme.goldiGradientBackground,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Header ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: GoldiTheme.goldiYellow.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 64,
                      color: GoldiTheme.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Store Setup',
                    style: GoldiTheme.headingLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure this device for your branch.\nThis is a one-time setup.',
                    style: GoldiTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ── Form ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: GoldiTheme.cardDecoration,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Branch Name
                          Text('Branch Name', style: GoldiTheme.labelBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _branchController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Burgos Branch',
                              prefixIcon:
                                  Icon(Icons.location_on_rounded, color: GoldiTheme.goldiGold),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter the branch name'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Cluster Number
                          Text('Cluster Number', style: GoldiTheme.labelBold),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: GoldiTheme.warmWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: GoldiTheme.goldiYellowDark.withValues(alpha: 0.3),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedCluster,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded,
                                    color: GoldiTheme.goldiGold),
                                items: List.generate(
                                  5,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(
                                      'Cluster ${i + 1}',
                                      style: GoldiTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCluster = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Staff Full Name
                          Text('Your Full Name', style: GoldiTheme.labelBold),
                          const SizedBox(height: 4),
                          Text(
                            'AM / ASM / Store Crew operating this device',
                            style: GoldiTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _staffNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Juan Dela Cruz',
                              prefixIcon:
                                  Icon(Icons.person_rounded, color: GoldiTheme.goldiGold),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your full name'
                                : null,
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitSetup,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded),
                                        const SizedBox(width: 8),
                                        Text('Complete Setup',
                                            style: GoldiTheme.buttonText),
                                      ],
                                    ),
                            ),
                          ),
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
