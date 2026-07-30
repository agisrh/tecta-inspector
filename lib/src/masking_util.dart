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

    return data;
  }
}
