import 'dart:convert';
import 'dart:io';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:async/async.dart';
import 'package:camera/camera.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:msgapp/color_config.dart';
import 'package:msgapp/config.dart';
import 'package:msgapp/repository/UserRepository.dart';
import 'package:msgapp/repository/aws-policy.dart';
import 'package:msgapp/screens/display_picture_page.dart';
import 'package:msgapp/size_config.dart';
import 'package:msgapp/widgets/page_route_animation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;


class RealTimeReceiptDetectorPage extends StatefulWidget {
  @override
  _RealTimeReceiptDetectorPageState createState() => _RealTimeReceiptDetectorPageState();
}

class _RealTimeReceiptDetectorPageState extends State<RealTimeReceiptDetectorPage> {
  CameraController _camera;
  final AsyncMemoizer _cameraMemoizer = AsyncMemoizer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _getCamera();
  }

  @override
  void dispose() {
    _camera.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }


  Future<void> _getCamera() async {
    return this._cameraMemoizer.runOnce(() async{
      final firstCamera = await availableCameras().then(
            (List<CameraDescription> cameras) => cameras.firstWhere(
              (CameraDescription camera) => camera.lensDirection == CameraLensDirection.back,
        ),
      );
      _camera = CameraController(
          firstCamera,
          defaultTargetPlatform == TargetPlatform.iOS
              ? ResolutionPreset.veryHigh
              : ResolutionPreset.high
      );
      await _camera.initialize();
      return true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _getCamera(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return CustomCamera(context);
          }
          else{
            print('카메라 찾는중..');
            return Container(
              color: Colors.black,
              child: Center(
                  child: CircularProgressIndicator()
              )
            );
          }
        },
      ),
    );
  }

  Widget CustomCamera(BuildContext context){
    return Stack(
      children: <Widget>[
        FutureBuilder(
          future: _getCamera(),
          builder: (context, snapshot) {
            if(snapshot.hasData){
              return CameraPreview(_camera);
            }
            else{
              print('카메라 찾는중..');
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: SizeConfig.screenWidth,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8)
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
              width: SizeConfig.screenWidth,
              height: 70,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8)
              ),
              padding: EdgeInsets.only(top:45),
              child: Column(
                children: <Widget>[
                  Text(
                      '영수증이 보이는 사진을 촬영해주세요.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Global.white,
                          fontWeight: FontWeight.w300
                      )
                  ),
                ],
              )
          ),
        ),
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
        ), // 뒤로가기 버튼
        Positioned(
          bottom: 10,
          child: Container(
            width: SizeConfig.screenWidth,
            height: 100,
            child: Center(
                child: ClipOval(
                    child : Material(
                      color: Colors.orange,
                      child: InkWell(
                        splashColor: Global.cheery,
                        child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.camera_alt, color: Global.white)
                        ),
                        onTap: () async {
                          try {
                            final imgpath = join(
                              (await getTemporaryDirectory()).path,
                              '${DateTime.now()}.png',
                            );
                            await _camera.takePicture(imgpath);
                            var imageFile;
                            defaultTargetPlatform == TargetPlatform.iOS
                            ? imageFile = await fixExifRotation(imgpath)
                            : imageFile = await FlutterExifRotation.rotateImage(path: imgpath);
                            var decodeImage = await decodeImageFromList(imageFile.readAsBytesSync());
                            var imageHeight = decodeImage.height.toDouble();
                            var imageWidth = decodeImage.width.toDouble();

                            await Navigator.push(
                              context,
                              CustomPageRoute(
                                  widget:DisplayPicturePage(
                                    imageFile: imageFile,
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight
                                  )
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            print('카메라 에러');
                            print(e);
                          }
                        },
                      ),
                    )
                )
            ),
          ),// 촬영 버튼
        ),
      ],
    );
  }

  Future<File> fixExifRotation(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    final height = originalImage.height;
    final width = originalImage.width;
    if (height >= width) {
      print('original File!');
      return originalFile;
    }
    final exifData = await readExifFromBytes(imageBytes);
    img.Image fixedImage;
    if (height < width) {
      if (exifData['Image Orientation'].printable.contains('Horizontal')) {
        print('rotate 90!');
        fixedImage = img.copyRotate(originalImage, 90);
      } else if (exifData['Image Orientation'].printable.contains('180')) {
        print('rotate -90!');
        fixedImage = img.copyRotate(originalImage, -90);
      } else if (exifData['Image Orientation'].printable.contains('CCW')) {
        print('rotate 180!');
        fixedImage = img.copyRotate(originalImage, 180);
      } else {
        print('rotate 0!');
        fixedImage = img.copyRotate(originalImage, 0);
      }
    }
    final fixedFile = await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }
}

