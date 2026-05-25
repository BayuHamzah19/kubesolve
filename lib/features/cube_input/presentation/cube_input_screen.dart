import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rubik_solver/core/services/ad_manager.dart';
import 'package:rubik_solver/core/widgets/ad_mob_banner.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/core/models/cube_validator.dart';
import 'package:rubik_solver/features/cube_input/state/cube_input_provider.dart';
import 'package:rubik_solver/features/cube_input/presentation/camera_scan_screen.dart';
import 'package:rubik_solver/features/cube_input/presentation/widgets/color_picker_bar.dart';
import 'package:rubik_solver/features/cube_input/presentation/widgets/cube_unfolded_view.dart';
import 'package:rubik_solver/features/cube_input/presentation/widgets/face_selector.dart';
import 'package:rubik_solver/features/cube_input/presentation/widgets/single_face_grid.dart';
import 'package:rubik_solver/features/solver/presentation/solution_screen.dart';
import 'package:rubik_solver/features/solver/state/solver_provider.dart';

class CubeInputScreen extends ConsumerStatefulWidget {
  const CubeInputScreen({super.key});

  @override
  ConsumerState<CubeInputScreen> createState() => _CubeInputScreenState();
}

class _CubeInputScreenState extends ConsumerState<CubeInputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  bool _isUnfoldedView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final initialFace = ref.read(cubeInputProvider).activeFace;
    _pageController = PageController(
      initialPage: CubeFace.values.indexOf(initialFace),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSolvePressed() {
    final cubeState = ref.read(cubeInputProvider);
    final cube = cubeState.cube;

    // Validasi dulu
    final validation = CubeValidator.validate(cube);

    if (!validation.isValid) {
      _showValidationErrors(validation.errors);
      return;
    }

    // Tampilkan dialog tonton iklan rewarded sebelum melihat solusi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              color: Color(0xFF00D4AA),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'Buka Solusi',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Tonton iklan video singkat untuk menampilkan solusi penyelesaian Rubik secara lengkap.',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showRewardedSolveAd(cube);
            },
            child: Text(
              'Tonton Iklan',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedSolveAd(dynamic cube) {
    // Tampilkan loading screen sementara menyiapkan iklan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161626),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
              SizedBox(height: 16),
              Text(
                'Menyiapkan iklan...',
                style: TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.none),
              ),
            ],
          ),
        ),
      ),
    );

    // Tampilkan iklan rewarded
    AdManager.instance.showRewardedAd(
      onRewardEarned: () {
        Navigator.pop(context); // Tutup loading dialog
        _proceedToSolution(cube);
      },
      onAdNotReady: () {
        Navigator.pop(context); // Tutup loading dialog
        // Jika iklan belum siap/gagal, tetap izinkan agar user tidak kesal
        _proceedToSolution(cube);
      },
    );
  }

  void _proceedToSolution(dynamic cube) {
    // Jalankan solver
    ref.read(solverProvider.notifier).solve(cube);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SolutionScreen()),
    );
  }

  void _showValidationErrors(List<String> errors) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Validasi Gagal',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: errors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errors[i],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showResetConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Kubus?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: const Text(
          'Semua warna yang sudah diinput akan dihapus.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cubeInputProvider.notifier).resetCube();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubeState = ref.watch(cubeInputProvider);
    final progress = cubeState.cube.filledCount / 54;

    ref.listen<CubeFace>(
      cubeInputProvider.select((s) => s.activeFace),
      (previous, next) {
        final index = CubeFace.values.indexOf(next);
        if (_pageController.hasClients &&
            _pageController.page?.round() != index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      },
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const AdMobBanner(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: const Color(0xFF0A0A0F).withOpacity(0.6),
              elevation: 0,
              title: Text(
                'KubeSolve',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              actions: [
                _buildAppBarButton(
                  icon: Icons.camera_alt_rounded,
                  tooltip: 'Pindai Kamera',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraScanScreen()),
                    );
                  },
                ),
                _buildAppBarButton(
                  icon: _isUnfoldedView ? Icons.view_in_ar : Icons.grid_view_rounded,
                  tooltip: _isUnfoldedView ? 'Tampilan per-sisi' : 'Jaring-jaring',
                  onPressed: () => setState(() => _isUnfoldedView = !_isUnfoldedView),
                ),
                _buildAppBarButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Reset',
                  onPressed: _showResetConfirm,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Aura Glowing Gradient
          Positioned.fill(
            child: Container(
              color: const Color(0xFF07070C),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundGlowPainter(),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Progress bar
                  _buildProgressBar(progress, cubeState.cube.filledCount),
    
                  // Tampilan kubus (toggle antara unfolded dan single-face)
                  Expanded(
                    child: _isUnfoldedView
                        ? const CubeUnfoldedView()
                        : Column(
                            children: [
                              const SizedBox(height: 8),
                              const FaceSelector(),
                          const SizedBox(height: 12),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: CubeFace.values.length,
                              onPageChanged: (index) {
                                ref
                                    .read(cubeInputProvider.notifier)
                                    .setActiveFace(CubeFace.values[index]);
                              },
                              itemBuilder: (context, index) {
                                return Center(
                                  child: SingleFaceGrid(
                                    face: CubeFace.values[index],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),

              // Color Picker
              const ColorPickerBar(),

              const SizedBox(height: 8),

              // Tombol Solve
              _buildSolveButton(cubeState.cube.isComplete),

              const SizedBox(height: 12),

              // Creator Footer
              Center(
                child: Text(
                  'Created by Hazett Corporate',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ],
  ),
);
}

  Widget _buildProgressBar(double progress, int filled) {
    final bool isDone = progress >= 1.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: isDone ? const Color(0xFF00D4AA) : const Color(0xFF6C63FF),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Progress Pengisian',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$filled / 54 Kotak',
                style: TextStyle(
                  color: isDone ? const Color(0xFF00D4AA) : const Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(
                isDone ? const Color(0xFF00D4AA) : const Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolveButton(bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isComplete
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isComplete ? null : const Color(0xFF1E1E30),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _onSolvePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_fix_high,
                color: isComplete ? Colors.white : Colors.white24,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'SELESAIKAN RUBIK',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isComplete ? Colors.white : Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    final Paint paint2 = Paint()
      ..color = const Color(0xFF00D4AA).withOpacity(0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Glow top right (purple)
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 180, paint1);
    // Glow bottom left (teal)
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 200, paint2);
    // Center-ish glow
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      140,
      Paint()
        ..color = const Color(0xFF6C63FF).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 95),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
