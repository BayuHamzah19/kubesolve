import 'cube_enums.dart';
import 'cube_model.dart';

/// Hasil validasi kubus. Berisi status valid/tidak dan pesan error.
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.valid() =>
      const ValidationResult(isValid: true, errors: []);

  factory ValidationResult.invalid(List<String> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

/// Validator kubus Rubik. Melakukan pengecekan sebelum solving.
class CubeValidator {
  /// Validasi utama: jalankan semua pengecekan.
  static ValidationResult validate(CubeModel cube) {
    final errors = <String>[];

    // 1. Cek apakah semua cell terisi
    if (!cube.isComplete) {
      errors.add(
        'Kubus belum lengkap! Masih ada ${54 - cube.filledCount} kotak kosong.',
      );
      return ValidationResult.invalid(errors);
    }

    // 2. Cek jumlah warna: harus tepat 9 untuk setiap warna
    final colorCountErrors = _validateColorCounts(cube);
    errors.addAll(colorCountErrors);

    // 3. Cek center pieces (harus sesuai standar)
    final centerErrors = _validateCenters(cube);
    errors.addAll(centerErrors);

    // 4. Cek edge pieces: tidak boleh ada edge yang mustahil
    final edgeErrors = _validateEdges(cube);
    errors.addAll(edgeErrors);

    // 5. Cek corner pieces: tidak boleh ada corner yang mustahil
    final cornerErrors = _validateCorners(cube);
    errors.addAll(cornerErrors);

    if (errors.isEmpty) {
      return ValidationResult.valid();
    }
    return ValidationResult.invalid(errors);
  }

  /// Validasi: tiap warna harus muncul tepat 9 kali.
  static List<String> _validateColorCounts(CubeModel cube) {
    final errors = <String>[];
    final counts = <CubeColor, int>{};

    for (final face in cube.faces.values) {
      for (final cell in face.cells) {
        counts[cell] = (counts[cell] ?? 0) + 1;
      }
    }

    final validColors = [
      CubeColor.white,
      CubeColor.red,
      CubeColor.green,
      CubeColor.yellow,
      CubeColor.orange,
      CubeColor.blue,
    ];

    for (final color in validColors) {
      final count = counts[color] ?? 0;
      if (count != 9) {
        errors.add(
          'Warna ${color.label}: ditemukan $count kotak (seharusnya 9).',
        );
      }
    }

    return errors;
  }

  /// Validasi: center piece harus sesuai standar.
  static List<String> _validateCenters(CubeModel cube) {
    final errors = <String>[];

    for (final face in CubeFace.values) {
      final expected = centerColorForFace(face);
      final actual = cube.faces[face]!.cells[4];
      if (actual != expected) {
        errors.add(
          'Center ${face.name} seharusnya ${expected.label}, tapi ditemukan ${actual.label}.',
        );
      }
    }

    return errors;
  }

  /// Validasi edge pieces: tidak boleh ada pasangan warna yang mustahil.
  /// Edge yang mustahil: dua warna pada sisi yang berlawanan
  /// (White-Yellow, Red-Orange, Green-Blue).
  static List<String> _validateEdges(CubeModel cube) {
    final errors = <String>[];

    // Definisi 12 edge positions pada kubus
    // Format: [face1, index1, face2, index2]
    final edges = [
      // U edges
      [CubeFace.U, 1, CubeFace.B, 1], // U2-B2
      [CubeFace.U, 3, CubeFace.L, 1], // U4-L2
      [CubeFace.U, 5, CubeFace.R, 1], // U6-R2
      [CubeFace.U, 7, CubeFace.F, 1], // U8-F2
      // D edges
      [CubeFace.D, 1, CubeFace.F, 7], // D2-F8
      [CubeFace.D, 3, CubeFace.L, 7], // D4-L8
      [CubeFace.D, 5, CubeFace.R, 7], // D6-R8
      [CubeFace.D, 7, CubeFace.B, 7], // D8-B8
      // Middle layer edges
      [CubeFace.F, 3, CubeFace.L, 5], // F4-L6
      [CubeFace.F, 5, CubeFace.R, 3], // F6-R4
      [CubeFace.B, 3, CubeFace.R, 5], // B4-R6
      [CubeFace.B, 5, CubeFace.L, 3], // B6-L4
    ];

    // Pasangan warna yang mustahil (sisi berlawanan)
    final opposites = {
      CubeColor.white: CubeColor.yellow,
      CubeColor.yellow: CubeColor.white,
      CubeColor.red: CubeColor.orange,
      CubeColor.orange: CubeColor.red,
      CubeColor.green: CubeColor.blue,
      CubeColor.blue: CubeColor.green,
    };

    for (final edge in edges) {
      final face1 = edge[0] as CubeFace;
      final idx1 = edge[1] as int;
      final face2 = edge[2] as CubeFace;
      final idx2 = edge[3] as int;

      final color1 = cube.faces[face1]!.cells[idx1];
      final color2 = cube.faces[face2]!.cells[idx2];

      // Cek apakah warnanya berlawanan
      if (opposites[color1] == color2) {
        errors.add(
          'Edge mustahil: warna ${color1.label} bersebelahan dengan warna lawannya ${color2.label} '
          '(pada sisi ${face1.label} kotak ke-${idx1 + 1} dan sisi ${face2.label} kotak ke-${idx2 + 1}).',
        );
      }

      // Cek apakah ada warna yang sama (duplikat edge)
      if (color1 == color2) {
        errors.add(
          'Edge mustahil: dua warna sama ${color1.label} '
          '(pada sisi ${face1.label} kotak ke-${idx1 + 1} dan sisi ${face2.label} kotak ke-${idx2 + 1}).',
        );
      }
    }

    return errors;
  }

  /// Validasi corner pieces: tidak boleh ada corner dengan dua warna berlawanan.
  static List<String> _validateCorners(CubeModel cube) {
    final errors = <String>[];

    // Definisi 8 corner positions
    // Format: [face1, index1, face2, index2, face3, index3]
    final corners = [
      // Upper layer corners
      [CubeFace.U, 0, CubeFace.L, 0, CubeFace.B, 2], // ULB
      [CubeFace.U, 2, CubeFace.B, 0, CubeFace.R, 2], // UBR
      [CubeFace.U, 6, CubeFace.F, 0, CubeFace.L, 2], // UFL
      [CubeFace.U, 8, CubeFace.R, 0, CubeFace.F, 2], // URF
      // Lower layer corners
      [CubeFace.D, 0, CubeFace.L, 8, CubeFace.F, 6], // DLF
      [CubeFace.D, 2, CubeFace.F, 8, CubeFace.R, 6], // DFR
      [CubeFace.D, 6, CubeFace.B, 8, CubeFace.L, 6], // DBL
      [CubeFace.D, 8, CubeFace.R, 8, CubeFace.B, 6], // DRB
    ];

    final opposites = {
      CubeColor.white: CubeColor.yellow,
      CubeColor.yellow: CubeColor.white,
      CubeColor.red: CubeColor.orange,
      CubeColor.orange: CubeColor.red,
      CubeColor.green: CubeColor.blue,
      CubeColor.blue: CubeColor.green,
    };

    for (final corner in corners) {
      final face1 = corner[0] as CubeFace;
      final idx1 = corner[1] as int;
      final face2 = corner[2] as CubeFace;
      final idx2 = corner[3] as int;
      final face3 = corner[4] as CubeFace;
      final idx3 = corner[5] as int;

      final colors = <CubeColor>[
        cube.faces[face1]!.cells[idx1],
        cube.faces[face2]!.cells[idx2],
        cube.faces[face3]!.cells[idx3],
      ];

      // Cek apakah ada warna yang sama pada satu corner
      if (colors[0] == colors[1] ||
          colors[1] == colors[2] ||
          colors[0] == colors[2]) {
        errors.add(
          'Corner mustahil: ada warna duplikat (${colors.map((c) => c.label).join(", ")}) '
          '(pada sisi ${face1.label} kotak ke-${idx1 + 1}, sisi ${face2.label} kotak ke-${idx2 + 1}, dan sisi ${face3.label} kotak ke-${idx3 + 1}).',
        );
      }

      // Cek apakah ada pasangan warna berlawanan pada satu corner
      bool hasOpposite = false;
      for (int i = 0; i < 3; i++) {
        for (int j = i + 1; j < 3; j++) {
          if (opposites[colors[i]] == colors[j]) {
            hasOpposite = true;
          }
        }
      }
      if (hasOpposite) {
        errors.add(
          'Corner mustahil: ada warna berseberangan yang tidak boleh berdekatan (${colors.map((c) => c.label).join(", ")}) '
          '(pada sisi ${face1.label} kotak ke-${idx1 + 1}, sisi ${face2.label} kotak ke-${idx2 + 1}, dan sisi ${face3.label} kotak ke-${idx3 + 1}).',
        );
      }
    }

    return errors;
  }
}
