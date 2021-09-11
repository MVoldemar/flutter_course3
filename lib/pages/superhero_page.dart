import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/superhero_bloc.dart';
import 'package:superheroes/model/biography.dart';
import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/model/superhero.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/resources/superheroes_icons.dart';
import 'package:superheroes/resources/superheroes_images.dart';

class SuperheroPage extends StatefulWidget {
  final http.Client? client;
  final String id;

  SuperheroPage({
    Key? key,
    this.client,
    required this.id,
  }) : super(key: key);

  @override
  _SuperheroPageState createState() => _SuperheroPageState();
}

class _SuperheroPageState extends State<SuperheroPage> {
  late SuperheroBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = SuperheroBloc(client: widget.client, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SuperheroContentPage(),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class SuperheroContentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SuperheroBloc>(context, listen: false);
    return StreamBuilder<Superhero>(
      stream: bloc.observeSuperhero(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        print("К нам пришли данные");
        final superhero = snapshot.data!;
        return CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SuperheroAppBar(superhero: superhero),
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  if (superhero.powerstats.isNotNull())
                    PowerstatsWidget(powerstats: superhero.powerstats),
                  BiographyWidget(biography: superhero.biography),
                  const SizedBox(height: 30,),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}

class PowerstatsWidget extends StatelessWidget {
  final Powerstats powerstats;
  const PowerstatsWidget({Key? key, required this.powerstats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            "Poverstats".toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                value: powerstats.intelligencePercent,
                name: "Intelligence",
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                value: powerstats.strengthPercent,
                name: "Strength",
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                value: powerstats.speedPercent,
                name: "Speed",
              ),
            )),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                value: powerstats.durabilityPercent,
                name: "Durability",
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                value: powerstats.powerPercent,
                name: "Power",
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                value: powerstats.combatPercent,
                name: "Combat",
              ),
            )),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        const SizedBox(
          height: 36,
        ),
      ],
    );
  }
}

class PowerstatWidget extends StatelessWidget {
  final String name;
  final double value;
  const PowerstatWidget({
    Key? key,
    required this.name,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ArcWidget(value: value, color: calculateColorByValue()),
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: Text(
            "${(value * 100).toInt()}",
            style: TextStyle(
              color: calculateColorByValue(),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Text(
            name.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Color calculateColorByValue() {
    if (value <= 0.5) {
      return Color.lerp(Colors.red, Colors.orangeAccent, value / 0.5)!;
    } else {
      return Color.lerp(
          Colors.orangeAccent, Colors.green, (value - 0.5) / 0.5)!;
    }
  }
}

class ArcWidget extends StatelessWidget {
  final double value;
  final Color color;

  const ArcWidget({Key? key, required this.value, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArcCustomPainter(value, color),
      size: Size(66, 33),
    );
  }
}

class ArcCustomPainter extends CustomPainter {
  final double value;
  final Color color;

  ArcCustomPainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final backgroundPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawArc(rect, pi, pi, false, backgroundPaint);
    canvas.drawArc(rect, pi, pi * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ArcCustomPainter) {
      return oldDelegate.value != value && oldDelegate.color != color;
    }
    return true;
  }
}

class BiographyWidget extends StatelessWidget {
  final Biography biography;
  const BiographyWidget({Key? key, required this.biography}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          color: SuperheroesColors.indigo,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
        ),
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Bio".toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              "Full Name".toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SuperheroesColors.greyBio,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              biography.fullName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Aliases".toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SuperheroesColors.greyBio,
              ),
            ),
            Text(
              biography.aliases.join(", "),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Place of birth".toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SuperheroesColors.greyBio,
              ),
            ),
            Text(
              biography.placeOfBirth,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        // child:
      ),

      if(biography.alignmentInfo != null )
        Align(
        alignment: Alignment.topRight,
        child: Container(
          alignment: Alignment.center,
          child: RotatedBox(
            quarterTurns: 1,
            child: Text(
              biography.alignment.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
               color: Colors.white,
              ),
            ),
          ),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
          ),
          height: 70,
          width: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            color: biography.alignmentInfo!.color,
          ),
        ),
      )
    ]);
  }
}

class SuperheroAppBar extends StatelessWidget {
  const SuperheroAppBar({
    Key? key,
    required this.superhero,
  }) : super(key: key);

  final Superhero superhero;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      pinned: true,
      floating: true,
      expandedHeight: 348,
      actions: [
        FavoriteButton(),
      ],
      backgroundColor: SuperheroesColors.background,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          superhero.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        background: CachedNetworkImage(
          placeholder: (context, error) =>
              ColoredBox(color: SuperheroesColors.indigo),
          errorWidget: (context, url, error) => Container(
            alignment: Alignment.center,
            color: SuperheroesColors.indigo,
            child: Image.asset(SuperheroesImages.unknown_big,
              width: 85,
              height: 264,),
          ),
          imageUrl: superhero.image.url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SuperheroBloc>(context, listen: false);
    return StreamBuilder<bool>(
        stream: bloc.observeIsFavorite(),
        initialData: false,
        builder: (context, snapshot) {
          final favorite =
              !snapshot.hasData || snapshot.data == null || snapshot.data!;
          return GestureDetector(
            //  bloc.superheroStateSubject
            onTap: () => favorite ? bloc.removeFromFavorites() : bloc.addToFavorite(),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: Image.asset(
                favorite
                    ? SuperheroesIcons.starFilled
                    : SuperheroesIcons.starEmpty,
                height: 32,
                width: 32,
              ),
            ),
          );
        });
  }
}
