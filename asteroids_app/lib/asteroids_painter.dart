import 'dart:math' as math;
import 'package:flutter/material.dart' hide Velocity;
import 'package:dentity/dentity.dart';

import 'asteroids_components.dart';
import 'basic_components.dart';

class AsteroidsPainter extends CustomPainter {
  final World world;

  static const double _largeAsteroidRadius = 40.0;
  static const double _mediumAsteroidRadius = 25.0;
  static const double _smallAsteroidRadius = 15.0;
  static const double _shipSize = 15.0;
  static const double _laserLength = 4.0;

  AsteroidsPainter(this.world);

  @override
  void paint(Canvas canvas, Size size) {
    _drawShip(canvas);
    _drawAsteroids(canvas);
    _drawLasers(canvas);
  }

  void _drawShip(Canvas canvas) {
    final shipView = world.viewForTypes({Ship, Position, Rotation});

    for (final entity in shipView) {
      final position = shipView.componentLists.get<Position>(entity)!;
      final rotation = shipView.componentLists.get<Rotation>(entity)!;
      final inputState = shipView.componentLists.get<InputState>(entity);

      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.save();
      canvas.translate(position.x, position.y);
      canvas.rotate(rotation.angle);

      final path = Path()
        ..moveTo(_shipSize, 0)
        ..lineTo(-_shipSize, -_shipSize / 2)
        ..lineTo(-_shipSize / 2, 0)
        ..lineTo(-_shipSize, _shipSize / 2)
        ..close();

      canvas.drawPath(path, paint);

      if (inputState?.thrust ?? false) {
        final thrustPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final thrustPath = Path()
          ..moveTo(-_shipSize, -_shipSize / 4)
          ..lineTo(-_shipSize * 1.5, 0)
          ..lineTo(-_shipSize, _shipSize / 4);

        canvas.drawPath(thrustPath, thrustPaint);
      }

      canvas.restore();
    }
  }

  void _drawAsteroids(Canvas canvas) {
    final asteroidView = world.viewForTypes({Asteroid, Position, Rotation});

    for (final entity in asteroidView) {
      final asteroid = asteroidView.componentLists.get<Asteroid>(entity)!;
      final position = asteroidView.componentLists.get<Position>(entity)!;
      final rotation = asteroidView.componentLists.get<Rotation>(entity)!;

      double radius;
      if (asteroid.size == 3) {
        radius = _largeAsteroidRadius;
      } else if (asteroid.size == 2) {
        radius = _mediumAsteroidRadius;
      } else {
        radius = _smallAsteroidRadius;
      }

      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.save();
      canvas.translate(position.x, position.y);
      canvas.rotate(rotation.angle);

      _drawAsteroidShape(canvas, radius, paint);

      canvas.restore();
    }
  }

  void _drawAsteroidShape(Canvas canvas, double radius, Paint paint) {
    final random = math.Random(42);
    final path = Path();
    const segments = 8;

    for (var i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final variation = 0.7 + random.nextDouble() * 0.6;
      final r = radius * variation;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawLasers(Canvas canvas) {
    final laserView = world.viewForTypes({Laser, Position, Velocity});

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    for (final entity in laserView) {
      final position = laserView.componentLists.get<Position>(entity)!;
      final velocity = laserView.componentLists.get<Velocity>(entity)!;

      final angle = math.atan2(velocity.y, velocity.x);
      final dx = math.cos(angle) * _laserLength;
      final dy = math.sin(angle) * _laserLength;

      canvas.drawLine(
        Offset(position.x - dx, position.y - dy),
        Offset(position.x + dx, position.y + dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AsteroidsPainter oldDelegate) => true;
}
