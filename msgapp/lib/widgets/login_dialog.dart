import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/size_config.dart';

class LoginDialog extends StatelessWidget {
  final title;
  final desc;
  final imgPath;

  LoginDialog({@required this.title,@required this.desc, @required this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      backgroundColor: Global.mainColor,
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    return Container(
      width: 100.0,
      height: 290.0,
      decoration: BoxDecoration(
        color: Colors.orange[400],
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Global.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.only(topRight: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
              ),
              width: double.infinity,
              height: 230.0,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SvgPicture.asset(imgPath, height:120.0, width: 120.0),
                    Padding(padding: EdgeInsets.all(8),),
                    Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            color: Global.black
                        )
                    ),
                    Padding(padding: EdgeInsets.all(2),),
                    Text(
                        desc,
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            color: Global.black
                        )
                    ),

                  ],
                ),
              )
            ),
          ),
          Expanded(
            flex: 1,
            child:GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                ),
                width: double.infinity,
                height: SizeConfig.screenHeight * 0.05,
                child: Center(
                  child: Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.w300, fontSize: 14.0, color: Global.white)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
