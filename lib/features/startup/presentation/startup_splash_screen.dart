import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';

const _brandGreen = Color(0xFF006B43);
const _brandGreenMuted = Color(0xFF3F7E61);
const _brandOrange = Color(0xFFF2751C);
const _dangerRed = Color(0xFFC22919);

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
  bool _hasEntered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(
      begin: 0.99,
      end: 1.02,
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
      _hasEntered = false;
      _startupFuture = _bootstrap();
    });
  }

  void _enterApp() {
    if (!mounted || _hasEntered) return;
    setState(() => _hasEntered = true);
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
          child: ready && _hasEntered
              ? widget.child
              : _SplashBody(
                  key: const ValueKey('startup-splash'),
                  logoScale: _logoScale,
                  error: snapshot.error,
                  onRetry: _retry,
                  onEnter: _enterApp,
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
  final VoidCallback onEnter;

  const _SplashBody({
    super.key,
    required this.logoScale,
    required this.error,
    required this.onRetry,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Scaffold(
      body: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasError ? onRetry : onEnter,
          child: _SplashLayout(logoScale: logoScale, error: error),
        ),
      ),
    );
  }
}

class _SplashLayout extends StatelessWidget {
  final Animation<double> logoScale;
  final Object? error;

  const _SplashLayout({required this.logoScale, required this.error});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFBFEFC), Color(0xFFF1FAF5)],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth < 560 || constraints.maxHeight < 520;
              final logoSize = isCompact ? 126.0 : 166.0;
              final titleSize = isCompact ? 28.0 : 34.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 20 : 32,
                  24,
                  isCompact ? 20 : 32,
                  isCompact ? 22 : 30,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _CenteredBrand(
                          logoScale: logoScale,
                          logoSize: logoSize,
                          titleSize: titleSize,
                          error: error,
                        ),
                      ),
                    ),
                    const _BottomPrompt(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CenteredBrand extends StatelessWidget {
  final Animation<double> logoScale;
  final double logoSize;
  final double titleSize;
  final Object? error;

  const _CenteredBrand({
    required this.logoScale,
    required this.logoSize,
    required this.titleSize,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: logoScale,
          child: Image.asset(
            AppConstants.appLogoAsset,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Firdan Farma',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _brandGreen,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              'Aplikasi gagal dimuat. Klik dimana saja untuk mencoba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _dangerRed.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomPrompt extends StatelessWidget {
  const _BottomPrompt();

  @override
  Widget build(BuildContext context) {
    return Text(
      'click dimana saja untuk lanjut',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.lerp(_brandGreenMuted, _brandOrange, 0.08),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}
