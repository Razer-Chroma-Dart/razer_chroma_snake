import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razer_chroma_rest_client/razer_chroma_rest_client.dart' as rcr;
import 'package:warnayarra/warnayarra.dart';

void main() async {
  final client = rcr.RazerChromaClient()
    ..onHeartbeatError = (error) {
      window.location.reload();
      return true;
    };

  try {
    await client.connect(warnayarraClientDetails);
  } on rcr.ClientException {
    // Leave the client unconnected when a failure occurs.
  }

  window.onUnload.listen(
    (_) => client
        .close()
        .catchError((e) {}, test: (e) => e is rcr.ClientException),
  );

  runApp(WarnayarraGui(client: client));
}

class WarnayarraGui extends StatelessWidget {
  final rcr.RazerChromaClient client;

  const WarnayarraGui({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[800],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(64),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: client.connected
                  ? WarnayarraGameView(client: client)
                  : const AspectRatio(
                      aspectRatio: warnayarraBoardWidth / warnayarraBoardHeight,
                      child: ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Could not attach to your keyboard.',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class WarnayarraGameView extends StatefulWidget {
  final rcr.RazerChromaClient client;

  const WarnayarraGameView({super.key, required this.client});

  @override
  State<WarnayarraGameView> createState() => _WarnayarraGameViewState();
}

class _WarnayarraGameViewState extends State<WarnayarraGameView> {
  static const backgroundColor = rcr.RgbColor(0x00, 0x00, 0x00);
  static const headColor = rcr.RgbColor(0xFF, 0x00, 0xFF);
  static const bodyColor = rcr.RgbColor(0x00, 0x00, 0xFF);
  static const tailColor = rcr.RgbColor(0x00, 0x00, 0xFF);
  static const foodColor = rcr.RgbColor(0x00, 0xFF, 0xFF);

  late SnakeGame _snakeGame;
  late final Timer _clock;

  /// Used to know if the painted board is invalid when building.
  /// setState does not need to be called when this is changed.
  var _tickCount = 0;

  late List<List<Color>> _board;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    SnakeGame createSnakeGame() {
      final snakeGame = createWarnayarraSnakeGame(
        widget.client,
        // ignore: avoid_redundant_argument_values
        backgroundColor: backgroundColor,
        // ignore: avoid_redundant_argument_values
        headColor: headColor,
        // ignore: avoid_redundant_argument_values
        bodyColor: bodyColor,
        // ignore: avoid_redundant_argument_values
        tailColor: tailColor,
        // ignore: avoid_redundant_argument_values
        foodColor: foodColor,
        initialSnakeDirection:
            Random().nextBool() ? SnakeDirection.right : SnakeDirection.left,
      );
      final warnayarraRenderer = snakeGame.renderer;
      snakeGame.renderer = () {
        warnayarraRenderer();
        if (!mounted) return;
        setState(() => _board = _renderBoard(snakeGame.getBoardWithSnake()));
      };
      return snakeGame;
    }

    _snakeGame = createSnakeGame();
    _board = _renderBoard(_snakeGame.getBoardWithSnake());
    _clock = Timer.periodic(
      const Duration(milliseconds: 250),
      (clock) {
        ++_tickCount;
        if (_snakeGame.completed) {
          _snakeGame = createSnakeGame();
          // Don't update the board immediately for a pause before restarting.
        } else {
          _snakeGame.tick();
        }
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (event) {
        final nextDirection = _keymap[event.logicalKey.keyId];
        if (nextDirection == null) return;
        _snakeGame.directionNextTick = nextDirection;
      },
      child: CustomPaint(
        painter: BoardPainter(
          tickCount: _tickCount,
          columnCount: warnayarraBoardWidth,
          board: _board,
        ),
        child: AspectRatio(aspectRatio: warnayarraBoardWidth / _board.length),
      ),
    );
  }

  static List<List<Color>> _renderBoard(List<List<SnakeItem>> board) => board
      .map(
        (row) => row.map((item) {
          switch (item) {
            case SnakeItem.head:
              return headColor.flutterColor;
            case SnakeItem.body:
              return bodyColor.flutterColor;
            case SnakeItem.tail:
              return tailColor.flutterColor;
            case SnakeItem.food:
              return foodColor.flutterColor;
            case SnakeItem.empty:
              return backgroundColor.flutterColor;
          }
        }).toList(growable: false),
      )
      .toList(growable: false);

  static final _keymap = {
    LogicalKeyboardKey.arrowUp.keyId: SnakeDirection.up,
    LogicalKeyboardKey.keyW.keyId: SnakeDirection.up,
    LogicalKeyboardKey.arrowDown.keyId: SnakeDirection.down,
    LogicalKeyboardKey.keyS.keyId: SnakeDirection.down,
    LogicalKeyboardKey.arrowLeft.keyId: SnakeDirection.left,
    LogicalKeyboardKey.keyA.keyId: SnakeDirection.left,
    LogicalKeyboardKey.arrowRight.keyId: SnakeDirection.right,
    LogicalKeyboardKey.keyD.keyId: SnakeDirection.right,
  };
}

class BoardPainter extends CustomPainter {
  final int tickCount;
  final int columnCount;
  final List<List<Color>> board;

  const BoardPainter({
    required this.tickCount,
    required this.columnCount,
    required this.board,
  });

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      tickCount != oldDelegate.tickCount;

  @override
  void paint(Canvas canvas, Size size) {
    final double unitSize;
    if (size.width >= size.height) {
      unitSize = size.height / board.length;
    } else {
      unitSize = size.width / columnCount;
    }
    final paint = Paint();
    for (var rowIndex = 0; rowIndex < board.length; ++rowIndex) {
      final row = board[rowIndex];
      for (var columnIndex = 0; columnIndex < row.length; ++columnIndex) {
        final rect = Rect.fromLTWH(
          columnIndex * unitSize,
          rowIndex * unitSize,
          unitSize + 1,
          unitSize + 1,
        );
        ;
        paint.color = row[columnIndex];
        canvas.drawRect(rect, paint);
      }
    }
  }
}

extension on rcr.RgbColor {
  Color get flutterColor =>
      Color.fromARGB(0xFF, r.round(), g.round(), b.round());
}
