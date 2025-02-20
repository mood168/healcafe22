import 'dart:io';
import 'package:flutter/material.dart';
import 'constant.dart';
import 'pouring.dart';

class CupSizePage extends StatefulWidget {
  const CupSizePage({
    super.key,
    required this.productName,
    required this.docId,
    required this.formulaString,
    required this.assetImg,
    required this.price,
    required this.drinkType,
  });
  final String productName;
  final String docId;
  final String formulaString;
  final String assetImg;
  final int price;
  final String drinkType;
  @override
  State<CupSizePage> createState() => _CupSizePageState();
}

class _CupSizePageState extends State<CupSizePage> {
  String documentsPath = AllConstants().documentsPath;
  String productName = '';
  String formulaString = '';
  String docId = '';
  String assetImg = '';
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
        docId = widget.docId;
        assetImg = widget.assetImg;
        price = widget.price;
        drinkType = widget.drinkType;
        formulaString = widget.formulaString;
      });
    }
    debugPrint('formulaString: $formulaString');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.file(
            File('$documentsPath/images/${productName}_twosize.png'),
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
            top: 428,
            left: 198,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MakeDrinkPage(
                      productName: productName,
                      formulaString: formulaString.split(',').isNotEmpty ? formulaString.split(',')[0] : '',
                    ),
                  ),
                );
              },
              child: const SizedBox(
                width: 410,
                height: 280,
              ),
            ),
          ),
          Positioned(
            top: 428,
            left: 730,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MakeDrinkPage(
                      productName: productName,
                      formulaString: formulaString.split(',').isNotEmpty ? formulaString.split(',')[1] : '',
                    ),
                  ),
                );
              },
              child: const SizedBox(
                width: 410,
                height: 280,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
