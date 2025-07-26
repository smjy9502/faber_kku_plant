import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 임시 이미지
            Container(
              width: 150,
              height: 150,
              color: Colors.green[200],
              child: const Icon(Icons.image, size: 80),
            ),
            const SizedBox(height: 16),
            const Text('여기에 정보를 표시합니다.'),
          ],
        ),
      ),
    );
  }
}
