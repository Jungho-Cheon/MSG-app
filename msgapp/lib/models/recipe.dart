import 'dart:convert';

import 'package:msgapp/models/Ingredient.dart';

// example data

class Recipe{
  Map<String, List<Ingredient>> ingredients;
  final String mainImageURL;
  final List<String> descriptions;
  final double protein;
  final List<String> descriptionImageURLs;
  final String recipeId;
  final double car;
  final double calories;
  final double na;
  final double fat;
  final String title;
  final String category;
  final String method;
  final String difficulty;


  Recipe({this.ingredients,
      this.mainImageURL,
      this.descriptions,
      this.protein,
      this.descriptionImageURLs,
      this.recipeId,
      this.car,
      this.calories,
      this.na,
      this.fat,
      this.title,
      this.category,
      this.method,
      this.difficulty});

  @override
  String toString() {
    return title;
  }
}