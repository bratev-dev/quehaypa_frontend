import 'package:flutter/material.dart';

import '../templates/my_plans_template.dart';

class MyPlansPage extends StatelessWidget {
  const MyPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFD600),
      body: MyPlansTemplate(),
    );
  }
}
