class MaskingUtil {
  static List<String> maskedKeys = [
    'authorization',
    'password',
    'token',
    'access_token',
    'secret',
    'pin',
    'cookie',
    'captcha',
    'otp',
  ];

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
  /// A key matches when the words of a masked key appear, in order, among the
  /// words of [key]. Words are split on case changes and on anything that is
  /// not a letter or digit, so `fcmToken`, `access_token` and `refresh-token`
  /// match `token`, while `shipping` does not match `pin`.
  static bool isMaskedKey(String key) {
    final words = _words(key);
    return maskedKeys.any((masked) {
      final needle = _words(masked);
      if (needle.isEmpty || needle.length > words.length) return false;
      for (var start = 0; start <= words.length - needle.length; start++) {
        var matches = true;
        for (var i = 0; i < needle.length; i++) {
          if (words[start + i] != needle[i]) {
            matches = false;
            break;
          }
        }
        if (matches) return true;
      }
      return false;
    });
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

    if (data is Map) {
      final Map<String, dynamic> maskedMap = {};
      data.forEach((key, value) {
        final String keyStr = key.toString();
        if (isMaskedKey(keyStr)) {
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
