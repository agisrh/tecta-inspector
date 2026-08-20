class MaskingUtil {
  static List<String> maskedKeys = [
    'authorization',
    'password',
    'token',
    'access_token',
    'secret',
    'pin',
    'cookie',
  ];

  static final List<RegExp> sensitivePatterns = [
    // JWT Token Pattern
    RegExp(r'eyJhbGciOi[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'),
    // Bearer Token Pattern
    RegExp(r'^Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$', caseSensitive: false),
    // Basic Auth Pattern
    RegExp(r'^Basic\s+[A-Za-z0-9+/=]+$', caseSensitive: false),
    // Credit Card (simple 13-16 digits pattern)
    RegExp(r'\b(?:\d[ -]*?){13,16}\b'),
  ];

  /// Masks sensitive fields recursively in maps or lists.
  static dynamic mask(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final Map<String, dynamic> maskedMap = {};
      data.forEach((key, value) {
        final String keyStr = key.toString();
        if (maskedKeys.any((maskedKey) => keyStr.toLowerCase().contains(maskedKey.toLowerCase()))) {
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
    }

    return data;
  }
}
