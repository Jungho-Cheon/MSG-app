import 'dart:async';

enum HistoryType{
  RECEIPT, RECIPE
}

class History{
  static StreamController<Map<DateTime, List<History>>> historyStream;
  final HistoryType historyType;
  final info;

  History({this.historyType, this.info});

}