import 'package:dishmark/data/dish_mark.dart';
import 'package:flutter/material.dart';

class DishEvents {
  static final ValueNotifier<int?> deletedDishId = ValueNotifier(null);
  static final ValueNotifier<DishMark?> addedDish = ValueNotifier(null);
  static final ValueNotifier<int?> updatedDishId = ValueNotifier(null);
}
