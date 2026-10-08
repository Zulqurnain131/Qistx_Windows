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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Help & support", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
    );
  }
}
