import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/shared/widgets/brand_logo.dart';

class StartupSplashScreen extends StatefulWidget {
  final Widget child;

  const StartupSplashScreen({super.key, required this.child});

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  late Future<void> _startupFuture;
  late final AnimationController _controller;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(
      begin: 0.985,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _startupFuture = _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    await Future.wait<dynamic>([
      initializeDateFormatting('id_ID', null),
      DatabaseHelper.instance.database,
    ]);

    final elapsed = DateTime.now().difference(startedAt);
    const minimumSplashTime = Duration(milliseconds: 950);
    if (elapsed < minimumSplashTime) {
      await Future<void>.delayed(minimumSplashTime - elapsed);
    }
  }

  void _retry() {
    setState(() {
      _startupFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        final ready =
            snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: ready
              ? widget.child
              : _SplashBody(
                  key: const ValueKey('startup-splash'),
                  logoScale: _logoScale,
                  error: snapshot.error,
                  onRetry: _retry,
                ),
        );
      },
    );
  }
}

class _SplashBody extends StatelessWidget {
  final Animation<double> logoScale;
  final Object? error;
  final VoidCallback onRetry;

  const _SplashBody({
    super.key,
    required this.logoScale,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgLight, AppTheme.bgSubtle],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: logoScale,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: const BrandLogo.full(width: 230),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasError ? 'Startup perlu diulang' : 'Menyiapkan kasir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (hasError)
                    Column(
                      children: [
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.dangerRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: 230,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          color: AppTheme.primaryTeal,
                          backgroundColor: AppTheme.primaryTealLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
