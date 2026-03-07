import 'package:flame/flame.dart';
import 'package:flame/game.dart';

/// Main entry point for the Codemaster Odyssey game engine.
class CodemasterOdysseyGame extends FlameGame {
  /// Creates a new instance of [CodemasterOdysseyGame].
  CodemasterOdysseyGame() {
    // Basic setup
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Enforce landscape orientation
    await Flame.device.setLandscape();
    await Flame.device.fullScreen();

    // Load components here
  }
}
