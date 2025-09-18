import 'package:flutter/material.dart';

class AppPalette {
  final String name;
  final Color seedColor;

  const AppPalette({required this.name, required this.seedColor});
}

final List<AppPalette> appPalettes = [
  // The original green
  const AppPalette(name: 'Default Green', seedColor: Colors.green),
  // 1. Blue Palette
  const AppPalette(name: 'Professional Blue', seedColor: Color(0xFF2C3E50)),
  // 2. Green Palette
  const AppPalette(name: 'Fresh Green', seedColor: Color(0xFF27AE60)),
  // 3. Purple Palette
  const AppPalette(name: 'Creative Purple', seedColor: Color(0xFF8E44AD)),
  // 4. Monochromatic Palette
  const AppPalette(name: 'Elegant Mono', seedColor: Color(0xFF34495E)),
  // 5. Orange & Yellow Palette
  const AppPalette(name: 'Energetic Orange', seedColor: Color(0xFFE67E22)),
];
