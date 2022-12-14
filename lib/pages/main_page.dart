import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';

import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  final http.Client? client;

  MainPage({Key? key, this.client}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc(client: widget.client);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: const Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SafeArea(
          child: MainPageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);

    return Stack(children: const [
      MainPageStateWidget(),
      // Align(
      //   alignment: Alignment.bottomCenter,
      //   child: Padding(
      //     padding: EdgeInsets.only(bottom: 30),
      //     child: ActionButton(
      //       text: 'Next state',
      //       onTap: () {
      //         bloc.nextState();
      //       },
      //     ),
      //   ),
      // ),
      Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SearchWidget(),
      ),
    ]);
  }
}

class SearchWidget extends StatefulWidget {
  const SearchWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController controller = TextEditingController();
  bool haveSearchedText = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
      controller.addListener(() {
        bloc.updateText(controller.text);
        final haveText = controller.text.isNotEmpty;
        if (haveSearchedText != haveText) {
          setState(() {
            haveSearchedText = haveText;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return TextField(
      focusNode: bloc.getSearchFocusNode(),
      controller: controller,
      cursorColor: SuperheroesColors.textEditCursorColor,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        filled: true,
        fillColor: SuperheroesColors.textEditBackground,
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: haveSearchedText
              ? const BorderSide(
                  width: 2, color: SuperheroesColors.textEditBorderColorEditing)
              : const BorderSide(
                  color: SuperheroesColors.textEditBorderColorEnabled),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: SuperheroesColors.textEditBorderColorEditing, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: SuperheroesColors.textEditIconsColor,
          size: 24,
        ),
        suffix: GestureDetector(
            onTap: () {
              controller.clear();
            },
            child: const Icon(
              Icons.clear,
              color: SuperheroesColors.whiteTextColor,
              size: 24,
            )),
      ),
      style: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 20,
        color: SuperheroesColors.whiteTextColor,
      ),
    );
  }
}

class MainPageStateWidget extends StatelessWidget {
  const MainPageStateWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);

    return StreamBuilder<MainPageState>(
      stream: bloc.observeMainPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        final MainPageState state = snapshot.data!;
        switch (state) {
          case MainPageState.noFavorites:
            return const NoFavoritesWidget();
          case MainPageState.minSymbols:
            return const MinSymbolsWidget();
          case MainPageState.loading:
            return const LoadingIndicator(
              topPadding: 110,
            );
          case MainPageState.nothingFound:
            return const NothingFoundWidget();
          case MainPageState.loadingError:
            return const LoadingErrorWidget();
          case MainPageState.searchResults:
            return SuperheroesList(
              title: "Search result",
              stream: bloc.observeSearchedSuperheroes(),
              ableToSwipe: false,
            );
          case MainPageState.favorites:
            return SuperheroesList(
              title: "Your favorites",
              stream: bloc.observeFavoriteSuperheroes(),
              ableToSwipe: true,
            );
          default:
            return Center(
                child: Text(
              state.toString(),
              style: const TextStyle(color: Colors.white),
            ));
        }
      },
    );
  }
}

class NothingFoundWidget extends StatelessWidget {
  const NothingFoundWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return InfoWithButton(
      title: 'Nothing found',
      subTitle: 'Search for something else',
      buttonText: 'Search',
      assetImage: SuperheroesImages.hulkImagePath,
      imageHeight: 112,
      imageWidth: 84,
      imageTopPadding: 16,
      onTap: () => bloc.setSearchActiveAndClear(),
    );
  }
}

class LoadingErrorWidget extends StatelessWidget {
  const LoadingErrorWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return InfoWithButton(
      title: 'Error happened',
      subTitle: 'Please, try again',
      buttonText: 'Retry',
      assetImage: SuperheroesImages.supermanImagePath,
      imageHeight: 106,
      imageWidth: 126,
      imageTopPadding: 22,
      onTap: () => bloc.retryLastQuery(),
    );
  }
}

class SuperheroesList extends StatelessWidget {
  final String title;
  final Stream<List<SuperheroInfo>> stream;
  final bool ableToSwipe;

  const SuperheroesList(
      {Key? key,
      required this.title,
      required this.stream,
      required this.ableToSwipe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SuperheroInfo>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final List<SuperheroInfo> superheroes = snapshot.data!;
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: superheroes.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return ListTitleWidget(title: title);
            }
            final SuperheroInfo item = superheroes[index - 1];
            return ListTile(
              superhero: item,
              ableToSwipe: ableToSwipe,
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(
              height: 8,
            );
          },
        );
      },
    );
  }
}

class ListTile extends StatelessWidget {
  final SuperheroInfo superhero;
  final bool ableToSwipe;

  const ListTile({
    Key? key,
    required this.superhero,
    required this.ableToSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ableToSwipe
          ? ListTileDismissibleWidget(superhero: superhero, bloc: bloc)
          : ListTileContainerWidget(superhero: superhero),
    );
  }
}

class ListTileDismissibleWidget extends StatelessWidget {
  const ListTileDismissibleWidget({
    Key? key,
    required this.superhero,
    required this.bloc,
  }) : super(key: key);

  final SuperheroInfo superhero;
  final MainBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(superhero.id),
      background: const DismissibleSwipeBackground(
        isLeft: true,
      ),
      secondaryBackground: const DismissibleSwipeBackground(
        isLeft: false,
      ),
      onDismissed: (_) => bloc.removeFromFavorites(superhero.id),
      child: ListTileContainerWidget(superhero: superhero),
    );
  }
}

class DismissibleSwipeBackground extends StatelessWidget {
  final String dismissibleBackgroundText = "Remove\nfrom\nfavorites";
  final bool isLeft;

  const DismissibleSwipeBackground({
    Key? key,
    required this.isLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: SuperheroesColors.cardSwipeRemove,
      ),
      height: 70,
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Text(
        dismissibleBackgroundText.toUpperCase(),
        textAlign: isLeft ? TextAlign.left : TextAlign.right,
        style: const TextStyle(
          fontSize: 12,
          color: SuperheroesColors.whiteTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ListTileContainerWidget extends StatelessWidget {
  const ListTileContainerWidget({
    Key? key,
    required this.superhero,
  }) : super(key: key);

  final SuperheroInfo superhero;

  @override
  Widget build(BuildContext context) {
    return SuperheroCard(
      superheroInfo: superhero,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SuperheroPage(
                  id: superhero.id,
                )));
      },
    );
  }
}

class ListTitleWidget extends StatelessWidget {
  const ListTitleWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 90, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          color: SuperheroesColors.whiteTextColor,
        ),
      ),
    );
  }
}

class NoFavoritesWidget extends StatelessWidget {
  const NoFavoritesWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return InfoWithButton(
      title: 'No favorites yet',
      subTitle: 'Search and add',
      buttonText: 'Search',
      assetImage: SuperheroesImages.ironmanImagePath,
      imageHeight: 119,
      imageWidth: 108,
      imageTopPadding: 9,
      onTap: () => bloc.setSearchActiveAndClear(),
    );
  }
}

class MinSymbolsWidget extends StatelessWidget {
  const MinSymbolsWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110, left: 16, right: 16),
        child: Text(
          "Enter at least 3 symbols",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: SuperheroesColors.whiteTextColor),
        ),
      ),
    );
  }
}
