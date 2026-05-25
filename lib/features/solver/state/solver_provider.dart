import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/core/models/cube_model.dart';
import 'package:rubik_solver/core/models/solve_result.dart';
import 'package:rubik_solver/features/solver/data/cube_solver_service.dart';

/// State untuk layar solusi: menyimpan result dan current step.
class SolverState {
  final SolveResult? result;
  final bool isLoading;
  final int currentStep; // 0-indexed

  const SolverState({
    this.result,
    this.isLoading = false,
    this.currentStep = 0,
  });

  SolverState copyWith({
    SolveResult? result,
    bool? isLoading,
    int? currentStep,
  }) {
    return SolverState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  bool get hasResult => result != null;
  bool get isSuccess => result?.success ?? false;
  int get totalSteps => result?.steps.length ?? 0;

  bool get canGoNext =>
      hasResult && isSuccess && currentStep < totalSteps - 1;
  bool get canGoPrevious => hasResult && isSuccess && currentStep > 0;

  SolveStep? get currentSolveStep {
    if (!isSuccess || result!.steps.isEmpty) return null;
    if (currentStep < 0 || currentStep >= totalSteps) return null;
    return result!.steps[currentStep];
  }
}

/// Notifier untuk mengelola state solver.
class SolverNotifier extends StateNotifier<SolverState> {
  final CubeSolverService _solverService;

  SolverNotifier(this._solverService) : super(const SolverState());

  /// Jalankan solver dengan CubeModel.
  Future<void> solve(CubeModel cubeModel) async {
    state = const SolverState(isLoading: true);

    try {
      final result = await _solverService.solve(cubeModel);

      state = SolverState(
        result: result,
        isLoading: false,
        currentStep: 0,
      );
    } catch (e) {
      state = SolverState(
        result: SolveResult.error('Unexpected error: $e'),
        isLoading: false,
        currentStep: 0,
      );
    }
  }

  /// Langkah berikutnya.
  void nextStep() {
    if (state.canGoNext) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Langkah sebelumnya.
  void previousStep() {
    if (state.canGoPrevious) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Lompat ke langkah tertentu.
  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Reset state solver.
  void reset() {
    state = const SolverState();
  }
}

/// Provider untuk CubeSolverService.
final cubeSolverServiceProvider = Provider<CubeSolverService>(
  (ref) => CubeSolverService(),
);

/// Provider untuk SolverNotifier.
final solverProvider = StateNotifierProvider<SolverNotifier, SolverState>(
  (ref) => SolverNotifier(ref.read(cubeSolverServiceProvider)),
);
