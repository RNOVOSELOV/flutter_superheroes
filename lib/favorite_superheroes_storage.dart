import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superheroes/model/superhero.dart';

class FavoriteSuperheroesStorage {
  static const _key = "favorite_superheroes";

  final updater = PublishSubject<Null>();

  FavoriteSuperheroesStorage._internal();

  static FavoriteSuperheroesStorage? instance;

  factory FavoriteSuperheroesStorage.getInstance() =>
      instance ??= FavoriteSuperheroesStorage._internal();

  Future<bool> addToFavorites(final Superhero superhero) async {
    final rawSupergeroes = await _getRawSuperheroes();
    rawSupergeroes.add(json.encode(superhero.toJson()));
    return _setRawSuperheroes(rawSupergeroes);
  }

  Future<bool> removeFromFavorites(final String id) async {
    final supergeroes = await _getSuperheroes();
    supergeroes.removeWhere((element) => element.id == id);
    return _setSuperheroes(supergeroes);
  }

  Future<List<Superhero>> _getSuperheroes() async {
    final rawSupergeroes = await _getRawSuperheroes();
    return rawSupergeroes
        .map((element) => Superhero.fromJson(json.decode(element)))
        .toList();
  }

  Future<bool> _setSuperheroes(final List<Superhero> superhero) async {
    final superheroes = superhero.map((e) => json.encode(e.toJson())).toList();
    return _setRawSuperheroes(superheroes);
  }

  Future<List<String>> _getRawSuperheroes() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_key) ?? [];
  }

  Future<bool> _setRawSuperheroes(final List<String> rawSupergeroes) async {
    final sp = await SharedPreferences.getInstance();
    final result = sp.setStringList(_key, rawSupergeroes);
    updater.add(null);
    return result;
  }

  Future<Superhero?> getSuperhero(final String id) async {
    final superheroes = await _getSuperheroes();
    for (final superhero in superheroes) {
      if (superhero.id == id) {
        return superhero;
      }
    }
    return null;
  }

  Stream<List<Superhero>> observeFavoriteSuperheroes() async* {
    yield await _getSuperheroes();
    await for (final _ in updater) {
      yield await _getSuperheroes();
    }
  }

  Stream<bool> observeIsFavorite(final String id) {
    return observeFavoriteSuperheroes().map(
        (superheroes) => superheroes.any((superhero) => superhero.id == id));
  }

  Future<bool> updateInfavorites(final Superhero superhero) async {
    final superheroes = await _getSuperheroes();
    final index =
        superheroes.indexWhere((element) => element.id == superhero.id);
    if (index == -1) return false;
    superheroes[index] = superhero;
    return _setSuperheroes(superheroes);
  }
}
