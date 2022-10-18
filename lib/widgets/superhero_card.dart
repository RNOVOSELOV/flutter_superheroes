import 'package:flutter/material.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';

class SuperheroCard extends StatelessWidget {
  final SuperheroInfo superhero;
  final VoidCallback onTab;

  const SuperheroCard({
    Key? key,
    required this.superhero,
    required this.onTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTab,
      child: Container(
        height: 70,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: SuperheroesColors.cardBackground,
        ),
        child: Row(
          children: [
            Image.network(
              superhero.imageUrl,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  superhero.name.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SuperheroesColors.whiteTextColor),
                ),
                Text(
                  superhero.realName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: SuperheroesColors.whiteTextColor,
                  ),
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}
