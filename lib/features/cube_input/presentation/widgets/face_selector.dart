import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/features/cube_input/state/cube_input_provider.dart';

/// Selector untuk memilih sisi kubus aktif (saat mode single-face).
class FaceSelector extends ConsumerWidget {
  const FaceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFace = ref.watch(
      cubeInputProvider.select((s) => s.activeFace),
    );

    final faceLabels = {
      CubeFace.U: ('U', 'Atas'),
      CubeFace.D: ('D', 'Bawah'),
      CubeFace.F: ('F', 'Depan'),
      CubeFace.B: ('B', 'Belakang'),
      CubeFace.L: ('L', 'Kiri'),
      CubeFace.R: ('R', 'Kanan'),
    };

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: CubeFace.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final face = CubeFace.values[index];
          final isActive = face == activeFace;
          final label = faceLabels[face]!;
          final centerColor = centerColorForFace(face);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(cubeInputProvider.notifier).setActiveFace(face);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? centerColor.color.withOpacity(0.18)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? centerColor.color.withOpacity(0.8)
                      : Colors.white.withOpacity(0.06),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: centerColor.color.withOpacity(0.25),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: centerColor.color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.$1,
                        style: GoogleFonts.outfit(
                          color: isActive ? Colors.white : Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        label.$2,
                        style: GoogleFonts.outfit(
                          color: isActive
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white30,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
