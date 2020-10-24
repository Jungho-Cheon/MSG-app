import 'package:amazon_cognito_identity_dart_2/cognito.dart';

class CustomCognitoCredentials {
  final String _region;
  final String _identityPoolId;
  final CognitoUserPool _pool;
  final Client _client;

  int _retryCount = 0;
  String accessKeyId;
  String secretAccessKey;
  String sessionToken;
  int expireTime;
  String userIdentityId;

  CustomCognitoCredentials(
      this._identityPoolId,
      this._pool, {
        String region,
        String userPoolId,
      })  : _region = region ?? _pool.getRegion(), _client = _pool.client;

  Future<void> getAwsCredentials(String identityId, String Token, bool refresh) async {
    if (!refresh){
      if (!(expireTime == null ||
          DateTime.now().millisecondsSinceEpoch > expireTime - 60000)) {
        return;
      }
    }

    userIdentityId = identityId;

    var paramsReq = <String, dynamic>{'IdentityId': userIdentityId};

    paramsReq['Logins'] = {
      'cognito-identity.amazonaws.com': Token
    };

    var data;
    try {
      data = await _client.request('GetCredentialsForIdentity', paramsReq,
          service: 'AWSCognitoIdentityService',
          endpoint: 'https://cognito-identity.$_region.amazonaws.com/');
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException' && _retryCount < 1) {
        _retryCount++;
        return await getAwsCredentials(identityId, Token, false);
      }

      _retryCount = 0;
      rethrow;
    }

    _retryCount = 0;

    accessKeyId = data['Credentials']['AccessKeyId'];
    secretAccessKey = data['Credentials']['SecretKey'];
    sessionToken = data['Credentials']['SessionToken'];
    expireTime = (data['Credentials']['Expiration']).toInt() * 1000;
  }

  Future<void> resetAwsCredentials() async {
    await CognitoIdentityId(_identityPoolId, _pool).removeIdentityId();
    expireTime = null;
    accessKeyId = null;
    secretAccessKey = null;
    sessionToken = null;
  }
}