import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/features/cube_input/presentation/widgets/single_face_grid.dart';

/// Tampilan jaring-jaring (unfolded) kubus — bentuk cross standar:
///
///         [U]
///    [L] [F] [R] [B]
///         [D]
///
/// Scrollable secara vertikal untuk layar kecil.
class CubeUnfoldedView extends ConsumerWidget {
  const CubeUnfoldedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Sizing calculation with a larger safety margin to fit 4 face grids and margins:
    // TotalWidth = 12 * cellSize + 100
    final cellSize = ((screenWidth - 110) / 12).clamp(16.0, 36.0);
    final faceWidth = cellSize * 3 + 18;

    final faceWidget = (CubeFace face) => SingleFaceGrid(
          face: face,
          cellSize: cellSize,
          showLabel: false,
        );

    // Empty placeholder matching exactly one face size (including borders & padding)
    final placeholder = SizedBox(
      width: faceWidth,
      height: faceWidth,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baris 1: label
              _buildFaceLabel('Atas (U)', centerColorForFace(CubeFace.U).color),
              const SizedBox(height: 4),
  
              // Baris 2: U (di atas F)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  placeholder,
                  const SizedBox(width: 4),
                  faceWidget(CubeFace.U),
                  const SizedBox(width: 4),
                  placeholder,
                  const SizedBox(width: 4),
                  placeholder,
                ],
              ),

            const SizedBox(height: 4),

            // Label baris tengah
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: faceWidth,
                  child: _buildFaceLabel(
                    'Kiri (L)',
                    centerColorForFace(CubeFace.L).color,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: faceWidth,
                  child: _buildFaceLabel(
                    'Depan (F)',
                    centerColorForFace(CubeFace.F).color,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: faceWidth,
                  child: _buildFaceLabel(
                    'Kanan (R)',
                    centerColorForFace(CubeFace.R).color,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: faceWidth,
                  child: _buildFaceLabel(
                    'Belakang (B)',
                    centerColorForFace(CubeFace.B).color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Baris 3: L, F, R, B (horizontal strip)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                faceWidget(CubeFace.L),
                const SizedBox(width: 4),
                faceWidget(CubeFace.F),
                const SizedBox(width: 4),
                faceWidget(CubeFace.R),
                const SizedBox(width: 4),
                faceWidget(CubeFace.B),
              ],
            ),

            const SizedBox(height: 4),

            // Label D
            _buildFaceLabel(
              'Bawah (D)',
              centerColorForFace(CubeFace.D).color,
            ),
            const SizedBox(height: 4),

            // Baris 4: D (di bawah F)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                placeholder,
                const SizedBox(width: 4),
                faceWidget(CubeFace.D),
                const SizedBox(width: 4),
                placeholder,
                const SizedBox(width: 4),
                placeholder,
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFaceLabel(String label, Color color) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color.withOpacity(0.8),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
