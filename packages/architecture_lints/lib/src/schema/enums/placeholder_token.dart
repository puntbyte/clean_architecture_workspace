import 'package:architecture_lints/src/utils/token_syntax.dart';
import 'package:collection/collection.dart';

enum PlaceholderToken {
  name('the Name'),
  affix('the Prefix or Suffix'),
  ;

  final String description;

  const PlaceholderToken(this.description);

  static PlaceholderToken? fromString(String template) {
    return PlaceholderToken.values.firstWhereOrNull((token) => token.template == template);
  }

  String get template => switch(this) {
    PlaceholderToken.name => TokenSyntax.wrap('name'),
    PlaceholderToken.affix => TokenSyntax.wrap('affix'),
  };

  bool isPresentIn(String configString) => configString.contains(template);
}
