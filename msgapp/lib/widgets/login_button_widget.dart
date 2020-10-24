import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msgapp/color_config.dart';

class LoginPageButtonWidget extends StatelessWidget {
  final String title;
  final bool hasBorder;
  final Color customColor;
  final Function onTapFunction;
  final double width;

  LoginPageButtonWidget({this.title, this.hasBorder, this.customColor, this.onTapFunction, this.width});

  @override
  Widget build(BuildContext context) {
    final mainColor = customColor != null ? customColor : Colors.orange[400];

    return Material(
      color: Global.white,
      child: Ink(
        decoration: BoxDecoration(
          color: hasBorder ? Global.white : Colors.orange[400],
          borderRadius: BorderRadius.circular(50.0),
          border: hasBorder
            ? Border.all(
            color: mainColor,
            width: 0.7,
          )
              : Border.fromBorderSide(BorderSide.none)
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(50.0),
          onTap: onTapFunction,
          child: Container(
            height: 50.0,
            width: width,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: hasBorder? mainColor : Global.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 16.0,
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
