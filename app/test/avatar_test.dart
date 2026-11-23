import 'package:powerhub/shared/widgets/misc/app_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initials use words only', () {
    expect(AppAvatar.initials('Hasibul Hasan'), 'HH');
    expect(AppAvatar.initials('rony'), 'R');
    expect(AppAvatar.initials('Abbu & Ammu (wedding)'), 'AA');
    expect(AppAvatar.initials('City Bank'), 'CB');
    expect(AppAvatar.initials('  '), '');
  });
}
