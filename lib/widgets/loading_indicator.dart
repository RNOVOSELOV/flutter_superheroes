import 'package:flutter/material.dart';
import 'package:superheroes/resources/superheroes_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double topPadding;
  const LoadingIndicator({
    Key? key, required this.topPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const CircularProgressIndicator(
          color: SuperheroesColors.blue,
          strokeWidth: 4,
        ),
      ),
    );
  }
}
