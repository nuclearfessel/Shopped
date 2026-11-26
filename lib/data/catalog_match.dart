// Predictive catalog / suggestion matching: every typed word must appear
// somewhere in the candidate (order does not matter). Light stemming and
// single-edit typos are allowed so "tomatoe", "potatos", and "onins" still hit.

/// Lowercase whitespace tokens; strips LIKE wildcards so callers can embed
/// tokens in SQL safely.
List<String> catalogTokens(String query) {
  final cleaned = query.trim().toLowerCase().replaceAll(RegExp(r'[%_\\]'), '');
  if (cleaned.isEmpty) return const [];
  return [
    for (final part in cleaned.split(RegExp(r'\s+')))
      if (part.isNotEmpty) part,
  ];
}

/// Crude English plural stem for grocery words (tomatoes → tomato).
String catalogStem(String token) {
  final t = token.toLowerCase();
  if (t.length < 4) return t;
  if (t.endsWith('ies') && t.length >= 5) {
    return '${t.substring(0, t.length - 3)}y';
  }
  if (t.endsWith('ses') ||
      t.endsWith('xes') ||
      t.endsWith('zes') ||
      t.endsWith('ches') ||
      t.endsWith('shes')) {
    return t.substring(0, t.length - 2);
  }
  if (t.endsWith('oes') && t.length >= 5) {
    return t.substring(0, t.length - 2);
  }
  if (t.endsWith('s') && !t.endsWith('ss')) {
    return t.substring(0, t.length - 1);
  }
  return t;
}

/// Forms used to broaden SQL LIKE candidate fetch for one typed token.
List<String> catalogSearchForms(String token) {
  final t = token.toLowerCase();
  final forms = <String>{t};
  final stem = catalogStem(t);
  if (stem.isNotEmpty) forms.add(stem);
  // Drop the last character so a one-letter typo still finds candidates.
  if (t.length >= 4) forms.add(t.substring(0, t.length - 1));
  if (stem.length >= 4) forms.add(stem.substring(0, stem.length - 1));
  return [for (final f in forms) if (f.isNotEmpty) f];
}

/// True when [a] and [b] are equal or one edit (insert/delete/substitute) apart.
bool withinOneEdit(String a, String b) {
  if (a == b) return true;
  final la = a.length;
  final lb = b.length;
  if ((la - lb).abs() > 1) return false;
  if (la > lb) return withinOneEdit(b, a);
  // la <= lb; at most one insert or substitute.
  var i = 0;
  var j = 0;
  var edits = 0;
  while (i < la && j < lb) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    edits++;
    if (edits > 1) return false;
    if (la == lb) {
      i++;
      j++;
    } else {
      j++; // insert into a / delete from b
    }
  }
  if (j < lb || i < la) edits++;
  return edits <= 1;
}

bool _tokenMatchesHaystack(String haystack, String token) {
  if (haystack.contains(token)) return true;
  final stem = catalogStem(token);
  if (stem != token && haystack.contains(stem)) return true;

  for (final raw in haystack.split(RegExp(r'[^a-z0-9]+'))) {
    if (raw.isEmpty) continue;
    if (raw == token || raw == stem) return true;
    final wordStem = catalogStem(raw);
    if (wordStem == token || wordStem == stem) return true;
    if (token.length >= 4 && raw.length >= 3 && withinOneEdit(raw, token)) {
      return true;
    }
    if (stem.length >= 4 &&
        wordStem.length >= 3 &&
        withinOneEdit(wordStem, stem)) {
      return true;
    }
  }
  return false;
}

/// True when every [tokens] entry is found in [haystack] (substring, stem, or
/// one-edit typo on a word). Comparison is case-insensitive.
bool matchesAllTokens(String haystack, List<String> tokens) {
  if (tokens.isEmpty) return false;
  final h = haystack.toLowerCase();
  for (final t in tokens) {
    if (!_tokenMatchesHaystack(h, t.toLowerCase())) return false;
  }
  return true;
}

/// Sort key: lower is better. Prefers prefix of first token, then a word
/// that starts with the first token, then alphabetical name.
int catalogMatchScore(String name, List<String> tokens) {
  if (tokens.isEmpty) return 1 << 20;
  final n = name.toLowerCase();
  final first = tokens.first;
  final firstStem = catalogStem(first);
  var score = 0;
  if (n.startsWith(first) || n.startsWith(firstStem)) {
    score += 0;
  } else if (n.contains(' $first') || n.contains(' $firstStem')) {
    score += 100;
  } else {
    score += 200;
  }
  // Prefer shorter names when equally matched (tighter fit).
  score += n.length;
  // Prefer exact/stem hits over fuzzy-only matches.
  if (!n.contains(first) && !n.contains(firstStem)) {
    score += 50;
  }
  return score;
}

/// Compare two names for ranking under [tokens] (then A–Z).
int compareCatalogMatches(String a, String b, List<String> tokens) {
  final byScore = catalogMatchScore(
    a,
    tokens,
  ).compareTo(catalogMatchScore(b, tokens));
  if (byScore != 0) return byScore;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Token bags are equal ignoring order (and duplicate counts must match).
bool sameTokenBag(String a, String b) {
  final ta = catalogTokens(a)..sort();
  final tb = catalogTokens(b)..sort();
  if (ta.length != tb.length) return false;
  for (var i = 0; i < ta.length; i++) {
    if (ta[i] != tb[i]) return false;
  }
  return true;
}
