// 📦 Package imports:
import 'package:fuzzy/fuzzy.dart';

// 🌎 Project imports:
import '../util/utility.dart';

final defaultFuzzyOption = FuzzyOptions(findAllMatches: true, tokenize: true, threshold: 0.5);

/// Interface to provide searchable properties
abstract class Searchable {
  /// <{property_name}, List<{property_reference}>>, property must be string or Iterable<String>
  Map<String, dynamic> get searchableProperties;
}

extension SearchableUtil on Searchable {
  /// Detect if a Searchable contains key fuzzily
  bool containsFuzzy(String key, {Iterable<String> searchPropertiesEnable, FuzzyOptions options}) {
    options ??= defaultFuzzyOption;
    var match = false;
    searchPropertiesEnable ??= searchableProperties.keys;
    for (final p in searchPropertiesEnable) {
      final property = searchableProperties[p];
      if (property is String &&
          property.containsFuzzy(key, options: options)) {
        match = true;
        break;
      } else if (property is Iterable<String> &&
          property.containsFuzzy(key, options: options)) {
        match = true;
        break;
      }
    }
    return match;
  }
}

extension SearchableListUtil on Iterable<Searchable> {
  /// Fuzzy search a list of Searchable by keyword, options can be provided
  List<T> searchFuzzy<T extends Searchable>(String key, {FuzzyOptions options}) {
    return where((item) => item.containsFuzzy(key, options: options)).toList();
  }
}
