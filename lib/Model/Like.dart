import 'package:flutter/foundation.dart';

class Like {
  String statusId = '';
  Like({@required this.statusId});

  Map<String, dynamic> toMap() {
    return {
      'statusID': statusId
    };
  }
}