import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFF4A22A8),
        child: Center(
          child: Text("If you see this, it's working!"),
        ),
      ),
    );
  }
}
