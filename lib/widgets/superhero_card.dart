import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';

class SuperheroCard extends StatelessWidget {
  final SuperheroInfo superheroInfo;
  final VoidCallback onTap;

  const SuperheroCard({
    Key? key,
    required this.superheroInfo,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: SuperheroesColors.cardBackground,
        ),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              color: SuperheroesColors.imagePlaceholder,
              child: CachedNetworkImage(
                imageUrl: superheroInfo.imageUrl,
                fit: BoxFit.cover,
                progressIndicatorBuilder: ((context, imageUrl, progress) {
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: progress.progress,
                        color: SuperheroesColors.progressImageColor,
                      ),
                    ),
                  );
                }),
                errorWidget: ((context, url, error) {
                  return Center(
                    child: Image.asset(
                      SuperheroesImages.unknownImagePath,
                      width: 20,
                      height: 62,
                      fit: BoxFit.cover,
                    ),
                  );
                }),
              ),
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
                  superheroInfo.name.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SuperheroesColors.whiteTextColor),
                ),
                Text(
                  superheroInfo.realName,
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
