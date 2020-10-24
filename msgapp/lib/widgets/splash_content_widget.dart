import 'package:flutter/material.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/size_config.dart';

class SplashContent extends StatelessWidget {
  final String text;
  final Image image;

  SplashContent({Key key,this.text, this.image}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          height: SizeConfig.screenWidth,
          width: SizeConfig.screenWidth,
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: image
            ),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: Global.black,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}