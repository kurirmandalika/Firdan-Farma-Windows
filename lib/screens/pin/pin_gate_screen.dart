import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pin_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';

class PinGateScreen extends StatefulWidget {
  final Widget child;

  const PinGateScreen({super.key, required this.child});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _pinInput = '';
  String _errorMessage = '';

  void _onKeyPress(String digit) {
    if (_pinInput.length < 6) {
      setState(() {
        _pinInput += digit;
        _errorMessage = '';
      });
      if (_pinInput.length == 6) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _submitPin() async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    if (pinProvider.hasPinSet) {
      final valid = await pinProvider.unlock(_pinInput);
      if (!valid) {
        setState(() {
          _pinInput = '';
          _errorMessage = 'PIN Salah! Silakan coba lagi.';
        });
      }
    } else {
      // Setup initial PIN
      await pinProvider.setupNewPin(_pinInput);
    }
  }

  Widget _buildKeypadButton(String text, {VoidCallback? onPressed, Widget? child}) {
    return Container(
      margin: const EdgeInsets.all(6),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed ?? () => _onKeyPress(text),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: child ?? Text(
              text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PinProvider>(
      builder: (context, pinProvider, _) {
        if (pinProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
          );
        }

        if (pinProvider.isUnlocked) {
          return widget.child;
        }

        final isSetupMode = !pinProvider.hasPinSet;

        return Scaffold(
          backgroundColor: AppTheme.sidebarBackground,
          body: Center(
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTealLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_pharmacy,
                      size: 40,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSetupMode
                        ? 'Buat PIN Keamanan Baru (6 Digit)'
                        : 'Masukkan 6 Digit PIN Pengaman',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _pinInput.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppTheme.primaryTeal : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? AppTheme.primaryTeal : AppTheme.borderLight,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Keypad
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['1', '2', '3'].map((d) => _buildKeypadButton(d)).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['4', '5', '6'].map((d) => _buildKeypadButton(d)).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['7', '8', '9'].map((d) => _buildKeypadButton(d)).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 84),
                          _buildKeypadButton('0'),
                          _buildKeypadButton(
                            '',
                            onPressed: _onBackspace,
                            child: const Icon(Icons.backspace_outlined, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
