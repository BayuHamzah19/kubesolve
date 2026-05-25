import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rubik_solver/core/widgets/ad_mob_banner.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/features/solver/state/solver_provider.dart';

class SolutionScreen extends ConsumerWidget {
  const SolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solverProvider);

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
                'Solusi KubeSolve',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                  tooltip: 'Panduan Pegang Kubus',
                  onPressed: () => _showHoldingGuide(context),
                ),
                const SizedBox(width: 8),
              ],
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withOpacity(0.85), size: 16),
                  onPressed: () {
                    ref.read(solverProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                ),
              ),
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
              child: state.isLoading
                  ? _buildLoading()
                  : state.hasResult
                      ? state.isSuccess
                          ? _buildSolution(context, ref, state)
                          : _buildError(state.result!.errorMessage ?? 'Unknown')
                      : _buildEmpty(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated loading indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      const Color(0xFF6C63FF).withOpacity(0.3),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const Icon(
                  Icons.extension_rounded,
                  color: Color(0xFF6C63FF),
                  size: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Menghitung Solusi...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Menggunakan Algoritma Kociemba Two-Phase',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF6B6B),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memecahkan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                ),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Tidak ada data.',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildSolution(
    BuildContext context,
    WidgetRef ref,
    SolverState state,
  ) {
    final result = state.result!;
    final steps = result.steps;

    if (steps.isEmpty) {
      return _buildAlreadySolved(result);
    }

    final currentStep = state.currentSolveStep!;
    final totalSteps = state.totalSteps;
    final stepIndex = state.currentStep;

    return Column(
      children: [
        // Header info
        _buildSolutionHeader(result, totalSteps),

        // Holding Guide Banner
        _buildHoldingGuideBanner(context),

        const SizedBox(height: 6),

        // Raw notation & verification
        _buildRawNotation(result),

        const SizedBox(height: 8),

        // Progress indicator
        _buildStepProgress(stepIndex, totalSteps),

        const SizedBox(height: 16),

        // Current step card
        Expanded(
          child: _buildCurrentStepCard(currentStep, stepIndex, totalSteps),
        ),

        // Step list (scrollable)
        _buildStepList(ref, steps, stepIndex),

        // Navigation buttons
        _buildNavigationButtons(ref, state),

        const SizedBox(height: 8),

        // Creator Footer
        Center(
          child: Text(
            'Created by Hazett Corporate',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.25),
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAlreadySolved(result) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF00D4AA),
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kubus Sudah Solved!',
            style: TextStyle(
              color: Color(0xFF00D4AA),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada langkah yang diperlukan.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionHeader(result, int totalSteps) {
    final isVerified = result.verified == true;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.15),
            (isVerified
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFFFF6B6B))
                .withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isVerified
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6B6B))
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: isVerified
                  ? const Color(0xFF00D4AA)
                  : const Color(0xFFFF6B6B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'Solusi Terverifikasi ✓'
                      : 'Solusi Ditemukan (Belum Terverifikasi)',
                  style: TextStyle(
                    color: isVerified
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFFFF6B6B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalSteps langkah • ${result.solveDuration.inMilliseconds}ms',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawNotation(result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notasi: ${result.rawSolution}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress(int current, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Langkah ${current + 1}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'dari $total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepCard(currentStep, int index, int total) {
    final faceColorMap = {
      'Atas (Up)': centerColorForFace(CubeFace.U).color,
      'Bawah (Down)': centerColorForFace(CubeFace.D).color,
      'Kanan (Right)': centerColorForFace(CubeFace.R).color,
      'Kiri (Left)': centerColorForFace(CubeFace.L).color,
      'Depan (Front)': centerColorForFace(CubeFace.F).color,
      'Belakang (Back)': centerColorForFace(CubeFace.B).color,
    };

    final String baseFaceChar = currentStep.notation[0];
    final CubeFace activeFace;
    switch (baseFaceChar) {
      case 'U': activeFace = CubeFace.U; break;
      case 'D': activeFace = CubeFace.D; break;
      case 'R': activeFace = CubeFace.R; break;
      case 'L': activeFace = CubeFace.L; break;
      case 'F': activeFace = CubeFace.F; break;
      case 'B': activeFace = CubeFace.B; break;
      default: activeFace = CubeFace.F;
    }

    final accentColor =
        faceColorMap[currentStep.faceName] ?? const Color(0xFF6C63FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  currentStep.notation,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: CubeRotationPainter(
                    activeFace: activeFace,
                    notation: currentStep.notation,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Nama sisi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentStep.faceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Arah putaran
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentStep.direction,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Deskripsi lengkap
          Text(
            currentStep.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepList(WidgetRef ref, List steps, int activeIndex) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: steps.length,
        itemBuilder: (_, i) {
          final isActive = i == activeIndex;
          final isPast = i < activeIndex;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(solverProvider.notifier).goToStep(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6C63FF)
                    : isPast
                        ? const Color(0xFF6C63FF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Colors.white.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  steps[i].notation,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : isPast
                            ? Colors.white70
                            : Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons(WidgetRef ref, SolverState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: state.canGoPrevious
                    ? () {
                        HapticFeedback.lightImpact();
                        ref.read(solverProvider.notifier).previousStep();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(
                    color: state.canGoPrevious
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: state.canGoNext
                    ? () {
                        HapticFeedback.lightImpact();
                        ref.read(solverProvider.notifier).nextStep();
                      }
                    : null,
                icon: const Text('Selanjutnya'),
                label: const Icon(Icons.chevron_right_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.canGoNext
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF2A2A3E),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white30,
                  disabledBackgroundColor: const Color(0xFF2A2A3E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: state.canGoNext ? 4 : 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingGuideBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF6C63FF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PANDUAN PEGANG KUBUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Hijau di depan, Kuning di atas.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showHoldingGuide(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Panduan',
              style: TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHoldingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12121D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            Text(
              'Cara Pegang Kubus',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agar hasil putaran sesuai, pegang kubus dengan posisi awal berikut sebelum memulai langkah pertama:',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _buildGuideRow('F (Front - Depan)', 'Hijau', Colors.green),
              _buildGuideRow('U (Up - Atas)', 'Kuning', Colors.yellow),
              _buildGuideRow('D (Down - Bawah)', 'Putih', Colors.white),
              _buildGuideRow('R (Right - Kanan)', 'Oranye', Colors.orange),
              _buildGuideRow('L (Left - Kiri)', 'Merah', Colors.red),
              _buildGuideRow('B (Back - Belakang)', 'Biru', Colors.blue),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'PENTING: Jangan putar/ubah arah pegangan kubus Anda saat memutar sisi. Sisi HIJAU harus selalu menghadap depan Anda.',
                        style: GoogleFonts.outfit(
                          color: Colors.amber.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mengerti',
              style: GoogleFonts.outfit(
                color: const Color(0xFF00D4AA),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(String label, String colorName, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            colorName,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class CubeRotationPainter extends CustomPainter {
  final CubeFace activeFace;
  final String notation;

  CubeRotationPainter({
    required this.activeFace,
    required this.notation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double L = size.width * 0.28;
    final double dx = L * math.sqrt(3) / 2;
    final double dy = L / 2;

    final Offset C = Offset(size.width / 2, size.height / 2);

    final bool isStandardView = activeFace == CubeFace.U || activeFace == CubeFace.F || activeFace == CubeFace.R;

    final CubeFace face1 = isStandardView ? CubeFace.U : CubeFace.D;
    final CubeFace face2 = isStandardView ? CubeFace.F : CubeFace.L;
    final CubeFace face3 = isStandardView ? CubeFace.R : CubeFace.B;

    Color getCellColor(CubeFace face) {
      final baseColor = centerColorForFace(face).color;
      if (face == activeFace) {
        return baseColor;
      } else {
        return Color.alphaBlend(baseColor.withOpacity(0.22), const Color(0xFF1E1E30));
      }
    }

    final Offset V_uc = C + Offset(0, -L);
    final Offset V_ul = C + Offset(-dx, -dy);
    final Offset V_ur = C + Offset(dx, -dy);
    final Offset V_dc = C + Offset(0, L);
    final Offset V_dl = C + Offset(-dx, dy);
    final Offset V_dr = C + Offset(dx, dy);

    void drawFaceGrid(Offset origin, Offset vec1, Offset vec2, CubeFace face) {
      final borderPaint = Paint()
        ..color = const Color(0xFF0F0F1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          Offset p(double u, double v) {
            return origin + Offset(
              u * vec1.dx + v * vec2.dx,
              u * vec1.dy + v * vec2.dy,
            );
          }

          final Offset p00 = p(i / 3, j / 3);
          final Offset p10 = p((i + 1) / 3, j / 3);
          final Offset p11 = p((i + 1) / 3, (j + 1) / 3);
          final Offset p01 = p(i / 3, (j + 1) / 3);

          final Path cellPath = Path()
            ..moveTo(p00.dx, p00.dy)
            ..lineTo(p10.dx, p10.dy)
            ..lineTo(p11.dx, p11.dy)
            ..lineTo(p01.dx, p01.dy)
            ..close();

          final fillPaint = Paint()
            ..color = getCellColor(face)
            ..style = PaintingStyle.fill;

          canvas.drawPath(cellPath, fillPaint);
          canvas.drawPath(cellPath, borderPaint);
        }
      }
    }

    drawFaceGrid(V_ul, V_uc - V_ul, C - V_ul, face1);
    drawFaceGrid(V_dl, V_ul - V_dl, V_dc - V_dl, face2);
    drawFaceGrid(V_dc, C - V_dc, V_dr - V_dc, face3);

    _drawArrow(canvas, C, V_uc, V_ul, V_ur, V_dc, V_dl, V_dr);
  }

  void _drawArrow(
    Canvas canvas,
    Offset C,
    Offset V_uc,
    Offset V_ul,
    Offset V_ur,
    Offset V_dc,
    Offset V_dl,
    Offset V_dr,
  ) {
    final bool isTop = activeFace == CubeFace.U || activeFace == CubeFace.D;
    final bool isLeft = activeFace == CubeFace.F || activeFace == CubeFace.L;

    Offset origin;
    Offset vec1;
    Offset vec2;

    if (isTop) {
      origin = V_ul;
      vec1 = V_uc - V_ul;
      vec2 = C - V_ul;
    } else if (isLeft) {
      origin = V_dl;
      vec1 = V_ul - V_dl;
      vec2 = V_dc - V_dl;
    } else {
      origin = V_dc;
      vec1 = C - V_dc;
      vec2 = V_dr - V_dc;
    }

    Offset mapPoint(double u, double v) {
      return origin + Offset(
        u * vec1.dx + v * vec2.dx,
        u * vec1.dy + v * vec2.dy,
      );
    }

    final bool isInverted = notation.contains("'");
    final bool isDouble = notation.contains("2");

    const double r = 0.35;
    final List<Offset> arrowPoints = [];

    double startAngle;
    double endAngle;

    if (isTop) {
      if (isInverted) {
        startAngle = -0.7 * math.pi;
        endAngle = 0.7 * math.pi;
      } else {
        startAngle = 0.7 * math.pi;
        endAngle = -0.7 * math.pi;
      }
    } else if (isLeft) {
      if (isInverted) {
        startAngle = -0.2 * math.pi;
        endAngle = 1.2 * math.pi;
      } else {
        startAngle = 1.2 * math.pi;
        endAngle = -0.2 * math.pi;
      }
    } else {
      if (isInverted) {
        startAngle = 0.7 * math.pi;
        endAngle = -0.7 * math.pi;
      } else {
        startAngle = -0.7 * math.pi;
        endAngle = 0.7 * math.pi;
      }
    }

    const int segments = 30;
    for (int i = 0; i <= segments; i++) {
      final double t = startAngle + (endAngle - startAngle) * (i / segments);
      final double u = 0.5 + r * math.cos(t);
      final double v = 0.5 + r * math.sin(t);
      arrowPoints.add(mapPoint(u, v));
    }

    final Color arrowColor = const Color(0xFFFFFFFF);
    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final Path arrowPath = Path();
    if (arrowPoints.isNotEmpty) {
      arrowPath.moveTo(arrowPoints.first.dx, arrowPoints.first.dy);
      for (int i = 1; i < arrowPoints.length; i++) {
        arrowPath.lineTo(arrowPoints[i].dx, arrowPoints[i].dy);
      }
    }

    canvas.drawPath(arrowPath, arrowPaint);

    if (arrowPoints.length >= 2) {
      final Offset endPoint = arrowPoints.last;
      final Offset prevPoint = arrowPoints[arrowPoints.length - 2];
      
      final Offset tangent = endPoint - prevPoint;
      final double angle = math.atan2(tangent.dy, tangent.dx);

      const double arrowSize = 12.0;

      final Path headPath = Path()
        ..moveTo(endPoint.dx, endPoint.dy)
        ..lineTo(
          endPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
          endPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
        )
        ..lineTo(
          endPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
          endPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
        )
        ..close();

      final headPaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(headPath, headPaint);

      if (isDouble) {
        final Offset startPoint = arrowPoints.first;
        final Offset nextPoint = arrowPoints[1];
        final Offset startTangent = startPoint - nextPoint;
        final double startAngle = math.atan2(startTangent.dy, startTangent.dx);

        final Path startHeadPath = Path()
          ..moveTo(startPoint.dx, startPoint.dy)
          ..lineTo(
            startPoint.dx - arrowSize * math.cos(startAngle - math.pi / 6),
            startPoint.dy - arrowSize * math.sin(startAngle - math.pi / 6),
          )
          ..lineTo(
            startPoint.dx - arrowSize * math.cos(startAngle + math.pi / 6),
            startPoint.dy - arrowSize * math.sin(startAngle + math.pi / 6),
          )
          ..close();

        canvas.drawPath(startHeadPath, headPaint);

        final Offset center = mapPoint(0.5, 0.5);
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '2',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CubeRotationPainter oldDelegate) {
    return oldDelegate.activeFace != activeFace || oldDelegate.notation != notation;
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
