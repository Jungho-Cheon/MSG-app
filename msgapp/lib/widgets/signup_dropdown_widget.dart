import 'package:flutter/material.dart';
import 'package:msgapp/color_config.dart';

class SignupDropdownWidget extends StatefulWidget {
  final String title;
  final List<String> selectList;
  final IconData prefixIcon;
  int _index = -1;
  get index => (_index % selectList.length);

  SignupDropdownWidget({Key key, @required this.title, @required this.selectList, this.prefixIcon}) : super(key: key);

  @override
  _SignupDropdownWidgetState createState() => _SignupDropdownWidgetState();
}

class _SignupDropdownWidgetState extends State<SignupDropdownWidget> {
  GlobalKey _actionKey;
  bool _isTouched = false;

  String _currentValue;
  List<String> _selectList;

  Color textColor = Global.mainColor;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.title;
    _selectList = widget.selectList;
    _actionKey = LabeledGlobalKey(widget.title);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _actionKey,
      onTap: (){
        setState(() {
          if(!_isTouched) {
            _isTouched = !_isTouched;
            textColor = Global.mainColor;
          }
          widget._index++;
          widget._index = widget._index % _selectList.length;
          _currentValue = _selectList[widget._index];
        });
      },
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 7.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(widget.prefixIcon, size: 20, color: Global.mainColor,),
              Padding(
                padding: const EdgeInsets.only(left: 3.0),
              ),
              Icon(Icons.arrow_left, color:Global.mainColor),
              Spacer(),
              Text(_currentValue, style: TextStyle(color: textColor)),
              Spacer(),
              Icon(Icons.arrow_right, color:Global.mainColor),
            ],
          ),
        ),
      ),
    );
  }
}
