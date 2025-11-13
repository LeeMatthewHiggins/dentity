import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:dentity/dentity.dart';

import 'asteroids_painter.dart';
import 'asteroids_components.dart';
import 'asteroids_example.dart';

class AsteroidsGame extends StatefulWidget {
  const AsteroidsGame({super.key});

  @override
  State<AsteroidsGame> createState() => _AsteroidsGameState();
}

class _AsteroidsGameState extends State<AsteroidsGame>
    with SingleTickerProviderStateMixin {
  late World _world;
  Ticker? _ticker;
  late Entity _shipEntity;
  late InputState _inputState;
  bool _gameOver = false;
  DateTime _lastFrameTime = DateTime.now();
  double _shieldPercent = 1.0;
  int _score = 0;

  static const double _worldWidth = 800.0;
  static const double _worldHeight = 600.0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _ticker = createTicker(_onTick);
    _ticker!.start();
  }

  void _initializeGame() {
    _world = createAsteroidsWorld(
      worldWidth: _worldWidth,
      worldHeight: _worldHeight,
    );

    final shipView = _world.viewForTypes({Ship});
    _shipEntity = shipView.first;
    _inputState = _world.getComponent<InputState>(_shipEntity)!;
    _gameOver = false;
    _lastFrameTime = DateTime.now();
    _score = 0;
  }

  void _onTick(Duration elapsed) {
    if (_gameOver) return;

    final now = DateTime.now();
    final delta = now.difference(_lastFrameTime);
    _lastFrameTime = now;

    _world.process(delta: delta);

    final shipView = _world.viewForTypes({Ship});
    if (shipView.isEmpty) {
      setState(() {
        _gameOver = true;
      });
    } else {
      final shield = _world.getComponent<Shield>(_shipEntity);
      final score = _world.getComponent<Score>(_shipEntity);
      setState(() {
        _shieldPercent = shield != null ? shield.current / shield.maximum : 0.0;
        _score = score?.value ?? 0;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_gameOver) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() {
          _initializeGame();
        });
      }
      return;
    }

    final isPressed = event is KeyDownEvent || event is KeyRepeatEvent;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _inputState.rotateLeft = isPressed;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _inputState.rotateRight = isPressed;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _inputState.thrust = isPressed;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      _inputState.fire = isPressed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Score: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 32),
                    const Text(
                      'Shield:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 200,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: _shieldPercent,
                            child: Container(
                              color: _shieldPercent > 0.5
                                  ? Colors.green
                                  : _shieldPercent > 0.25
                                      ? Colors.yellow
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: _worldWidth,
                    height: _worldHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRect(
                      child: CustomPaint(
                        painter: AsteroidsPainter(_world),
                      ),
                    ),
                  ),
                  if (_gameOver)
                    Container(
                      width: _worldWidth,
                      height: _worldHeight,
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GAME OVER',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Press ENTER to restart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Controls: Arrow Keys to rotate/thrust, Space to fire',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
