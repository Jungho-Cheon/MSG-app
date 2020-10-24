import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

class Ingredient{
  String type;
  String title;

  Ingredient({this.type, this.title});

  @override
  String toString() {
    return title;
  }

  @override
  bool operator ==(other) {
    return this.title == other.title;
  }

  @override
  int get hashCode => super.hashCode;

}
