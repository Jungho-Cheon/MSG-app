import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msgapp/screens/calendar_page.dart';
import 'package:msgapp/screens/home_page.dart';
import 'package:msgapp/screens/ingredient_management_page.dart';
import 'package:msgapp/size_config.dart';


import '../color_config.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var _currentIndex = 0;

  var userInfo;
  String nickname;
  String userProfileImageURL;
  List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      IngredientManagementPage(),
      CalendarPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return WillPopScope(
      onWillPop: (){
        return Future(()=>false);
      },
      child: Scaffold(
          backgroundColor: Global.white,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.0)
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index){
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Global.white,
                iconSize: 30.0,
                selectedIconTheme: IconThemeData(
                    color: Global.mainColor
                ),
                unselectedIconTheme: IconThemeData(
                    color: Global.grey
                ),
                items: [
                  BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(top:8.0),
                        child: Icon(Icons.home),
                      ),
                      title: Text('')
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(top:8.0),
                      child: Icon(Icons.category),
                    ),
                    title: Text(''),
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(top:8.0),
                      child: Icon(Icons.calendar_today),
                    ),
                    title: Text(''),
                  ),
                ],
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
      ),
    );
  }
}
