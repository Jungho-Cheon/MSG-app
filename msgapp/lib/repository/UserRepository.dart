import 'dart:convert';
import 'dart:developer';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/all.dart';
import 'package:http/http.dart' as http;
import 'package:msgapp/models/Ingredient.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/models/history.dart';
import 'package:msgapp/models/receipt.dart';
import 'package:msgapp/models/recipe.dart';
import 'package:msgapp/repository/user-info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../size_config.dart';
import 'custom_aws_credential.dart';
import 'login_statement.dart';

enum RecommendType{
  CanMake,
  JustRecommend,
}

class UserRepository{
  static UserRepository _instance = UserRepository._internal();
  static bool kakaoInstalled = false;
  static bool kakaoLogin = false;
  static CognitoUserPool _cognitoUserPool;

  // Cognito UserPool로 부터 얻은 cognito Credential
  static CognitoCredentials _cognitoCredentials;

  // Kakao 소셜로그인으로 부터 얻은 Cognito Credential
  static CustomCognitoCredentials _cognitoCredentialsWithKakao;

  static CognitoUser _cognitoUser;
  static CognitoUserSession _session;
  LoginStatement _loginStatement;

  // kakao user object
  static User user;
  static Map<String, dynamic> userInfo = {};

//  ============================================================================

  static UserRepository getInstance() {
    if(_instance == null){
      _instance = UserRepository._internal();
    }
    return _instance;
  }

  static getCredentials(){
    if (kakaoLogin){
      return _cognitoCredentialsWithKakao;
    }else{
      return _cognitoCredentials;
    }
  }


  factory UserRepository(){
    return _instance;
  }

  UserRepository._internal() {
    _cognitoUserPool = CognitoUserPool(
      Config.cognitoUserPoolId,
      Config.cognitoUserPoolClientId,
    );
    _cognitoCredentials = CognitoCredentials(
        Config.cognitoIdentityPoolId, _cognitoUserPool);

    _cognitoCredentialsWithKakao = CustomCognitoCredentials(
        Config.cognitoIdentityPoolId, _cognitoUserPool);

  }

//  =================================================================================

  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = Storage(prefs);
    _cognitoUserPool.storage = storage;

    _cognitoUser = await _cognitoUserPool.getCurrentUser();

    if (_cognitoUser == null) {
      return false;
    }
    _session = await _cognitoUser.getSession();

    final _isValid = _session.isValid();
    if(_isValid){
      try{
        await _cognitoCredentials.getAwsCredentials(_session.getIdToken().getJwtToken());
      } catch (e){
        print(e);
      }
    }

    return _isValid;
  }

//  =================================================================================

  static Future<List<Recipe>> refreshRecommendedRecipes() async {
    List<Recipe> recommendedRecipes = List<Recipe>();
    try{
      // 레시피 추천 요청
      final headers = {
        'Accept-Encoding': 'gzip, deflate, br',
        'Content-Type': 'application/json',
        'x-api-key' : Config.recipe_recommendation_API_KEY
      };
      final _userInfo = await getUserInfo('UserRepository refreshRecommendedRecipes()');
      final url = Config.API_URL + '/recipeRecommend?providerId=${_userInfo['PROVIDER_ID']}';
      print('레시피 요청');
      final _response = await http.get(url, headers:headers);
      var responseBody = json.decode(_response.body);
      responseBody = json.decode(responseBody['body']);

      final tempDifficulty = ['쉬움', '중간', '어려움'];
      int index = 0;
      print('[UserRepository] 새로고침');
      for(dynamic recipe in responseBody){
        if (!recipe.containsKey('MANUAL')) continue;
        List<String> descriptions = recipe['MANUAL'].cast<String>();
        List<String> descriptionsImageURLS = recipe['MANUAL_IMG'].cast<String>();
        Map<String, dynamic> _ingredients = recipe['INGREDIENTS_MAP'];
        Map<String, List<Ingredient>> ingredients = Map<String, List<Ingredient>>();
        _ingredients.forEach((key, value) {
          ingredients[key] = List<Ingredient>();
          value.forEach((i) => ingredients[key].add(Ingredient(title: i.toString(), type:'')));
        });

        recommendedRecipes.add(
            Recipe(
                descriptionImageURLs: descriptionsImageURLS,
                difficulty: tempDifficulty[index % 3],
                descriptions: descriptions,
                ingredients: ingredients,
                mainImageURL: recipe['MAIN_IMG'],
                title: recipe['RECIPE_TITLE'],
                calories: double.parse(recipe['CALORIES']),
                car: double.parse(recipe['CAR']),
                category: recipe['CATEGORY'],
                fat: double.parse(recipe['FAT']),
                method: recipe['METHOD'],
                na: double.parse(recipe['NA']),
                protein: double.parse(recipe['PROTEIN']),
                recipeId: recipe['RECIPE_ID']
            )
        );
        index++;
      }

    } catch (e){
      print('refreshRecommendedRecipes() exception');
      print(e);
    }

    print('[UserRepository] 레시피 새로고침 완료');

    return recommendedRecipes;
  }

  static Future<List<Recipe>> getRecommendedRecipes(RecommendType recommendType) async {
    List<Recipe> recommendedRecipes = List<Recipe>();
    // 레시피 추천 요청
    try{
      final headers = {
        'Accept-Encoding': 'gzip, deflate, br',
        'Content-Type': 'application/json; charset=utf-8',
        'x-api-key' : Config.recipe_recommendation_API_KEY
      };
      final _userInfo = await getUserInfo('UserRepository getRecommendedRecipe()');
      final url = Config.RecipeRecommendAddress + '?providerId=${_userInfo['PROVIDER_ID']}&recommendType=${recommendType.toString().split('.').last}';
      final _response = await http.get(url, headers:headers);
      var responseBody = json.decode(_response.body);

      final tempDifficulty = ['쉬움', '중간', '어려움'];
      int index = 0;
      print('[UserRepository] 최초 화면 추천');

      for(dynamic recipe in responseBody){
        if (!recipe.containsKey('MANUAL')) continue;
        List<String> descriptions = recipe['MANUAL'].cast<String>();
        List<String> descriptionsImageURLS = recipe['MANUAL_IMG'].cast<String>();
        Map<String, dynamic> _ingredients = recipe['INGREDIENTS_MAP'];
        Map<String, List<Ingredient>> ingredients = Map<String, List<Ingredient>>();
        _ingredients.forEach((key, value) {
          ingredients[key] = List<Ingredient>();
          value.forEach((i) => ingredients[key].add(Ingredient(title: i.toString(), type:'')));
        });

        recommendedRecipes.add(
            Recipe(
                descriptionImageURLs: descriptionsImageURLS,
                difficulty: tempDifficulty[index % 3],
                descriptions: descriptions,
                ingredients: ingredients,
                mainImageURL: recipe['MAIN_IMG'],
                title: recipe['RECIPE_TITLE'],
                calories: double.parse(recipe['CALORIES']),
                car: double.parse(recipe['CAR']),
                category: recipe['CATEGORY'],
                fat: double.parse(recipe['FAT']),
                method: recipe['METHOD'],
                na: double.parse(recipe['NA']),
                protein: double.parse(recipe['PROTEIN']),
                recipeId: recipe['RECIPE_ID']
            )
        );
        index++;
      }
      print('[UserRepository] 추천레시피 변환 완료');
    } catch (e){
      print(e);
    }

    return recommendedRecipes;
  }

  // DynamoDB에서 사용자가 보유한 식재료를 탐색한다.
  static Future<List<Ingredient>> fetchIngredients() async {
    final userInfo = await getUserInfo('UserRepository fetchIngredients()');
    final url = Config.API_URL + 'msg-ingredients?PROVIDER_ID=${userInfo['PROVIDER_ID']}';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.dynamoDB_API_KEY
    };

    final _response = await http.get(url, headers:headers);

    // 보유 식재료가 없는 경우 빈 리스트를 반환한다.
    if(_response.body == 'null'){
      return List<Ingredient>();
    }

    final responseBody = json.decode(utf8.decode(_response.bodyBytes));
    final items = json.decode(responseBody);
    final List<Ingredient> ret = List<Ingredient>();
    for(var ingredient in items['INGREDIENTS']){
      ret.add(Ingredient(title : ingredient, type:''));
    }

    // print('[UserRepository] fetchIngredients return ${ret.toString()}');
    return ret;
  }

  /// 식재료 업데이트
  /// DynamoDB의 식재료 테이블을 업데이트한다.
  static Future<void> updateIngredients(List<Ingredient> originIngredients, List<Ingredient> updateIngredients) async {
    final userInfo = await getUserInfo('UserRepository - updateIngredients()');
    final url = Config.API_URL + 'msg-ingredients';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.dynamoDB_API_KEY
    };

    final Set<String> ingredientSet = Set<String>();
    originIngredients.forEach((ingredient) => ingredientSet.add(ingredient.title));
    updateIngredients.forEach((ingredient) => ingredientSet.add(ingredient.title));

    final List<String> _ingredients = List<String>();
    for(String ingredient in ingredientSet.toList()){
      _ingredients.add(ingredient.toString());
    }

    final body = {
      'PROVIDER_ID': userInfo['PROVIDER_ID'].toString(),
      'INGREDIENTS': _ingredients // TODO 대분류 추가시 구조 바꿔야 함.
    };
    print('[UserRepository] updateIngredients request body : ${json.encode(body)}');

    final _response = await http.post(url, headers:headers, body: json.encode(body));
  }


  ///  [datetime] : 영수증의 날짜 (인식하지 못한 경우 현재 시간)
  ///  [ingredients] : 영수증의 식재료와 사용자가 추가한 식재료
  ///  [price] : 영수증의 총액 (인식하지 못한 경우 사용자가 입력한 총액)
  ///  1. DynamoDB의 영수증 테이블에 영수증 정보를 추가한다.
  ///  2. 현재 보유 식재료와 추가된 식재료를 합하여 갱신한다.
  static Future<void> putReceiptInfo(DateTime datetime, List<String> ingredients, String price) async {
    try{
      final userInfo = await getUserInfo('UserRepository - updateIngredients()');
      final url = Config.API_URL + 'msg-receipt';
      final headers = {
        'Accept-Encoding': 'gzip, deflate, br',
        'Content-Type': 'application/json',
        'x-api-key' : Config.receipt_API_KEY
      };
      final _now = new DateTime.now().toString();
      final body = {
        "PROVIDER_ID": userInfo['PROVIDER_ID'].toString(), // 식별자 ID
        'DATE': _now, // 영수증 출력 날짜
        'RECEIPT_DATE' : datetime.toString(), // DB 등록 날짜
        'INGREDIENTS': ingredients,
        'PRICE': price
      };
      final _response = await http.post(url, headers:headers, body: json.encode(body));

      // 식재료 갱신
      final originIngredients = await fetchIngredients();
      final insertIngredients = List<Ingredient>();
      ingredients.forEach((ingredient) => insertIngredients.add(new Ingredient(type: '', title: ingredient)));
      await updateIngredients(originIngredients, insertIngredients);
    }catch(e){
      print('putReceiptInfo Exception');
    }

  }

  // DynamoDB에 사용자 데이터 추가
  Future<void> persistUserInfo(
      String providerId,
      String email,
      String nickname,
      List attributes,
      String provider
      ) async {

    final url = Config.API_URL + 'sign-up';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json; charset=utf-8',
      'x-api-key' : Config.dynamoDB_API_KEY
    };
    final body = {
      'PROVIDER_ID': providerId,
      'EMAIL': email,
      'NICKNAME': nickname,
      'CHECK_TASTE': 'false',
    };

    if(provider =='cognito'){
      for(int i = 0; i < attributes.length; i++) {
        String key = attributes[i].name.split(':')[1];
        body[key] = attributes[i].value;
      }
    } else if (provider == 'kakao'){
      for(int i = 0; i < attributes.length; i++){
        body[attributes[i].name] = attributes[i].value;
      }
    }

    // 취향 검사 유무 체크
    final response = await http.post(url, headers:headers, body: json.encode(body));
    final responseBody = utf8.decode(response.bodyBytes);
    final responseData = json.decode(responseBody);
    final checkTaste = responseData['body']['message']['Item']['CHECK_TASTE'];
    userInfo['CHECK_TASTE'] = checkTaste;

  }

  static Future<Map<String, dynamic>> getUserInfo(String call) async {
    if (userInfo.containsKey('PROVIDER_ID')){
      return userInfo;
    }

    if (user != null){
      final _userInfo = user.toJson();
      userInfo['PROVIDER_ID'] = _userInfo['id'];
    }
    else{
      final storage = await SharedPreferences.getInstance();
      if (storage.containsKey('apple-login-info')){
        final _appleUserInfo = storage.getStringList('apple-login-info');
        userInfo['PROVIDER_ID'] = _appleUserInfo[0];
      }
    }
    final url = Config.API_URL + 'msg-user?providerId=${userInfo['PROVIDER_ID']}';

    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.login_API_KEY
    };

    final _response = await http.get(url, headers:headers);
    final _responseBody = json.decode(_response.body);
    final _userInfo = json.decode(_responseBody['body']);
    print('getUserInfo _responseBody $_userInfo');

    userInfo = _userInfo;
    return userInfo;
  }

  //---------------------------------------------------------------------------//
  // 카카오 소셜 로그인 관련 메소드
  Future<bool> isKakaoInstalled() async {
    kakaoInstalled = await isKakaoTalkInstalled();
    return kakaoInstalled;
  }

  Future<void> issueAccessToken(String authCode, bool isFirstLoggin, AccessToken accessToken) async {
    print('[UserRepository] Kakao AccessToken');
    try{
      // 카카오 로그인으로 토큰 얻기
      AccessTokenResponse token;

      isFirstLoggin
          ?token = await AuthApi.instance.issueAccessToken(authCode)
          :token = await AuthApi.instance.refreshAccessToken(accessToken.refreshToken);

      AccessTokenStore.instance.toStore(token);
      user = await UserApi.instance.me();

      final userInfo = user.toJson();
      final profileImage = userInfo['kakao_account']['profile']['profile_image_url'];
      final userUniqueID = userInfo['id'].toString();
      final email = userInfo['kakao_account']['email'];
      final nickname = userInfo['kakao_account']['profile']['nickname'];
      String gender = '';
      if(userInfo['kakao_account']['gender'] == 'male')
        gender = '남성';
      else if(userInfo['kakao_account']['gender'] == 'female'){
        gender = '여성';
      }else{
        gender = '비공개';
      }
      final ageRange = userInfo['kakao_account']['age_range'].split('~')[0] + '대';
      final List<AttributeArg> attributes = [
        AttributeArg(name: "GENDER", value: gender),
        AttributeArg(name: "AGE_RANGE", value: ageRange),
        AttributeArg(name: "PROFILE_IMAGE",value:profileImage)
      ];

      await persistUserInfo(userUniqueID, email, nickname, attributes, 'kakao');

      // 정합성 검증을 위해 API Gateway에 카카오 id, access_token, expires_in을 보낸다.
      final url = Config.API_URL + 'MSG-login?'
          'id=${user.id.toString()}&'
          'access_token=${token.accessToken}&'
          'expires_in=${token.expiresIn.toString()}';
      final headers = {
        'x-api-key': Config.login_API_KEY
      };

      // 정합성이 검증되었다면 AWS Credential을 얻는다.
      final _response = await http.get(url, headers:headers);
      final Map<String, dynamic> response = json.decode(_response.body);
      await _cognitoCredentialsWithKakao.getAwsCredentials(response['IdentityId'], response['Token'], true);

    } catch (e){
      print('[UserRepository] error occurred on issuing access token : $e');
    }
  }

  Future<void> loginWithApple(
      String givenName,
      String familyName,
      String email,
      String authorizationCode,
      String identityToken,
      String state
      ) async {
    try{
      final url = Config.API_URL + 'apple-login';
      final headers = {
        'Accept-Encoding': 'gzip, deflate, br',
        'Content-Type': 'application/json; charset=utf-8',
        'x-api-key' : Config.login_API_KEY
      };
      final _body = {
        'givenName': givenName?? '',
        'familyName': familyName?? '',
        'email': email != null ? email : '',
        'authorizationCode': authorizationCode,
        'identityToken': identityToken
      };

      final _response = await http.post(url, headers:headers, body: json.encode(_body));
      final _responseBody = json.decode(_response.body)['body'];
      final _appleUserInfo = json.decode(_responseBody);
      print(_appleUserInfo);

      final storage = await SharedPreferences.getInstance();
      storage.setStringList('apple-login-info', [
        _appleUserInfo['PROVIDER_ID'], _appleUserInfo['REFRESH_TOKEN']
      ]);

      userInfo['PROVIDER_ID'] = _appleUserInfo['PROVIDER_ID'];
      userInfo['NICKNAME'] = _appleUserInfo['NICKNAME'];
      userInfo['CHECK_TASTE'] = _appleUserInfo['CHECK_TASTE'];

    }catch(e){
      print('loginWithApple() Exception');
      print(e);
    }
  }

  Future<bool> loginWithKakao() async {
    try{
      var code = await AuthCodeClient.instance.request();
      await issueAccessToken(code, true, null);
    } catch (e){
      // print(e.toString());
      return false;
    }
    return true;
  }

  Future<bool> loginWithTalk() async {
    try{
      var code = await AuthCodeClient.instance.requestWithTalk();
      await issueAccessToken(code, true, null);
    } on KakaoAuthException catch (e) {
      // some error happened during the course of user login... deal with it.
      print(e);
      return false;
    } on KakaoClientException catch (e) {
      //
      print(e);
      return false;
    } catch (e) {
      //
      print(e);
      return false;
    }
    return true;
  }

  logOutTalk() async {
    try{
      var code = await UserApi.instance.logout();
      print(code);
    } catch (e) {
      print(e.toString());
    }
  }

  unlinkTalk() async {
    try{
      var code = await UserApi.instance.unlink();
      print(code);
    } catch (e){
      print(e.toString());
    }
  }

  static Future<Map<DateTime, List<History>>> fetchHistory() async {
    final _allHistory = new Map<DateTime, List<History>>();

    final userInfo = await getUserInfo('UserRepository - _fetchRecipeHistory()');
    final url = Config.API_URL + 'msg-history?PROVIDER_ID=${userInfo['PROVIDER_ID']}';

    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.dynamoDB_API_KEY
    };

    try{
      final _response = await http.get(url, headers:headers);
      final _body = json.decode(_response.body)['body'];
      final _recipeHistory = json.decode(_body)['RECIPE_HISTORY'];
      final _receiptHistory = json.decode(_body)['RECEIPT_HISTORY'];

      // 레시피 기록 추가
      for (var history in _recipeHistory){
        final _date = history['DATE'].toString().split(' ')[0].split('-');
        final _dateTime = DateTime(
          int.parse(_date[0]),
          int.parse(_date[1]),
          int.parse(_date[2]),
        );

        if (!_allHistory.containsKey(_dateTime)){
          _allHistory[_dateTime] = List<History>();
        }
        _allHistory[_dateTime].add(
            History(
                historyType: HistoryType.RECIPE,
                info: Recipe(
                    mainImageURL: history['RECIPE_MAIN_IMAGE_URL'],
                    title: history['RECIPE_TITLE'],
                    method: history['RECIPE_METHOD'],
                    calories: double.parse(history['RECIPE_CALORIES']),
                    category: history['RECIPE_CATEGORY']
                )
            )
        );
      }

      // 영수증 기록 추가
      for(var history in _receiptHistory){
        final _date = history['RECEIPT_DATE'].toString().split(' ')[0].split('-');
        final _dateTime = DateTime(
          int.parse(_date[0]),
          int.parse(_date[1]),
          int.parse(_date[2]),
        );

        if (!_allHistory.containsKey(_dateTime)){
          _allHistory[_dateTime] = List<History>();
        }

        final _ingredients = List<Ingredient>();
        (history['INGREDIENTS'] as List).forEach((element) {
          _ingredients.add(Ingredient(title: element, type: ''));
        });

        _allHistory[_dateTime].add(
            History(
                historyType: HistoryType.RECEIPT,
                info: Receipt(
                  price: history['PRICE'],
                  ingredients: _ingredients,
                  date: _dateTime
                )
            )
        );
      }
    }catch(e){
      print(e);
    }

    return _allHistory;
  }

  /// 취향분석, 레시피 완성시 사용자의 취향 분석을 위해 정보를 저장
  /// [recipe] - 현재 평가할 레시피
  /// [score] - 추천 알고리즘에 사용될 레시피 점수
  static void updateUserTaste(Recipe recipe, int score) async {
    final userInfo = await getUserInfo('UserRepository - updateUserTaste()');
    final url = Config.API_URL + 'msg-taste';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.dynamoDB_API_KEY
    };
    final _now = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day
    );
    final body = {
      "PROVIDER_ID": userInfo['PROVIDER_ID'].toString(),
      'DATE': _now.toString().split(' ')[0],
      'RECIPE_ID' : recipe.recipeId,
      'SCORE': score
    };
    await http.post(url, headers:headers, body: json.encode(body));
  }

  static void updateCheckTaste() async {
    final userInfo = await getUserInfo('UserRepository - updateCheckTaste()');
    final url = Config.API_URL + 'msg-taste?PROVIDER_ID=${userInfo['PROVIDER_ID']}&CHECK_TASTE=true';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.dynamoDB_API_KEY
    };
    final _response = await http.get(url, headers:headers);

  }

  static Future<void> updateRecipeHistory(Recipe recipe) async {
    final userInfo = await getUserInfo('UserRepository - updateRecipeHistory()');
    final url = Config.API_URL + 'msg-update-recipe-history';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.dynamoDB_API_KEY
    };
    final _now = DateTime.now().toString();

    final body = {
      "PROVIDER_ID" : userInfo['PROVIDER_ID'].toString(),
      'DATE': _now,
      'RECIPE_ID' : recipe.recipeId,
      'RECIPE_TITLE' : recipe.title,
      'RECIPE_MAIN_IMAGE_URL' : recipe.mainImageURL,
      'RECIPE_METHOD' : recipe.method,
      'RECIPE_CATEGORY' : recipe.category,
      'RECIPE_CALORIES' : recipe.calories,
    };
    await http.post(url, headers:headers, body: json.encode(body));
  }

  static Future<void> appleRefreshToken(String providerId, String refreshToken) async {
    final url = Config.API_URL + 'apple-login?refreshToken=$refreshToken';
    final headers = {
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'x-api-key' : Config.login_API_KEY
    };
    final _response = await http.get(url, headers:headers);
    final _responseBody = json.decode(_response.body);
    final _idToken = json.decode(_responseBody['body']);
    final _providerID = _idToken['sub'];

    if (providerId == _providerID){
      print('apple provider id 일치');
    }
  }
}

class Storage extends CognitoStorage {
  SharedPreferences _prefs;
  Storage(this._prefs);

  @override
  Future getItem(String key) async {
    String item;
    try {
      final String _item = _prefs.getString(key);
      if (_item == null){
        print('[Storage] getItem item $key 없음');
        return null;
      }
      item = await json.decode(_item);
    } catch (e) {
      print('[Storage] error $item ${e.toString()}');
      return null;
    }
    //print('[Storage] getItem item : ' + item);
    return item;
  }

  @override
  Future setItem(String key, value) async {
    await _prefs.setString(key, json.encode(value));
    return getItem(key);
  }

  @override
  Future removeItem(String key) async {
    final item = getItem(key);
    if (item != null) {
      await _prefs.remove(key);
      return item;
    }
    return null;
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
