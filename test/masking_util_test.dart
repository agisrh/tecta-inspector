import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/masking_util.dart';

void main() {
  const masked = '*** [MASKED] ***';

  tearDown(() {
    MaskingUtil.enabled = true;
    MaskingUtil.maskedKeys = [...MaskingUtil.defaultMaskedKeys];
    MaskingUtil.unmaskedKeys = [];
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

    test('does not mask a flag or a number that only describes a secret', () {
      for (final key in [
        'passwordExpired',
        'passwordAgeDays',
        'passwordWarning',
        'passwordChangeRequired',
        'tokenType',
        'tokenExpDate',
        'accessTokenExpiresIn',
      ]) {
        expect(MaskingUtil.isMaskedKey(key), isFalse, reason: key);
      }
    });

    test('does not mask a date or a time that only describes a secret', () {
      for (final key in [
        'expireDate',
        'passwordChangedAt',
        'passwordUpdatedAt',
        'passwordCreatedDate',
        'tokenIssuedAt',
        'tokenValidUntil',
        'passwordLastChanged',
      ]) {
        expect(MaskingUtil.isMaskedKey(key), isFalse, reason: key);
      }
    });

    test('still masks a secret that has a word after it', () {
      for (final key in [
        'passwordChangeToken',
        'mfaToken',
        'otpCode',
        'passwordHash',
        'newPassword',
        'currentPassword',
      ]) {
        expect(MaskingUtil.isMaskedKey(key), isTrue, reason: key);
      }
    });

    test('a flag with a name no list knows is not masked', () {
      for (final key in [
        'passwordResetPending',
        'passwordRotationDue',
        'tokenRefreshSoon',
        'secretQuestionAnswered',
      ]) {
        expect(MaskingUtil.isMaskedKey(key), isFalse, reason: key);
      }
    });

    test('a field that repeats a password is masked', () {
      for (final key in [
        'passwordConfirmation',
        'passwordConfirm',
        'confirmPassword',
        'oldPassword',
      ]) {
        expect(MaskingUtil.isMaskedKey(key), isTrue, reason: key);
      }
    });

    test('unmaskedKeys names fields that are never masked', () {
      MaskingUtil.unmaskedKeys = ['sort_key'];

      expect(MaskingUtil.isMaskedKey('sortKey'), isFalse);
      expect(MaskingUtil.isMaskedKey('otherKey'), isTrue);
    });

    test('unmaskedKeys wins over a masked name', () {
      MaskingUtil.unmaskedKeys = ['token'];

      expect(MaskingUtil.isMaskedKey('token'), isFalse);
      expect(MaskingUtil.isMaskedKey('mfaToken'), isTrue,
          reason: 'exact names only');
    });

    test('the app can extend the defaults', () {
      MaskingUtil.maskedKeys = [...MaskingUtil.defaultMaskedKeys, 'cpf'];

      expect(MaskingUtil.isMaskedKey('userCpf'), isTrue);
      expect(MaskingUtil.isMaskedKey('password'), isTrue);
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

    test('masks the secrets of a login answer and keeps its flags', () {
      final result = MaskingUtil.mask({
        'token': 'a.b.c',
        'refreshToken': 'r',
        'passwordExpired': false,
        'passwordAgeDays': 12,
        'passwordWarning': 'soon',
        'mfaRequired': false,
        'mfaToken': 'm',
        'passwordChangeRequired': false,
        'passwordChangeToken': 'c',
      }) as Map;

      expect(result['token'], masked);
      expect(result['refreshToken'], masked);
      expect(result['mfaToken'], masked);
      expect(result['passwordChangeToken'], masked);
      expect(result['passwordExpired'], false);
      expect(result['passwordAgeDays'], 12);
      expect(result['passwordWarning'], 'soon');
      expect(result['mfaRequired'], false);
      expect(result['passwordChangeRequired'], false);
    });

    test('a true or false is never masked, whatever the key', () {
      final result = MaskingUtil.mask({
        'password': true,
        'isPassword': false,
        'passwordChanged': true,
        'token': 'abc',
      }) as Map;

      expect(result['password'], true);
      expect(result['isPassword'], false);
      expect(result['passwordChanged'], true);
      expect(result['token'], masked);
    });

    test('shows the real values while masking is switched off', () {
      MaskingUtil.enabled = false;

      final result = MaskingUtil.mask({
        'password': 'Abcdef1!',
        'nested': {'token': 'abc'},
        'header': 'Bearer abc.def.ghi',
      }) as Map;

      expect(result['password'], 'Abcdef1!');
      expect((result['nested'] as Map)['token'], 'abc');
      expect(result['header'], 'Bearer abc.def.ghi');
    });

    test('masks again once it is switched back on', () {
      MaskingUtil.enabled = false;
      MaskingUtil.enabled = true;

      expect((MaskingUtil.mask({'password': 'x'}) as Map)['password'], masked);
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
