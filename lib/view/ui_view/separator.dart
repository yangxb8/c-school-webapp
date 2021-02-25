// Flutter imports:
import 'package:flutter/material.dart';

class FancySeparator extends StatelessWidget {
  const FancySeparator({
    Key key, @required this.middleWidget,
  }) : super(key: key);

  final Widget middleWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Colors.white10,
                  Colors.white,
                ],
                begin: const FractionalOffset(0.0, 0.0),
                end: const FractionalOffset(1.0, 1.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp),
          ),
          width: 100.0,
          height: 1.0,
        ),
        middleWidget,
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white10,
                ],
                begin: const FractionalOffset(0.0, 0.0),
                end: const FractionalOffset(1.0, 1.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp),
          ),
          width: 100.0,
          height: 1.0,
        ),
      ],
    );
  }
}
