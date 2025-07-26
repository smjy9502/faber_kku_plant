import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main Screen')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 달력 자리(Placeholder)
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32.0),
                color: Colors.grey[300],
                child: const Center(child: Text('달력(캘린더) 영역')),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/info'),
                  child: const Text('Info'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/diary'),
                  child: const Text('Diary'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
