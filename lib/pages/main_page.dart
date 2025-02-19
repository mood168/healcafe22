import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healcafe/pages/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'beans_page.dart';
import 'login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.qrCodeId});

  final String? qrCodeId;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String pipeUseId = '1';
  String userEmail = '';
  int stepPage = 1;
  String qrCodeId = '';
  bool showEnglish = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('showEnglish', showEnglish);
      if (mounted) {
        setState(() {
          showEnglish = prefs.getBool('showEnglish') ?? true;
          pipeUseId = prefs.getString('pipeUseId') ?? '1';
          userEmail = prefs.getString('userEmail') ?? '';
          qrCodeId = widget.qrCodeId ?? '';
        });
        if (prefs.getString('M${pipeUseId}g16Gram') == null && prefs.getString('M${pipeUseId}g16FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g16LastNoticeGram') == null && prefs.getString('M${pipeUseId}g16ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g16Gram', '90000');
          prefs.setString('M${pipeUseId}g16FirstNoticeGram', '2000');
          prefs.setString('M${pipeUseId}g16LastNoticeGram', '1000');
          prefs.setString('M${pipeUseId}g16ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g1Gram') == null && prefs.getString('M${pipeUseId}g1FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g1LastNoticeGram') == null && prefs.getString('M${pipeUseId}g1ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g1Gram', '5000');
          prefs.setString('M${pipeUseId}g1FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g1LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g1ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g2Gram') == null && prefs.getString('M${pipeUseId}g2FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g2LastNoticeGram') == null && prefs.getString('M${pipeUseId}g2ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g2Gram', '5000');
          prefs.setString('M${pipeUseId}g2FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g2LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g2ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g3Gram') == null && prefs.getString('M${pipeUseId}g3FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g3LastNoticeGram') == null && prefs.getString('M${pipeUseId}g3ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g3Gram', '5000');
          prefs.setString('M${pipeUseId}g3FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g3LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g3ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g4Gram') == null && prefs.getString('M${pipeUseId}g4FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g4LastNoticeGram') == null && prefs.getString('M${pipeUseId}g4ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g4Gram', '5000');
          prefs.setString('M${pipeUseId}g4FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g4LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g4ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g5Gram') == null && prefs.getString('M${pipeUseId}g5FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g5LastNoticeGram') == null && prefs.getString('M${pipeUseId}g5ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g5Gram', '5000');
          prefs.setString('M${pipeUseId}g5FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g5LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g5ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g6Gram') == null && prefs.getString('M${pipeUseId}g6FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g6LastNoticeGram') == null && prefs.getString('M${pipeUseId}g6ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g6Gram', '5000');
          prefs.setString('M${pipeUseId}g6FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g6LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g6ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g7Gram') == null && prefs.getString('M${pipeUseId}g7FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g7LastNoticeGram') == null && prefs.getString('M${pipeUseId}g7ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g7Gram', '5000');
          prefs.setString('M${pipeUseId}g7FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g7LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g7ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g8Gram') == null && prefs.getString('M${pipeUseId}g8FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g8LastNoticeGram') == null && prefs.getString('M${pipeUseId}g8ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g8Gram', '5000');
          prefs.setString('M${pipeUseId}g8FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g8LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g8ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g9Gram') == null && prefs.getString('M${pipeUseId}g9FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g9LastNoticeGram') == null && prefs.getString('M${pipeUseId}g9ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g9Gram', '5000');
          prefs.setString('M${pipeUseId}g9FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g9LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g9ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g10Gram') == null && prefs.getString('M${pipeUseId}g10FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g10LastNoticeGram') == null && prefs.getString('M${pipeUseId}g10ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g10Gram', '5000');
          prefs.setString('M${pipeUseId}g10FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g10LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g10ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g11Gram') == null && prefs.getString('M${pipeUseId}g11FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g11LastNoticeGram') == null && prefs.getString('M${pipeUseId}g11ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g11Gram', '5000');
          prefs.setString('M${pipeUseId}g11FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g11LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g11ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g12Gram') == null && prefs.getString('M${pipeUseId}g12FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g12LastNoticeGram') == null && prefs.getString('M${pipeUseId}g12ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g12Gram', '5000');
          prefs.setString('M${pipeUseId}g12FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g12LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g12ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g13Gram') == null && prefs.getString('M${pipeUseId}g13FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g13LastNoticeGram') == null && prefs.getString('M${pipeUseId}g13ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g13Gram', '5000');
          prefs.setString('M${pipeUseId}g13FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g13LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g13ResetDateTime', DateTime.now().toString());
        }

        if (prefs.getString('M${pipeUseId}g14Gram') == null && prefs.getString('M${pipeUseId}g14FirstNoticeGram') == null && prefs.getString('M${pipeUseId}g14LastNoticeGram') == null && prefs.getString('M${pipeUseId}g14ResetDateTime') == null) {
          prefs.setString('M${pipeUseId}g14Gram', '5000');
          prefs.setString('M${pipeUseId}g14FirstNoticeGram', '800');
          prefs.setString('M${pipeUseId}g14LastNoticeGram', '500');
          prefs.setString('M${pipeUseId}g14ResetDateTime', DateTime.now().toString());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      backgroundColor: bgColor,
      body: userEmail == '' ? const LoginPage() : BeansPage(qrCodeId: qrCodeId),
    );
  }
}
