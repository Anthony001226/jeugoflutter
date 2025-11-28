import 'package:flutter/material.dart';

class LoadingUI extends StatelessWidget {
  const LoadingUI({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'Loading World...',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
