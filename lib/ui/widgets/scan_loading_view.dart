import 'package:flutter/material.dart';

class ScanLoadingView extends StatelessWidget{

  const ScanLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20,),
          Text(
            "Scanning in progress, please wait a moment :o",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24
            ),
          ),
        ],
      ),
    );
  }
}