import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String nameMs;
  final String icon;
  final int colorIndex;
  final String ageGroup;

  const CategoryModel({
    this.id,
    required this.name,
    required this.nameMs,
    required this.icon,
    required this.colorIndex,
    required this.ageGroup,
  });

  Color get color => AppColors.categoryColors[colorIndex % AppColors.categoryColors.length];

  List<Color> get gradient => AppColors.gradients[colorIndex % AppColors.gradients.length];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'name_ms': nameMs,
        'icon': icon,
        'color_index': colorIndex,
        'age_group': ageGroup,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'],
        name: map['name'],
        nameMs: map['name_ms'],
        icon: map['icon'],
        colorIndex: map['color_index'],
        ageGroup: map['age_group'],
      );
}
