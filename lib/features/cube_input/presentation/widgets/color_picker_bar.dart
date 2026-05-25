import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/core/models/cube_enums.dart';
import 'package:rubik_solver/features/cube_input/state/cube_input_provider.dart';

/// Color Picker horizontal: 6 warna standar Rubik.
class ColorPickerBar extends ConsumerWidget {
  const ColorPickerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(
      cubeInputProvider.select((s) => s.selectedColor),
    );

    final colors = [
      CubeColor.white,
      CubeColor.yellow,
      CubeColor.red,
      CubeColor.orange,
      CubeColor.blue,
      CubeColor.green,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pilih Warna',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.map((color) {
              final isSelected = color == selectedColor;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(cubeInputProvider.notifier).selectColor(color);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 50 : 42,
                  height: isSelected ? 50 : 42,
                  decoration: BoxDecoration(
                    color: color.color,
                    borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.color.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: color == CubeColor.white ||
                                  color == CubeColor.yellow
                              ? Colors.black54
                              : Colors.white,
                          size: 22,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              selectedColor.label,
              key: ValueKey(selectedColor),
              style: TextStyle(
                color: selectedColor.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
