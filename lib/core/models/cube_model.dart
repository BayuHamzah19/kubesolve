import 'cube_enums.dart';

/// Model data untuk satu sisi kubus (3x3 grid).
/// Index layout:
///   [0][1][2]
///   [3][4][5]   <-- index 4 = center piece (tetap)
///   [6][7][8]
class FaceModel {
  final CubeFace face;
  final List<CubeColor> cells; // 9 elemen

  FaceModel({required this.face, required this.cells})
      : assert(cells.length == 9);

  /// Buat sisi baru dengan center piece sudah ter-set, sisanya kosong.
  factory FaceModel.empty(CubeFace face) {
    final cells = List<CubeColor>.filled(9, CubeColor.none);
    cells[4] = centerColorForFace(face); // Center piece tetap
    return FaceModel(face: face, cells: cells);
  }

  /// Buat sisi yang sudah solved (semua warna = center color).
  factory FaceModel.solved(CubeFace face) {
    final color = centerColorForFace(face);
    return FaceModel(face: face, cells: List.filled(9, color));
  }

  /// Copy sisi ini dengan satu cell diganti warnanya.
  FaceModel setCell(int index, CubeColor color) {
    if (index == 4) return this; // Center piece tidak bisa diubah
    final newCells = List<CubeColor>.from(cells);
    newCells[index] = color;
    return FaceModel(face: face, cells: newCells);
  }

  /// Konversi 9 cell ke string 9 karakter untuk Kociemba.
  String toKociembaString() {
    return cells.map((c) => c.toFaceChar).join();
  }

  @override
  String toString() => '${face.name}: ${toKociembaString()}';
}

/// Model utama: keseluruhan kubus 3x3x3 (6 sisi).
/// Format string Kociemba 54 karakter: UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB
class CubeModel {
  final Map<CubeFace, FaceModel> faces;

  CubeModel({required this.faces});

  /// Buat kubus kosong (hanya center pieces yang terisi).
  factory CubeModel.empty() {
    return CubeModel(
      faces: {
        for (final face in CubeFace.values) face: FaceModel.empty(face),
      },
    );
  }

  /// Buat kubus solved.
  factory CubeModel.solved() {
    return CubeModel(
      faces: {
        for (final face in CubeFace.values) face: FaceModel.solved(face),
      },
    );
  }

  /// Set warna cell tertentu pada sisi tertentu.
  CubeModel setCell(CubeFace face, int index, CubeColor color) {
    final newFaces = Map<CubeFace, FaceModel>.from(faces);
    newFaces[face] = faces[face]!.setCell(index, color);
    return CubeModel(faces: newFaces);
  }

  /// Konversi ke string 54 karakter format Kociemba.
  /// Urutan: U(9) + R(9) + F(9) + D(9) + L(9) + B(9)
  String toKociembaString() {
    final buffer = StringBuffer();
    for (final face in [
      CubeFace.U,
      CubeFace.R,
      CubeFace.F,
      CubeFace.D,
      CubeFace.L,
      CubeFace.B,
    ]) {
      buffer.write(faces[face]!.toKociembaString());
    }
    return buffer.toString();
  }

  /// Cek apakah semua cell sudah diisi (tidak ada CubeColor.none).
  bool get isComplete {
    return faces.values.every(
      (face) => face.cells.every((c) => c != CubeColor.none),
    );
  }

  /// Hitung berapa cell yang sudah terisi.
  int get filledCount {
    int count = 0;
    for (final face in faces.values) {
      for (final c in face.cells) {
        if (c != CubeColor.none) count++;
      }
    }
    return count;
  }

  /// Reset semua sisi (kembali ke empty, hanya center piece).
  CubeModel reset() => CubeModel.empty();

  @override
  String toString() => toKociembaString();
}
