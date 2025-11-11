import 'package:flutter/material.dart';

import 'game_state.dart';

void main() {
  runApp(const AsteroidsApp());
}

class AsteroidsApp extends StatelessWidget {
  const AsteroidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asteroids - Dentity ECS Example',
      theme: ThemeData.dark(),
      home: const AsteroidsGame(),
    );
  }
}
