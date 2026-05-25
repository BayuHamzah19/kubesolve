import 'package:cuber/cuber.dart' as cuber;
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/core/models/cube_model.dart';
import 'package:rubik_solver/core/models/solve_result.dart';

/// Service untuk memecahkan Rubik's Cube menggunakan package `cuber`
/// yang mengimplementasikan algoritma Kociemba Two-Phase.
class CubeSolverService {
  /// Memecahkan kubus dari CubeModel.
  /// Mengembalikan SolveResult berisi langkah-langkah solusi.
  Future<SolveResult> solve(CubeModel cubeModel) async {
    final stopwatch = Stopwatch()..start();

    try {
      final cubeString = cubeModel.toKociembaString();

      // Buat instance Cube dari string 54 karakter
      final cube = cuber.Cube.from(cubeString);

      // Verifikasi apakah kubus valid menurut library cuber
      final status = cube.verify();
      if (status != cuber.CubeStatus.ok) {
        stopwatch.stop();
        return SolveResult.error(
          'Kubus tidak valid: ${_translateStatus(status)}\n'
          'String Kociemba: $cubeString',
        );
      }

      // Cek apakah sudah solved
      if (cube.isSolved) {
        stopwatch.stop();
        return SolveResult(
          success: true,
          steps: [],
          rawSolution: '(Sudah solved!)',
          solveDuration: stopwatch.elapsed,
          kociembaString: cubeString,
          verified: true,
        );
      }

      // Solve menggunakan Kociemba Two-Phase algorithm
      // maxDepth: batas kedalaman pencarian (default 25 cukup optimal)
      // timeout: batas waktu pencarian
      final solution = cube.solve(
        maxDepth: 25,
        timeout: const Duration(seconds: 30),
      );

      stopwatch.stop();

      if (solution == null) {
        return SolveResult.error(
          'Tidak dapat menemukan solusi dalam batas waktu.\n'
          'String Kociemba: $cubeString',
        );
      }

      // Parse moves dari solusi
      final moves = solution.algorithm.moves;
      final rawString = moves.map((m) => m.toString()).join(' ');
      final steps = _parseMovesToSteps(moves);

      // VERIFIKASI: terapkan solusi ke kubus dan cek apakah benar-benar solved
      final solvedCube = solution.algorithm.apply(cube);
      final isVerified = solvedCube.isSolved;

      return SolveResult(
        success: true,
        steps: steps,
        rawSolution: rawString,
        solveDuration: stopwatch.elapsed,
        kociembaString: cubeString,
        verified: isVerified,
      );
    } catch (e) {
      stopwatch.stop();
      return SolveResult.error('Error saat solving: $e');
    }
  }

  /// Parse list Move dari cuber menjadi list SolveStep.
  List<SolveStep> _parseMovesToSteps(List<cuber.Move> moves) {
    final steps = <SolveStep>[];

    for (int i = 0; i < moves.length; i++) {
      final move = moves[i];
      final notation = move.toString();
      final parsed = _describeMove(notation);

      steps.add(SolveStep(
        stepNumber: i + 1,
        notation: notation,
        faceName: parsed['face']!,
        direction: parsed['direction']!,
        description: parsed['description']!,
      ));
    }

    return steps;
  }

  /// Deskripsikan satu move dalam Bahasa Indonesia.
  /// Menyertakan warna center sisi dan perspektif cara memutar.
  Map<String, String> _describeMove(String notation) {
    // Ambil base face (karakter pertama)
    final base = notation[0];

    final faceNames = {
      'U': 'Atas (Up)',
      'D': 'Bawah (Down)',
      'R': 'Kanan (Right)',
      'L': 'Kiri (Left)',
      'F': 'Depan (Front)',
      'B': 'Belakang (Back)',
    };

    final faceName = faceNames[base] ?? base;

    final faceEnumMap = {
      'U': CubeFace.U,
      'D': CubeFace.D,
      'R': CubeFace.R,
      'L': CubeFace.L,
      'F': CubeFace.F,
      'B': CubeFace.B,
    };
    final face = faceEnumMap[base];
    final colorLabel = face != null
        ? centerColorForFace(face).label
        : '';
    final faceNameWithColor = face != null
        ? '$faceName ($colorLabel)'
        : faceName;

    // Perspektif dari mana user harus melihat saat memutar
    final perspektif = {
      'U': 'Lihat kubus dari ATAS.',
      'D': 'Lihat kubus dari BAWAH.',
      'F': 'Lihat sisi DEPAN.',
      'B': 'Lihat sisi BELAKANG (putar kubus 180°).',
      'R': 'Lihat sisi KANAN.',
      'L': 'Lihat sisi KIRI.',
    };

    String direction;
    String description;

    if (notation.length == 1) {
      // Gerakan searah jarum jam 90°
      direction = '90° searah jarum jam ↻';
      description = '${perspektif[base]} '
          'Putar sisi $faceNameWithColor 90° searah jarum jam ↻';
    } else if (notation.endsWith("'")) {
      // Gerakan berlawanan jarum jam 90°
      direction = "90° berlawanan jarum jam ↺";
      description = '${perspektif[base]} '
          'Putar sisi $faceNameWithColor 90° berlawanan jarum jam ↺';
    } else if (notation.endsWith('2')) {
      // Gerakan 180°
      direction = '180° (setengah putaran)';
      description = '${perspektif[base]} '
          'Putar sisi $faceNameWithColor 180° (setengah putaran)';
    } else {
      direction = notation;
      description = 'Gerakan $notation';
    }

    return {
      'face': faceName,
      'direction': direction,
      'description': description,
    };
  }

  /// Terjemahkan CubeStatus dari library cuber ke pesan yang jelas.
  String _translateStatus(cuber.CubeStatus status) {
    switch (status) {
      case cuber.CubeStatus.ok:
        return 'OK';
      case cuber.CubeStatus.missingEdge:
        return 'Ada edge piece yang hilang. Periksa kembali warna edge (tepi).';
      case cuber.CubeStatus.twistedEdge:
        return 'Ada edge piece yang terbalik. Periksa orientasi stiker pada edge.';
      case cuber.CubeStatus.missingCorner:
        return 'Ada corner piece yang hilang. Periksa kembali warna corner (sudut).';
      case cuber.CubeStatus.twistedCorner:
        return 'Ada corner piece yang terbalik. Periksa orientasi stiker pada corner.';
      case cuber.CubeStatus.parityError:
        return 'Parity error: konfigurasi kubus tidak mungkin ada di dunia nyata. '
            'Periksa apakah ada stiker yang salah input.';
      default:
        return 'Konfigurasi kubus tidak valid (status: $status). '
            'Pastikan setiap warna muncul tepat 9 kali dan tidak ada '
            'konfigurasi edge/corner yang mustahil.';
    }
  }
}
