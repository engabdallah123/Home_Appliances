import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/app_colors.dart';

class CameraBarcodeScannerScreen extends StatefulWidget {
  final String title;

  const CameraBarcodeScannerScreen({
    super.key,
    this.title = "مسح باركود المنتج",
  });

  static Future<String?> scan(BuildContext context, {String title = "مسح باركود المنتج"}) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraBarcodeScannerScreen(title: title),
      ),
    );
  }

  @override
  State<CameraBarcodeScannerScreen> createState() => _CameraBarcodeScannerScreenState();
}

class _CameraBarcodeScannerScreenState extends State<CameraBarcodeScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _hasScanned = false;
  bool _torchOn = false;
  bool _hasCameraError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        setState(() {
          _hasScanned = true;
        });
        Navigator.pop(context, code.trim());
      }
    }
  }

  Future<void> _showManualBarcodeDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.keyboard_alt_rounded, color: AppColors.cyan),
              SizedBox(width: 8),
              Text(
                "إدخال الباركود يدوياً",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "اكتب رقم الباركود هنا...",
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("إلغاء", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final code = textController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(dialogCtx, code);
                }
              },
              child: const Text("تأكيد"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _hasScanned = true;
      });
      Navigator.pop(context, result);
    }
  }

  Widget _buildErrorWidget(MobileScannerException error) {
    String message = "تعذر تشغيل الكاميرا.";
    String hint = "يرجى التأكد من منح إذن الكاميرا أو إدخال الباركود يدوياً.";

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = "إذن استخدام الكاميرا غير مفعل";
        hint = "يرجى تفعيل صلاحية الكاميرا لتطبيق Cashier من إعدادات الهاتف.";
        break;
      case MobileScannerErrorCode.unsupported:
        message = "الكاميرا غير مدعومة على هذا الجهاز";
        hint = "يمكنك استخدام ميزة الإدخال اليدوي للباركود.";
        break;
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.genericError:
      default:
        message = "حدث خطأ أثناء تشغيل الكاميرا";
        hint = "يرجى الضغط على إعادة المحاولة أو إدخال الباركود يدوياً.";
        break;
    }

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.no_photography_rounded,
                color: Colors.redAccent,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    setState(() {
                      _hasCameraError = false;
                    });
                    try {
                      await _scannerController.start();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("إعادة المحاولة", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: const BorderSide(color: AppColors.cyan),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showManualBarcodeDialog,
                  icon: const Icon(Icons.keyboard_alt_rounded, size: 18),
                  label: const Text("إدخال يدوي"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "إدخال يدوي",
            icon: const Icon(Icons.keyboard_alt_outlined, color: AppColors.cyan),
            onPressed: _showManualBarcodeDialog,
          ),
          IconButton(
            tooltip: "الفلاش",
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () async {
              try {
                await _scannerController.toggleTorch();
                setState(() {
                  _torchOn = !_torchOn;
                });
              } catch (_) {}
            },
          ),
          IconButton(
            tooltip: "تبديل الكاميرا",
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () async {
              try {
                await _scannerController.switchCamera();
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return _buildErrorWidget(error);
            },
          ),

          // Custom Scanner Overlay with Viewfinder
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cyan, width: 2.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner markers
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),

                  // Center guideline
                  Center(
                    child: Container(
                      height: 2,
                      width: 230,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instruction Text & Manual Entry button below scanner
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: AppColors.cyan, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "وجّه الكاميرا نحو باركود المنتج للمسح تلقائياً",
                        style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showManualBarcodeDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.keyboard_alt_outlined, color: AppColors.cyan, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "أو اضغط هنا لإدخال الباركود يدوياً",
                            style: TextStyle(color: AppColors.cyan, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
