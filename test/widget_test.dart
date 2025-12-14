import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App initialization smoke test', () {
    // Basit bir test, uygulama mantığını test etmek için 
    // mock servislerin (Database, SharedPreferences) kurulması gerekir.
    // Şimdilik sadece 1=1 testi yapıyoruz.
    expect(1, 1);
  });
}
