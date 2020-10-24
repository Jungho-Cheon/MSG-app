import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kakao_flutter_sdk/all.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/screens/home_page.dart';
import 'package:msgapp/screens/main_page.dart';
import 'package:msgapp/screens/preview_page.dart';
import 'package:msgapp/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_config.dart';
import 'repository/UserRepository.dart';

void main() async {
  KakaoContext.clientId = Config.kakaoClientId;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool previewFlag = false;
  int previewCountTest;
  bool isCognitoLoggin = false;
  String email = '';


  final AsyncMemoizer _userTokenMemoizer = AsyncMemoizer();

  @override
  void initState() {
    super.initState();

  }

  void checKakaoInstalled() async {
    final repo = UserRepository.getInstance();
    final isKakaoInstalled = await repo.isKakaoInstalled();
    print('[init] 카카오톡 설치 유무 : $isKakaoInstalled');
  }

  Future<dynamic> initData() async {
    return this._userTokenMemoizer.runOnce(() async {
      try{
        AccessToken token = await AccessTokenStore.instance.fromStore();
        final storage = await SharedPreferences.getInstance();
        if (token.refreshToken != null) {
          print('[Init] Kakao User 로그인 정보 확인');
          final repo = UserRepository.getInstance();
          await repo.issueAccessToken(null, false, token);
          UserRepository.kakaoLogin= true;
          final accessToken = await AuthApi.instance.refreshAccessToken(token.refreshToken);
          AccessTokenStore.instance.toStore(accessToken);
        }
        else if (storage.containsKey('apple-login-info')){
          print('[Init] Apple User 로그인 정보 확인');
          final _appleUserInfo = storage.getStringList('apple-login-info');
          print('_appleUserInfo $_appleUserInfo');

          await UserRepository.appleRefreshToken(_appleUserInfo[0], _appleUserInfo[1]);

        } else{
          print('[init] refreshToken 없음');
          return {};
        }
        final userData = UserRepository.getUserInfo('main');
        return userData;
      }catch(e){
        print(e);
        return {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '미식한 고독가',
          theme: ThemeData(
            primaryColor: Global.white,
            accentColor: Global.mainColor,
            fontFamily: 'NEXON_Lv1_Gothic',
            textTheme: TextTheme(
              bodyText1: TextStyle(color: Global.black),
//              bodyText2: TextStyle(color: Global.black),
            ),
            scaffoldBackgroundColor: Global.white,
            visualDensity: VisualDensity.adaptivePlatformDensity
          ),
          home: FutureBuilder(
            future: initData(),
            builder: (context, snapshot){
              if (!snapshot.hasData){
                return Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.screenHeight,
                  child: Image.asset(
                      'assets/images/Loading.png',
                      fit: BoxFit.fitWidth
                  ),
                );
              } // 데이터 로딩 중 스플레쉬 화면
              else if (snapshot.hasError){
                print('errer!');
                print(snapshot.error);
              } // 에러 발생한 경우

              if ((snapshot.data as Map).containsKey('PROVIDER_ID') && (snapshot.data as Map)['PROVIDER_ID'] != null){ // 로그인 데이터가 있는 경우
                return MainPage();
              }else{ // 로그인 데이터가 없는 경우
                return PreviewPage();
              }
            }
          )
    );
  }

}

