import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/model/superhero.dart';

class MainBloc {
  static const minSymbols = 3;
  bool changedText = false;
  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();
  final favoriteSuperheroesSubject =
      BehaviorSubject<List<SuperheroInfo>>.seeded(SuperheroInfo.mocked);

  final searchedSuperheroesSubject =
      BehaviorSubject<List<SuperheroInfo>>(); // проверить
  final currentTextSubject = BehaviorSubject<String>.seeded("");

  StreamSubscription? textSubscribtion;
  StreamSubscription? searchSubscribtion;

  http.Client? client;

  MainBloc({this.client}) {
    stateSubject.add(MainPageState.noFavorites);

    textSubscribtion =
        Rx.combineLatest2<String, List<SuperheroInfo>, MainPageStateInfo>(
      currentTextSubject.distinct().debounceTime(Duration(milliseconds: 500)),
      favoriteSuperheroesSubject,
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

  Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() =>
      favoriteSuperheroesSubject;
  Stream<List<SuperheroInfo>> observedSearchedSuperheroes() =>
      searchedSuperheroesSubject;
  Stream<String> observedCurrentTextSubject() => currentTextSubject;

  Future<List<SuperheroInfo>> search(final String text) async {
    // await Future.delayed(Duration(seconds: 1));
    final token = dotenv.env["SUPERHERO_TOKEN"];
    final response = await (client ??=http.Client())
        .get(Uri.parse("https://superheroapi.com/api/$token/search/$text"));
    final decoded = json.decode(response.body);
    print(decoded);
    if (decoded['response'] == 'success') {
      final List<dynamic> results = decoded['results'];
      final List<Superhero> superheroes = results.map((rawSuperhero) =>
          Superhero.fromJson(rawSuperhero)).toList();

      final List<SuperheroInfo> found = superheroes.map((superhero) {
        return SuperheroInfo(
          name: superhero.name,
          realName: superhero.biography.fullName,
          imageUrl: superhero.image.url,
        );
      }).toList();
      return found;
    }
    else if(decoded['response'] == 'error'){
      if(decoded['error'] == 'character with given name not found'){
        return [];
      }
    }
    throw Exception("Unknow error happened");
    //{

    //     "response": "error",
    //     "error": "character with given name not found"
    // }


  }

  Stream<MainPageState> observeMainPageState() => stateSubject;

  void nextState() {
    final currentState = stateSubject.value;
    final nextState = MainPageState.values[
        (MainPageState.values.indexOf(currentState) + 1) %
            MainPageState.values.length];
    stateSubject.add(nextState);
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

  void removeFavorite() {
    print("Remove");
    if (favoriteSuperheroesSubject.value.length == 0 ||
        !favoriteSuperheroesSubject.hasValue) {
      favoriteSuperheroesSubject.add(SuperheroInfo.mocked);
    } else {
      List<SuperheroInfo> newList =
          List<SuperheroInfo>.from(favoriteSuperheroesSubject.value);
      newList.removeLast();
      favoriteSuperheroesSubject.add(newList);
    }
  }

  void dispose() {
    stateSubject.close();
    favoriteSuperheroesSubject.close();
    searchedSuperheroesSubject.close();
    currentTextSubject.close();

    textSubscribtion?.cancel();
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
  final String name;
  final String realName;
  final String imageUrl;

  const SuperheroInfo({
    required this.name,
    required this.realName,
    required this.imageUrl,
  });

  @override
  String toString() {
    return 'SuperHeroInfo{name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;

  static const List<SuperheroInfo> mocked1 = [];

  static const mocked = [
    SuperheroInfo(
      name: "Batman",
      realName: "Bruce Wayne",
      imageUrl:
          "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg",
    ),
    SuperheroInfo(
      name: "Ironman",
      realName: "Tony Stark",
      imageUrl: "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg",
    ),
    SuperheroInfo(
      name: "Venom",
      realName: "Eddie Brock",
      imageUrl: "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg",
    ),
  ];
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
    return 'MainPageStateInfo{searchText: $searchText, haveFavorites: $haveFavorites}';
  }
}
