import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen barcode / QR scanner — supermarket-style real-time scan
// Compatible with mobile_scanner ^6.0
// ─────────────────────────────────────────────────────────────────────────────
class QrScannerSheet extends ConsumerStatefulWidget {
  const QrScannerSheet({super.key});

  @override
  ConsumerState<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends ConsumerState<QrScannerSheet>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.dataMatrix,
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-start camera when app comes back to foreground
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _handled = true;
        // Vibrate feedback via controller (if supported)
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;

    return Scaffold(
      backgroundColor: Colors.black,
      // ── AppBar ────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isSw ? 'Skani Bidhaa' : 'Scan Product',
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Torch toggle
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (_, state, __) {
              if (state.error != null) return const SizedBox.shrink();
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: isSw ? 'Tochi' : 'Torch',
                icon: Icon(
                  torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: torchOn ? Colors.yellow : Colors.white,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // Camera flip
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (_, state, __) {
              if (state.error != null || (state.availableCameras ?? 0) < 2) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: isSw ? 'Badilisha Kamera' : 'Flip Camera',
                icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                onPressed: () => _controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      // ── Body ──────────────────────────────────────────────────────
      body: ValueListenableBuilder<MobileScannerState>(
        valueListenable: _controller,
        builder: (context, state, child) {
          // Error state (permission denied, no camera, etc.)
          if (state.error != null) {
            return _ErrorView(
              error: state.error!,
              isSw: isSw,
              onRetry: () async {
                setState(() {});
                await _controller.start();
              },
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Camera preview ──────────────────────────────────
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) => _ErrorView(
                  error: error,
                  isSw: isSw,
                  onRetry: () async {
                    setState(() {});
                    await _controller.start();
                  },
                ),
              ),

              // ── Scan window overlay ──────────────────────────────
              _ScanOverlay(isSw: isSw),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan overlay — supermarket-style viewfinder with animated line
// ─────────────────────────────────────────────────────────────────────────────
class _ScanOverlay extends StatefulWidget {
  final bool isSw;
  const _ScanOverlay({required this.isSw});

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _lineCtrl;
  late Animation<double>   _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxSize = (size.width * 0.72).clamp(220.0, 300.0);
    final top    = (size.height - boxSize) / 2 - 40;

    return Stack(
      children: [
        // Semi-transparent overlay with cut-out
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(
            boxSize: boxSize,
            offsetY: top,
          ),
        ),

        // Viewfinder corners
        Positioned(
          top: top,
          left: (size.width - boxSize) / 2,
          child: SizedBox(
            width: boxSize, height: boxSize,
            child: Stack(
              children: [
                // Top-left
                Positioned(top: 0, left: 0,  child: _Corner()),
                // Top-right
                Positioned(top: 0, right: 0, child: _Corner(flipX: true)),
                // Bottom-left
                Positioned(bottom: 0, left: 0, child: _Corner(flipY: true)),
                // Bottom-right
                Positioned(bottom: 0, right: 0, child: _Corner(flipX: true, flipY: true)),

                // Animated scan line
                AnimatedBuilder(
                  animation: _lineAnim,
                  builder: (_, __) => Positioned(
                    top: _lineAnim.value * (boxSize - 4),
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.success.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Instructions
        Positioned(
          top: top + boxSize + 24,
          left: 0, right: 0,
          child: Column(
            children: [
              Text(
                widget.isSw
                    ? 'Elekeza kamera kwenye barcode au QR'
                    : 'Point at product barcode or QR code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSw
                    ? 'Inasaidia: EAN-13, QR Code, Code-128, na zaidi'
                    : 'Supports: EAN-13, QR Code, Code-128, and more',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Tinted overlay with transparent box cut-out
class _OverlayPainter extends CustomPainter {
  final double boxSize;
  final double offsetY;

  const _OverlayPainter({required this.boxSize, required this.offsetY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final left  = (size.width - boxSize) / 2;
    final top   = offsetY;
    final right  = left + boxSize;
    final bottom = top + boxSize;
    final radius = const Radius.circular(12);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromLTRBR(left, top, right, bottom, radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.boxSize != boxSize || old.offsetY != offsetY;
}

// Corner bracket widget
class _Corner extends StatelessWidget {
  final bool flipX;
  final bool flipY;
  const _Corner({this.flipX = false, this.flipY = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipX ? -1 : 1,
      scaleY: flipY ? -1 : 1,
      child: SizedBox(
        width: 24, height: 24,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 20), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(20, 0), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final MobileScannerException error;
  final bool isSw;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.isSw, required this.onRetry});

  String _message(MobileScannerErrorCode code, bool isSw) {
    switch (code) {
      case MobileScannerErrorCode.permissionDenied:
        return isSw
            ? 'Ruhusa ya kamera imekataliwa.\nTafadhali wezesha ruhusa ya kamera katika mipangilio ya simu.'
            : 'Camera permission denied.\nPlease enable camera permission in device settings.';
      case MobileScannerErrorCode.unsupported:
        return isSw
            ? 'Kifaa hiki hakisaidii skana.'
            : 'This device does not support the scanner.';
      default:
        return isSw
            ? 'Hitilafu ya kamera imetokea.\nJaribu tena.'
            : 'Camera error occurred.\nPlease try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              _message(error.errorCode, isSw),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (error.errorCode == MobileScannerErrorCode.permissionDenied)
              OutlinedButton.icon(
                onPressed: () {
                  // Direct user to settings
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                label: Text(
                  isSw ? 'Funga' : 'Close',
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isSw ? 'Jaribu tena' : 'Try again'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Push the full-screen scanner and return the scanned code string.
/// Returns null if the user cancelled or an error occurred.
Future<String?> showQrScanner(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const QrScannerSheet(),
    ),
  );
}
