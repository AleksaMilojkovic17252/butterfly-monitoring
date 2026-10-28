/// Lower-cases [text] and drops the Serbian diacritics, so that "Smeđaš" and
/// "smedjas" compare equal. Used for the `taxon.searchText` column and for
/// what the observer types (T045).
///
/// `đ` becomes `dj`, so typing a plain "d" does not find it.
String searchTextOf(String text) {
  const replacements = {'č': 'c', 'ć': 'c', 'š': 's', 'ž': 'z', 'đ': 'dj'};
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

/// The text a taxon is searched by: its scientific, Serbian and English names
/// joined with spaces, run through [searchTextOf].
String taxonSearchText(String scientific, String sr, String en) {
  return searchTextOf('$scientific $sr $en');
}
