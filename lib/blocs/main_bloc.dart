import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/api_exception.dart';
import 'package:superheroes/favorite_superheroes_storage.dart';
import 'package:superheroes/model/alignment_info.dart';
import 'package:superheroes/model/superhero.dart';

class MainBloc {
  static const minSymbols = 3;
  bool changedText = false;
  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();

  final searchedSuperheroesSubject =
      BehaviorSubject<List<SuperheroInfo>>(); // проверить
  final currentTextSubject = BehaviorSubject<String>.seeded("");

  StreamSubscription? textSubscribtion;
  StreamSubscription? searchSubscribtion;
  StreamSubscription? removeFromFavoriteSubscription;

  http.Client? client;

  MainBloc({this.client}) {
        textSubscribtion =
        Rx.combineLatest2<String, List<Superhero>, MainPageStateInfo>(
      currentTextSubject.distinct().debounceTime(Duration(milliseconds: 500)),
      FavoriteSuperheroesStorage.getInstance().observeFavoriteSuperheroes(),
      (searchedText, favorites) =>
          MainPageStateInfo(searchedText, favorites.isNotEmpty),
    ).listen((value) {
      print("CHANGED $value");

      searchSubscribtion?.cancel();
      if (value.searchText.isEmpty) {
        if (value.haveFavorites) {
          stateSubject.add(MainPageState.favorites);
        } else {
          stateSubject.add(MainPageState.noFavorites);
        }
        changedText = false;
      } else if (value.searchText.length < minSymbols) {
        stateSubject.add(MainPageState.minSymbols);
      } else {
        searchForSuperheroes(value.searchText);
      }
    });
  }
  void searchForSuperheroes(final String text) {
    stateSubject.add(MainPageState.loading);
    searchSubscribtion = search(text).asStream().listen(
      (searchResults) {
        if (searchResults.isEmpty) {
          stateSubject.add(MainPageState.nothingFound);
        } else {
          searchedSuperheroesSubject.add(searchResults);
          stateSubject.add(MainPageState.searchResults);
        }
      },
      onError: (error, stackTrace) {
        stateSubject.add(MainPageState.loadingError);
      },
    );
  }

  Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() {
     return FavoriteSuperheroesStorage.getInstance().observeFavoriteSuperheroes().map((superheroes){
       return superheroes.map((superhero) =>
         SuperheroInfo.fromSuperhero(superhero)).toList();});
     }

  Stream<List<SuperheroInfo>> observedSearchedSuperheroes() =>
      searchedSuperheroesSubject;
  Stream<String> observedCurrentTextSubject() => currentTextSubject;

  Future<List<SuperheroInfo>> search(final String text) async {
    // await Future.delayed(Duration(seconds: 1));
    final token = dotenv.env["SUPERHERO_TOKEN"];

    final response = await (client ??= http.Client())
        .get(Uri.parse("https://superheroapi.com/api/$token/search/$text"));
    final decoded = json.decode(response.body);
    print(response.statusCode);
    if (response.statusCode >= 500) {
      throw ApiException("Server error happened");
    } else if (response.statusCode < 500 && response.statusCode >= 400) {
      throw ApiException("Client error happened");
    } else if (decoded['response'] == 'success') {
      print("OK");
      final List<dynamic> results = decoded['results'];
      final List<Superhero> superheroes = results
          .map((rawSuperhero) => Superhero.fromJson(rawSuperhero))
          .toList();

      final List<SuperheroInfo> found = superheroes.map((superhero) {
        return SuperheroInfo.fromSuperhero(superhero);
      }).toList();
      return found;
    } else if (decoded['response'] == 'error') {
      if (decoded['error'] == 'character with given name not found') {
        return [];
      } else if (decoded['error'] != 'character with given name not found') {
        throw ApiException("Client error happened");
      }
    }

    throw Exception("Unknow error happened");

    //     "response": "error",
    //     "error": "character with given name not found"
    // }
  }

  Stream<MainPageState> observeMainPageState() => stateSubject;

  void  removeFromFavorites(final String id){
    removeFromFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription = FavoriteSuperheroesStorage.getInstance()
        .removeFromFavorites(id).asStream().listen((event) {
      print("Removed from favorites: $event");

    }
        ,
        onError: (error, stackTrace) =>
            print("Error happened in removeFromFavorites: $error, $stackTrace"));


  }


  void retry() {
    search(currentTextSubject.value);
    print("RETRY: ${currentTextSubject.value}");
    searchForSuperheroes(currentTextSubject.value);
  }


  void updateText(final String? text) {
    var previousTextSubject = currentTextSubject.value;
    currentTextSubject.add(text ?? "");
    if (previousTextSubject.length != currentTextSubject.value.length &&
        (previousTextSubject == "" || currentTextSubject.value == "")) {
      changedText = true;
    } else
      changedText = false;
  }

  void dispose() {
    stateSubject.close();
    searchedSuperheroesSubject.close();
    currentTextSubject.close();
    searchSubscribtion?.cancel();
    textSubscribtion?.cancel();
    removeFromFavoriteSubscription?.cancel();
    client?.close();
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
    this.alignmentInfo,
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
  static const List<SuperheroInfo> mocked1 = [];

}

class MainPageStateInfo {
  final String searchText;
  final bool haveFavorites;

  const MainPageStateInfo(this.searchText, this.haveFavorites);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageStateInfo &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          haveFavorites == other.haveFavorites;

  @override
  int get hashCode => searchText.hashCode ^ haveFavorites.hashCode;

  @override
  String toString() {
    return 'MainPfenuageStateInfo{searchText: $searchText, haveFavorites: $haveFavorites}';
  }
}
