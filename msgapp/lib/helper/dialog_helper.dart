import 'package:flutter/material.dart';
import 'package:msgapp/widgets/login_dialog.dart';

class DialogHelper{
  static exit(context, String title, String desc, String imgPath) => showDialog(
    context: context,
    builder: (context) => LoginDialog(
      title: title,
      desc: desc,
      imgPath: imgPath,
    )
  );
}
