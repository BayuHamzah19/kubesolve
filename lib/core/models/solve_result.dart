/// Model untuk satu langkah solusi Rubik.
class SolveStep {
  final int stepNumber;
  final String notation;   // e.g. "R2", "U'", "F"
  final String faceName;   // Nama sisi yang diputar
  final String direction;  // Arah putaran
  final String description; // Deskripsi lengkap dalam Bahasa Indonesia

  const SolveStep({
    required this.stepNumber,
    required this.notation,
    required this.faceName,
    required this.direction,
    required this.description,
  });
}

/// Hasil dari solver.
class SolveResult {
  final bool success;
  final List<SolveStep> steps;
  final String rawSolution; // String notasi mentah, e.g. "U R2 F' ..."
  final String? errorMessage;
  final Duration solveDuration;
  final String? kociembaString; // String Kociemba yang dikirim ke solver (untuk debug)
  final bool verified; // Apakah solusi telah diverifikasi (menyelesaikan kubus)

  const SolveResult({
    required this.success,
    required this.steps,
    required this.rawSolution,
    this.errorMessage,
    required this.solveDuration,
    this.kociembaString,
    this.verified = false,
  });

  factory SolveResult.error(String message) => SolveResult(
        success: false,
        steps: [],
        rawSolution: '',
        errorMessage: message,
        solveDuration: Duration.zero,
      );
}
