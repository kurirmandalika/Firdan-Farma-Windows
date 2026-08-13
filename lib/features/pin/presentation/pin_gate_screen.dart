import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firdan_farma_windows/application/providers/pin_provider.dart';
import 'package:firdan_farma_windows/data/services/pin_service.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/shared/widgets/brand_logo.dart';

class PinGateScreen extends StatefulWidget {
  final Widget child;

  const PinGateScreen({super.key, required this.child});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String _pinInput = '';
  String _errorMessage = '';
  int _lockoutSeconds = 0;
  Timer? _timer;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLockoutStatus() async {
    final remaining = await PinService().getRemainingLockoutSeconds();
    if (remaining > 0 && mounted) {
      setState(() {
        _lockoutSeconds = remaining;
      });
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds > 1 && mounted) {
        setState(() {
          _lockoutSeconds--;
        });
      } else if (mounted) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _errorMessage = '';
        });
      }
    });
  }

  void _onKeyPress(String digit) {
    if (_lockoutSeconds > 0) return;
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
    if (_lockoutSeconds > 0) return;
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return;
    }

    final label = event.logicalKey.keyLabel;
    if (RegExp(r'^[0-9]$').hasMatch(label)) {
      _onKeyPress(label);
    }
  }

  Future<void> _submitPin() async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    if (pinProvider.hasPinSet) {
      try {
        final valid = await pinProvider.unlock(_pinInput);
        if (mounted && !valid) {
          setState(() {
            _pinInput = '';
            _errorMessage = 'PIN salah. Coba lagi.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _pinInput = '';
          _errorMessage = msg;
        });
        await _checkLockoutStatus();
      }
    } else {
      try {
        await pinProvider.setupNewPin(_pinInput);
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _pinInput = '';
          _errorMessage = msg;
        });
      }
    }
  }

  void _showResetPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset / Lupa PIN'),
        content: const Text(
          'Mereset PIN akan menghapus PIN pengaman saat ini dan Anda akan diminta membuat PIN baru saat membuka aplikasi.\n\nApakah Anda yakin ingin menghapus PIN lama?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await Provider.of<PinProvider>(context, listen: false).resetPin();
              if (!mounted) return;
              setState(() {
                _pinInput = '';
                _errorMessage = '';
                _lockoutSeconds = 0;
              });
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    VoidCallback? onPressed,
    Widget? child,
  }) {
    final isDisabled = _lockoutSeconds > 0;
    return Container(
      margin: const EdgeInsets.all(5),
      child: Material(
        color: isDisabled ? AppTheme.bgLight : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: isDisabled ? null : (onPressed ?? () => _onKeyPress(text)),
          child: Container(
            width: 66,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child:
                child ??
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDisabled
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                  ),
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
          return Scaffold(
            backgroundColor: AppTheme.bgLight,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo.mark(size: 72, shadow: true),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: AppTheme.primaryTeal,
                        backgroundColor: AppTheme.primaryTealLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (pinProvider.isUnlocked) {
          return widget.child;
        }

        final isSetupMode = !pinProvider.hasPinSet;

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: KeyboardListener(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandLogo.mark(size: 82, shadow: true),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSetupMode ? 'Buat PIN 6 digit' : 'Masukkan PIN',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
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
                                color: isFilled
                                    ? AppTheme.primaryTeal
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isFilled
                                      ? AppTheme.primaryTeal
                                      : AppTheme.borderLight,
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_lockoutSeconds > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Terkunci! Coba lagi dalam $_lockoutSeconds detik',
                              style: TextStyle(
                                color: AppTheme.dangerRed,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        // Keypad
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                '1',
                                '2',
                                '3',
                              ].map((d) => _buildKeypadButton(d)).toList(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                '4',
                                '5',
                                '6',
                              ].map((d) => _buildKeypadButton(d)).toList(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                '7',
                                '8',
                                '9',
                              ].map((d) => _buildKeypadButton(d)).toList(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 84),
                                _buildKeypadButton('0'),
                                _buildKeypadButton(
                                  '',
                                  onPressed: _onBackspace,
                                  child: Icon(
                                    Icons.backspace_outlined,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (pinProvider.hasPinSet) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _showResetPinDialog,
                            icon: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            label: Text(
                              'Lupa PIN?',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
