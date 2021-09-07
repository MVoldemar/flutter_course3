import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superheroes/model/superhero.dart';

class FavoriteSuperheroesStorage {
  static const _key = "favorite_superheroes";

  static FavoriteSuperheroesStorage? _instance;
    
  factory FavoriteSuperheroesStorage.getInstance() => _instance ??= FavoriteSuperheroesStorage._internal();
  
  FavoriteSuperheroesStorage._internal();

  final updater = PublishSubject<Null>();

  Future<bool> addToFavorites(final Superhero superhero) async {
    final rawSuperheroes = await _getRawSuperheroes();
    rawSuperheroes.add(json.encode(superhero.toJson()));
    return _setRawSuperheroes(rawSuperheroes);
  }

  Future<bool> removeFromFavorites(final String id) async {
    final superheroes = await _getSuperheroes();
    superheroes.removeWhere((superhero) => superhero.id == id);
    return _setSuperheroes(superheroes);
  }

  Future<bool> replaceToFavorites(final Superhero superhero) async {//передали супергероя из API
    final rawSuperheroes = await _getRawSuperheroes();//получили список супергероев из хранилища
    final rawSuperhero = await getSuperhero(superhero.id);//получили супергероя из хранилища
    print("Проверяем, если ли сырой супергерой у нас в хранилище");
    if(rawSuperhero != null){
      int indexToReplace = rawSuperheroes.indexWhere((element) =>
      element == json.encode(rawSuperhero.toJson()));//нашли индекс элемента в списке сырых супергероев
      rawSuperheroes[indexToReplace] = json.encode(superhero.toJson());
      print("Метод замены супергероя по индексу ${rawSuperheroes[indexToReplace]}");
    }
    return _setRawSuperheroes(rawSuperheroes);

  }

  Future<List<String>> _getRawSuperheroes() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_key) ?? [];
  }

  Future<bool>  _setRawSuperheroes(final List<String> rawSuperheroes) async {
    final sp = await SharedPreferences.getInstance();
    final result = sp.setStringList(_key, rawSuperheroes);
    updater.add(null);
    return result;
  }

  Future<List<Superhero>> _getSuperheroes() async {
    final rawSuperheroes = await _getRawSuperheroes();
    return rawSuperheroes
        .map((rawSuperhero) => Superhero.fromJson(json.decode(rawSuperhero)))
        .toList();
  }

  Future<bool> _setSuperheroes(final List<Superhero> superheroes) {
    final rawSuperheroes = superheroes
        .map((superhero) => json.encode(superhero.toJson()))
        .toList();
    return _setRawSuperheroes(rawSuperheroes);
  }

  Future<Superhero?> getSuperhero(final String id) async {
    final superheroes = await _getSuperheroes();
    for(final superhero in superheroes){
      if(superhero.id == id) {
        return superhero;
      }
    }
    return null;
  }


  Stream<List<Superhero>> observeFavoriteSuperheroes() async* {
    yield await _getSuperheroes();
    await for(final _ in updater){
      yield await _getSuperheroes();
    }
  }

  Stream<bool> observeIsFavorite(final String id) {
    return observeFavoriteSuperheroes().map((superheroes)
    => superheroes.any((superhero) => superhero.id == id));
  }
}
