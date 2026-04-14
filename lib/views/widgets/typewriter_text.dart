import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;

  const TypewriterText({super.key, required this.text});

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String displayed = "";

  @override
  void initState() {
    super.initState();
    type();
  }

  void type() async {
    for (int i = 0; i < widget.text.length; i++) {
      await Future.delayed(Duration(milliseconds: 15));
      setState(() {
        displayed += widget.text[i];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(displayed, style: TextStyle(color: Colors.white));
  }
}
