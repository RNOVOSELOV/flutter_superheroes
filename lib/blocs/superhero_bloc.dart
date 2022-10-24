import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:superheroes/exception/api_exception.dart';
import 'package:superheroes/favorite_superheroes_storage.dart';
import 'package:superheroes/model/superhero.dart';

class SuperheroBlock {
  http.Client? client;
  final String id;

  final superheroSubject = BehaviorSubject<Superhero>();

  StreamSubscription? requestSubscription;
  StreamSubscription? getFromFavoritesSubscription;
  StreamSubscription? addToFavoriteSubscription;
  StreamSubscription? removeFromFavoriteSubscription;

  SuperheroBlock({required this.id, this.client}) {
    getFromFavorites();
  }

  void getFromFavorites () {
    getFromFavoritesSubscription?.cancel();
    getFromFavoritesSubscription = FavoriteSuperheroesStorage.getInstance()
        .getSuperhero(id)
        .asStream()
        .listen((superhero) {
        if (superhero != null) {
          superheroSubject.add(superhero);
        }
        requestSuperhero();
    },
        onError: (error, stackTrace) => print(
            "Error happened in get from favorites: $error, $stackTrace"));
  }

  void addToFavorite() {
    final superhero = superheroSubject.valueOrNull;
    if (superhero == null) {
      print("ERROR: addToFavorite(). Superhero is NULL while shouldn't be.");
      return;
    }

    addToFavoriteSubscription?.cancel();
    addToFavoriteSubscription = FavoriteSuperheroesStorage.getInstance()
        .addToFavorites(superhero)
        .asStream()
        .listen((event) {
      print("EVENT: added to favorite $event");
    },
            onError: (error, stackTrace) => print(
                "Error happened in add to favorite: $error, $stackTrace"));
  }

  void removeFromFavorite() {
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

  Stream<bool> observeIsFavorite() =>
      FavoriteSuperheroesStorage.getInstance().observeIsFavorite(id);

  void requestSuperhero() {
    requestSubscription?.cancel();
    requestSubscription = request().asStream().listen((superhero) {
      superheroSubject.add(superhero);
    }, onError: (error, stackTrace) {
      if (error is ApiException) {
        print(error.message);
      }
      print("Error happened in requestSuperhero: $error $stackTrace");
    });
  }

  Future<Superhero> request() async {
    final token = dotenv.env["SUPERHERO_TOKEN"];
    final uri = "https://www.superheroapi.com/api/$token/$id";
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
        Superhero superhero = Superhero.fromJson(decoded);
        return superhero;
      } else if (decoded["response"] == "error") {
        throw ApiException(message: 'Client error happened');
      }
    }
    throw Exception("Unknown error happened");
  }

  Stream<Superhero> observeSuperhero() => superheroSubject;

  void dispose() {
    client?.close();
    requestSubscription?.cancel();
    getFromFavoritesSubscription?.cancel();
    addToFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();
    superheroSubject.close();
  }
}
