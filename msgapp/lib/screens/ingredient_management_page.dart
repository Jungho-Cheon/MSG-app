import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/helper/json_wrapper.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/screens/camera_page.dart';
import 'package:msgapp/size_config.dart';

import '../color_config.dart';
import '../models/Ingredient.dart';

class IngredientManagementPage extends StatefulWidget {
  IngredientManagementPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _IngredientManagementPageState createState() => _IngredientManagementPageState();
}

class _IngredientManagementPageState extends State<IngredientManagementPage> {
  Future<List<Ingredient>> _futureIngredients;
  List<Ingredient> _ingredients;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  void fetch() async {
    // DynamoDB 식재료 테이블에서 식재료 가져오기
    _futureIngredients = UserRepository.fetchIngredients();
    _ingredients = await _futureIngredients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: "camera",
          child: Icon(Icons.camera_alt, color: Global.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RealTimeReceiptDetectorPage()),
            ).then((_){
              setState(() {
                fetch();
              });
            });
          },
        ),
        appBar: AppBar(
          title: Center(
            child: Text('식재료 관리',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  color: Global.white
              ),
            ),
          ),
          leading: IconButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context){
                  return AddIngredientDialog(_ingredients);
                }
              );
              setState(() {
                fetch();
              });
            },
            icon: Icon(Icons.add, color: Colors.white),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  fetch();
                });
              },
            )
          ],
          elevation: 0.0,
          backgroundColor: Colors.orange,
        ),

        body: _futureBuilder()
    );
  }

  Widget _futureBuilder(){
    return FutureBuilder(
      future: _futureIngredients,
      builder: (context, snapshot) {
        switch(snapshot.connectionState){
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return Center(child: CircularProgressIndicator(),);
          case ConnectionState.done:
            if (snapshot.hasError)
              return Center(child: Text('오류가 발생했습니다.'),);
            var ingredients = snapshot.data;
            return _buildbody(ingredients);
        }
        return null;
      },
    );
  }

  Widget _buildbody(List<Ingredient> ingredients) {
    return Padding(
        padding: EdgeInsets.only(left:20.0, right: 20.0),
        child: _buildIngredientList(ingredients)
    );
  }

  Widget _buildIngredientList(List<Ingredient> _ingredients) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(height: 0,),
      itemCount: _ingredients.length,
      itemBuilder: (BuildContext context, int index){
        Ingredient ingredient = _ingredients[index];
        return Slidable(
          actionPane: SlidableDrawerActionPane(),
          actionExtentRatio: 0.2,
          secondaryActions: <Widget>[
            IconSlideAction(
              color: Colors.red,
              icon: Icons.delete,
              onTap: () {
                setState(() {
                  _ingredients.removeAt(index);
                });
                UserRepository.updateIngredients([], _ingredients);
              },
            ),
          ],
          child: ListTile(
              title: Text(ingredient.title, style: TextStyle(fontWeight:FontWeight.w500),),
              trailing: Icon(Icons.chevron_left, color: Colors.black45,)
          ),
          key: UniqueKey(),
        );
      },
      shrinkWrap: true,
    );
  }
}

class AddIngredientDialog extends StatefulWidget {
  final originIngredients;


  AddIngredientDialog(this.originIngredients);

  @override
  _AddIngredientDialogState createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  // 검색을 위한 소켓 통신
  WebSocket socket;
  List<String> _searchResults = List<String>();
  List<String> _selectedIngredients = List<String>();

  String searchText = '';
  TextEditingController searchIngredientController = new TextEditingController();
  ScrollController searchScrollController = new ScrollController();

  void _handleWebSocket(socketData) async {
    print('socketData : $socketData');

    if (socketData.runtimeType == String){
      String cmd;
      Map<String, dynamic> data;
      try{
        Map<String, dynamic> decodeData = jsonDecode(socketData);
        print(decodeData);
        cmd = decodeData['CMD'];
        data = decodeData['DATA'];
        switch (cmd) {
          case 'SEARCH':
            break;
          case 'RESULTS':
            final ingredients = List<String>.from(data['ingredients']);
            setState(() {
              _searchResults.clear();
              _searchResults.addAll(ingredients);
              print('current searchResults : $_searchResults');
            });
            break;
        }
      }
      catch(e){
        print(e.toString());
      }
    }
  }

  Future<void> _startReceiptDetection() async {
    while (true){
      print('conneting websock to ${Config.SearchWebSocketAddress}');
      try{
        socket = await WebSocket.connect(Config.SearchWebSocketAddress);
      }
      catch (e){
        print(e.toString());
      }
      if (socket != null)
        break;
    }
    socket.listen(_handleWebSocket,
        onDone: (){
          print('** 소켓 통신 종료 **');
          socket.close();
        },
        onError: (error) {
          print('error $error');
          reConnectWs();
        }
    );
    print('** 소켓 통신 시작 **');
    socket.add(cmdJsonEncode('START', ''));
  }

  void reConnectWs(){
    print('재연결 중..');
    Future.delayed(Duration(milliseconds: 500)).then((_){
      _startReceiptDetection();
    });
  }


  @override
  void initState() {
    super.initState();
    _startReceiptDetection();
  }


  @override
  void dispose() {
    socket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        width: SizeConfig.screenWidth * 0.8,
        height: SizeConfig.screenHeight * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height:15),
            Center(
              child: Text(
                '식재료 등록',
                style: TextStyle(
                  fontSize: 21,

                ),
              ),
            ),
            SizedBox(height:20),
            Container(
              padding: EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.0)
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                  ),
                  hintText: '식재료명을 입력해주세요.',
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                  ),
                  border: InputBorder.none,
                ),
                controller: searchIngredientController,
                onChanged: (text) {
                  setState(() {
                    searchText = text;
                  });
                  socket.add(cmdJsonEncode('SEARCH', text));
                },
                onTap: (){
                  if (socket.closeCode != null){
                    reConnectWs();
                  }
                },
              ),
            ),
            Expanded(
              child: Scrollbar(
                isAlwaysShown: false,
                controller: searchScrollController,
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: searchScrollController,
                  itemExtent: 50.0,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index){
                    return ListTile(
                        leading: Container(
                          height: 40,
                          child: IconButton(
                            icon: Icon(
                                Icons.add,
                                color: Colors.orange,
                                size: 20.0
                            ),
                            onPressed: (){
                              setState(() {
                                if (!_selectedIngredients.contains(_searchResults[index]))
                                  _selectedIngredients.add(_searchResults[index]);
                              });
                            },
                          ),
                        ),
                        title: Text(
                          _searchResults[index],
                        )
                    );
                  },
                ),
              ),
            ),
            SizedBox(height:5),
            Divider(height: 1, indent: 5, endIndent: 5, color: Colors.grey[400],),
            SizedBox(height:5),
            Container(
              width: SizeConfig.screenWidth,
              height: 80,
              child: SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 2.0,
                    children: List<Widget>.generate(_selectedIngredients.length, (int index){
                      return Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: ActionChip(
                          label: Text(
                            _selectedIngredients[index],
                            style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight:FontWeight.w500),
                          ),
                          labelPadding: EdgeInsets.only(left:8.0, right: 8.0, top: 4.0, bottom: 4.0),
                          backgroundColor: Colors.white,
                          shadowColor: Colors.grey[80],
                          elevation: 5.0,
                          padding: EdgeInsets.all(3.0),
                          onPressed: (){
                            setState(() {
                              _selectedIngredients.removeAt(index);
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            SizedBox(height:10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FlatButton(
                  child: Text('돌아가기', style: TextStyle(fontSize: 16, color: Colors.red)),
                  onPressed: (){
                    // UserRepository.updateIngredients(_ingredients, )
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text('추가하기', style: TextStyle(fontSize: 16, color: Colors.blue)),
                  onPressed: () async {
                    final List<Ingredient> updateIngredients = new List<Ingredient>();
                    _selectedIngredients.forEach(
                            (ingredient) => updateIngredients.add(new Ingredient(type: '', title: ingredient))
                    );
                    await UserRepository.updateIngredients(widget.originIngredients, updateIngredients);
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
