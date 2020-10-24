import 'package:flutter/material.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/screens/display_picture_page.dart';

class ReceiptInfoWidget extends StatefulWidget {
  final List<String> ingredients;
  final List<Line> ingredientsLines;
  final Line dateLine;
  final Line priceLine;

  ReceiptInfoWidget({this.ingredients, this.ingredientsLines, this.dateLine, this.priceLine});

  @override
  _ReceiptInfoWidgetState createState() => _ReceiptInfoWidgetState();
}

class _ReceiptInfoWidgetState extends State<ReceiptInfoWidget> with TickerProviderStateMixin{
  List<AnimationController> _controllers;
  List<Animation<double>> _scaleAnimations;

  AnimationController _animationStarterController;
  Animation<double> _animationStarter;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controllers = List<AnimationController>();
    _scaleAnimations = List<Animation<double>>();

    int len_controllers = 0;
    if (widget.dateLine != null) len_controllers += 1;
    if (widget.priceLine != null) len_controllers += 1;
    len_controllers += widget.ingredientsLines.length;

    for (int i = 0; i < len_controllers; i++){
      _controllers.add(AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 500)
      ));
      _scaleAnimations.add(CurvedAnimation(
          parent: _controllers[i],
          curve: Curves.elasticOut
      ));
    }

    _animationStarterController = AnimationController(
      vsync: this,
      duration : Duration(milliseconds: 700)
    );
    _animationStarter = CurvedAnimation(
      parent: _animationStarterController,
      curve: Curves.fastOutSlowIn,
    )..addListener(() {
      for(int i = 0; i < len_controllers; i++){
        if (i/len_controllers <= _animationStarter.value){
          _controllers[i].forward();
        }
      }
    });
    // Future.delayed(const Duration(seconds: 1), () {});
    _animationStarterController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ...buildInfoPopUp()
      ]
    );
  }

  List<Widget> buildInfoPopUp() {
    final infoPopUps = List<Widget>();
    final popUpWidth = 50.0;
    final popUpHeight = 25.0;

    if (widget.ingredientsLines != null){
      if (widget.dateLine != null){
        infoPopUps.add(
          Positioned(
            top: widget.dateLine.from.y - 19,
            left: widget.dateLine.from.x - 43,
            child: ScaleTransition(
              scale: _scaleAnimations[0],
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.greenAccent[700],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(1, 1),
                      )
                    ],
                    borderRadius: BorderRadius.circular(30)
                ),
                child: InkWell(
                  child: SizedBox(
                      width: 35,
                      height: 35,
                      child: Center(
                        child: Text(
                            '날짜',
                            style: TextStyle(
                                color: Global.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.0
                            )
                        ),
                      )
                  ),
                ),
              ),
            ),
          ),
        );
      }
      for(int i = 0; i < widget.ingredientsLines.length; i++){
        infoPopUps.add(
          Positioned(
            top: widget.ingredientsLines[i].from.y - 15,
            left: widget.ingredientsLines[i].from.x - 57,
            child: ScaleTransition(
              scale: _scaleAnimations[widget.dateLine != null ? i+1 : i],
              child: Container(
                width: popUpWidth,
                height: popUpHeight,
                decoration: BoxDecoration(
                    color: Colors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(1, 1),
                      )
                    ],
                    borderRadius: BorderRadius.circular(30)
                ),
                child: Center(
                  child: Text(
                      widget.ingredients[i],
                      style: TextStyle(
                          color: Global.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.0
                      )
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    if (widget.priceLine != null){
      infoPopUps.add(
        Positioned(
          top: widget.priceLine.from.y - 19,
          left: widget.priceLine.from.x - 43,
          child: ScaleTransition(
            scale: _scaleAnimations[_scaleAnimations.length-1],
            child: Container(
              decoration: BoxDecoration(
                      color: Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: Offset(1, 1),
                        )
                      ],
                      borderRadius: BorderRadius.circular(30)
                  ),
              child: InkWell(
                child: SizedBox(
                    width: 35,
                    height: 35,
                    child: Center(
                      child: Text(
                                '금액',
                                style: TextStyle(
                                    color: Global.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.0
                                )
                            ),
                    )
                ),
              ),
            ),
          ),
        ),
      );
    }
    return infoPopUps;
  }
}
