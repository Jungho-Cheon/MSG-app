import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/helper/json_wrapper.dart';
import 'package:msgapp/models/history.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/size_config.dart';
import 'package:msgapp/widgets/input_dialog.dart';
import 'package:msgapp/widgets/splash_content_widget.dart';

import '../color_config.dart';

class RegisterReceiptPage extends StatefulWidget {
  final receiptImageBytes;
  final int year;
  final int month;
  final int day;
  final ingredients;
  final String price;

  RegisterReceiptPage({this.receiptImageBytes, this.year, this.month, this.day, this.ingredients, this.price});

  @override
  _RegisterReceiptPageState createState() => _RegisterReceiptPageState();
}

class _RegisterReceiptPageState extends State<RegisterReceiptPage> with TickerProviderStateMixin{
  int _pageViewIndex = 0;
  DateTime pickDateTime;
  List<String> ingredients;
  String price;
  final _pageViewController = PageController(keepPage: false);
  final _scrollController = ScrollController();
  final _searchScrollController = ScrollController();

  bool _searchFolded = false;
  bool _priceChange = false;
  final _priceTextFieldController = TextEditingController();

  Animation<double> _searchIconAnimation;
  AnimationController _searchIconAnimationController;
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchNode = FocusNode();
  String _searchText = '';
  String _priceText = '';

  // 검색을 위한 소켓 통신
  WebSocket socket;
  bool _isConnected = false;
  List<String> _searchResults = List<String>();
  List<String> _selectedIngredients = List<String>();


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
            setState(() {
              _isConnected = true;
            });
            break;
          case 'RESULTS':
            final ingredients = List<String>.from(data['ingredients']);
            setState(() {
              _searchResults.clear();
              _searchResults.addAll(ingredients);
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
  void dispose() {
    socket.add(cmdJsonEncode('CLOSE', ''));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 검색 웹소켓 연결
    _startReceiptDetection();

    pickDateTime = DateTime(widget.year, widget.month, widget.day);
    widget.ingredients != null
      ? ingredients = widget.ingredients
      : ingredients = List<String>();
    widget.price != null ? price = widget.price : price = '0';
    Future.delayed(Duration(milliseconds: 500), (){
      setState(() {
        _pageViewController.animateToPage(1, duration: Duration(milliseconds: 1300), curve: Curves.elasticOut);
      });
    });

    _searchIconAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300)
    );
    _searchIconAnimation = Tween(begin: 0.0, end: 1.0).animate(_searchIconAnimationController);
  }

  @override
  Widget build(BuildContext context) {
    bool _keyboardVisible = MediaQuery.of(context).viewInsets.vertical > 0;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress)
          return false;
        else
          return true;
      },
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Material(
          color: Global.white,
          child: Container(
            width: SizeConfig.screenWidth,
            height : SizeConfig.screenHeight,
            padding: EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                !_keyboardVisible
                ? Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Global.black,
                          size: 30,
                        ),
                        onPressed: (){
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(height:10),
                    ],
                  ),
                ):Container(),
                Expanded(
                  flex: 16,
                  child: SizedBox(
                    height: SizeConfig.screenHeight * 0.8,
                    width: double.infinity,
                    child: PageView(
                      onPageChanged: (value) {
                        setState(() {
                          _pageViewIndex = value;
                        });
                      },
                      controller: _pageViewController,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.memory(
                              widget.receiptImageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      !_keyboardVisible ?
                                      Column(
                                        children: [
                                          ListTile(
                                            leading: ClipOval(
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.greenAccent[700],
                                                ),
                                              ),
                                            ),
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: <Widget>[

                                                Text(
                                                  pickDateTime.year.toString()
                                                      + '-'
                                                      + pickDateTime.month.toString()
                                                      + '-'
                                                      + pickDateTime.day.toString(),
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize : 20
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.today, color: Colors.black, size: 20),
                                              onPressed: () {
                                                DatePicker.showDatePicker(
                                                    context,
                                                    locale: DateTimePickerLocale.ko,
                                                    initialDateTime: pickDateTime,
                                                    maxDateTime: DateTime.now(),
                                                    dateFormat: 'yyyy년-MM월-dd일',
                                                    pickerTheme: DateTimePickerTheme(
                                                        confirm: Text('확인'),
                                                        cancel: Text('취소')
                                                    ),
                                                    onConfirm: (DateTime dateTime, List<int> selectedIndex){
                                                      setState(() {
                                                        pickDateTime = dateTime;
                                                      });
                                                    }
                                                );
                                              },
                                            ),

                                          ),
                                          Divider(height: 2, color: Colors.black, indent: 10, endIndent: 10,),
                                        ],
                                      ): Container(),
                                      ListTile(
                                          leading: ClipOval(
                                            child: Container(
                                              height: 20,
                                              width: 20,
                                            ),
                                          ),
                                          title: Text(
                                            '식재료',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500
                                            ),
                                          )
                                      ),
                                      Divider(height: 2, color: Colors.black, indent: 10, endIndent: 10,),
                                      Container(
                                        height: !_keyboardVisible
                                            ? SizeConfig.screenHeight * 0.43
                                            : SizeConfig.screenHeight * 0.39
                                        ,
                                        child: _searchFolded
                                        ? Scrollbar(
                                          isAlwaysShown: false,
                                          controller: _searchScrollController,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            controller: _searchScrollController,
                                            itemExtent: 50.0,
                                            itemCount: _searchResults.length,
                                            itemBuilder: (context, index){
                                              return ListTile(
                                                  leading: Container(
                                                    height: 40,
                                                    width: 40,
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
                                        )
                                        : Scrollbar(
                                          isAlwaysShown: false,
                                          controller: _scrollController,
                                          child: ListView.builder(
                                              shrinkWrap: true,
                                              controller: _scrollController,
                                              itemExtent: 50.0,
                                              itemCount: widget.ingredients.length,
                                              itemBuilder: (BuildContext context, int index){
                                                return ListTile(
                                                  leading: ClipOval(
                                                    child: Container(
                                                      height: 20,
                                                      width: 20,
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                      ingredients[index]
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: <Widget>[
                                                      // IconButton(
                                                      //     icon: Icon(Icons.edit, size: 20, color: Colors.black)
                                                      // ),
                                                      IconButton(
                                                        icon: Icon(Icons.remove_circle, size: 25, color: Colors.red[800]),
                                                        onPressed: (){
                                                          setState(() {
                                                            ingredients.removeAt(index);
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                          ),
                                        )
                                      ),
                                      Divider(height: 2, color: Colors.black, indent: 10, endIndent: 10,),
                                      _searchFolded
                                          ? Container(
                                            width: SizeConfig.screenWidth,
                                            height: 60,
                                            child: Center(
                                                child: Wrap(
                                                  spacing: 10.0,
                                                  runSpacing: 2.0,
                                                  children: List<Widget>.generate(_selectedIngredients.length, (int index){
                                                    return ActionChip(
                                                      label: Text(
                                                        _selectedIngredients[index],
                                                        style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight:FontWeight.w500),
                                                      ),
                                                      labelPadding: EdgeInsets.only(left:8.0, right: 8.0, top: 4.0, bottom: 4.0),
                                                      backgroundColor: Colors.white,
                                                      shadowColor: Colors.grey[80],
                                                      elevation: 5.0,
                                                      padding: EdgeInsets.all(6.0),
                                                      onPressed: (){
                                                        setState(() {
                                                          _selectedIngredients.removeAt(index);
                                                        });
                                                      },
                                                    );
                                                  }),
                                                ),
                                              ),
                                          )
                                          : ListTile(
                                            leading: ClipOval(
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ),
                                            title: _priceChange
                                            ? Container(
                                              height: 30,
                                              child: TextField(
                                                decoration: InputDecoration(
                                                    hintText: '금액을 입력해주세요.',
                                                    hintStyle: TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black38,
                                                    ),
                                                    border: InputBorder.none,
                                                    suffixIcon: _priceText.length > 0
                                                        ? IconButton(
                                                      icon: Icon(Icons.close, size: 16, color: Colors.grey,),
                                                      onPressed: (){
                                                        setState(() {
                                                          _priceTextFieldController.text = '';
                                                          price = '0';
                                                        });
                                                      },
                                                    )
                                                        : null
                                                ),
                                                onChanged: (text){
                                                  setState(() {
                                                    _priceText = text;
                                                  });
                                                },
                                                controller: _priceTextFieldController,
                                              ),
                                            )
                                            : Text(
                                              price + ' 원',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize : 20
                                              ),
                                            ),
                                            trailing: Container(
                                              width: 45,
                                              child: _priceChange
                                                  ? IconButton(
                                                icon: Icon(Icons.check_circle, size: 25, color: Colors.blue),
                                                onPressed: (){
                                                  setState(() {
                                                    _priceChange = !_priceChange;
                                                    if (_priceTextFieldController.text != '')
                                                      price = _priceTextFieldController.text;
                                                  });
                                                },
                                              )
                                                  : IconButton(
                                                icon: Icon(Icons.edit, size: 20, color: Colors.black),
                                                onPressed: (){
                                                  setState(() {
                                                    _priceChange = !_priceChange;
                                                  });
                                                },
                                              )
                                            ),
                                          )
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: !_keyboardVisible?61:1,
                                  right: 12,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    width: _searchFolded ? SizeConfig.screenWidth - 62 : 56,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      color: _searchFolded ? Colors.grey[100] : Global.white,

                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                              padding: EdgeInsets.fromLTRB(20.0, 8.0, 0.0, 12.0),
                                              child: _searchFolded
                                                  ? TextField(
                                                decoration: InputDecoration(
                                                    hintText: '식재료명을 입력해주세요.',
                                                    hintStyle: TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w300,
                                                      color: Colors.black38,
                                                    ),
                                                    border: InputBorder.none,

                                                    suffixIcon: _searchText.length > 0
                                                        ? IconButton(
                                                      icon: Icon(Icons.close, size: 16, color: Colors.grey,),
                                                      onPressed: (){
                                                        setState(() {
                                                          _searchTextController.text = '';
                                                          _searchText = '';
                                                          _searchResults.clear();
                                                        });
                                                      },
                                                    )
                                                        : null
                                                ),
                                                controller: _searchTextController,
                                                onChanged: (text) {
                                                  setState(() {
                                                    _searchText = text;
                                                  });
                                                  socket.add(cmdJsonEncode('SEARCH', text));
                                                },
                                                onTap: (){
                                                  if (socket.closeCode != null){
                                                    reConnectWs();
                                                  }
                                                },
                                              )
                                                  : null
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: !_keyboardVisible?61:1,
                                  right: 12,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    width: _searchFolded ? SizeConfig.screenWidth - 62 : 56,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(60),
                                        color: _searchFolded ? Colors.grey[100] : Global.white,

                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                              padding: EdgeInsets.fromLTRB(20.0, 8.0, 0.0, 12.0),
                                              child: _searchFolded
                                                  ? TextField(
                                                    decoration: InputDecoration(
                                                      hintText: '식재료명을 입력해주세요.',
                                                      hintStyle: TextStyle(
                                                        fontSize: 14.0,
                                                        fontWeight: FontWeight.w300,
                                                        color: Colors.black38,
                                                      ),
                                                      border: InputBorder.none,

                                                      suffixIcon: _searchText.length > 0
                                                        ? IconButton(
                                                          icon: Icon(Icons.close, size: 16, color: Colors.grey,),
                                                          onPressed: (){
                                                            setState(() {
                                                              _searchTextController.text = '';
                                                              _searchText = '';
                                                              _searchResults.clear();
                                                            });
                                                          },
                                                        )
                                                        : null
                                                    ),
                                                    controller: _searchTextController,
                                                    onChanged: (text) {
                                                      setState(() {
                                                        _searchText = text;
                                                      });
                                                      socket.add(cmdJsonEncode('SEARCH', text));
                                                    },
                                                    onTap: (){
                                                      if (socket.closeCode != null){
                                                        reConnectWs();
                                                      }
                                                    },
                                                  )
                                                  : null
                                          ),
                                        ),
                                        InkWell(
                                          splashColor: Global.white,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(0.0,10.0,16.0,10.0),
                                            child: AnimatedIcon(
                                              icon: AnimatedIcons.search_ellipsis,
                                              progress: _searchIconAnimation,
                                            )
                                            // child: Icon(Icons.search, size: 20.0),
                                          ),
                                          onTap: (){
                                            if (socket.closeCode != null){
                                              reConnectWs();
                                            }
                                            setState(() {
                                              _searchFolded = !_searchFolded;
                                              if (_searchFolded){
                                                _searchIconAnimationController.forward();
                                              }
                                              else{
                                                socket.add(cmdJsonEncode('CLOSE', ''));
                                                _searchIconAnimationController.reverse();
                                              }
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: _searchFolded
                        ? FlatButton(
                            child: Container(
                              child: Text(
                                '식재료 추가',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize : 20,
                                  color: Colors.orange
                                ),
                              ),
                            ),
                            onPressed: (){
                              setState(() {
                                for (String s in _selectedIngredients){
                                  if (!ingredients.contains(s)){
                                    ingredients.add(s);
                                  }
                                }
                                _searchFolded = false;
                                _searchTextController.text = '';
                              });
                            },
                          )
                        : FlatButton(
                          child: Container(
                            child: Text(
                              '영수증 등록',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize : 20
                              ),
                            ),
                          ),
                          onPressed: () async {
                            await UserRepository.putReceiptInfo(pickDateTime, ingredients, price);
                            final updatedHistory = await UserRepository.fetchHistory();
                            History.historyStream.add(updatedHistory);
                            Navigator.pop(context);
                          },
                        ),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: List.generate(2, (index) => buildDot(index: index)),
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AnimatedContainer buildDot({int index}){
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      margin: EdgeInsets.only(right:5),
      height: 6,
      width: _pageViewIndex == index ? 25 : 8,
      decoration: BoxDecoration(
          color: _pageViewIndex == index ? Colors.blueAccent : Colors.grey[400],
          borderRadius: BorderRadius.circular(3)
      ),
    );
  }

}
