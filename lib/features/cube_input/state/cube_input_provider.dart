import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/core/models/cube_model.dart';

/// State untuk input kubus: menyimpan CubeModel, warna terpilih, dan sisi aktif.
class CubeInputState {
  final CubeModel cube;
  final CubeColor selectedColor;
  final CubeFace activeFace;

  const CubeInputState({
    required this.cube,
    required this.selectedColor,
    required this.activeFace,
  });

  factory CubeInputState.initial() => CubeInputState(
        cube: CubeModel.empty(),
        selectedColor: CubeColor.white,
        activeFace: CubeFace.F,
      );

  CubeInputState copyWith({
    CubeModel? cube,
    CubeColor? selectedColor,
    CubeFace? activeFace,
  }) {
    return CubeInputState(
      cube: cube ?? this.cube,
      selectedColor: selectedColor ?? this.selectedColor,
      activeFace: activeFace ?? this.activeFace,
    );
  }
}

/// Notifier untuk mengelola state input kubus.
class CubeInputNotifier extends StateNotifier<CubeInputState> {
  CubeInputNotifier() : super(CubeInputState.initial());

  /// Pilih warna dari color picker.
  void selectColor(CubeColor color) {
    state = state.copyWith(selectedColor: color);
  }

  /// Ganti sisi aktif yang sedang ditampilkan.
  void setActiveFace(CubeFace face) {
    state = state.copyWith(activeFace: face);
  }

  /// Set warna cell pada sisi aktif.
  void setCell(int index, CubeColor color) {
    if (index == 4) return; // Center piece tidak bisa diubah
    final newCube = state.cube.setCell(state.activeFace, index, color);
    state = state.copyWith(cube: newCube);
  }

  /// Set warna cell pada sisi tertentu (untuk unfolded view).
  void setCellOnFace(CubeFace face, int index, CubeColor color) {
    if (index == 4) return;
    final newCube = state.cube.setCell(face, index, color);
    state = state.copyWith(cube: newCube);
  }

  /// Tap cell: terapkan warna yang terpilih.
  void tapCell(int index) {
    setCell(index, state.selectedColor);
  }

  /// Tap cell pada sisi tertentu.
  void tapCellOnFace(CubeFace face, int index) {
    setCellOnFace(face, index, state.selectedColor);
  }

  /// Reset seluruh kubus.
  void resetCube() {
    state = CubeInputState.initial();
  }

  /// Set seluruh 9 warna cell pada sisi tertentu (untuk camera scan).
  void setFaceColors(CubeFace face, List<CubeColor> colors) {
    CubeModel newCube = state.cube;
    for (int i = 0; i < 9; i++) {
      if (i == 4) continue; // Pertahankan center asli
      newCube = newCube.setCell(face, i, colors[i]);
    }
    state = state.copyWith(cube: newCube);
  }
}

/// Provider untuk CubeInputNotifier.
final cubeInputProvider =
    StateNotifierProvider<CubeInputNotifier, CubeInputState>(
  (ref) => CubeInputNotifier(),
);
