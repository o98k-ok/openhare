class _SqlToken {
  final String text;
  final _SqlTokenType type;

  const _SqlToken(this.text, this.type);

  bool get isWord => type == _SqlTokenType.word;
}

enum _SqlTokenType {
  word,
  symbol,
  string,
  comment,
  other,
}

const Set<String> _singleWordUpperKeywords = {
  'SELECT',
  'FROM',
  'WHERE',
  'HAVING',
  'LIMIT',
  'OFFSET',
  'VALUES',
  'SET',
  'UPDATE',
  'INSERT',
  'INTO',
  'DELETE',
  'UNION',
  'JOIN',
  'INNER',
  'LEFT',
  'RIGHT',
  'FULL',
  'OUTER',
  'CROSS',
  'ON',
  'AND',
  'OR',
  'AS',
  'DISTINCT',
  'CASE',
  'WHEN',
  'THEN',
  'ELSE',
  'END',
  'WITH',
  'BY',
  'GROUP',
  'ORDER',
};

const Set<String> _majorClauses = {
  'SELECT',
  'FROM',
  'WHERE',
  'GROUP BY',
  'ORDER BY',
  'HAVING',
  'LIMIT',
  'OFFSET',
  'VALUES',
  'SET',
  'INSERT INTO',
  'UPDATE',
  'DELETE FROM',
  'UNION',
  'UNION ALL',
  'WITH',
};

const Set<String> _joinClauses = {
  'JOIN',
  'INNER JOIN',
  'LEFT JOIN',
  'RIGHT JOIN',
  'FULL JOIN',
  'LEFT OUTER JOIN',
  'RIGHT OUTER JOIN',
  'FULL OUTER JOIN',
  'CROSS JOIN',
  'ON',
};

String formatSelectedSql(String sql) {
  final input = sql.trim();
  if (input.isEmpty) return sql;

  final tokens = _tokenizeSql(input);
  if (tokens.isEmpty) return input;

  final lines = <String>[];
  final line = StringBuffer();
  var lineHasToken = false;
  var indent = 0;
  var parenDepth = 0;
  String? currentClause;
  String? prevText;

  void beginLine() {
    line.write('  ' * indent);
    lineHasToken = false;
  }

  void pushLine({bool allowEmpty = false}) {
    final text = line.toString().trimRight();
    if (text.isNotEmpty || allowEmpty) {
      lines.add(text);
    }
    line.clear();
    beginLine();
  }

  void appendToken(String text, {bool spaceBefore = true}) {
    if (!lineHasToken) {
      line.write(text);
      lineHasToken = true;
      prevText = text;
      return;
    }
    final noSpaceBefore = prevText == '(' || prevText == '.';
    if (spaceBefore && !noSpaceBefore) {
      line.write(' ');
    }
    line.write(text);
    prevText = text;
  }

  String? clausePhraseAt(int index) {
    String? joinWords(int count) {
      if (index + count > tokens.length) return null;
      for (int i = 0; i < count; i++) {
        if (!tokens[index + i].isWord) return null;
      }
      return tokens.sublist(index, index + count).map((t) => t.text.toUpperCase()).join(' ');
    }

    for (final count in const [3, 2]) {
      final phrase = joinWords(count);
      if (phrase == null) continue;
      if (_majorClauses.contains(phrase) || _joinClauses.contains(phrase)) {
        return phrase;
      }
    }
    if (tokens[index].isWord) {
      final one = tokens[index].text.toUpperCase();
      if (_majorClauses.contains(one) || _joinClauses.contains(one)) {
        return one;
      }
    }
    return null;
  }

  int phraseWordCount(String phrase) => phrase.split(' ').length;

  bool shouldBreakBeforeLogic(String word) {
    if (word != 'AND' && word != 'OR') return false;
    return currentClause == 'WHERE' || currentClause == 'HAVING' || currentClause == 'ON';
  }

  bool nextTokenStartsQuery(int index) {
    if (index >= tokens.length) return false;
    for (int i = index; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.type == _SqlTokenType.comment) continue;
      if (!token.isWord) return false;
      final upper = token.text.toUpperCase();
      return upper == 'SELECT' || upper == 'WITH';
    }
    return false;
  }

  beginLine();

  for (int i = 0; i < tokens.length; i++) {
    final token = tokens[i];

    if (token.type == _SqlTokenType.comment) {
      if (lineHasToken) pushLine();
      appendToken(token.text.trimRight(), spaceBefore: false);
      pushLine();
      continue;
    }

    if (token.text == ';') {
      appendToken(';', spaceBefore: false);
      pushLine();
      pushLine(allowEmpty: true);
      indent = 0;
      parenDepth = 0;
      currentClause = null;
      continue;
    }

    if (token.text == ',') {
      appendToken(',', spaceBefore: false);
      if ((currentClause == 'SELECT' || currentClause == 'SET' || currentClause == 'VALUES') && parenDepth == 0) {
        pushLine();
      }
      continue;
    }

    if (token.text == '(') {
      appendToken('(', spaceBefore: prevText != null && prevText != '(');
      parenDepth++;
      indent++;
      if (nextTokenStartsQuery(i + 1)) {
        pushLine();
      }
      continue;
    }

    if (token.text == ')') {
      parenDepth = parenDepth > 0 ? parenDepth - 1 : 0;
      indent = indent > 0 ? indent - 1 : 0;
      if (lineHasToken && !line.toString().trimRight().endsWith('(')) {
        pushLine();
      }
      appendToken(')', spaceBefore: false);
      continue;
    }

    final clause = clausePhraseAt(i);
    if (clause != null) {
      if (lineHasToken) {
        pushLine();
      }
      appendToken(clause, spaceBefore: false);
      currentClause = clause == 'UNION ALL' || clause == 'UNION' ? 'SELECT' : clause;
      i += phraseWordCount(clause) - 1;
      continue;
    }

    if (token.isWord) {
      final upper = token.text.toUpperCase();
      if (shouldBreakBeforeLogic(upper) && lineHasToken) {
        pushLine();
      }
      appendToken(_singleWordUpperKeywords.contains(upper) ? upper : token.text);
      continue;
    }

    appendToken(token.text, spaceBefore: token.text != '.');
  }

  final lastLine = line.toString().trimRight();
  if (lastLine.isNotEmpty) {
    lines.add(lastLine);
  }

  final result = lines.join('\n').trim();
  return result.isEmpty ? input : result;
}

List<_SqlToken> _tokenizeSql(String sql) {
  final tokens = <_SqlToken>[];
  int i = 0;

  bool isWordChar(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 48 && code <= 57) || // 0-9
        (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122) || // a-z
        c == '_' ||
        c == r'$';
  }

  while (i < sql.length) {
    final c = sql[i];

    if (c.trim().isEmpty) {
      i++;
      continue;
    }

    if (c == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
      int j = i + 2;
      while (j < sql.length && sql[j] != '\n') {
        j++;
      }
      tokens.add(_SqlToken(sql.substring(i, j), _SqlTokenType.comment));
      i = j;
      continue;
    }

    if (c == '/' && i + 1 < sql.length && sql[i + 1] == '*') {
      int j = i + 2;
      while (j + 1 < sql.length && !(sql[j] == '*' && sql[j + 1] == '/')) {
        j++;
      }
      j = (j + 1 < sql.length) ? j + 2 : sql.length;
      tokens.add(_SqlToken(sql.substring(i, j), _SqlTokenType.comment));
      i = j;
      continue;
    }

    if (c == '\'' || c == '"' || c == '`') {
      final quote = c;
      int j = i + 1;
      while (j < sql.length) {
        final current = sql[j];
        if (current == '\\' && quote != '`' && j + 1 < sql.length) {
          j += 2;
          continue;
        }
        if (current == quote) {
          if (quote == '\'' && j + 1 < sql.length && sql[j + 1] == '\'') {
            j += 2;
            continue;
          }
          j++;
          break;
        }
        j++;
      }
      tokens.add(_SqlToken(sql.substring(i, j), _SqlTokenType.string));
      i = j;
      continue;
    }

    if ('(),;.'.contains(c)) {
      tokens.add(_SqlToken(c, _SqlTokenType.symbol));
      i++;
      continue;
    }

    int j = i;
    while (j < sql.length) {
      final cc = sql[j];
      if (cc.trim().isEmpty || '(),;.\'"`'.contains(cc)) {
        break;
      }
      if (cc == '-' && j + 1 < sql.length && sql[j + 1] == '-') {
        break;
      }
      if (cc == '/' && j + 1 < sql.length && sql[j + 1] == '*') {
        break;
      }
      j++;
    }
    final text = sql.substring(i, j);
    tokens.add(_SqlToken(text, text.split('').every(isWordChar) ? _SqlTokenType.word : _SqlTokenType.other));
    i = j;
  }

  return tokens;
}
