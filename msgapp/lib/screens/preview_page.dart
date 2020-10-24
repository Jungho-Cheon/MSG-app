import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/screens/main_page.dart';
import 'package:msgapp/screens/taste_check_page.dart';
import 'package:msgapp/size_config.dart';

import 'package:msgapp/widgets/splash_content_widget.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';


class PreviewPage extends StatefulWidget {
  int previewCount;

  PreviewPage({this.previewCount});

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  UserRepository _userRepository;
  bool loginProgress = false;
  int currentSplashPage = 0;
  Image logo;
  List<Map<String, dynamic>> splashData = [
    {
      "text": '어떤 음식을 만들지 고민이신가요?',
      'image': Image.asset('assets/images/splash_image_1.png', gaplessPlayback: true, fit: BoxFit.cover)
    },
    {
      "text": '영수증 분석을 통해 식재료를 편리하게 관리하고',
      'image': Image.asset('assets/images/splash_image_2.png', gaplessPlayback: true, fit: BoxFit.cover)
    },
    {
      "text": 'AI가 추천해주는 맞춤형 레시피를 만나보세요!',
      'image': Image.asset('assets/images/splash_image_3.png', gaplessPlayback: true, fit: BoxFit.cover)
    },
  ];

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository.getInstance();
    _userRepository.isKakaoInstalled();
    // logo = Image.asset('assets/images/LOGO.png', gaplessPlayback: true, fit: BoxFit.cover);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    precacheImage(splashData[0]['image'].image, context);
    precacheImage(splashData[1]['image'].image, context);
    precacheImage(splashData[2]['image'].image, context);
    // precacheImage(logo.image, context);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Expanded(
                    //   flex:2,
                    //   child: Padding(
                    //     padding: const EdgeInsets.only(top: 20.0),
                    //     child: logo
                    //   ),
                    // ),
                    Expanded(
                        flex: 8,
                        child: PageView.builder(
                          onPageChanged: (value) {
                            setState(() {
                              currentSplashPage = value;
                            });
                          },
                          itemCount: splashData.length,
                          itemBuilder: (context, index) => SplashContent(
                            text: splashData[index]['text'],
                            image: splashData[index]['image'],
                          ),
                        )
                    ),

                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(50)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: List.generate(splashData.length, (index) => buildDot(index: index)),
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            defaultTargetPlatform != TargetPlatform.iOS?
                            SizedBox(height:40):SizedBox(height:20),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  loginProgress = true;
                                });

                                bool isKakaoLoginSuccess;

                                if(UserRepository.kakaoInstalled){
                                  isKakaoLoginSuccess = await _userRepository.loginWithTalk();
                                }
                                else{
                                  isKakaoLoginSuccess = await _userRepository.loginWithKakao();
                                }

                                setState(() {
                                  loginProgress = false;
                                });

                                if(isKakaoLoginSuccess){
                                  UserRepository.kakaoLogin = true;
                                  if (UserRepository.userInfo['CHECK_TASTE'] == 'false'){
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) => TasteCheckPage()
                                        )
                                    );
                                  }
                                  else{
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) => MainPage()
                                        )
                                    );
                                  }
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50.0),
                                child: Image.asset(
                                    'assets/images/kakao_login_large_narrow.png',
                                    width: 240.0,
                                    height: 50.0,
                                    fit: BoxFit.fitWidth),
                              ),
                            ),
                            SizedBox(height: 10,),
                            defaultTargetPlatform == TargetPlatform.iOS?
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  loginProgress = true;
                                });

                                try{
                                  final credential = await SignInWithApple.getAppleIDCredential(
                                    scopes: [
                                      AppleIDAuthorizationScopes.email,
                                      AppleIDAuthorizationScopes.fullName,
                                    ],
                                  );

                                  await _userRepository.loginWithApple(
                                      credential.givenName,
                                      credential.familyName,
                                      credential.email,
                                      credential.authorizationCode,
                                      credential.identityToken,
                                      credential.state
                                  );

                                  // print('givenName : ${credential.givenName}');
                                  // print('familyName : ${credential.familyName}');
                                  // credential.email != null ?
                                  //   print('email : ${credential.email}')
                                  // : print('email : null');
                                  // print('authorizationCode : ${credential.authorizationCode}');
                                  // print('identityToken : ${credential.identityToken}');
                                  // print('state : ${credential.state}');

                                  setState(() {
                                    loginProgress = false;
                                  });

                                  if (UserRepository.userInfo['CHECK_TASTE'] == 'false'){
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) => TasteCheckPage()
                                        )
                                    );
                                  }
                                  else{
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) => MainPage()
                                        )
                                    );
                                  }
                                } catch (e){
                                  setState(() {
                                    loginProgress = false;
                                  });
                                  print(e);
                                }
                              },

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  width: 240,
                                  height: 50,
                                  color: Colors.black,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/Apple_Logo.png',
                                        width: 40.0,
                                        height: 40.0,
                                        fit: BoxFit.fitWidth
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Login With Apple",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 19
                                        )
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ):Container(),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          loginProgress
          ? Container(
            color: Colors.black.withOpacity(0.6),
            width: SizeConfig.screenWidth,
            height: SizeConfig.screenHeight,
            child: Center(
              child: CircularProgressIndicator(),
            )
            ,
          )
          : Container()
        ],
      )
    );
  }
  AnimatedContainer buildDot({int index}){
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      margin: EdgeInsets.only(right:5),
      height: 6,
      width: currentSplashPage == index ? 25 : 8,
      decoration: BoxDecoration(
          color: currentSplashPage == index ? Colors.orange[500] : Colors.grey[400],
          borderRadius: BorderRadius.circular(3)
      ),
    );
  }
}
