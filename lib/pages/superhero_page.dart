import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/superhero_bloc.dart';
import 'package:superheroes/model/biography.dart';
import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/model/server_image.dart';
import 'package:superheroes/model/superhero.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/resources/superheroes_icons.dart';

class SuperheroPage extends StatefulWidget {
  final String id;
  final http.Client? client;

  const SuperheroPage({Key? key, required this.id, this.client})
      : super(key: key);

  @override
  State<SuperheroPage> createState() => _SuperheroPageState();
}

class _SuperheroPageState extends State<SuperheroPage> {
  late SuperheroBlock bloc;

  @override
  void initState() {
    super.initState();
    bloc = SuperheroBlock(client: widget.client, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: const Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SuperheroContentPage(),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class SuperheroContentPage extends StatelessWidget {
  const SuperheroContentPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SuperheroBlock bloc = Provider.of<SuperheroBlock>(context);

    return StreamBuilder<Superhero>(
      stream: bloc.observeSuperhero(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        Superhero superhero = snapshot.data!;
        return CustomScrollView(
          slivers: [
            SuperheroAppBar(superhero: superhero),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  if (superhero.powerstats.isNotNull())
                    PowerstatsWidget(powerstats: superhero.powerstats),
                  BiographyWidget(biography: superhero.biography),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}

class SuperheroAppBar extends StatelessWidget {
  const SuperheroAppBar({
    Key? key,
    required this.superhero,
  }) : super(key: key);

  final Superhero superhero;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      primary: true,
      stretch: true,
      pinned: true,
      floating: true,
      expandedHeight: 348,
      actions: [
        FavoriteButtonWidget()
      ],
      backgroundColor: SuperheroesColors.background,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          superhero.name,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: SuperheroesColors.whiteTextColor,
              fontSize: 22),
        ),
        centerTitle: true,
        background: CachedNetworkImage(
          imageUrl: superhero.image.url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class FavoriteButtonWidget extends StatelessWidget {
  const FavoriteButtonWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SuperheroBlock bloc = Provider.of<SuperheroBlock>(context);
    return StreamBuilder<bool>(
      stream: bloc.observeIsFavorite(),
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        final favorite =
            !snapshot.hasData || snapshot.data == null || snapshot.data!;
        return GestureDetector(
          onTap: () =>
              favorite ? bloc.removeFromFavorite() : bloc.addToFavorite(),
          child: Container(
            height: 52,
            width: 52,
            alignment: Alignment.center,
            child: Image.asset(
              favorite
                  ? SuperheroesIcons.starFilled
                  : SuperheroesIcons.starEmpty,
              width: 32,
              height: 32,
            ),
          ),
        );
      },
    );
  }
}

class PowerstatsWidget extends StatelessWidget {
  final Powerstats powerstats;

  const PowerstatsWidget({Key? key, required this.powerstats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            "Powerstats".toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: SuperheroesColors.whiteTextColor,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(
          height: 24,
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Intelligence",
                value: powerstats.intelligencePercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Strength",
                value: powerstats.strengthPercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Speed",
                value: powerstats.speedPercent,
              ),
            )),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Durability",
                value: powerstats.durabilityPercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Power",
                value: powerstats.powerPercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Combat",
                value: powerstats.combatPercent,
              ),
            )),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        SizedBox(
          height: 36,
        ),
      ],
    );
  }
}

class PowerstatWidget extends StatelessWidget {
  final String name;
  final double value;

  const PowerstatWidget({
    Key? key,
    required this.name,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ArcWidget(value: value, color: calculateColorByValue(value)),
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: Text(
            "${(value * 100).toInt()}",
            style: TextStyle(
              color: calculateColorByValue(value),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Text(
            name.toUpperCase(),
            style: TextStyle(
              color: SuperheroesColors.whiteTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Color calculateColorByValue(double value) {
    if (value <= 0.5) {
      return Color.lerp(Colors.red, Colors.orangeAccent, value / 0.5)!;
    } else {
      return Color.lerp(
          Colors.orangeAccent, Colors.green, (value - 0.5) / 0.5)!;
    }
  }
}

class ArcWidget extends StatelessWidget {
  final double value;
  final Color color;

  const ArcWidget({Key? key, required this.value, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArcCustomPainter(color: color, value: value),
      size: Size(66, 33),
    );
  }
}

class ArcCustomPainter extends CustomPainter {
  final double value;
  final Color color;

  ArcCustomPainter({
    required this.value,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final bgPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawArc(rect, pi, pi, false, bgPaint);
    canvas.drawArc(rect, pi, pi * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ArcCustomPainter) {
      return oldDelegate.value != value && oldDelegate.color != color;
    }
    return true;
  }
}

class BiographyWidget extends StatelessWidget {
  final Biography biography;

  const BiographyWidget({Key? key, required this.biography}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Text(
        biography.toJson().toString(),
        style: TextStyle(color: Colors.white),
      ),
      alignment: Alignment.center,
    );
  }
}
