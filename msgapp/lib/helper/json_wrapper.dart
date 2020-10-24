import 'dart:convert';

String cmdJsonEncode(String cmd, Object object){
  final JsonEncoder encoder = JsonEncoder.withIndent('\t');
  final data = Map<String, dynamic>();

  data['CMD'] = cmd;
  data['BODY'] = object;

  try{
    String jsonString = encoder.convert(data);
    return jsonString;
  }catch(e){
    print(e);
  }
}