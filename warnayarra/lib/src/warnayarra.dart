import 'package:razer_chroma_rest_client/razer_chroma_rest_client.dart';
import 'package:snake/snake.dart';

const warnayarraClientDetails = ClientDetails(
  title: 'Warnayarra',
  description: 'Snake on your keyboard',
  author: Author(name: 'hacker1024', contact: ''),
  supportedDevices: {DeviceType.keyboard},
  category: ClientCategory.game,
);

const warnayarraRightPadding = 1; // Exclude macro keys that may not exist.
const warnayarraBoardWidth = RazerKey.columnCount - warnayarraRightPadding;
const warnayarraBoardHeight = RazerKey.rowCount;

SnakeGame createWarnayarraSnakeGame(
  RazerChromaClient client, {
  Color backgroundColor = const Color.rgb(0x00, 0x00, 0x00),
  Color paddingColor = const Color.rgb(0x1D, 0x1D, 0x1D),
  Color headColor = const Color.rgb(0xFF, 0x00, 0xFF),
  Color bodyColor = const Color.rgb(0x00, 0x00, 0xFF),
  Color tailColor = const Color.rgb(0x00, 0x00, 0xFF),
  Color foodColor = const Color.rgb(0x00, 0xFF, 0xFF),
  required SnakeDirection initialSnakeDirection,
  int initialSnakeSize = 3,
  int maxTicksBeforeFood = 0, // 0 is recommended to reduce confusion.
}) {
  final backgroundColorValue = backgroundColor.toBgr();
  final paddingColorValue = paddingColor.toBgr();
  final headColorValue = headColor.toBgr();
  final bodyColorValue = bodyColor.toBgr();
  final tailColorValue = tailColor.toBgr();
  final foodColorValue = foodColor.toBgr();

  late SnakeGame snakeGame;
  return snakeGame = SnakeGame(
    renderer: () {
      final colorMatrix = snakeGame.getBoardWithSnake().map(
        (row) {
          return Iterable.generate(
            warnayarraRightPadding,
            (_) => paddingColorValue,
          ).followedBy(
            row.map((item) {
              switch (item) {
                case SnakeItem.head:
                  return headColorValue;
                case SnakeItem.body:
                  return bodyColorValue;
                case SnakeItem.tail:
                  return tailColorValue;
                case SnakeItem.food:
                  return foodColorValue;
                case SnakeItem.empty:
                  return backgroundColorValue;
              }
            }),
          ).toList(growable: false);
        },
      ).toList(growable: false);
      client.setKeyboardEffect(KeyboardEffect.custom(colorMatrix));
    },
    boardWidth: warnayarraBoardWidth,
    boardHeight: warnayarraBoardHeight,
    initialSnakeX: 6,
    initialSnakeY: 3,
    initialSnakeDirection: initialSnakeDirection,
    initialSnakeSize: 3,
    maxTicksBeforeFood: 0,
  );
}
