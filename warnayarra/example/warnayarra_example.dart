import 'dart:async';
import 'dart:io';

import 'package:razer_chroma_rest_client/razer_chroma_rest_client.dart';
import 'package:snake/snake.dart';
import 'package:warnayarra/warnayarra.dart';

void main() async {
  final client = RazerChromaClient();
  await client.connect(warnayarraClientDetails);

  late SnakeGame snakeGame;
  SnakeGame createSnakeGame() => createWarnayarraSnakeGame(
        client,
        initialSnakeDirection: SnakeDirection.right,
      );
  snakeGame = createSnakeGame();
  final clock = Timer.periodic(
    const Duration(milliseconds: 250),
    (clock) {
      if (snakeGame.completed) {
        snakeGame = createSnakeGame();
      } else {
        snakeGame.tick();
      }
    },
  );

  stdin
    ..lineMode = false
    ..echoMode = false;
  final stdinSubscription = stdin.listen(
    (input) {
      if (input.length != 3 ||
          !(input[0] == 0x1B &&
              input[1] == 0x5B &&
              input[2] >= 0x41 &&
              input[2] <= 0x44)) return;
      switch (input[2]) {
        case 0x41:
          snakeGame.directionNextTick = SnakeDirection.up;
          break;
        case 0x42:
          snakeGame.directionNextTick = SnakeDirection.down;
          break;
        case 0x43:
          snakeGame.directionNextTick = SnakeDirection.right;
          break;
        case 0x44:
          snakeGame.directionNextTick = SnakeDirection.left;
          break;
      }
    },
  );

  var _stopping = false;
  late final StreamSubscription<void> _stopSubscription;
  _stopSubscription = ProcessSignal.sigint.watch().listen((_) async {
    if (!_stopping) {
      _stopping = true;
      clock.cancel();
      await stdinSubscription.cancel();
      await client.close();
      await _stopSubscription.cancel();
    }
  });
}
