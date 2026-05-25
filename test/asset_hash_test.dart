import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Quran asset SHA-256 matches scripts/quran_hash.txt', () {
    final asset = File('assets/quran/quran_uthmani.json');
    final hashFile = File('scripts/quran_hash.txt');
    expect(asset.existsSync(), isTrue);
    expect(hashFile.existsSync(), isTrue);

    final bytes = asset.readAsBytesSync();
    final computed = sha256.convert(bytes).toString();
    final approved = hashFile.readAsStringSync().trim();

    expect(computed, approved,
        reason:
            'The Quran asset has been modified. If this is intentional, '
            're-derive the JSON from the approved Tanzil source XML, '
            'MANUALLY VERIFY the contents, then update scripts/quran_hash.txt.');
  });
}
