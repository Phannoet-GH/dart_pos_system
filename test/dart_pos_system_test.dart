import 'package:dart_pos_system/app.dart';
import 'package:test/test.dart';

void main() {
  test('App initializes without errors', () {
    final App posApp = App();
    expect(posApp, isNotNull);
  });
}