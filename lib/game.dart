import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class TilemapGame extends FlameGame with TapCallbacks {
  // Player Attributes
  late Vector2 playerPos;
  late Vector2 playerVel;
  final Vector2 playerSize = Vector2(28, 36);
  bool isGrounded = false;
  int lives = 3;
  int score = 0;
  bool isGameOver = false;
  bool isVictory = false;

  // Game Physics
  final double gravity = 900.0;
  final double moveSpeed = 200.0;
  final double jumpForce = -430.0;
  double horizontalInput = 0.0;

  // Level World Components
  List<Rect> tilemapPlatforms = [];
  List<Rect> collectibles = [];
  late Rect finishFlag;

  // Dual Enemy AI Entities
  late PatrolEnemy patrolEnemy;
  late ChaseEnemy chaseEnemy;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    initGame();
  }

  void initGame() {
    lives = 3;
    score = 0;
    isGameOver = false;
    isVictory = false;
    horizontalInput = 0.0;

    playerPos = Vector2(40, size.y - 120);
    playerVel = Vector2.zero();

    // 1. Grid-based Tilemap Level Layout
    tilemapPlatforms = [
      Rect.fromLTWH(0, size.y - 40, size.x, 40),          // Main Floor
      Rect.fromLTWH(40, size.y - 140, 100, 20),        // Platform 1
      Rect.fromLTWH(180, size.y - 220, 120, 20),       // Platform 2
      Rect.fromLTWH(60, size.y - 320, 110, 20),        // Platform 3
      Rect.fromLTWH(size.x - 140, size.y - 150, 100, 20)// Goal Platform
    ];

    // 2. Collectibles (Gems)
    collectibles = [
      Rect.fromLTWH(80, size.y - 180, 20, 20),
      Rect.fromLTWH(230, size.y - 260, 20, 20),
      Rect.fromLTWH(100, size.y - 360, 20, 20),
    ];

    // 3. Goal / Finish Point Flag
    finishFlag = Rect.fromLTWH(size.x - 90, size.y - 210, 30, 60);

    // 4. Enemy 1: Patrol AI (Moves back & forth on platform)
    patrolEnemy = PatrolEnemy(
      pos: Vector2(190, size.y - 250),
      size: Vector2(28, 28),
      minX: 180,
      maxX: 280,
      speed: 90,
    );

    // 5. Enemy 2: Chase AI (Detects player proximity & aggressively pursues)
    chaseEnemy = ChaseEnemy(
      pos: Vector2(size.x - 120, size.y - 70),
      size: Vector2(30, 30),
      speed: 110,
    );
  }

  // ---------------------------------------------------------------------------
  // AUDIO FEEDBACK SYSTEM & CONTROLS
  // ---------------------------------------------------------------------------
  void playAudioFeedback(String type) {
    try {
      // Audio playback helper via FlameAudio
      if (type == 'collect') {
        FlameAudio.play('collect.wav');
      } else if (type == 'hit') {
        FlameAudio.play('hit.wav');
      } else if (type == 'win') {
        FlameAudio.play('win.wav');
      }
    } catch (_) {
      // Audio fallback handling if asset files are omitted locally
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver || isVictory) {
      initGame();
      return;
    }

    final tapPos = event.canvasPosition;

    // Mobile On-Screen D-Pad & Jump Controls
    if (tapPos.y > size.y - 100) {
      if (tapPos.x < 90) {
        horizontalInput = -1.0;
      } else if (tapPos.x > 100 && tapPos.x < 190) {
        horizontalInput = 1.0;
      } else if (tapPos.x > size.x - 120 && isGrounded) {
        playerVel.y = jumpForce;
        isGrounded = false;
      }
    } else if (isGrounded) {
      playerVel.y = jumpForce;
      isGrounded = false;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    horizontalInput = 0.0;
  }

  // ---------------------------------------------------------------------------
  // GAME LOOP UPDATE & AI BEHAVIORS
  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver || isVictory) return;

    // Update AI Behaviors
    patrolEnemy.update(dt);
    chaseEnemy.update(dt, playerPos);

    // Apply Player Velocity & Movement
    playerVel.x = horizontalInput * moveSpeed;
    playerVel.y += gravity * dt;

    playerPos.x += playerVel.x * dt;
    playerPos.x = playerPos.x.clamp(0.0, size.x - playerSize.x);

    playerPos.y += playerVel.y * dt;

    // Tilemap Platform Collisions
    isGrounded = false;
    final Rect playerRect = Rect.fromLTWH(playerPos.x, playerPos.y, playerSize.x, playerSize.y);

    for (final platform in tilemapPlatforms) {
      if (playerRect.overlaps(platform) &&
          playerVel.y > 0 &&
          (playerPos.y + playerSize.y - playerVel.y * dt) <= platform.top + 10) {
        playerPos.y = platform.top - playerSize.y;
        playerVel.y = 0;
        isGrounded = true;
      }
    }

    // Collectible Gems Collisions
    for (int i = collectibles.length - 1; i >= 0; i--) {
      if (playerRect.overlaps(collectibles[i])) {
        collectibles.removeAt(i);
        score += 50;
        playAudioFeedback('collect');
      }
    }

    // Finish Flag Reached Collision
    if (playerRect.overlaps(finishFlag)) {
      isVictory = true;
      playAudioFeedback('win');
    }

    // Enemy Collisions (Patrol or Chase Enemy)
    if (playerRect.overlaps(patrolEnemy.rect) || playerRect.overlaps(chaseEnemy.rect)) {
      lives--;
      playAudioFeedback('hit');
      if (lives <= 0) {
        isGameOver = true;
      } else {
        playerPos = Vector2(40, size.y - 120);
        playerVel = Vector2.zero();
      }
    }

    // Fall Off Screen Outer Boundary
    if (playerPos.y > size.y) {
      lives--;
      playAudioFeedback('hit');
      if (lives <= 0) {
        isGameOver = true;
      } else {
        playerPos = Vector2(40, size.y - 120);
        playerVel = Vector2.zero();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CANVAS RENDERING
  // ---------------------------------------------------------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Render Tilemap Platforms
    final Paint tilePaint = Paint()..color = const Color(0xFF334155);
    for (final platform in tilemapPlatforms) {
      canvas.drawRRect(RRect.fromRectAndRadius(platform, const Radius.circular(4)), tilePaint);
    }

    // 2. Render Collectibles (Gems)
    final Paint gemPaint = Paint()..color = const Color(0xFF38BDF8);
    for (final gem in collectibles) {
      canvas.drawCircle(gem.center, gem.width / 2, gemPaint);
    }

    // 3. Render Finish Flag Goal
    final Paint flagPolePaint = Paint()..color = Colors.white;
    final Paint flagBannerPaint = Paint()..color = const Color(0xFF22C55E);
    canvas.drawRect(Rect.fromLTWH(finishFlag.left, finishFlag.top, 6, finishFlag.height), flagPolePaint);
    canvas.drawPath(
      Path()
        ..moveTo(finishFlag.left + 6, finishFlag.top)
        ..lineTo(finishFlag.left + 35, finishFlag.top + 15)
        ..lineTo(finishFlag.left + 6, finishFlag.top + 30)
        ..close(),
      flagBannerPaint,
    );

    // 4. Render Patrol Enemy (Orange)
    final Paint patrolPaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawRect(patrolEnemy.rect, patrolPaint);

    // 5. Render Chase Enemy (Red Aggro)
    final Paint chasePaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawRect(chaseEnemy.rect, chasePaint);

    // 6. Render Player Character (Green)
    final Paint playerPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(playerPos.x, playerPos.y, playerSize.x, playerSize.y), const Radius.circular(6)),
      playerPaint,
    );

    // 7. Render Score & Health HUD
    final TextPainter hudText = TextPainter(
      text: TextSpan(
        text: 'Score: $score  \vert{}  Lives:${"❤️ " * lives}',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    hudText.layout();
    hudText.paint(canvas, const Offset(20, 45));

    // 8. Render Touch Control Buttons
    final Paint btnPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, size.y - 90, 70, 60), const Radius.circular(8)), btnPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(100, size.y - 90, 70, 60), const Radius.circular(8)), btnPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.x - 100, size.y - 90, 80, 60), const Radius.circular(8)), btnPaint);

    // 9. Overlay Screens (Victory / Game Over)
    if (isGameOver || isVictory) {
      final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.85);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

      final String title = isVictory ? 'LEVEL CLEARED! 🎉' : 'GAME OVER 💀';
      final Color titleColor = isVictory ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

      final TextPainter statusText = TextPainter(
        text: TextSpan(
          text: '$title\nFinal Score:$score\n\nTap to Play Again',
          style: TextStyle(color: titleColor, fontSize: 28, fontWeight: FontWeight.bold, height: 1.4),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      statusText.layout();
      statusText.paint(canvas, Offset((size.x - statusText.width) / 2, (size.y - statusText.height) / 2));
    }
  }
}

// -----------------------------------------------------------------------------
// AI ENEMY CLASSES (Patrol AI & Proximity Chase AI)
// -----------------------------------------------------------------------------
class PatrolEnemy {
  Vector2 pos;
  Vector2 size;
  double minX;
  double maxX;
  double speed;

  PatrolEnemy({required this.pos, required this.size, required this.minX, required this.maxX, required this.speed});

  Rect get rect => Rect.fromLTWH(pos.x, pos.y, size.x, size.y);

  void update(double dt) {
    pos.x += speed * dt;
    if (pos.x <= minX) speed = speed.abs();
    if (pos.x >= maxX) speed = -speed.abs();
  }
}

class ChaseEnemy {
  Vector2 pos;
  Vector2 size;
  double speed;

  ChaseEnemy({required this.pos, required this.size, required this.speed});

  Rect get rect => Rect.fromLTWH(pos.x, pos.y, size.x, size.y);

  void update(double dt, Vector2 playerPos) {
    // Distance check for agro pursuit trigger (radius of 200px)
    double distance = pos.distanceTo(playerPos);
    if (distance < 200) {
      if (playerPos.x > pos.x) {
        pos.x += speed * 0.7 * dt;
      } else {
        pos.x -= speed * 0.7 * dt;
      }
    }
  }
}