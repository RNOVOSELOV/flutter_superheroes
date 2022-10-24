import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/api_exception.dart';
import 'package:superheroes/favorite_superheroes_storage.dart';
import 'package:superheroes/model/alignment_info.dart';
import 'package:superheroes/model/superhero.dart';

class MainBloc {
  static const minSymbols = 3;

  final FocusNode searchFocus = FocusNode();

  FocusNode getSearchFocusNode() => searchFocus;

  void setSearchActiveAndClear() {
    searchFocus.requestFocus();
  }

  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();
  final searchedSuperheroesSubject = BehaviorSubject<List<SuperheroInfo>>();
  final currentTextSubject = BehaviorSubject<String>.seeded("");

  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;
  StreamSubscription? removeFromFavoriteSubscription;

  http.Client? client;

  MainBloc({this.client}) {
    textSubscription =
        Rx.combineLatest2<String, List<Superhero>, MainPageStateInfo>(
                currentTextSubject
                    .distinct()
                    .debounceTime(const Duration(milliseconds: 500)),
                FavoriteSuperheroesStorage.getInstance()
                    .observeFavoriteSuperheroes(),
                (searchedText, favorites) =>
                    MainPageStateInfo(searchedText, favorites.isNotEmpty))
            .listen((value) {
      print("CHANGED $value");
      searchSubscription?.cancel();
      if (value.searchText.isEmpty) {
        if (value.haveFavorites) {
          stateSubject.add(MainPageState.favorites);
        } else {
          stateSubject.add(MainPageState.noFavorites);
        }
      } else if (value.searchText.length < minSymbols) {
        stateSubject.add(MainPageState.minSymbols);
      } else {
        stateSubject.add(MainPageState.searchResults);
        searchForSuperheroes(value.searchText);
      }
    });
  }

  void retryLastQuery() {
    String currentText = currentTextSubject.value;
    searchForSuperheroes(currentText);
  }

  void searchForSuperheroes(final String text) {
    stateSubject.add(MainPageState.loading);
    searchSubscription = search(text).asStream().listen((searchResult) {
      if (searchResult.isEmpty) {
        stateSubject.add(MainPageState.nothingFound);
      } else {
        searchedSuperheroesSubject.add(searchResult);
        stateSubject.add(MainPageState.searchResults);
      }
    }, onError: (error, stackTrace) {
      if (error is ApiException) {
        print(error.message);
      }
      stateSubject.add(MainPageState.loadingError);
    });
  }

  Future<List<SuperheroInfo>> search(final String text) async {
    final token = dotenv.env["SUPERHERO_TOKEN"];
    final uri = "https://www.superheroapi.com/api/$token/search/$text";
    final response = await (client ??= http.Client())
        .get(Uri.parse(uri))
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw ApiException(message: "Timeout exception"));

    if (response.statusCode >= 500 && response.statusCode < 600) {
      throw ApiException(message: 'Server error happened');
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      throw ApiException(message: 'Client error happened');
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = json.decode(response.body);
      if (decoded["response"] == "success") {
        final List<dynamic> results = decoded["results"];
        final List<Superhero> superheroes = results.map((rawSuperhero) {
          return Superhero.fromJson(rawSuperhero);
        }).toList();
        final List<SuperheroInfo> found = superheroes.map((e) {
          return SuperheroInfo.fromSuperhero(e);
        }).toList();
        return found;
      } else if (decoded["response"] == "error") {
        if (decoded["error"] == "character with given name not found") {
          return [];
        }
        throw ApiException(message: 'Client error happened');
      }
    }
    throw Exception("Unknown error happened");
  }

  Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() {
    return FavoriteSuperheroesStorage.getInstance()
        .observeFavoriteSuperheroes()
        .map((superheroes) {
      return superheroes
          .map((superhero) => SuperheroInfo.fromSuperhero(superhero))
          .toList();
    });
  }

  /*
    Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() =>
      FavoriteSuperheroesStorage.getInstance().observeFavoriteSuperheroes().map(
          (superheroes) => superheroes
              .map((superhero) => SuperheroInfo.fromSuperhero(superhero))
              .toList());
   */

  Stream<List<SuperheroInfo>> observeSearchedSuperheroes() =>
      searchedSuperheroesSubject;

  Stream<MainPageState> observeMainPageState() => stateSubject;

  void nextState() {
    final currentState = stateSubject.value;
    final nextState = MainPageState.values[
        (MainPageState.values.indexOf(currentState) + 1) %
            MainPageState.values.length];
    stateSubject.add(nextState);
  }

  void updateText(final String? text) {
    currentTextSubject.add(text ?? "");
  }

  void dispose() {
    stateSubject.close();
    searchedSuperheroesSubject.close();
    currentTextSubject.close();

    textSubscription?.cancel();
    searchSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();

    client?.close();
    searchFocus.dispose();
  }

  void removeFromFavorites(final String id) {
    removeFromFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription = FavoriteSuperheroesStorage.getInstance()
        .removeFromFavorites(id)
        .asStream()
        .listen((event) {
      print("EVENT: removed from favorite $event");
    },
        onError: (error, stackTrace) => print(
            "Error happened in remove from favorites: $error, $stackTrace"));
  }
}

enum MainPageState {
  noFavorites,
  minSymbols,
  loading,
  nothingFound,
  loadingError,
  searchResults,
  favorites,
}

class SuperheroInfo {
  final String id;
  final String name;
  final String realName;
  final String imageUrl;
  final AlignmentInfo? alignmentInfo;

  const SuperheroInfo({
    required this.id,
    required this.name,
    required this.realName,
    required this.imageUrl,
    this.alignmentInfo
  });

  factory SuperheroInfo.fromSuperhero(final Superhero superhero) {
    return SuperheroInfo(
      id: superhero.id,
      name: superhero.name,
      realName: superhero.biography.fullName,
      imageUrl: superhero.image.url,
      alignmentInfo: superhero.biography.alignmentInfo,
    );
  }

  @override
  String toString() {
    return 'SuperheroInfo{id: $id, name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;
  static const mocked = [
    SuperheroInfo(
      id: "70",
      name: "Batman",
      realName: 'Bruce Wayne',
      imageUrl:
          'https://www.superherodb.com/pictures2/portraits/10/100/639.jpg',
    ),
    SuperheroInfo(
      id: "732",
      name: "Ironman",
      realName: 'Tony Stark',
      imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/85.jpg',
    ),
    SuperheroInfo(
      id: "687",
      name: "Venom",
      realName: 'Eddie Brock',
      imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/22.jpg',
    ),
  ];
}

class MainPageStateInfo {
  final String searchText;
  final bool haveFavorites;

  const MainPageStateInfo(this.searchText, this.haveFavorites);

  @override
  String toString() {
    return 'MainPageStateInfo{searchText: $searchText, haveFavorites: $haveFavorites}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageStateInfo &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          haveFavorites == other.haveFavorites;

  @override
  int get hashCode => searchText.hashCode ^ haveFavorites.hashCode;
}
