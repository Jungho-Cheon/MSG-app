import 'dart:ffi';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/all.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/models/Ingredient.dart';
import 'package:msgapp/models/history.dart';
import 'package:msgapp/models/recipe.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/screens/calendar_page.dart';
import 'package:msgapp/size_config.dart';
import 'package:msgapp/widgets/login_button_widget.dart';
import 'package:msgapp/widgets/remove_ingredients_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeDetailPage extends StatelessWidget {
  final BuildContext context;
  final ImageProvider mainImage;
  final Recipe recipe;
  final _scrollController = ScrollController();

  RecipeDetailPage({this.context, this.mainImage, this.recipe});


  Future<List<CachedNetworkImageProvider>> _loadDescriptionImages(List<String> descImageURLs) async{
    List<CachedNetworkImageProvider> cachedImages = List<CachedNetworkImageProvider>();
    for (String URL in descImageURLs){
      final _config = createLocalImageConfiguration(context);
      cachedImages.add(CachedNetworkImageProvider(URL)..resolve(_config));
    }
    return cachedImages;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          child: Scrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: <Widget>[
                SliverAppBar(
                  leading: SizedBox(),
                  backgroundColor: Colors.transparent,
                  expandedHeight: SizeConfig.screenWidth,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: mainImage,
                            fit: BoxFit.cover
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        recipe.category,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Global.grey
                        ),
                      ),
                      subtitle: Text(
                        recipe.title,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            color: Global.black
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[

                          Text(
                            '${recipe.calories} kcal',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: Global.black
                            ),
                          ),
                          SizedBox(
                            height: getProportionateScreenHeight(5),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.access_time, color: Global.black, size: 14,),
                              SizedBox(width: 5,),
                              Text(
                                  '쉬움',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Global.black,
                                      fontWeight: FontWeight.w300
                                  )
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    FutureBuilder(
                      future: UserRepository.fetchIngredients(),
                      builder: (context, snapshot){
                        if (snapshot.hasData){
                          return _buildIngredients(snapshot.data);
                        }
                        else{
                          return Container();
                        }
                      },
                    ),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    FutureBuilder(
                      future: _loadDescriptionImages(recipe.descriptionImageURLs),
                      builder: (context, snapshot){
                        if (snapshot.hasData){
                          List<ImageProvider> _descImages = snapshot.data;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              ...List<Widget>.generate(recipe.descriptions.length, (index) {
                                return DescriptionWidget(
                                  description: recipe.descriptions[index],
                                  descImage: _descImages[index],
                                  width: SizeConfig.screenWidth,
                                );
                              })
                            ],
                          );
                        }
                        else{
                          return Center(
                              child: SizedBox(
                                height: 56,
                                width: 56,
                                child: CircularProgressIndicator(),
                              )
                          );
                        }
                      },
                    ),
                    SizedBox(height: SizeConfig.screenHeight * 0.02),
                    CheckUsedIngredient(),
                    SizedBox(height: SizeConfig.screenHeight * 0.05)
                  ]),
                ),
              ],
            ),
          )
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: SizeConfig.screenWidth,
            height: 120,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: FractionalOffset.topCenter,
                    end: FractionalOffset.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.grey.withOpacity(0.0),
                    ],
                    stops: [
                      0.0,
                      0.7
                    ])),
          ),
        ),
        Positioned(
            top: getProportionateScreenHeight(40),
            left: 20,
            child: InkWell(
              child: Icon(Icons.arrow_back_ios, size: 25.0, color: Colors.white),
              onTap: (){
                Navigator.pop(context);
              },
            )
        )
      ],
    );
  }

  Widget CheckUsedIngredient() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '다 만드셨나요?\n완성하기를 눌러 다 쓴 재료를 알려주세요!',
          style: TextStyle(color: Global.black),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10,),
        LoginPageButtonWidget(
          title: '완성하기',
          hasBorder: false,
          width: 240.0,
          onTapFunction: () async {
            await showDialog(
               context: context,
               builder: (context) => RemoveIngredientDialog(
                   title: '다쓴 재료를 선택해주세요.', ingredients: recipe.ingredients,)
            );

            try{
              await UserRepository.updateRecipeHistory(recipe);
              final updatedHistory = await UserRepository.fetchHistory();
              History.historyStream.add(updatedHistory);
            }catch(e){
              print(e);
            }

            Navigator.pop(context);
          },
        )
      ],
    );
  }

  Widget _buildIngredients(List<Ingredient> ingredients) {
    List<Widget> _subIngredients = List<Widget>();
    double _size = defaultTargetPlatform == TargetPlatform.iOS? 16 : 13;

    // 주재료가 아닌 식재료
    for (String key in recipe.ingredients.keys) {
      List<Ingredient> values = recipe.ingredients[key];
      _subIngredients.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              key,
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                  fontSize: 20.0
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 6.0,
              runSpacing: 5.0,
              direction: Axis.horizontal,
              children: List.generate(values.length, (index) =>
                  ingredients.contains(Ingredient(title: values[index].title, type: ''))
                  ? Text(
                      values[index].title,
                      style: TextStyle(
                          fontSize: _size,
                          fontWeight: FontWeight.w500,
                          color: Colors.green
                      )
                  )
                  : GestureDetector(
                    child: Container(
                      width: _size * values[index].title.length + 16,
                      child: Row(
                        children: [
                          Text(
                              values[index].title,
                              style: TextStyle(
                                  fontSize: _size,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black
                              )
                          ),
                          Container(
                            height: _size,
                            width: _size,
                            // color: Colors.blue,
                            child: Icon(Icons.search_sharp, color: Colors.black, size: _size)
                          )
                        ],
                      ),
                    ),
                    onTap: () async {
                      String url = 'https://www.coupang.com/np/search?component=&q=${Uri.encodeFull(values[index].title)}&channel=user';
                      // String url = 'https://google.com';
                      print(url);
                      if (await canLaunch(url)) {
                        print('open!');
                        await launch(
                          url,
                          forceSafariVC: false
                        );
                      } else {
                        print('error!');
                        throw 'Could not launch $url';
                      }
                    }
                  )
              )
            ),
            SizedBox(height:10)
          ],
        )
      );
      _subIngredients.add(SizedBox(height:10));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ..._subIngredients
        ],
      ),
    );
  }
}

class DescriptionWidget extends StatelessWidget {
  final String description;
  final descImage;
  final width;

  DescriptionWidget({this.description, this.descImage, @required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: width,
            height: width * 3/4,
            decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.fitWidth,
                  image: descImage
              ),
            ),
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                description.replaceAll(r'\n', ''),
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16
                ),
              ),
            ),
          ),
          SizedBox(height: 25),
          Center(
              child: Container(
                height: 7,
                width: 70,
                decoration: BoxDecoration(
                    color: Colors.orange[300],
                    borderRadius: BorderRadius.all(Radius.circular(50))
                ),
              )
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}

