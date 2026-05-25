import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/features/cube_input/state/cube_input_provider.dart';

/// Widget grid 3x3 untuk satu sisi kubus.
/// Digunakan baik di single-face view maupun di unfolded view.
class SingleFaceGrid extends ConsumerWidget {
  final CubeFace face;
  final double cellSize;
  final bool showLabel;

  const SingleFaceGrid({
    super.key,
    required this.face,
    this.cellSize = 60,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faceModel = ref.watch(
      cubeInputProvider.select((s) => s.cube.faces[face]!),
    );

    final faceLabels = {
      CubeFace.U: 'Atas (U)',
      CubeFace.D: 'Bawah (D)',
      CubeFace.F: 'Depan (F)',
      CubeFace.B: 'Belakang (B)',
      CubeFace.L: 'Kiri (L)',
      CubeFace.R: 'Kanan (R)',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            faceLabels[face]!,
            style: TextStyle(
              color: centerColorForFace(face).color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: SizedBox(
            width: cellSize * 3 + 8,
            height: cellSize * 3 + 8,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final color = faceModel.cells[index];
                final isCenter = index == 4;

                return GestureDetector(
                  onTap: isCenter
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(cubeInputProvider.notifier)
                              .tapCellOnFace(face, index);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: color.color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCenter
                            ? Colors.white.withOpacity(0.35)
                            : Colors.white.withOpacity(0.1),
                        width: isCenter ? 2 : 1,
                      ),
                      boxShadow: color != CubeColor.none
                          ? [
                              BoxShadow(
                                color: color.color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : [],
                    ),
                    child: isCenter
                        ? Center(
                            child: Icon(
                              Icons.lock_rounded,
                              size: cellSize * 0.25,
                              color: (color == CubeColor.white ||
                                      color == CubeColor.yellow)
                                  ? Colors.black38
                                  : Colors.white38,
                            ),
                          )
                        : color == CubeColor.none
                            ? Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  size: cellSize * 0.3,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              )
                            : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
