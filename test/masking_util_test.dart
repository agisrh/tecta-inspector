import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/masking_util.dart';

void main() {
  const masked = '*** [MASKED] ***';

  tearDown(() {
    MaskingUtil.maskedKeys = [
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
  });

  group('isMaskedKey', () {
    test('matches a masked word in any casing style', () {
      for (final key in [
        'password',
        'Password',
        'fcmToken',
        'refreshToken',
        'access_token',
        'refresh-token',
        'mfaToken',
        'Authorization',
        'captcha',
        'userPin',
      ]) {
        expect(MaskingUtil.isMaskedKey(key), isTrue, reason: key);
      }
    });

    test('does not match a word that only contains a masked one', () {
      for (final key in ['shipping', 'mapping', 'optional', 'pinned']) {
        expect(MaskingUtil.isMaskedKey(key), isFalse, reason: key);
      }
    });

    test('honours keys added by the app', () {
      MaskingUtil.maskedKeys = ['national_id'];

      expect(MaskingUtil.isMaskedKey('nationalId'), isTrue);
      expect(MaskingUtil.isMaskedKey('id'), isFalse);
    });
  });

  group('mask', () {
    test('masks the values of sensitive keys, deeply', () {
      final result = MaskingUtil.mask({
        'username': 'demo',
        'password': 'secret',
        'deviceInfo': {'model': 'A1'},
        'items': [
          {'fcmToken': 'abc', 'name': 'ok'},
        ],
      }) as Map;

      expect(result['username'], 'demo');
      expect(result['password'], masked);
      expect((result['deviceInfo'] as Map)['model'], 'A1');
      final item = (result['items'] as List).single as Map;
      expect(item['fcmToken'], masked);
      expect(item['name'], 'ok');
    });

    test('keeps ordinary fields that only look like a masked key', () {
      final result =
          MaskingUtil.mask({'shipping': 'JNE', 'mapping': 'x'}) as Map;

      expect(result['shipping'], 'JNE');
      expect(result['mapping'], 'x');
    });

    test('masks a real card number but not a millisecond timestamp', () {
      expect(MaskingUtil.mask('4111 1111 1111 1111'), masked);
      expect(MaskingUtil.mask('4111111111111111'), masked);
      expect(MaskingUtil.mask('1764206759820'), '1764206759820');
      expect(MaskingUtil.mask('081234567890'), '081234567890');
    });

    test('still masks a JWT', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc123';

      expect(MaskingUtil.mask(jwt), masked);
    });
  });
}
