import 'package:flutter_test/flutter_test.dart';
import 'package:shopped/data/catalog_match.dart';

void main() {
  test('catalogTokens splits on whitespace and strips LIKE wildcards', () {
    expect(catalogTokens('  Almond   milk '), ['almond', 'milk']);
    expect(catalogTokens('a%b_c\\d'), ['abcd']);
    expect(catalogTokens('   '), isEmpty);
  });

  test('matchesAllTokens requires every word in any order', () {
    expect(matchesAllTokens('Almond milk', ['almond', 'milk']), isTrue);
    expect(matchesAllTokens('Unsweetened almond milk', ['milk', 'almond']), isTrue);
    expect(matchesAllTokens('Almond milk', ['almond', 'oat']), isFalse);
    expect(matchesAllTokens('Milk', ['almond', 'milk']), isFalse);
  });

  test('matchesAllTokens accepts plurals and one-edit typos', () {
    expect(matchesAllTokens('Sweet potatoes', ['sweet', 'potato']), isTrue);
    expect(matchesAllTokens('Chicken breasts', ['chicken', 'breast']), isTrue);
    expect(matchesAllTokens('Red onions', ['red', 'onion']), isTrue);
    expect(matchesAllTokens('Almond milk', ['almod', 'milk']), isTrue);
    expect(matchesAllTokens('Almond milk', ['almnd', 'milk']), isTrue);
    expect(matchesAllTokens('Almond milk', ['xyzzy', 'milk']), isFalse);
  });

  test('catalogStem strips common grocery plurals', () {
    expect(catalogStem('tomatoes'), 'tomato');
    expect(catalogStem('potatoes'), 'potato');
    expect(catalogStem('breasts'), 'breast');
    expect(catalogStem('milk'), 'milk');
  });

  test('sameTokenBag ignores order', () {
    expect(sameTokenBag('almond milk', 'milk almond'), isTrue);
    expect(sameTokenBag('almond milk', 'almond oat milk'), isFalse);
  });

  test('compareCatalogMatches prefers prefix of the first token', () {
    final tokens = ['milk', 'almond'];
    expect(
      compareCatalogMatches('Milk almond', 'Unsweetened almond milk', tokens),
      lessThan(0),
    );
  });
}
