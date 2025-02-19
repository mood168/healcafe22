import 'package:flutter/material.dart';
import 'package:healcafe/pages/member_manage.dart';
import 'package:healcafe/pages/products_manage.dart';
import 'constant.dart';
import 'main_page.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: healDarkGrey,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPage()));
            },
            child: Image.asset(
              'lib/assets/images/Back.jpg',
              width: 45,
              height: 45,
            ),
          ),
        ),
        toolbarHeight: 100,
        title: const Text('Settings', style: TextStyle(color: colorWhite80, fontSize: 26, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: colorTransparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => MemberManage()));
                      },
                      child: Container(
                        // 四邊都加上圓角框 框的顏色為healDarkGrey
                        decoration: BoxDecoration(
                          color: healDarkGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: 150,
                        height: 150,
                        child: const Center(
                          child: Text(
                            'Dashboard',
                            style: TextStyle(color: colorWhite80, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsManage()));
                      },
                      child: Container(
                        // 四邊都加上圓角框 框的顏色為healDarkGrey
                        decoration: BoxDecoration(
                          color: healDarkGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: 150,
                        height: 150,
                        child: const Center(
                          child: Text(
                            'Products\nManage',
                            style: TextStyle(color: colorWhite80, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MemberManage()));
                      },
                      child: Container(
                        // 四邊都加上圓角框 框的顏色為healDarkGrey
                        decoration: BoxDecoration(
                          color: healDarkGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: 150,
                        height: 150,
                        child: const Center(
                          child: Text(
                            'Members\nManage',
                            style: TextStyle(color: colorWhite80, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Container()));
                      },
                      child: Container(
                        // 四邊都加上圓角框 框的顏色為healDarkGrey
                        decoration: BoxDecoration(
                          color: healDarkGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: 150,
                        height: 150,
                        child: const Center(
                          child: Text(
                            'Import\nExcel Data',
                            style: TextStyle(color: colorWhite80, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      // 四邊都加上圓角框 框的顏色為healDarkGrey
                      decoration: BoxDecoration(
                        color: healDarkGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: 150,
                      height: 150,
                      child: const Center(
                        child: Text(
                          'Import\nFiles',
                          style: TextStyle(color: colorWhite80, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
