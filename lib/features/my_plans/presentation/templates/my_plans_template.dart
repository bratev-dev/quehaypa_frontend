import 'package:flutter/material.dart';

import '../organisms/my_plans_header_organism.dart';
import '../organisms/my_plans_grid_organism.dart';

class MyPlansTemplate extends StatelessWidget {
  const MyPlansTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFD600),
      child: const Column(
        children: [
          MyPlansHeaderOrganism(),
          Expanded(child: MyPlansGridOrganism()),
        ],
      ),
    );
  }
}
