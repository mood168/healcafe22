import 'dart:io';
import 'package:flutter/material.dart';
import 'constant.dart';
import 'cup_size_page.dart';

class HotColdPage extends StatefulWidget {
  const HotColdPage({super.key, required this.productName, required this.docId, required this.formulaString, required this.assetImg, required this.price, this.pipeFieldName});
  final String productName;
  final String docId;
  final String formulaString;
  final String assetImg;
  final int price;
  final String? pipeFieldName;

  @override
  State<HotColdPage> createState() => _HotColdPageState();
}

class _HotColdPageState extends State<HotColdPage> {
  String documentsPath = AllConstants().documentsPath;
  String productName = '';
  String formulaString = '';
  String docId = '';
  String assetImg = '';
  String pipeFieldName = '';
  int price = 0;
  String drinkType = '';

  @override
  void initState() {
    super.initState();
    // Future.microtask(() async {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   if (mounted) {
    //     setState(() {

    //     });
    //   }
    // });
    if (mounted) {
      setState(() {
        productName = widget.productName;
        formulaString = widget.formulaString;
        docId = widget.docId;
        assetImg = widget.assetImg;
        price = widget.price;
        pipeFieldName = widget.pipeFieldName ?? '';
      });
    }
  }

  String findHotOrIced(String formula, String pipeFieldName) {
    // 將字符串分割成單獨的部分
    List<String> parts = formula.split(',');

    // 使用正則表達式匹配包含 'pipeFieldName=' 的部分
    RegExp regExp = RegExp('(.+)@$pipeFieldName=');

    // 儲存結果
    List<String> result = [];

    for (String part in parts) {
      Match? match = regExp.firstMatch(part);
      if (match != null) {
        // 如果匹配成功，添加 '@' 之前的部分到結果列表
        result.add(match.group(1)!);
      }
    }

    // 檢查結果中是否包含 HOT 或 ICED
    if (result.any((item) => item.contains('HOT'))) {
      return 'HOT';
    } else if (result.any((item) => item.contains('ICED'))) {
      return 'ICED';
    }

    // 如果既不包含 HOT 也不包含 ICED，返回空字符串或者你想要的默認值
    return '';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('formulaString: $formulaString');
    return Scaffold(
      body: Stack(
        children: [
          Image.file(
            File('$documentsPath/images/${productName}_hotcold.png'),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.fill,
          ),
          Positioned(
            top: 10,
            left: 20,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.file(
                File('$documentsPath/images/BackArrow.png'),
                width: 150,
                height: 100,
              ),
            ),
          ),
          Positioned(
            top: 416,
            left: 159,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CupSizePage(
                      productName: productName,
                      docId: docId,
                      formulaString: formulaString.split(',').length >= 2 ? '${formulaString.split(',')[0]},${formulaString.split(',')[1]}' : '',
                      assetImg: assetImg,
                      price: price,
                      drinkType: 'HOT',
                    ),
                  ),
                );
              },
              child: const SizedBox(
                width: 414,
                height: 280,
              ),
            ),
          ),
          Positioned(
            top: 416,
            left: 699,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CupSizePage(
                      productName: productName,
                      docId: docId,
                      formulaString: formulaString.split(',').length >= 4 ? '${formulaString.split(',')[2]},${formulaString.split(',')[3]}' : '',
                      assetImg: assetImg,
                      price: price,
                      drinkType: 'ICED',
                    ),
                  ),
                );
              },
              child: const SizedBox(
                width: 414,
                height: 280,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
