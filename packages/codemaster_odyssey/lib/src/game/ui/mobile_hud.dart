import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../odyssey_game.dart';

/// HUD Layer containing mobile virtual controls.
class MobileHUD extends HudMarginComponent with HasGameReference<OdysseyGame> {
  late final JoystickComponent joystick;
  late final HudButtonComponent attackButton;
  late final HudButtonComponent specialButton;
  late final HudButtonComponent dodgeButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Virtual Joystick (Bottom Left)
    final knobPaint = Paint()..color = Colors.cyan.withAlpha(200);
    final backgroundPaint = Paint()..color = Colors.cyan.withAlpha(80);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 60, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);

    // 2. Dodge Button (Bottom Right corner)
    dodgeButton = HudButtonComponent(
      button: CircleComponent(
        radius: 30,
        paint: Paint()..color = const Color(0xFFFF8C00).withAlpha(180),
      ),
      margin: const EdgeInsets.only(right: 30, bottom: 30),
      onPressed: () => game.player.dodge(),
    );
    add(dodgeButton);

    // 3. Attack Button (Above Dodge)
    attackButton = HudButtonComponent(
      button: CircleComponent(
        radius: 40,
        paint: Paint()..color = const Color(0xFFFFD700).withAlpha(180),
      ),
      margin: const EdgeInsets.only(right: 30, bottom: 100),
      onPressed: () => game.player.attack(0),
    );
    add(attackButton);

    // 4. Special Button (Left of Dodge)
    specialButton = HudButtonComponent(
      button: CircleComponent(
        radius: 30,
        paint: Paint()..color = const Color(0xFF00E5FF).withAlpha(180),
      ),
      margin: const EdgeInsets.only(right: 100, bottom: 30),
      onPressed: () => game.player.attack(1),
    );
    add(specialButton);

    // 5. Jump Button (Left of Attack / Above Special)
    final jumpButton = HudButtonComponent(
      button: CircleComponent(
        radius: 35,
        paint: Paint()..color = Colors.lightGreenAccent.withAlpha(180),
      ),
      margin: const EdgeInsets.only(right: 100, bottom: 100),
      onPressed: () => game.player.jump(),
    );
    add(jumpButton);
    // 5. Codedex Button (Top Right - Cyan)
    final codedexButton = HudButtonComponent(
      button: CircleComponent(
        radius: 25,
        paint: Paint()..color = const Color(0xFF00E5FF).withAlpha(150),
      ),
      margin: const EdgeInsets.only(right: 20, top: 40),
      onPressed: () => game.overlays.add('Codedex'),
    );
    codedexButton.add(
      SpriteComponent(
        sprite: await game.loadSprite('ui/book_icon.png'),
        size: Vector2.all(20),
        position: Vector2.all(15), // Center it
      ),
    );
    add(codedexButton);
  }
}
