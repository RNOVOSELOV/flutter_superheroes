import 'dart:ui';

import 'package:superheroes/resources/superheroes_colors.dart';

class AlignmentInfo {
  final String name;
  final Color color;

  const AlignmentInfo._ (this.name, this.color);

  static const bad = AlignmentInfo._ ("bad", SuperheroesColors.badPersonageColor);
  static const good = AlignmentInfo._ ("good", SuperheroesColors.goodPersonageColor);
  static const neutral = AlignmentInfo._ ("neutral", SuperheroesColors.neutralPersonageColor);

  static AlignmentInfo? fromAlignment (final String alignment) {
    if (alignment == "bad") {
      return bad;
    } else if (alignment == "good") {
      return good;
    } else if (alignment == "neutral") {
      return neutral;
    }
    return null;
  }
}