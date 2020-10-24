import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/models/Ingredient.dart';
import 'package:msgapp/size_config.dart';
import 'package:msgapp/widgets/login_button_widget.dart';

class RemoveIngredientDialog extends StatefulWidget {
  final title;
  final Map<String,List<Ingredient>> ingredients;
  final List<bool> isSelected = List<bool>();
  List<Ingredient> values = List<Ingredient>();

  RemoveIngredientDialog({this.title, this.ingredients}){
    init();
  }

  void init(){
    print(this.ingredients);
    int total_ingredient = 0;
    for(String key in this.ingredients.keys){
      print('key : $key, values : ${this.ingredients[key]}, length : ${this.ingredients[key].length}');
      total_ingredient += this.ingredients[key].length;
      values.addAll(this.ingredients[key]);
    }
    print('all_values : $values, total_ingredient : $total_ingredient');
    for(int i=0; i<total_ingredient; i++){
      this.isSelected.add(false);
    }
    print(this.isSelected);
  }

  @override
  _RemoveIngredientDialogState createState() => _RemoveIngredientDialogState();
}

class _RemoveIngredientDialogState extends State<RemoveIngredientDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    final ScrollController _scrollController = ScrollController();

    return Container(
      width: SizeConfig.screenWidth * 0.9,
      height: 550,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical : 20.0),
                  child: Image.asset(
                    'assets/images/double-tap_200_transparent.gif',
                    width: 60,
                    height: 60
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: getProportionateScreenWidth(14),
                    color: Global.black)
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.only(topRight: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Scrollbar(
                        isAlwaysShown: true,
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: widget.values.length,
                          itemBuilder: (context, index){
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: (){
                                widget.isSelected[index] = !widget.isSelected[index];
                                setState(() {});
                              },
                              child: Container(
                                color: widget.isSelected[index]
                                    ? Global.mainColor
                                    : Global.white,
                                child: Row(
                                  children: <Widget>[
                                    Checkbox(
                                      value: widget.isSelected[index],
                                      onChanged: (s){
                                        widget.isSelected[index] = !widget.isSelected[index];
                                        setState(() {});
                                      },
                                    ),
                                    Text(
                                        widget.values[index].title,
                                        style: TextStyle(
                                            fontSize: getProportionateScreenWidth(14),
                                            color: widget.isSelected[index] ? Global.white : Global.black
                                        )
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ),
          ),
          GestureDetector(
            onTap: (){
              final selectedIngredients = List<String>();
              for(int i = 0; i < widget.isSelected.length; i++){
                // ignore: unnecessary_statements
                widget.isSelected[i] ? selectedIngredients.add(widget.values[i].title) : null;
              }

              // TODO 선택된 식재료 삭제 처리
              print('[RemoveIngredientsDialog] 삭제된 재료 목록 : ${selectedIngredients.toString()}');

              Navigator.pop(context);
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              width: double.infinity,
              height: 50,
              child: Center(
                child: Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 18.0, color: Global.black)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
