import 'package:animations/animations.dart';
import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/all.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/models/history.dart';
import 'package:msgapp/models/recipe.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/screens/preview_page.dart';
import 'package:msgapp/screens/recipe_detail_page.dart';
import 'package:msgapp/screens/taste_check_page.dart';
import 'package:msgapp/size_config.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin{
  String nickname;
  String userProfileImageURL;

  List<Recipe> recommendedRecipes;
  List<CachedNetworkImageProvider> _recipeMainImages;
  List<Recipe> bottomRecommendedRecipes;
  List<CachedNetworkImageProvider> _bottomRecipeMainImages;

  bool isRecommend = false;

  final AsyncMemoizer _userInfoMemoizer = AsyncMemoizer();
  final AsyncMemoizer _recommendRecipesMemoizer = AsyncMemoizer();
  final AsyncMemoizer _bottomRecommendRecipesMemoizer = AsyncMemoizer();
  RefreshController _refreshController;

  void _onLoading() async {
    await _getRecommendedRecipes(RecommendType.CanMake);
    await _getRecommendedRecipes(RecommendType.JustRecommend);
    _refreshController.loadComplete();
  }


  _fetchInfo() async {
    return this._userInfoMemoizer.runOnce(() async {
      final userInfo = await UserRepository.getUserInfo('HomePage - _fetchInfo()');
      nickname = userInfo['NICKNAME'];
      userProfileImageURL = userInfo['PROFILE_IMAGE'];
      return nickname;
    });
  }

  _refreshRecommendedRecipes(String type) async {
    if (type == 'main'){
      // recommendedRecipes.clear();
      recommendedRecipes = await UserRepository.refreshRecommendedRecipes();
      _recipeMainImages = await _loadMainImages(recommendedRecipes);
    }
    else if (type == 'bottom'){
      // bottomRecommendedRecipes.clear();
      bottomRecommendedRecipes = await UserRepository.refreshRecommendedRecipes();
      _bottomRecipeMainImages = await _loadMainImages(bottomRecommendedRecipes);
    }
    else{
      throw new Exception('[Refresh Recipe] type error');
    }
  }

  _getRecommendedRecipes(RecommendType recommandType) async {
    if (recommandType == RecommendType.CanMake){
      return this._recommendRecipesMemoizer.runOnce(() async {
        recommendedRecipes = await UserRepository.getRecommendedRecipes(recommandType);
        _recipeMainImages = await _loadMainImages(recommendedRecipes);
        return recommendedRecipes;
      });
    }
    else if (recommandType == RecommendType.JustRecommend){
      return this._bottomRecommendRecipesMemoizer.runOnce(() async {
        bottomRecommendedRecipes = await UserRepository.refreshRecommendedRecipes();
        _bottomRecipeMainImages = await _loadMainImages(bottomRecommendedRecipes);
        return bottomRecommendedRecipes;
      });
    }
    else{
      throw new Exception('[Get Recipe] type error');
    }
  }

  Future<List<CachedNetworkImageProvider>> _loadMainImages(List<Recipe> recipes) async {
    List<CachedNetworkImageProvider> cachedImages = List<CachedNetworkImageProvider>();
    for (Recipe recipe in recipes){
      final _config = createLocalImageConfiguration(context);
      cachedImages.add(CachedNetworkImageProvider(recipe.mainImageURL)..resolve(_config));
    }
    return cachedImages;
  }

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _refreshController.loadComplete();
  }


  @override
  void dispose() {
    super.dispose();
    _refreshController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        // height: SizeConfig.screenHeight,
        width: SizeConfig.screenWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: getProportionateScreenHeight(430),
              width: SizeConfig.screenWidth,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: SizeConfig.screenHeight *  0.33,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Global.mainColor,
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.orange[400],
                              Colors.orange[700],
                            ]),
                      ),
                      padding: EdgeInsets.fromLTRB(32, 20, 32, 12),
                    ),
                  ),
                  Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 70,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: FutureBuilder(
                            future: _fetchInfo(),
                            builder: (context, snapshot){
                              if (snapshot.hasData == false) {
                                return SizedBox();
                              }
                              else if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                );
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  GestureDetector(
                                    child: Icon(Icons.exit_to_app, color: Colors.white, size: 20),
                                    onTap: () async {
                                      final storage = await SharedPreferences.getInstance();
                                      if (UserRepository.kakaoLogin){
                                        final unlinkCode = await UserApi.instance.unlink();
                                        // final code = await UserApi.instance.logout();
                                        UserRepository.kakaoLogin = false;
                                        // print('kakao logout $code');
                                        print('kakao unlink $unlinkCode');
                                      }
                                      UserRepository.userInfo = Map<String, dynamic>();

                                      await History.historyStream.close();

                                      await storage.clear();
                                      await AccessTokenStore.instance.clear();

                                      Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                              builder: (BuildContext context) => PreviewPage()
                                          )
                                      );
                                    },
                                  ),
                                  SizedBox(width: 10),
                                ],
                              );
                            }
                        ),
                      )
                  ),
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: SizeConfig.screenHeight * 0.53,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: 30.0),
                            child: Row(
                              children: <Widget>[
                                FutureBuilder(
                                    future: _fetchInfo(),
                                    builder: (context, snapshot){
                                      if (snapshot.hasData == false) {
                                        return Container(
                                            width: 100,
                                            height: 100,
                                            child: CircularProgressIndicator()
                                        );
                                      }
                                      else if (snapshot.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        );
                                      }
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text('$nickname님을 위한', style: TextStyle(
                                              fontSize: getProportionateScreenHeight(24.0),
                                              fontWeight: FontWeight.w300,
                                              color: Global.white
                                          )),
                                          Text('추천 레시피', style: TextStyle(
                                              fontSize: getProportionateScreenHeight(40.0),
                                              fontWeight: FontWeight.w400,
                                              color: Global.white
                                          )),
                                        ],
                                      );
                                    }
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            margin: EdgeInsets.only(bottom:10),
                            height: getProportionateScreenHeight(280),
                            child: FutureBuilder(
                              future: _getRecommendedRecipes(RecommendType.CanMake),
                              builder: (context, snapshot){
                                if (snapshot.hasData == false) {
                                  return Column(
                                    children: <Widget>[
                                      CircularProgressIndicator(),
                                      SizedBox(height: 100,)
                                    ],
                                  );
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
                                return _recommendRecipeCards();
                              },
                            ),
                          ), // 추천 레시피 카드

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: SizeConfig.screenWidth,
              padding: EdgeInsets.only(left: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('지금 만들 수 있는', style: TextStyle(
                      fontSize: getProportionateScreenHeight(24.0),
                      fontWeight: FontWeight.w300,
                      color: Global.black
                  )),
                  Text('맞춤 레시피', style: TextStyle(
                      fontSize: getProportionateScreenHeight(40.0),
                      fontWeight: FontWeight.w400,
                      color: Global.black
                  )),
                ],
              ),
            ),
            SizedBox(height:10),
            FutureBuilder(
              future: _getRecommendedRecipes(RecommendType.JustRecommend),
              builder: (context, snapshot){
                if (snapshot.hasData) {
                  return Column(
                    children: List.generate(bottomRecommendedRecipes.length, (index) => _recommendRecipeLargeCard(context, index)),
                  );
                  // return ListView.separated(
                  //     scrollDirection: Axis.vertical,
                  //     physics: NeverScrollableScrollPhysics(),
                  //     shrinkWrap: true,
                  //     separatorBuilder: (context, _index){
                  //       return SizedBox(height: 0);
                  //     },
                  //     itemCount: bottomRecommendedRecipes.length,
                  //     itemBuilder: ,
                  // );
                }
                else{
                  return Container(
                      width: SizeConfig.screenWidth,
                      height: SizeConfig.screenWidth,
                      child: Center(
                          child: CircularProgressIndicator()
                      )
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _recommendRecipeLargeCard(context, index){
    ImageProvider _mainImage = _bottomRecipeMainImages[index];
    return Container(
      width: SizeConfig.screenWidth,
      child: OpenContainer(
        closedElevation: 0.0,
        transitionDuration: Duration(milliseconds: 600),
        transitionType: ContainerTransitionType.fade,
        openBuilder: (openContainerContext, _) {
          return RecipeDetailPage(
              context: context,
              mainImage: _mainImage,
              recipe: bottomRecommendedRecipes[index]
          );
        },
        closedBuilder: (context, openContainer){
          return GestureDetector(
            onTap: (){
              openContainer();
            },
            child: Container(
              child: Stack(
                  children: [
                    Container(
                      width: SizeConfig.screenWidth,
                      height: SizeConfig.screenWidth,
                      decoration: BoxDecoration(
                        // borderRadius: BorderRadius.circular(15.0),
                          image: DecorationImage(
                              image: _mainImage,
                              fit: BoxFit.cover
                          )
                      ),
                    ),
                    Positioned(
                      top: SizeConfig.screenWidth * 0.85,
                      left: 0,
                      right: 0,
                      height: SizeConfig.screenWidth * 0.15,
                      child: Container(
                        width: SizeConfig.screenWidth,
                        height: SizeConfig.screenWidth * 0.15,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 10.0, 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Flexible(
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: bottomRecommendedRecipes[index].title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                          fontSize: 16
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _recommendRecipeCards() {
    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: false,
      controller: _refreshController,
      onRefresh: () async {
        await _refreshRecommendedRecipes('main');
        setState(() {});
        _refreshController.refreshCompleted();
      },
      onLoading: _onLoading,
      header: ClassicHeader(
        iconPos: IconPosition.top,
        outerBuilder: (child) {
          return Container(
            padding: EdgeInsets.only(left:50),
            width: 100.0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      child: ListView.builder(
        itemCount: recommendedRecipes.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return _recommendCard(index);
        },
      ),
    );
  }

  Widget _recommendCard(int index) {
    ImageProvider _mainImage = _recipeMainImages[index];

    return Container(
        margin: EdgeInsets.only(left: 20, bottom: 13.0),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Global.white,
              boxShadow: [BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 2),
              )
              ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: OpenContainer(
                    closedElevation: 0.0,
                    closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20.0),
                            topLeft: Radius.circular(20.0)
                        )
                    ),
                    transitionDuration: Duration(milliseconds: 300),
                    openBuilder: (context, _) {
                      return RecipeDetailPage(
                        context: context,
                        mainImage: _mainImage,
                        recipe: recommendedRecipes[index]
                      );
                    },
                    closedBuilder: (context, openContainer) {
                      return ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20.0)),
                          child: GestureDetector(
                            onTap: openContainer,
                            child: Container(
                              width: getProportionateScreenHeight(200),
                              height: getProportionateScreenHeight(200),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: _mainImage,
                                    fit: BoxFit.cover
                                ),
                              ),
                            ),
                            // child: Image.network(
                            //     recommendedRecipes[index].mainImageURL,
                            //     width: getProportionateScreenHeight(200),
                            //     height: getProportionateScreenHeight(200),
                            //     fit: BoxFit.cover
                            // ),
                          )
                      );
                    }
                ),
              ),
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20.0, bottom: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: getProportionateScreenHeight(10.0),),
                      Text(
                        recommendedRecipes[index].category,
                        style: TextStyle(
                            color: Global.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenHeight(14.0)
                        ),
                      ),
                      Container(
                        width: getProportionateScreenHeight(165),
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text:recommendedRecipes[index].title,
                            style: TextStyle(
                                fontWeight: FontWeight.w500, color: Global.black,
                                fontSize: getProportionateScreenHeight(16.0)
                            ),

                          ),
                          strutStyle: StrutStyle(fontSize: getProportionateScreenHeight(14.0)),
                        ),
                      ),
//                      Text(
//                        recommendedRecipes[index].title,
//                        style: TextStyle(
//                            color: Global.black,
//                            fontWeight: FontWeight.w800,
//                            fontSize: getProportionateScreenHeight(16.0)
//                        ),
//                      ),

                      Text(
                        recommendedRecipes[index].calories.toString() + ' kcal',
                        style: TextStyle(
                            color: Global.black,
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenHeight(14.0)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}
