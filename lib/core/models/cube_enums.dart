import 'package:flutter/material.dart';

/// Enum representasi 6 sisi Rubik's Cube.
/// Urutan sesuai standar Kociemba: U, R, F, D, L, B
enum CubeFace { U, R, F, D, L, B }

/// Enum 6 warna standar Rubik + placeholder kosong.
enum CubeColor { white, red, green, yellow, orange, blue, none }

/// Mapping warna Rubik ke Flutter Color untuk rendering UI.
/// Menggunakan warna yang lebih vivid untuk tampilan premium.
extension CubeColorExtension on CubeColor {
  Color get color {
    switch (this) {
      case CubeColor.white:
        return const Color(0xFFF0F0F0);
      case CubeColor.red:
        return const Color(0xFFE53935);
      case CubeColor.green:
        return const Color(0xFF43A047);
      case CubeColor.yellow:
        return const Color(0xFFFFEB3B);
      case CubeColor.orange:
        return const Color(0xFFFF9800);
      case CubeColor.blue:
        return const Color(0xFF1E88E5);
      case CubeColor.none:
        return const Color(0xFF2A2A3E);
    }
  }

  /// Label Indonesia untuk tiap warna.
  String get label {
    switch (this) {
      case CubeColor.white:
        return 'Putih';
      case CubeColor.red:
        return 'Merah';
      case CubeColor.green:
        return 'Hijau';
      case CubeColor.yellow:
        return 'Kuning';
      case CubeColor.orange:
        return 'Oranye';
      case CubeColor.blue:
        return 'Biru';
      case CubeColor.none:
        return 'Kosong';
    }
  }

  /// Konversi ke karakter standar Kociemba (U, R, F, D, L, B).
  /// Mapping: White=U, Red=R, Green=F, Yellow=D, Orange=L, Blue=B
  String get toFaceChar {
    switch (this) {
      case CubeColor.white:
        return 'D';
      case CubeColor.red:
        return 'L';
      case CubeColor.green:
        return 'F';
      case CubeColor.yellow:
        return 'U';
      case CubeColor.orange:
        return 'R';
      case CubeColor.blue:
        return 'B';
      case CubeColor.none:
        return '?';
    }
  }
}

/// Mapping dari CubeFace ke center color yang tetap.
CubeColor centerColorForFace(CubeFace face) {
  switch (face) {
    case CubeFace.U:
      return CubeColor.yellow;
    case CubeFace.D:
      return CubeColor.white;
    case CubeFace.F:
      return CubeColor.green;
    case CubeFace.B:
      return CubeColor.blue;
    case CubeFace.L:
      return CubeColor.red;
    case CubeFace.R:
      return CubeColor.orange;
  }
}

/// Membuat CubeColor dari karakter face Kociemba.
CubeColor cubeColorFromChar(String ch) {
  switch (ch) {
    case 'U':
      return CubeColor.yellow;
    case 'R':
      return CubeColor.orange;
    case 'F':
      return CubeColor.green;
    case 'D':
      return CubeColor.white;
    case 'L':
      return CubeColor.red;
    case 'B':
      return CubeColor.blue;
    default:
      return CubeColor.none;
  }
}
