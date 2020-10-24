import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:exif/exif.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/helper/dialog_helper.dart';
import 'package:msgapp/helper/json_wrapper.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/screens/register_receipt_page.dart';
import 'package:msgapp/size_config.dart';
import 'package:msgapp/widgets/login_dialog.dart';
import 'package:msgapp/widgets/receipt_info_widget.dart';

enum CameraProcess{
  Ready, Processing, Complete
}

class Point{
  double x;
  double y;
  Point(this.x, this.y);
}

class Line{
  Point from;
  Point to;
  Line(this.from, this.to);
}

class DisplayPicturePage extends StatefulWidget {
  final File imageFile;
  final double imageWidth;
  final double imageHeight;

  DisplayPicturePage({Key key, this.imageFile, this.imageWidth, this.imageHeight});

  @override
  _DisplayPicturePageState createState() => _DisplayPicturePageState();
}

class _DisplayPicturePageState extends State<DisplayPicturePage> with TickerProviderStateMixin{
  final sendDataSize = pow(2, 20);
  WebSocket socket;
  int POS;
  String base64Image;
  CameraProcess _state;

  double widthRate;
  double heightRate;

  // 영수증 모서리 좌표
  List<Point> contourPoints;

  // 레시피 정보
  // 좌표값, 애니메이션
  Line _dateLine;
  Line _priceLine;
  List<Line> _receiptInfoLines;
  Animation<double> _receiptInfoAnimation;
  AnimationController _receiptInfoAnimationController;
  double _receiptInfoProgress = 0.0;
  // 날짜, 식재료, 가격 정보
  int _year;
  int _month;
  int _day;
  String _priceName;
  String _price;
  List<String> _ingredients = List<String>();


  String _providerID;

  bool _receiptInfoReady = false;
  bool _receiptLinePainted = false;

  // 영수증 업로드 프로그레스 바 애니메이션
  Animation<double> _progressLineAnimation;
  AnimationController _progressLineAnimationController;
  double _progressBarValue = 0.0;

  // 영수증 업로드 프로그레스 바 컬러 애니메이션
  Animation<Color> _progressBarColor;
  AnimationController _progressBarAnimationController;

  // 위젯 캡쳐
  GlobalKey _globalKey = new GlobalKey();

  @override
  void initState() {
    super.initState();
    POS = 0;
    base64Image = '';
    _state = CameraProcess.Ready;
    contourPoints = List<Point>();
    _receiptInfoLines = List<Line>();
    _ingredients = List<String>();

    widthRate = SizeConfig.screenWidth / widget.imageWidth;
    heightRate = SizeConfig.screenHeight / widget.imageHeight;
    print('${SizeConfig.screenWidth} ${widget.imageWidth}');
    print('${SizeConfig.screenHeight} ${widget.imageHeight}');

    // 식재료 페인트 애니메이션 초기화
    _receiptInfoAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700)
    );

    _receiptInfoAnimation = Tween(begin:0.0, end: 1.0).animate(_receiptInfoAnimationController)
    ..addListener(() {
      setState(() {
        _receiptInfoProgress = _receiptInfoAnimation.value;
        if (_receiptInfoProgress == 1.0){
          _receiptLinePainted = true;
        }
      });
    });


    // 영수증 업로드 프로그레스 바 애니메이션 초기화
    _progressLineAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _progressLineAnimation = Tween(begin: 0.0, end: 1.0).animate(_progressLineAnimationController)
      ..addListener(() {
        setState(() {
          _progressBarValue = _progressLineAnimation.value;
        });
      });

    // 영수증 업로드 프로그레스 바 컬러 애니메이션 초기화
    _progressBarAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _progressBarColor = ColorTween(begin: Global.cheery, end: Colors.green[600])
        .animate(_progressBarAnimationController);

    _startAnalysis();
  }


  void _handleWebSocket(socketData) async {
    if (socketData.runtimeType == String){
      String cmd;
      Map<String, dynamic> data;
      try{
        Map<String, dynamic> decodeData = jsonDecode(socketData);
        print(decodeData);
        cmd = decodeData['CMD'];
        data = decodeData['DATA'];
      }
      catch(e){
        print('리시브 에러');
        print(e.toString());
      }
      switch (cmd) {
        case 'GET_INFO':
          final String providerId = _providerID;
          final String fileName = _providerID +
              '-' + DateTime.now().toString();
          final String fileSize = base64Image.length.toString();
          final Map<String, String> data = Map<String, String>();
          
          data['PROVIDER_ID'] = providerId;
          data['FILE_NAME'] = fileName;
          data['FILE_SIZE'] = fileSize;
          
          socket.add(cmdJsonEncode('GET_INFO', data));
          _progressBarAnimationController.forward();
          _progressLineAnimationController.forward();
          break;
        case 'IMAGE_DATA':
          if (base64Image == '') {
            print('변환된 이미지 없음');
            break;
          }

          try{
            if (POS + sendDataSize > base64Image.length){
              socket.add(cmdJsonEncode('IMAGE_DATA', base64Image.substring(POS, base64Image.length)));
            }
            else{
              socket.add(cmdJsonEncode('IMAGE_DATA', base64Image.substring(POS, POS + sendDataSize)));
            }

            // socket.add('DATA');
            // POS + sendDataSize > base64Image.length
            //     ? socket.add(base64Image.substring(POS, base64Image.length))
            //     : socket.add();
            POS += sendDataSize;
            setState(() {
              _progressBarValue += sendDataSize / base64Image.length;
              print('_progressBarValue : $_progressBarValue');
            });
          }catch(e){
            print('사진 업로드 에러 $e');
          }
          break;
        case 'RECEIPT_INFO':
          try{
            final date = data['date'];
            final ingredients = data['ingredients'];

            // 날짜 파싱 - 좌표 데이터가 없는 경우 현재 날짜를 반환한다.
            _year = int.parse(date['year']);
            _month = int.parse(date['month']);
            _day = int.parse(date['day']);

            // 날짜 좌표 데이터가 있는 경우 페인트
            if(date.containsKey('coordinate')){
              _dateLine = Line(
              Point(date['coordinate'][0][0] * widthRate, date['coordinate'][0][1] * heightRate),
              Point(date['coordinate'][1][0] * widthRate, date['coordinate'][1][1] * heightRate)
              );
            }

            // 각 식재료 파싱, 페인트
            for (int i = 0; i < ingredients.length; i++){
              final ingredientLine = Line(
                  Point(ingredients[i]['coordinate'][0][0] * widthRate,
                      ingredients[i]['coordinate'][0][1] * heightRate),
                  Point(ingredients[i]['coordinate'][1][0] * widthRate,
                      ingredients[i]['coordinate'][1][1] * heightRate)
              );
              _receiptInfoLines.add(ingredientLine);
              _ingredients.add(ingredients[i]['ingredient']);
            }

            // 가격 정보가 있는 경우 파싱, 페인트
            if (data.containsKey('price')){
              final price = data['price'];
              _price = price['price'];
              _priceName = price['price_kind'];
              _priceLine = Line(
                Point(price['coordinate'][0][0] * widthRate,
                    price['coordinate'][0][1] * heightRate),
                Point(price['coordinate'][1][0] * widthRate,
                    price['coordinate'][1][1] * heightRate)
              );
            }
            _paintReceiptInfo();
            socket.add(cmdJsonEncode('CLOSE', ''));
          }
          catch(e){
            print('RECEIPT INFO Exception');
            print(e.toString());
          }
          setState(() {
            _progressBarValue = 1.0;
            _progressBarColor = AlwaysStoppedAnimation<Color>(Colors.green);
            _state = CameraProcess.Complete;
          });
          await _returnProgressBar();

          // 영수증 등록 페이지 이동
          await Future.delayed(Duration(seconds: 1));
          RenderRepaintBoundary boundary = _globalKey.currentContext.findRenderObject();
          ui.Image image = await boundary.toImage(pixelRatio: 1.0);
          ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
          var pngBytes = byteData.buffer.asUint8List();

          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context){
                    return RegisterReceiptPage(
                      ingredients: _ingredients,
                      year: _year,
                      day: _day,
                      month: _month,
                      price: _price,
                      receiptImageBytes: pngBytes,
                    );
                  }
              )
          );
          Navigator.pop(context);
          break;
        case 'NO_INGREDIENTS':
          await showDialog(
              context: context,
              builder: (context) => LoginDialog(
                title: '영수증이 인식되지 않았습니다.',
                desc: '상품명이 가려지지 않게해주세요!',
                imgPath: 'assets/images/receipt-icon.svg',
              )
          );
          try{
            socket.add(cmdJsonEncode('CLOSE', ''));
            print('close dialog!');
            Navigator.pop(context);
          }catch(e){
            print('NO_INGREDIENTS 에러');
            print(e);
          }
          break;
        case 'ERROR':
          print('TODO Error Handler');
          await showDialog(
              context: context,
              builder: (context) => LoginDialog(
                title: '영수증이 인식되지 않았습니다.',
                desc: '배경이 없는 곳에서 다시 찍어주세요!',
                imgPath: 'assets/images/receipt-icon.svg',
              )
          );
          setState(() {
            _state = CameraProcess.Ready;
          });
          try{
            Navigator.pop(context);
          }catch(e){
            print('ERROR 에러');
            print(e);
          }
          break;
      }
    }
  }

  // 소켓 통신 시작
  Future<void> _startReceiptDetection() async {
    print('** 소켓 연결 시작 **');
    while (true){
      print('conneting websock to ${Config.WebSocketAddress}');
      try{
        socket = await WebSocket.connect(Config.WebSocketAddress);
      }
      catch (e){
        print('웹소켓 에러');
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
        setState(() {
         _state = CameraProcess.Ready;
        });
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
    try{
      socket.close();
    }catch(e){
      print('dispose 에러');
      print(e);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Material(
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            RepaintBoundary(
              key: _globalKey,
              child: Stack(
                children: <Widget>[
                  Image.file(
                    widget.imageFile,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    fit: BoxFit.cover
                  ),
                  _receiptInfoReady ?
                  Positioned(
                    child: CustomPaint(
                      painter: ReceiptInfoPainter(
                          progress: _receiptInfoProgress,
                          ingredientLines: _receiptInfoLines,
                          dateLine: _dateLine,
                          priceLine: _priceLine
                      ),
                    ),
                  )
                      :
                  Container(),
                  _receiptLinePainted
                      ? ReceiptInfoWidget(
                    ingredients: _ingredients,
                    ingredientsLines: _receiptInfoLines,
                    dateLine: _dateLine,
                    priceLine: _priceLine,
                  )
                      : Container()
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                height: 6,
                width: SizeConfig.screenWidth,
                child: LinearProgressIndicator(
                  value: _progressBarValue, // percent filled
                  valueColor: _progressBarColor,
                  backgroundColor: Colors.black.withOpacity(0.0),
                ),
              ),
            ),
            _state == CameraProcess.Complete ?
            Positioned(
              bottom: 10,
              child: Container(
                  width: SizeConfig.screenWidth,
                  height: 150,
                  child: Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: FlareActor(
                        'assets/images/Success Check.flr',
                        animation:"Untitled",
                      ),
                    )
                  )
              ),
            ) : Container(),
            Positioned(
              left: 10,
              top: 30,
              child: Container(
                width: 30,
                height: 30,
                child: IconButton(
                  icon:Icon(
                    Icons.arrow_back_ios,
                    color: Global.white,
                    size: 20,
                  ),
                  onPressed: (){
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis() async {
    try{
      POS = 0;
      base64Image = await _encodeImage(widget.imageFile.path);
      final _userInfo = await UserRepository.getUserInfo('DisplayPicture - for naming file');
      _providerID = _userInfo['PROVIDER_ID'].toString();
      setState(() {
        _state = CameraProcess.Processing;
      });
      await _startReceiptDetection();
    } catch(e){
      print(e);
    }
  }

  Future<String> _encodeImage(String imagePath) async {
    final Uint8List bytes = Uint8List.fromList( await FlutterImageCompress.compressWithFile(
        imagePath,
        autoCorrectionAngle: false,
        quality: 40
    ));
    final encodedImage = base64Encode(bytes);
    print('이미지 변환 완료');
    return encodedImage;
  }

  void _paintReceiptInfo() {
    setState(() {
      _state = CameraProcess.Complete;
      _receiptInfoReady = true;
      _receiptInfoAnimationController.forward();
    });
    print('Start ReceiptInfo painting');
  }

  Future<void> _returnProgressBar() async {
    for(double i= 1.0; i >= 0; i -= 0.005){
      await Future.delayed(Duration(milliseconds: 1), () {});
      setState(() {
        _progressBarValue = i;
      });
    }
    setState(() {
      _progressBarValue = 0;
    });
  }
}

// 영수증 주요 정보 위치 프린트
class ReceiptInfoPainter extends CustomPainter {
  Line dateLine;
  Line priceLine;
  List<Line> ingredientLines;
  double progress;

  ReceiptInfoPainter({this.dateLine, this.progress, this.ingredientLines, this.priceLine});


  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    try{

      // 페인트 애니메이션
      progress = Curves.ease.transform(progress);

      // 날짜 페인트 설정
      Paint datePaint = Paint()
        ..color = Colors.greenAccent[700].withOpacity(0.4)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12.0;

      // 식재료 페인트 설정
      Paint ingredientPaint = Paint()
        ..color = Colors.orange.withOpacity(0.4)
        ..blendMode = BlendMode.srcOver
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12.0;

      // 가격 페인트 설정
      Paint pricePaint = Paint()
        ..color = Colors.blue.withOpacity(0.4)
        ..blendMode = BlendMode.srcOver
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12.0;

      // 날짜 좌표가 존재하는 경우 페인트
      if (dateLine != null){
        Offset dfrom = Offset(dateLine.from.x, dateLine.from.y);
        Offset dto = Offset(
            (dateLine.from.x + (dateLine.to.x - dateLine.from.x) * progress),
            (dateLine.from.y + (dateLine.to.y - dateLine.from.y) * progress)
        );
        canvas.drawLine(dfrom, dto, datePaint);
      }

      // 가격 좌표가 존재하는 경우 페인트
      if (priceLine != null){
        Offset pfrom = Offset(priceLine.from.x, priceLine.from.y);
        Offset pto = Offset(
            (priceLine.from.x + (priceLine.to.x - priceLine.from.x) * progress),
            (priceLine.from.y + (priceLine.to.y - priceLine.from.y) * progress)
        );
        canvas.drawLine(pfrom, pto, pricePaint);
      }

      // 식재료 페인트
      List<Offset> froms = List<Offset>();
      List<Offset> tos = List<Offset>();
      for(int i = 0; i < ingredientLines.length; i++){
        froms.add(Offset(ingredientLines[i].from.x, ingredientLines[i].from.y ));
        tos.add(Offset(
          (ingredientLines[i].from.x + (ingredientLines[i].to.x - ingredientLines[i].from.x) * progress),
          (ingredientLines[i].from.y + (ingredientLines[i].to.y - ingredientLines[i].from.y) * progress),
        ));
      }
      for (int i = 0; i < ingredientLines.length; i++) {
        canvas.drawLine(froms[i], tos[i], ingredientPaint);
      }
    }catch(e){
      print('ReceiptInfoPainter Exception');
      print(e.toString());
    }
  }

  @override
  bool shouldRepaint(ReceiptInfoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}


