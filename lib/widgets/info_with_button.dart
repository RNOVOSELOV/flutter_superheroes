import 'package:flutter/material.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/widgets/action_button.dart';

class InfoWithButton extends StatelessWidget {
  final String title;
  final String subTitle;
  final String buttonText;
  final String assetImage;
  final double imageHeight;
  final double imageWidth;
  final double imageTopPadding;
  final VoidCallback onTap;

  const InfoWithButton({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.buttonText,
    required this.assetImage,
    required this.imageHeight,
    required this.imageWidth,
    required this.imageTopPadding,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 108,
                width: 108,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SuperheroesColors.actionButtonColor,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: imageTopPadding),
                child: Image.asset(
                  assetImage,
                  height: imageHeight,
                  width: imageWidth,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            title,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: SuperheroesColors.whiteTextColor),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            subTitle.toUpperCase(),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SuperheroesColors.whiteTextColor),
          ),
          const SizedBox(
            height: 30,
          ),
          ActionButton(text: buttonText, onTap: onTap),
        ],
      ),
    );
  }
}
