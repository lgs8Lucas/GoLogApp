import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:golog/util/jwt_utils.dart';
import 'package:golog/util/map_utils.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

String _jwt(Map<String, dynamic> payload) {
  String enc(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc(payload)}.assinatura';
}

void main() {
  group('JwtUtils', () {
    final now = DateTime.utc(2026, 11, 17, 12);

    test('lê exp', () {
      final exp = now.add(const Duration(hours: 1));
      final token = _jwt({'exp': exp.millisecondsSinceEpoch ~/ 1000});
      expect(JwtUtils.expiration(token), exp);
      expect(JwtUtils.isExpiringSoon(token, now: now), isFalse);
    });

    test('perto de expirar', () {
      final exp = now.add(const Duration(minutes: 2));
      final token = _jwt({'exp': exp.millisecondsSinceEpoch ~/ 1000});
      expect(JwtUtils.isExpiringSoon(token, now: now), isTrue);
    });

    test('token ilegível é tratado como expirando', () {
      expect(JwtUtils.expiration('não-é-jwt'), isNull);
      expect(JwtUtils.isExpiringSoon('não-é-jwt', now: now), isTrue);
    });
  });

  group('MapUtils.getCenterAndZoom', () {
    test('lista vazia', () {
      final r = MapUtils.getCenterAndZoom([]);
      expect(r['zoom'], 2.0);
    });

    test('centro é a média e zoom fica no intervalo', () {
      final r = MapUtils.getCenterAndZoom(const [
        LatLng(latitude: -23.0, longitude: -46.0),
        LatLng(latitude: -24.0, longitude: -47.0),
      ]);
      final center = r['center'] as LatLng;
      expect(center.latitude, closeTo(-23.5, 1e-9));
      expect(center.longitude, closeTo(-46.5, 1e-9));
      expect(r['zoom'], inInclusiveRange(3.0, 15.0));
    });

    test('ponto único usa zoom padrão', () {
      final r = MapUtils.getCenterAndZoom(const [
        LatLng(latitude: -23.0, longitude: -46.0),
      ]);
      expect(r['zoom'], 13.0);
    });
  });
}
