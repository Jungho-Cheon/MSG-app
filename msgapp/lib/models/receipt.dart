import 'package:msgapp/models/Ingredient.dart';

class Receipt{
  final DateTime date;
  final List<Ingredient> ingredients;
  final String price;

  Receipt({this.date, this.ingredients, this.price});

  @override
  String toString() {
    return price + '원';
  }
}