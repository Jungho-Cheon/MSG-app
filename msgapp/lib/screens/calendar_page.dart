import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:msgapp/main.dart';
import 'package:msgapp/models/history.dart';
import 'package:msgapp/models/receipt.dart';
import 'package:msgapp/models/recipe.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/size_config.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';


class CalendarPage extends StatefulWidget {

  Map<DateTime, List<History>> events;
  List selectedEvents;

  getHistory(BuildContext context) async {
    final _selectedDay = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day
    );

    events = await UserRepository.fetchHistory();
    selectedEvents = events[_selectedDay] ?? [];
    // _onDaySelected(_selectedDay, _selectedEvents);
    History.historyStream.add(events);
  }

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin{
  DateTime _selectedDay;

  CalendarController _calendarController;
  AnimationController _animationController;

  _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedDay = day;
      widget.selectedEvents = events;
    });
  }

  @override
  void initState() {
    super.initState();

    History.historyStream = StreamController<Map<DateTime, List<History>>>();

    _selectedDay = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day
    );

    _calendarController = CalendarController();
    initializeDateFormatting('ko', null);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    widget.getHistory(context);
    _animationController.forward();
  }



  @override
  void dispose() {
    _calendarController.dispose();
    _animationController.dispose();
    History.historyStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: History.historyStream.stream,
      builder: (context, snapshot){
       if (snapshot.hasData){
         return SingleChildScrollView(
           child: SafeArea(
             child: Container(
               width: SizeConfig.screenWidth,
               child: Column(
                 mainAxisSize: MainAxisSize.max,
                 children: [
                   TableCalendar(
                     locale: 'ko',
                     events: snapshot.data,
                     builders: CalendarBuilders(
                         singleMarkerBuilder: (context, date, event){
                           return Container(
                             height: 8.0,
                             width: 8.0,
                             margin: const EdgeInsets.all(0.5),
                             decoration: BoxDecoration(
                               color: event.historyType == HistoryType.RECEIPT ? Colors.blue : Colors.deepOrange[400],
                               shape: BoxShape.circle,
                             ),
                           );
                         }
                     ),
                     initialCalendarFormat: CalendarFormat.month,
                     availableGestures: AvailableGestures.horizontalSwipe,
                     availableCalendarFormats: const {
                       CalendarFormat.month: '2주',
                       CalendarFormat.week: '한달',
                       CalendarFormat.twoWeeks: '1주',
                     },
                     calendarController: _calendarController,
                     calendarStyle: CalendarStyle(
                       selectedColor: Colors.orange[400],
                       todayColor: Colors.grey[300],
                       markersColor: Colors.brown[700],
                       outsideDaysVisible: false,
                       canEventMarkersOverflow: false,
                     ),
                     headerStyle: HeaderStyle(
                       formatButtonTextStyle: TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
                       formatButtonDecoration: BoxDecoration(
                         color: Colors.deepOrange[400],
                         borderRadius: BorderRadius.circular(16.0),
                       ),

                     ),
                     onDaySelected: (date, events, holidays){
                       _onDaySelected(date, events);
                       _animationController.forward(from: 0.0);
                       },
                   ),
                   SizedBox(height:15),
                   ..._buildEventList(snapshot.data),
                 ],
               ),
             ),
           ),
         );
       }
       else{
         return Container(
           width: SizeConfig.screenWidth,
           height: SizeConfig.screenHeight,
           child: Center(child: CircularProgressIndicator()),
         );
       }
      }
    );
  }

  List<Widget> _buildEventList(Map<DateTime, List<History>> data) {
    if (data != null && data.containsKey(_selectedDay))
      widget.selectedEvents = data[_selectedDay];
    return widget.selectedEvents
        .map((event) => HistoryWidget(history: event)
    ).toList();
  }

  Widget buildHistory(History event) {
    final mainColor = event.historyType == HistoryType.RECEIPT ? Colors.blue : Colors.deepOrange[400];
    final subTitle = event.info.toString();

    return Container(
      margin: EdgeInsets.only(bottom: 15, left:10, right: 10),
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)
        ),
        boxShadow: [
          BoxShadow(
            // color: mainColor.withOpacity(0.2),
            color: Colors.grey[200].withOpacity(0.6),
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 2)
          ),
        ],
      ),
      width: SizeConfig.screenWidth,
      height: 60,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 60,
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Center(
                        child: Text(
                            event.historyType == HistoryType.RECEIPT
                                ? '영수증'
                                : '레시피',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white
                            )
                        ),
                      )
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      subTitle,
                      style: TextStyle(
                        // color: mainColor,
                        fontSize: 14
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.visibility, size: 20, color: mainColor,)
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class HistoryWidget extends StatefulWidget {
  final history;
  Color mainColor;
  String subTitle;

  HistoryWidget({@required this.history}){
    this.mainColor = history.historyType == HistoryType.RECEIPT ? Colors.blue : Colors.deepOrange[400];
    this.subTitle = history.info.toString();
  }

  @override
  _HistoryWidgetState createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      margin: EdgeInsets.only(bottom: 15, left:10, right: 10),
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)
        ),
        boxShadow: [
          BoxShadow(
            // color: mainColor.withOpacity(0.2),
              color: Colors.grey[200].withOpacity(0.6),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 2)
          ),
        ],
      ),
      width: SizeConfig.screenWidth,
      height: widget.history.historyType == HistoryType.RECEIPT
            ? 101 + (widget.history.info.ingredients.length * 20.0)
            : 200
      ,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      height: 30,
                      width: 60,
                      decoration: BoxDecoration(
                          color: widget.mainColor,
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Center(
                        child: Text(
                            widget.history.historyType == HistoryType.RECEIPT
                                ? '영수증'
                                : '레시피',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white
                            )
                        ),
                      )
                  ),
                  Row(
                    children: [
                      Container(
                        width: 220,
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            text: widget.subTitle,
                            style: TextStyle(
                                fontWeight: FontWeight.w300, color: Colors.black,
                                fontSize: 14
                            ),

                          ),
                          strutStyle: StrutStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 14
                          ),
                        ),
                      ),
                      // Text(
                      //   widget.subTitle,
                      //   style: TextStyle(
                      //     // color: mainColor,
                      //       fontSize: 14
                      //   ),
                      // ),
                      SizedBox(width: 20),
                      // Icon(Icons.visibility, size: 20, color: widget.mainColor,)
                    ],
                  )
                ],
              ),
            ),
            Divider(color: Colors.grey[300], height: 1, indent: 5, endIndent: 5,),
            widget.history.historyType == HistoryType.RECEIPT
              ? Container( // 영수증
                width: double.infinity,// 기록
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    widget.history.info.ingredients.length, (index) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text:widget.history.info.ingredients[index].title,
                          style: TextStyle(
                              fontWeight: FontWeight.w300, color: Colors.black,
                              fontSize: 14
                          ),

                        ),
                        strutStyle: StrutStyle(fontSize: getProportionateScreenHeight(14.0)),
                      ),
                      // child: Text(widget.history.info.ingredients[index].title),
                    ),
                  )
                ),
              )
             : Container( // 레시피 기록
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height:100,
                      child: Image.network(
                        (widget.history.info as Recipe).mainImageURL,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width:10),
                    SizedBox(width:10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.history.info as Recipe).category,
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)
                        ),
                        Text(
                            (widget.history.info as Recipe).method,
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)
                        ),
                        Text(
                            (widget.history.info as Recipe).calories.toString() + ' kcal',
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)
                        ),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
