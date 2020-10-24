import 'package:flutter/material.dart';

class CustomPageRoute extends PageRouteBuilder{

  final Widget widget;

  CustomPageRoute({this.widget}): super(
    transitionDuration: Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      animation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn
      );
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return widget;
    },
  );
}