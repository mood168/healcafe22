import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 讀取系統參數設定值
Future<String?> getApiPayUrl() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('apiPayUrl');
}

Future<int?> getUserLevel() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userLevel');
}

Future<String?> getRouterIP() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('routerIP');
}

Future<String?> getGroupId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('groupId');
}

Future<String?> getPipeUseId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('pipeUseId');
}

Future<String?> getRouterId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('routerId');
}

Future<String?> getUserEmail() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userEmail');
}

Future<String?> getSystemPanelPwd() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('systemPanelPwd');
}

Future<bool?> getShowPrice() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('showPrice');
}

Future<bool?> getShowEnglish() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('showEnglish');
}

Future<bool?> getIsOnline() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isOnline');
}

// Future<String?> getg1Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g1ResetDateTime');
// }

// Future<String?> getg2Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g2ResetDateTime');
// }

// Future<String?> getg3Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g3ResetDateTime');
// }

// Future<String?> getg4Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g4ResetDateTime');
// }

// Future<String?> getg5Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g5ResetDateTime');
// }

// Future<String?> getg6Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g6ResetDateTime');
// }

// Future<String?> getg7Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g7ResetDateTime');
// }

// Future<String?> getg8Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g8ResetDateTime');
// }

// Future<String?> getg9Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g9ResetDateTime');
// }

// Future<String?> getg10Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g10ResetDateTime');
// }

// Future<String?> getg11Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g11ResetDateTime');
// }

// Future<String?> getg12Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g12ResetDateTime');
// }

// Future<String?> getg13Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g13ResetDateTime');
// }

// Future<String?> getg14Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g14ResetDateTime');
// }

// Future<String?> getg16Gram() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('g16ResetDateTime');
// }

// Future<String?> getAesKey() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('aeskey');
// }

// Future<String?> getIv() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('iv');
// }

// Future<String?> getMChid() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('mChid');
// }

// Future<String?> getTradeKey() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('tradeKey');
// }

Future<Map<String, String?>> getGPipeResetDateTimes() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Map<String, String?> gPipeResetDateTimes = {};
  String? pipeUseId = prefs.getString('pipeUseId') ?? '1';
  for (int i = 1; i <= 16; i++) {
    String key = 'M${pipeUseId}g${i}ResetDateTime';
    String? value = prefs.getString(key);
    gPipeResetDateTimes[key] = value;
  }

  return gPipeResetDateTimes;
}

// Future<int?> getSettingCount() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getInt('settingCount');
// }

// Future<int?> getSelectedIndex() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getInt('selectedIndex');
// }

Future<List> getCartItems() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // 使用getStringList方法獲取保存的購物車內容
  String? cartItems = prefs.getString('cart');
  if (cartItems == null) {
    return []; // 返回空列表
  }
  List items = jsonDecode(cartItems);
  return items;
}
