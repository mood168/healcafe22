import 'dart:io';
import 'package:flutter/material.dart';
import 'constant.dart';
import 'main_page.dart';

class DrinkIsReady extends StatefulWidget {
  const DrinkIsReady({super.key});

  @override
  State<DrinkIsReady> createState() => _DrinkIsReadyState();
}

class _DrinkIsReadyState extends State<DrinkIsReady> {
  String documentsPath = AllConstants().documentsPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: healUnderBg,
      body: Center(
        child: SizedBox(
          width: 800,
          height: 800,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.file(
                    File('$documentsPath/images/coffeeready.png'),
                    width: 600,
                    fit: BoxFit.fitWidth,
                  ),
                  Image.file(
                    File('$documentsPath/images/enjoy.png'),
                    width: 600,
                    fit: BoxFit.fitWidth,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Your cup is ready ', style: TextStyle(color: healDarkGrey, fontSize: 28)),
              const Text('Enjoy your coffee, see you ', style: TextStyle(color: healDarkGrey, fontSize: 28)),
              FutureBuilder(
                future: Future.delayed(const Duration(seconds: 5)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (BuildContext context) => const MainPage()),
                      );
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
              // const SizedBox(height: 80),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => const MainPage()));
              //   },
              //   child: Image.file(
              //     File('$documentsPath/images/confirm.png'),
              //     height: 80,
              //     fit: BoxFit.fitHeight,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
