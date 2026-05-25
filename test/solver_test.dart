import 'package:cuber/cuber.dart' as cuber;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kociemba solver produces correct solution for scrambled cube', () {
    // Buat kubus solved, lalu scramble
    final scramble = cuber.Algorithm.parse("R U F' D2 L B R2 U' F D");
    final scrambledCube = scramble.apply(cuber.Cube.solved);

    // Cek kubus belum solved
    expect(scrambledCube.isSolved, false);

    // Solve
    final solution = scrambledCube.solve(
      maxDepth: 25,
      timeout: const Duration(seconds: 30),
    );

    expect(solution, isNotNull);

    // Terapkan solusi dan verifikasi hasilnya solved
    final result = solution!.algorithm.apply(scrambledCube);
    expect(result.isSolved, true,
        reason: 'Solusi harus mengembalikan kubus ke keadaan solved');

    // ignore: avoid_print
    print('Scramble: R U F\' D2 L B R2 U\' F D');
    // ignore: avoid_print
    print('Solution: ${solution.algorithm}');
    // ignore: avoid_print
    print('Moves: ${solution.length}');
    // ignore: avoid_print
    print('Result isSolved: ${result.isSolved}');
  });

  test('Solved string produces solved cube', () {
    final solvedString = 'UUUUUUUUURRRRRRRRR''FFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';
    final cube = cuber.Cube.from(solvedString);
    expect(cube.isSolved, true,
        reason: 'String solved standar harus menghasilkan kubus solved');
    expect(cube.verify(), cuber.CubeStatus.ok);
  });

  test('Scrambled cube solves correctly via definition string', () {
    final solvedCube = cuber.Cube.from('UUUUUUUUURRRRRRRRR''FFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB');
    expect(solvedCube.isSolved, true);

    // Apply scramble
    final scramble = cuber.Algorithm.parse("U R' F2 D L' B U2 R F D'");
    final scrambled = scramble.apply(solvedCube);
    expect(scrambled.isSolved, false);

    // Get definition string of scrambled cube
    final scrambledDef = scrambled.definition;
    // ignore: avoid_print
    print('Scrambled definition: $scrambledDef');

    // Re-create cube from definition and solve
    final cubeFromDef = cuber.Cube.from(scrambledDef);
    expect(cubeFromDef.verify(), cuber.CubeStatus.ok);

    final solution = cubeFromDef.solve(maxDepth: 25, timeout: const Duration(seconds: 30));
    expect(solution, isNotNull);

    final result = solution!.algorithm.apply(cubeFromDef);
    expect(result.isSolved, true,
        reason: 'Solusi dari string definition harus menyelesaikan kubus');

    // ignore: avoid_print
    print('Solution: ${solution.algorithm}');
    // ignore: avoid_print
    print('Moves: ${solution.length}');
  });
}
