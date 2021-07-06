import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';

class MainPage extends StatefulWidget {
  MainPage({
    Key? key,
  }) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MainBloc bloc = MainBloc();

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
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
  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);
    return Stack(
      children: [
        MainPageStateWidget(),
        // ;
        //
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: ActionButton(
              text: "Next state",
              onTap: () {
                bloc.nextState();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MainPageStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);
    return StreamBuilder<MainPageState>(
      stream: bloc.observeMainPageState(),
      builder: (BuildContext context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox();
        }
        final MainPageState state = snapshot.data!;
        switch (state) {
          case MainPageState.loading:
            return LoadingIndicator();
          case MainPageState.noFavorites:
            return NoFavoritesPage();
          case MainPageState.minSymbols:
            return MinSymbolsPage();
          case MainPageState.nothingFound:
          case MainPageState.loadingError:
          case MainPageState.searchResults:
            return SearchResultPage();
          case MainPageState.favorites:
            return YourFavoritesPage();
          default:
            return Center(
                child: Text(
              snapshot.data!.toString(),
              style: TextStyle(color: Colors.white),
            ));
        }
      },
    );
  }
}

class SearchResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 90,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Search results",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(name: 'Batman',
            realName: 'Bruce Wayne',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/639.jpg',
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: SuperheroCard(name: 'Venom',
              realName: 'Eddie Brock',
              imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/22.jpg.',
            )
        ),

      ],
    );
  }
}

class YourFavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 90,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Your favorites",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(name: 'Batman',
            realName: 'Bruce Wayne',
            imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/639.jpg',
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: SuperheroCard(name: 'Ironman',
              realName: 'Tony Stark',
              imageUrl: 'https://www.superherodb.com/pictures2/portraits/10/100/85.jpg',
            )
        ),

      ],
    );
  }
}


class NoFavoritesPage extends StatelessWidget {
  const NoFavoritesPage({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SuperheroesColors.blue,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 9),
                    child: Image.asset(
                      SuperheroesImages.ironman,
                      height: 119,
                      width: 108,
                      //fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "No favorites yet",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "SEARCH AND ADD",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 30,
              ),
              ActionButton(
                text: "Search",
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MinSymbolsPage extends StatelessWidget {
  const MinSymbolsPage({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: 110,
          left: 16,
          right: 16,
        ),
        child: Text(
          "Enter at least 3 symbols",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: CircularProgressIndicator(
          color: SuperheroesColors.blue,
          strokeWidth: 4,
        ),
      ),
    );
  }
}
