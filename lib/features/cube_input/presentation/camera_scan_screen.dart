import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/features/cube_input/state/cube_input_provider.dart';

class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  bool _isProcessing = false;

  // Scan order: Front -> Right -> Back -> Left -> Up -> Down
  final List<CubeFace> _scanOrder = [
    CubeFace.F,
    CubeFace.R,
    CubeFace.B,
    CubeFace.L,
    CubeFace.U,
    CubeFace.D,
  ];
  int _currentScanIndex = 0;

  // Detected colors for confirmation overlay
  List<CubeColor>? _detectedColors;
  String? _capturedFilePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium, // Medium is faster to decode and plenty of resolution
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (e is CameraException && e.code == 'CameraAccessDenied') {
        setState(() {
          _isPermissionDenied = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  CubeFace get _currentFace => _scanOrder[_currentScanIndex];

  Future<void> _captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      HapticFeedback.mediumImpact();
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Run image processing
      final detected = await compute(_processCubeImage, bytes);

      if (mounted) {
        // Center color of the active face is fixed
        final centerColor = centerColorForFace(_currentFace);
        final finalDetected = List<CubeColor>.from(detected);
        finalDetected[4] = centerColor; // lock center

        setState(() {
          _isProcessing = false;
          _detectedColors = finalDetected;
          _capturedFilePath = file.path;
        });
      }
    } catch (e) {
      debugPrint('Error during scanning: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menganalisis gambar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Pure function run in separate isolate (compute) for smooth UI frames
  static List<CubeColor> _processCubeImage(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return List<CubeColor>.filled(9, CubeColor.none);
    }

    // We assume Rubik's cube is centered in the photo
    final int width = decoded.width;
    final int height = decoded.height;
    final int size = (math.min(width, height) * 0.65).toInt();

    final int startX = (width / 2 - size / 2).toInt();
    final int startY = (height / 2 - size / 2).toInt();

    final List<CubeColor> detected = [];

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        // Center coordinate of each cell in the image
        final int cellX = (startX + (c + 0.5) * (size / 3)).toInt();
        final int cellY = (startY + (r + 0.5) * (size / 3)).toInt();

        // Sample a small 5x5 average around the cell center to avoid single-pixel noise
        double avgR = 0, avgG = 0, avgB = 0;
        int count = 0;

        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -2; dy <= 2; dy++) {
            final int px = cellX + dx;
            final int py = cellY + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              final img.Color pixel = decoded.getPixel(px, py);
              avgR += pixel.r.toDouble();
              avgG += pixel.g.toDouble();
              avgB += pixel.b.toDouble();
              count++;
            }
          }
        }

        avgR /= count;
        avgG /= count;
        avgB /= count;

        final hsv = _rgbToHsv(avgR, avgG, avgB);
        final color = _classifyHsvColor(hsv['h']!, hsv['s']!, hsv['v']!);
        
        // Log to console for debugging and calibration
        debugPrint('Cell ${r * 3 + c}: R=${avgR.toStringAsFixed(1)}, G=${avgG.toStringAsFixed(1)}, B=${avgB.toStringAsFixed(1)} | H=${hsv['h']!.toStringAsFixed(1)}, S=${hsv['s']!.toStringAsFixed(2)}, V=${hsv['v']!.toStringAsFixed(2)} => Detected: ${color.name}');
        
        detected.add(color);
      }
    }

    return detected;
  }

  static Map<String, double> _rgbToHsv(double r, double g, double b) {
    final double rf = r / 255.0;
    final double gf = g / 255.0;
    final double bf = b / 255.0;

    final double max = [rf, gf, bf].reduce((c, n) => c > n ? c : n);
    final double min = [rf, gf, bf].reduce((c, n) => c < n ? c : n);
    final double delta = max - min;

    double h = 0;
    if (delta > 0) {
      if (max == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (max == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else if (max == bf) {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) {
      h += 360;
    }

    final double s = max == 0 ? 0 : delta / max;
    final double v = max;

    return {'h': h, 's': s, 'v': v};
  }

  static CubeColor _classifyHsvColor(double h, double s, double v) {
    // 1. White detection
    // White has very low saturation. Even under warm yellow lights, saturation is low.
    if (s < 0.28) {
      if (v > 0.35) {
        return CubeColor.white;
      }
    }

    // 2. Blue: Hue 165 - 260
    if (h >= 165 && h <= 260) {
      if (s > 0.25) {
        return CubeColor.blue;
      }
    }

    // 3. Green: Hue 76 - 165
    if (h >= 76 && h < 165) {
      if (s > 0.25) {
        return CubeColor.green;
      }
    }

    // 4. Yellow: Hue 42 - 75
    if (h >= 42 && h < 75) {
      if (s > 0.28) {
        return CubeColor.yellow;
      }
    }

    // 5. Orange: Hue 11 - 42
    if (h >= 11 && h < 42) {
      if (s > 0.28) {
        return CubeColor.orange;
      }
    }

    // 6. Red: Hue < 11 or > 335
    if (h < 11 || h > 335) {
      if (s > 0.28) {
        return CubeColor.red;
      }
    }

    // Fallbacks if saturation is low but color is present
    if (h >= 42 && h < 75) return CubeColor.yellow;
    if (h >= 76 && h < 165) return CubeColor.green;
    if (h >= 165 && h < 260) return CubeColor.blue;
    if (h >= 11 && h < 42) return CubeColor.orange;

    return CubeColor.red;
  }

  void _saveAndNext() {
    if (_detectedColors == null) return;

    HapticFeedback.lightImpact();
    // Update face colors in the state provider
    ref.read(cubeInputProvider.notifier).setFaceColors(_currentFace, _detectedColors!);

    if (_currentScanIndex < _scanOrder.length - 1) {
      setState(() {
        _currentScanIndex++;
        _detectedColors = null;
        _capturedFilePath = null;
      });
    } else {
      // Completed all 6 faces!
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pindaian 6 sisi selesai! Silakan periksa hasil input Anda.'),
          backgroundColor: Color(0xFF00D4AA),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _cycleCellColor(int index) {
    if (index == 4 || _detectedColors == null) return;

    HapticFeedback.selectionClick();
    final colors = [
      CubeColor.white,
      CubeColor.yellow,
      CubeColor.green,
      CubeColor.blue,
      CubeColor.red,
      CubeColor.orange,
    ];

    setState(() {
      final currentColor = _detectedColors![index];
      final nextIndex = (colors.indexOf(currentColor) + 1) % colors.length;
      _detectedColors![index] = colors[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text('Pindai Sisi: ${_faceLabel(_currentFace)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Sisi ${_currentScanIndex + 1}/6',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isPermissionDenied) {
      return _buildPermissionDeniedView();
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),

        // Scanning overlay viewport
        Positioned.fill(
          child: _buildScannerOverlay(),
        ),

        // Processing Loading State
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.85),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 16),
                  Text(
                    'Menganalisis warna sisi...',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        // Confirmation dialog / Bottom panel
        if (_detectedColors != null)
          _buildConfirmationPanel(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    final faceColor = centerColorForFace(_currentFace).color;

    return Column(
      children: [
        // Top instruction bar
        Container(
          width: double.infinity,
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            children: [
              Text(
                'Luruskan sisi ${_faceLabel(_currentFace)} dengan kotak',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'PENTING: Kuning harus tetap di atas, Hijau tetap di depan saat memutar!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.yellowAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Viewport square
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: faceColor, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // 3x3 Grid thin lines
              _buildOverlayGridLines(),
              // Center square visual indicator
              Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: faceColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: faceColor, width: 2),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Bottom capture bar
        Container(
          width: double.infinity,
          color: Colors.black54,
          padding: const EdgeInsets.only(bottom: 24, top: 16),
          child: Center(
            child: FloatingActionButton.large(
              onPressed: _detectedColors == null ? _captureAndScan : null,
              backgroundColor: faceColor,
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayGridLines() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
              Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF161626),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Konfirmasi Hasil Pindaian',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Titik pada gambar menunjukkan koordinat warna yang diambil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Captured Image Visualizer
                if (_capturedFilePath != null)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            File(_capturedFilePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SamplingGridPainter(
                              detectedColors: _detectedColors!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3x3 Grid Editor
                SizedBox(
                  width: 130,
                  height: 130,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                    ),
                    itemBuilder: (ctx, idx) {
                      final color = _detectedColors![idx];
                      final isCenter = idx == 4;

                      return GestureDetector(
                        onTap: isCenter ? null : () => _cycleCellColor(idx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCenter ? Colors.white : Colors.white24,
                              width: isCenter ? 2 : 1,
                            ),
                          ),
                          child: isCenter
                              ? const Center(child: Icon(Icons.lock, color: Colors.white70, size: 12))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _detectedColors = null;
                      _capturedFilePath = null;
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pindai Ulang'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAndNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_currentScanIndex < _scanOrder.length - 1 ? 'Simpan & Lanjut' : 'Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              'Akses Kamera Ditolak',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Aplikasi ini memerlukan akses ke kamera perangkat Anda untuk memindai sisi Rubik.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  String _faceLabel(CubeFace face) {
    switch (face) {
      case CubeFace.U:
        return 'Atas (Kuning)';
      case CubeFace.D:
        return 'Bawah (Putih)';
      case CubeFace.F:
        return 'Depan (Hijau)';
      case CubeFace.B:
        return 'Belakang (Biru)';
      case CubeFace.L:
        return 'Kiri (Merah)';
      case CubeFace.R:
        return 'Kanan (Oranye)';
    }
  }
}

class SamplingGridPainter extends CustomPainter {
  final List<CubeColor> detectedColors;

  SamplingGridPainter({required this.detectedColors});

  @override
  void paint(Canvas canvas, Size size) {
    final double canvasSize = math.min(size.width, size.height);
    final double boxSize = canvasSize * 0.65;

    final double startX = (size.width - boxSize) / 2;
    final double startY = (size.height - boxSize) / 2;

    final Paint borderPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Bounding Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, startY, boxSize, boxSize),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    // Sampling dots
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final double cx = startX + (c + 0.5) * (boxSize / 3);
        final double cy = startY + (r + 0.5) * (boxSize / 3);
        final int idx = r * 3 + c;
        final colorVal = detectedColors[idx].color;

        // Black outer circle
        canvas.drawCircle(Offset(cx, cy), 5.5, Paint()..color = Colors.black);
        // White boundary ring
        canvas.drawCircle(Offset(cx, cy), 4.5, Paint()..color = Colors.white);
        // Inner color dot
        canvas.drawCircle(Offset(cx, cy), 3.0, Paint()..color = colorVal);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SamplingGridPainter oldDelegate) {
    return oldDelegate.detectedColors != detectedColors;
  }
}
