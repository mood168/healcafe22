import 'dart:ui';

const primaryColor = Color.fromARGB(255, 255, 154, 38);
const secondaryColor = Color(0xFF2A2D3E);
const bgColor = Color.fromARGB(221, 214, 204, 200);
//#e0e0e0
const healGreyBg = Color(0xFFECEAE4);
const healGreyPicBg = Color(0xFFFFFFFF);
const healUnderBg = Color(0xFFC6C4BE);
const healDarkGrey = Color(0xFF19302A);
const healLightGrey = Color.fromARGB(255, 140, 140, 140);
const healRed = Color(0xFF832522);

const colorDark = Color.fromARGB(255, 4, 3, 2);
//#040302 opacity 0.05
const colorDarkOpacity = Color.fromARGB(13, 4, 3, 2);
//Colors.transparent0.07
const colorTransparent = Color.fromARGB(18, 0, 0, 0);
//#2e2719
const colorDarkBrown = Color.fromARGB(255, 46, 39, 25);
//#594b2f
const colorBrown = Color.fromARGB(255, 89, 75, 47);
//#836f46
const colorLightBrown = Color.fromARGB(255, 131, 111, 70);
//#404040
const colorGrey = Color.fromARGB(255, 64, 64, 64);
//#2a2b2b
const colorDarkGrey = Color.fromARGB(255, 42, 43, 43);
const colorDarkGrey2 = Color.fromARGB(255, 25, 25, 25);
//Colors.white80
const colorWhite80 = Color.fromARGB(200, 255, 255, 255);
//Colors.white50
const colorWhite50 = Color.fromARGB(127, 255, 255, 255);
//Colors.white30
const colorWhite30 = Color.fromARGB(76, 255, 255, 255);
//price color red
const colorPriceRed = Color.fromARGB(255, 188, 35, 35);

const defaultPadding = 16.0;

class AllConstants {
  static final AllConstants _singleton = AllConstants._internal();

  factory AllConstants() {
    return _singleton;
  }

  AllConstants._internal();

  /// 系統面板參數預設值
  var systemPassWord = '0000';
  static var robotUse = false;
  var routerIP = '192.168.66.77';
  var softVersion = 'V3_HealCafe22_202502003';
  static var showPrice = true;
  static var showEnglish = true;
  static var isDrinkMade = false;
  var documentsPath = '/storage/emulated/0/Documents/healcafe22';
  var pipeUseId = '1';

  // 各項訊息預設值
  var drinkMakingStatus = 'Please place a cup before making';
  var checkPayStatus = 'Please choose Add to Cart or Checkout Payment';
  var checkCartStatus = 'unpaid items in the cart, continue to add to the cart';
  var openDoorCleanStatus = 'Pipe connect with materials, run at least 10sec';
  var closeDoorCleanStatus = 'remove material from pipes, run water bucket 2L';
  var singlePipeCleanStatus = '';

  // 暫定設定值
  var salesId = 'admin@gmail.com';
  static const sourceId = '1';
}
