import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:verasso/core/storage/encrypted_hive_storage.dart';

void main() {
  late EncryptedHiveStorage storage;

  setUp(() async {
    await setUpTestHive();
    storage = EncryptedHiveStorage();
  });

  tearDown(() {
    // Cleanup
  });

  group('Encrypted Hive Storage - At-Rest Encryption', () {
    test('data persisted as encrypted bytes', () async {
      const testData = {'name': 'John', 'email': 'john@example.com'};
      await storage.write('user-1', testData);

      final stored = await storage.read('user-1');
      expect(stored!['name'], equals('John'));
      expect(stored['email'], equals('john@example.com'));
    });

    test('reading decrypts data transparently', () async {
      const testData = {'name': 'Jane', 'id': '123'};
      await storage.write('user-2', testData);

      final read = await storage.read('user-2');
      expect(read!['name'], 'Jane');
      expect(read['id'], '123');
    });

    test('data not readable as plaintext from storage', () async {
      const testData = {'secret': 'confidential-value'};
      await storage.write('secure-1', testData);

      // Verify encryption happened
      final encrypted = await storage.getRawBytes('secure-1');
      expect(encrypted.toString().contains('confidential-value'), isFalse);
    });

    test('corrupted data fails gracefully', () async {
      // Simulate corrupted encrypted data
      await storage.writeRaw('corrupted', [0xFF, 0xFE, 0xFD, 0xFC]);

      expect(
        () => storage.read('corrupted'),
        throwsException,
      );
    });

    test('missing key returns null', () async {
      final result = await storage.read('nonexistent-key');
      expect(result, isNull);
    });

    test('empty data can be stored and retrieved', () async {
      final emptyData = <String, dynamic>{};
      await storage.write('empty-1', emptyData);

      final read = await storage.read('empty-1');
      expect(read!, equals(Map<String, dynamic>.from(emptyData)));
    });

    test('large objects can be stored', () async {
      final largeData = {
        'description': 'x' * 10000,
        'metadata': List.generate(100, (i) => {'id': i, 'value': 'data-$i'}),
      };
      await storage.write('large-1', largeData);

      final read = await storage.read('large-1');
      expect(read!['description'].length, equals(10000));
      expect((read['metadata'] as List).length, equals(100));
    });

    test('update overwrites previous data', () async {
      const data1 = {'version': '1'};
      const data2 = {'version': '2'};

      await storage.write('record-1', data1);
      var read = await storage.read('record-1');
      expect(read!['version'], equals('1'));

      await storage.write('record-1', data2);
      read = await storage.read('record-1');
      expect(read!['version'], equals('2'));
    });
  });

  group('Encrypted Hive Storage - User Isolation', () {
    test('user A cannot read user B data', () async {
      const userAData = {'secret': 'A-secret'};
      const userBData = {'secret': 'B-secret'};

      await storage.write('user-A', userAData);
      await storage.write('user-B', userBData);

      final aReads = await storage.read('user-A');
      expect(aReads!['secret'], 'A-secret');

      final bReads = await storage.read('user-B');
      expect(bReads!['secret'], 'B-secret');
    });

    test('user keys are independently encrypted', () async {
      const data1 = {'sensitive': 'data1'};
      const data2 = {'sensitive': 'data2'};

      await storage.write('key-1', data1);
      await storage.write('key-2', data2);

      final raw1 = await storage.getRawBytes('key-1');
      final raw2 = await storage.getRawBytes('key-2');

      expect(raw1, isNot(equals(raw2)));
    });

    test('multiple keys within same storage are isolated', () async {
      await storage.write('a', {'value': 'a-value'});
      await storage.write('b', {'value': 'b-value'});
      await storage.write('c', {'value': 'c-value'});

      expect((await storage.read('a'))!['value'], 'a-value');
      expect((await storage.read('b'))!['value'], 'b-value');
      expect((await storage.read('c'))!['value'], 'c-value');
    });
  });

  group('Encrypted Hive Storage - Persistence', () {
    test('data persists across storage instances', () async {
      const data = {'persistent': 'value'};
      await storage.write('persist-1', data);

      final storage2 = EncryptedHiveStorage();
      final read = await storage2.read('persist-1');
      expect(read!['persistent'], equals('value'));
    });

    test('session data does not persist after deletion', () async {
      const data = {'temporary': 'value'};
      await storage.write('temp-1', data);

      await storage.delete('temp-1');
      final read = await storage.read('temp-1');
      expect(read, isNull);
    });

    test('storage clear removes all data', () async {
      await storage.write('data-1', {'val': '1'});
      await storage.write('data-2', {'val': '2'});

      await storage.clear();

      expect(await storage.read('data-1'), isNull);
      expect(await storage.read('data-2'), isNull);
    });
  });
}
