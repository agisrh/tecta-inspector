class MaskingUtil {
  /// Whether [mask] hides anything. It is on unless the inspector's user turned
  /// it off to read the real values; it only affects what is logged afterwards.
  static bool enabled = true;

  /// The names that are secrets, as shipped. An app that sets [maskedKeys]
  /// replaces them; to add its own, `[...MaskingUtil.defaultMaskedKeys, 'cpf']`.
  static const List<String> defaultMaskedKeys = [
    'authorization',
    'password',
    'passwd',
    'pwd',
    'password confirm',
    'password confirmation',
    'password repeat',
    'token',
    'secret',
    'pin',
    'cookie',
    'captcha',
    'otp',
    'otp code',
    'key',
    'hash',
    'signature',
  ];

  /// The names whose fields are masked. A field is masked when its name ENDS
  /// with one of them, word by word: `newPassword`, `refresh_token` and
  /// `passwordChangeToken` end with `password` or `token`; `passwordExpired`
  /// and `tokenType` do not. What a name ends with is what the field holds.
  static List<String> maskedKeys = [...defaultMaskedKeys];

  /// Field names that are never masked, even when they end with a masked name.
  /// Each one matches the whole name, in any casing style: `sort_key` matches
  /// `sortKey`, not `primaryKey`.
  static List<String> unmaskedKeys = [];


  static final List<RegExp> sensitivePatterns = [
    // JWT Token Pattern
    RegExp(r'eyJhbGciOi[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'),
    // Bearer Token Pattern
    RegExp(r'^Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$', caseSensitive: false),
    // Basic Auth Pattern
    RegExp(r'^Basic\s+[A-Za-z0-9+/=]+$', caseSensitive: false),
  ];

  /// A run of 13 to 19 digits, optionally grouped by spaces or dashes. It is
  /// masked only when it also passes the Luhn check, so ordinary numbers such
  /// as millisecond timestamps are left alone.
  static final RegExp _cardCandidate = RegExp(r'\b(?:\d[ -]?){12,18}\d\b');

  /// Whether the field called [key] holds something sensitive.
  ///
  /// The name is split into words on case changes and on anything that is not a
  /// letter or digit: `fcmToken`, `access_token` and `refresh-token` end with
  /// the word `token`. A field is masked when its words end with the words of a
  /// masked name, so `shipping` does not match `pin`, and `passwordExpired` does
  /// not match `password` because the name ends with `expired`.
  static bool isMaskedKey(String key) {
    final words = _words(key);
    if (words.isEmpty) return false;
    if (unmaskedKeys.any((name) => _sameWords(_words(name), words))) return false;
    return maskedKeys.any((masked) {
      final needle = _words(masked);
      if (needle.isEmpty || needle.length > words.length) return false;
      final offset = words.length - needle.length;
      for (var i = 0; i < needle.length; i++) {
        if (words[offset + i] != needle[i]) return false;
      }
      return true;
    });
  }

  static bool _sameWords(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<String> _words(String key) => key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word.toLowerCase())
      .toList();

  static bool _looksLikeCardNumber(String value) {
    for (final match in _cardCandidate.allMatches(value)) {
      final digits = match[0]!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 13 && digits.length <= 19 && _luhn(digits)) {
        return true;
      }
    }
    return false;
  }

  static bool _luhn(String digits) {
    var sum = 0;
    var double = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = digits.codeUnitAt(i) - 48;
      if (double) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      double = !double;
    }
    return sum % 10 == 0;
  }

  /// Masks sensitive fields recursively in maps or lists.
  static dynamic mask(dynamic data) {
    if (data == null) return null;
    if (!enabled) return data;

    if (data is Map) {
      final Map<String, dynamic> maskedMap = {};
      data.forEach((key, value) {
        final String keyStr = key.toString();
        // A true or false cannot be a secret, whatever the key is called.
        if (isMaskedKey(keyStr) && value is! bool) {
          maskedMap[keyStr] = '*** [MASKED] ***';
        } else {
          maskedMap[keyStr] = mask(value);
        }
      });
      return maskedMap;
    }

    if (data is List) {
      return data.map((item) => mask(item)).toList();
    }

    if (data is String) {
      for (final pattern in sensitivePatterns) {
        if (pattern.hasMatch(data)) {
          return '*** [MASKED] ***';
        }
      }
      if (_looksLikeCardNumber(data)) return '*** [MASKED] ***';
    }

    return data;
  }
}
