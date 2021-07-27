import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/model/server_image.dart';

import 'biography.dart';

import 'package:json_annotation/json_annotation.dart';

part 'superhero.g.dart';

@JsonSerializable(fieldRename: FieldRename.kebab, explicitToJson: true)



class Superhero {
  final Powerstats powerstats;
  final String id;
  final String name;
  final Biography biography;
  final ServerImage image;

  Superhero(this.name, this.biography, this.image, this.powerstats, this.id);

  factory Superhero.fromJson(final Map<String, dynamic> json) => _$SuperheroFromJson(json);
  Map<String, dynamic> toJson() => _$SuperheroToJson(this);
}
