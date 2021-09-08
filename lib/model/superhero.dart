import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/model/server_image.dart';

import 'biography.dart';

import 'package:json_annotation/json_annotation.dart';

part 'superhero.g.dart';

@JsonSerializable()



class Superhero {
  final Powerstats powerstats;
  final String id;
  final String name;
  final Biography biography;
  final ServerImage image;


  @override
  String toString() {
    return 'Superhero{powerstats: $powerstats, id: $id, name: $name, biography: $biography, image: $image}';
  }

  Superhero({required this.id, required this.name, required this.biography, required this.image, required this.powerstats,}) ;

  factory Superhero.fromJson(final Map<String, dynamic> json) => _$SuperheroFromJson(json);
  Map<String, dynamic> toJson() => _$SuperheroToJson(this);
}
