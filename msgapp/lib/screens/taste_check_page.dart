import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:async/async.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tindercard/flutter_tindercard.dart';
import 'package:msgapp/models/recipe.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/screens/main_page.dart';
import 'package:msgapp/screens/recipe_detail_page.dart';
import 'package:msgapp/size_config.dart';
import 'package:msgapp/widgets/login_dialog.dart';
import 'package:msgapp/widgets/percent_number_widget.dart';
import 'dart:math' as Math;

import '../color_config.dart';

enum CheckState{
  ready, like, dislike
}

class TasteCheckPage extends StatefulWidget {
  final String nickname;

  TasteCheckPage({this.nickname});

  @override
  _TasteCheckPageState createState() => _TasteCheckPageState();
}

class _TasteCheckPageState extends State<TasteCheckPage> with SingleTickerProviderStateMixin{

  // 레시피 호불호 체크리스트
  List<Map<Recipe, bool>> checkedRecipe = List<Map<Recipe, bool>>();
  ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  CheckState checkState;
  Animation<double> animation;
  WaveBackground waveBackground;
  int _percentage;
  List<Recipe> recommendedRecipes;

  Future<List<Recipe>> _getRecommendedRecipes() async {
    if (recommendedRecipes.length > 0){
      return recommendedRecipes;
    }

    recommendedRecipes = await UserRepository.refreshRecommendedRecipes();
    return recommendedRecipes;
  }

  @override
  void initState() {
    super.initState();
    recommendedRecipes = List<Recipe>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await showDialog(
          context: context,
          builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0.0,
              backgroundColor: Global.white,
              child: _buildDialog(context)
          )
      );
    });
    checkState = CheckState.ready;
    waveBackground = WaveBackground(SizeConfig.screenHeight * 0.9, checkState);
    _percentage = 0;
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Global.white,
        body: Stack(
          children: <Widget>[
            waveBackground,
            Container(
              width: SizeConfig.screenWidth,
              height: SizeConfig.screenHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 30.0),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    Column(
                      children: <Widget>[
                        Text('회원님의 취향을 알려주세요.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Global.black),),

                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: AnimatedCount(
                        count: _percentage,
                        duration: Duration(milliseconds: 800),
                        curve: Curves.decelerate,
                      ),
                    ),
                    checkState != CheckState.ready
                        ? _analizingWidget()
                        : SizedBox(height: 16,)
                    ,
                    SizedBox(
                      height: 10,
                    ),
                    FutureBuilder(
                      future: _getRecommendedRecipes(),
                      builder: (context, snapshot){
                        if (snapshot.hasData == false) {
                          return CircularProgressIndicator();
                        }
                        //error가 발생하게 될 경우 반환하게 되는 부분
                        else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(fontSize: 15),
                            ),
                          );
                        }
                        return Container(
                            margin: EdgeInsets.only(bottom: 10.0),
                            height: getProportionateScreenWidth(320),
                            child: TinderSwapCard(
                              swipeDown: false,
                              swipeUp: false,
                              orientation: AmassOrientation.BOTTOM,
                              totalNum: 100,
                              stackNum: 2,
                              swipeEdge: 3.0,
                              maxHeight: getProportionateScreenWidth(330.0),
                              maxWidth: getProportionateScreenWidth(330.0),
                              minHeight: getProportionateScreenWidth(280.0),
                              minWidth: getProportionateScreenWidth(280.0),
                              allowVerticalMovement: true,
                              cardBuilder: (context, index) {
                                return Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      image: DecorationImage(
                                          image: NetworkImage(recommendedRecipes[index % recommendedRecipes.length].mainImageURL),
                                          fit: BoxFit.cover
                                      )
                                  ),
                                  child: Stack(
                                      children: [
                                        Positioned(
                                          top: getProportionateScreenWidth(250),
                                          left: 0,
                                          right: 0,
                                          height: getProportionateScreenWidth(55),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                    bottomLeft: Radius.circular(15.0),
                                                    bottomRight: Radius.circular(15.0)
                                                ),
                                                color: Colors.black.withOpacity(0.4)
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.fromLTRB(20.0, 5.0, 10.0, 10.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: <Widget>[
                                                  Flexible(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        text:'${recommendedRecipes[index % recommendedRecipes.length].title}',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w300,
                                                            color: Global.white,
                                                            fontSize: 18
                                                        ),
                                                      ),
                                                      strutStyle: StrutStyle(fontSize: 18),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]
                                  ),
                                );
                              },
                              cardController: CardController(),
                              animDuration: 50,
                              swipeUpdateCallback:
                                  (DragUpdateDetails details, Alignment align) {
                                if (align.x < 0) {
                                  //Card is LEFT swiping
                                } else if (align.x > 0) {
                                  //Card is RIGHT swiping
                                }
                              },
                              swipeCompleteCallback: (CardSwipeOrientation orientation, int index) {
                                switch (orientation) {
                                  // 부정 평가
                                  case CardSwipeOrientation.RIGHT:
                                    _scrollController.animateTo(
                                        (_currentIndex) * 80.0,
                                        duration: Duration(milliseconds: 500),
                                        curve: Curves.decelerate
                                    );
                                    setState(() {
                                      checkedRecipe.add({recommendedRecipes[index % recommendedRecipes.length]: true});
                                      waveBackground.checkState = CheckState.like;
                                      increasePercent();
                                      checkState = CheckState.like;
                                      _currentIndex++;
                                    });

                                    UserRepository.updateUserTaste(recommendedRecipes[index % recommendedRecipes.length], -1);

                                    break;
                                  // 긍정 평가
                                  case CardSwipeOrientation.LEFT:
                                    _scrollController.animateTo(
                                        (_currentIndex) * 80.0,
                                        duration: Duration(milliseconds: 500),
                                        curve: Curves.decelerate
                                    );
                                    setState(() {
                                      checkedRecipe.add({recommendedRecipes[index % recommendedRecipes.length]: false});
                                      waveBackground.checkState = CheckState.dislike;
                                      increasePercent();
                                      checkState = CheckState.dislike;
                                      _currentIndex++;
                                    });

                                    UserRepository.updateUserTaste(recommendedRecipes[index % recommendedRecipes.length], 1);

                                    break;
                                  case CardSwipeOrientation.RECOVER:
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) =>
                                            RecipeDetailPage(recipe: recommendedRecipes[index % recommendedRecipes.length]))
                                    );
                                    break;
                                  case CardSwipeOrientation.DOWN:
                                  case CardSwipeOrientation.UP:
                                    break;
                                }
                              },
                            )
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: checkedRecipe.length,
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemBuilder: (context, index) {
                          final recipe = checkedRecipe[index].keys.toList()[0];
                          final check = checkedRecipe[index][recipe];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),

                            width: SizeConfig.screenWidth - 20.0,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.all(Radius.circular(20.0))
                            ),
                            height: 70,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10.0, 5.0, 30.0, 5.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  OpenContainer(
                                    closedElevation: 0.0,
                                    closedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(20.0)
                                        )
                                    ),
                                    transitionDuration: Duration(milliseconds: 300),
                                    openBuilder: (context, _) {
                                      return RecipeDetailPage(recipe: recipe);
                                    },
                                    closedBuilder: (context, openContainer){
                                      return ClipRRect(
                                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                          child: GestureDetector(
                                            onTap: openContainer,
                                            child: Container(
                                              width: 65,
                                              height: 65,
                                              child: Image.network(
                                                  recipe.mainImageURL,
                                                  width: getProportionateScreenHeight(200),
                                                  height: getProportionateScreenHeight(200),
                                                  fit: BoxFit.cover
                                              ),
                                            ),
                                          )
                                      );
                                    },

                                  ),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        text:'${recipe.title}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w300, color: Global.white),

                                      ),
                                      strutStyle: StrutStyle(fontSize: 18),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  //Text('${recipe.title}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Global.white),),
                                  check ? Icon(Icons.favorite, color: Global.white,) : Icon(Icons.sentiment_dissatisfied, color: Global.white)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        )
    );
  }

  _buildDialog(BuildContext context) {
    return Container(
      width: SizeConfig.screenWidth * 0.7,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child
                : Container(
                decoration: BoxDecoration(
                  color: Global.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
                ),
                width: double.infinity,
                height: 300.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      Padding(padding: EdgeInsets.all(8),),
                      Text(
                          '회원님의 취향을 알려주세요!',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: getProportionateScreenWidth(16),
                              color: Global.black
                          )
                      ),
                      Padding(padding: EdgeInsets.all(8),),
                      Text(
                        '맛있어 보이는 레시피는 오른쪽으로\n맛없어 보이는 레시피는 왼쪽으로',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: getProportionateScreenWidth(12),
                          color: Global.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Image.asset('assets/images/drag-right_200_transparent.gif', height:80.0, width: 80.0),
                      ),
                      Text(
                          '스와이프 해주세요!',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: getProportionateScreenWidth(14),
                              color: Global.black
                          )
                      ),
                    ],
                  ),
                )
            ),
          ),
          GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 15.0),
              decoration: BoxDecoration(
              ),
              width: double.infinity,
              height: 30,
              child: Center(
                child: Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0, color: Global.black)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  _buildCheckCompleteDialog(BuildContext context) {
    return Container(
      width: SizeConfig.screenWidth * 0.7,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child
                : Container(
                decoration: BoxDecoration(
                  color: Global.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
                ),
                width: double.infinity,
                height: 200.0,
                child: Padding(
                  padding: const EdgeInsets.only(top:30.0, bottom:10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SvgPicture.asset(
                          'assets/images/pasta.svg',
                          width: getProportionateScreenWidth(120),
                          fit: BoxFit.fitWidth
                      ),
                      Text(
                          '분석이 완료되었습니다!',
                          style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: getProportionateScreenWidth(16),
                              color: Global.black
                          )
                      ),

                    ],
                  ),
                )
            ),
          ),
          SizedBox(height: 10,),
          Expanded(
            flex:1,
            child: GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 15.0),
                decoration: BoxDecoration(
                ),
                width: double.infinity,
                height: SizeConfig.screenHeight * 0.05,
                child: Center(
                  child: Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0, color: Global.black)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analizingWidget() {
    return Text(
        '추천 AI가 회원님의 취향을 분석 중 입니다...',
        style: TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.w400,
            color: Global.black)
    );
  }

  void increasePercent() async {
    var random = Math.Random();
    int increaseNum = random.nextInt(20);
    if(increaseNum == 0) increaseNum += 1;
    _percentage = _percentage + increaseNum >= 100 ? 100 :_percentage + increaseNum;
    waveBackground.setYOffset(SizeConfig.screenHeight * increaseNum / 100);

    if (_percentage == 100){
      print('[TasteCheckPage]검사율 100% 완료');

      UserRepository.updateCheckTaste();

      await showDialog(
          context: context,
          builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0.0,
              backgroundColor: Global.white,
              child: _buildCheckCompleteDialog(context)
          )
      );
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (BuildContext context) => MainPage()
          )
      );
    }
  }

}

class WaveBackground extends StatefulWidget {
  double yOffset;
  CheckState checkState;

  void setYOffset(double y){
    yOffset = yOffset - y < - SizeConfig.screenHeight * 0.1 ? yOffset : yOffset - y;
  }

  WaveBackground(this.yOffset, this.checkState);

  @override
  _WaveBackgroundState createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> with TickerProviderStateMixin{
  AnimationController animationController;
  List<Offset> wavePoints = [];


  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 5000))
      ..addListener(() {
        wavePoints.clear();

        final double waveSpeed = animationController.value * 1080;
        final double fullSphere = animationController.value *  Math.pi * 2;
        final double normalizer = Math.cos(fullSphere);
        final double waveWidth = Math.pi / 270;
        final double waveHeight = 20.0;

        for(int i = 0;  i <= SizeConfig.screenWidth.toInt(); i++){
          double calc = Math.sin((waveSpeed - i) * waveWidth);
          wavePoints.add(
              Offset(
                i.toDouble(),
                calc * waveHeight * normalizer + widget.yOffset,

              )
          );
        }
      });
    animationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        return ClipPath(
          clipper: ClipWidget(
              waveList: wavePoints
          ),
          child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: SizeConfig.screenWidth,
              height: SizeConfig.screenHeight,
              decoration: customDecoration(widget.checkState)
          ),
        );
      },
    );
  }

}

class ClipWidget extends CustomClipper<Path>{
  final List<Offset> waveList;

  ClipWidget({this.waveList});

  @override
  getClip(Size size) {
    final Path path = Path();
    path.addPolygon(waveList, false);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

BoxDecoration customDecoration(CheckState checkState){
  switch(checkState){
    case CheckState.ready:
      return BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, colors: [
          Colors.orange[400],
          Colors.orange[700]
        ]),
      );
      break;
    case CheckState.like:
      return BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, colors: [
          Colors.green[200],
          Colors.green[400]
        ]),
      );
      break;
    case CheckState.dislike:
      return BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, colors: [
          Colors.red[300],
          Colors.red[400]
        ]),
      );
      break;
  }
}