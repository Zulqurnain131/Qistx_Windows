import 'package:flutter/material.dart';

class Helpandsupport extends StatefulWidget {
  const Helpandsupport({super.key});

  @override
  State<Helpandsupport> createState() => _HelpandsupportState();
}

class _HelpandsupportState extends State<Helpandsupport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Help & support",
          style: TextStyle(backgroundColor: Colors.orange, color: Colors.white),
        ),
        centerTitle: true,
      ),
    );
  }
}
