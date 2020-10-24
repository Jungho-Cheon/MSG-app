import 'package:amazon_cognito_identity_dart_2/cognito.dart';

class UserInfo {
  String email;
  String name;
  String password;
  bool confirmed = false;
  bool hasAccess = false;

  UserInfo({this.email, this.name});

  factory UserInfo.fromUserAttributes(List<CognitoUserAttribute> attributes) {
    final user = UserInfo();
    attributes.forEach((attribute) {
      if (attribute.getName() == 'email') {
        user.email = attribute.getValue();
      } else if (attribute.getName() == 'name') {
        user.name = attribute.getValue();
      }
    });
    return user;
  }
}