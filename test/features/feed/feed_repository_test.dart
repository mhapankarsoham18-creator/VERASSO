import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/features/feed/repositories/feed_repository.dart';
import 'dart:convert';

class MockBox extends Mock implements Box {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late FeedRepository repository;
  late MockBox mockBox;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockBox = MockBox();
    mockSupabase = MockSupabaseClient();
    
    repository = FeedRepository(
      null,
      mockBox,
      mockSupabase,
    );
  });

  group('FeedRepository Offline Logic', () {
    test('getFeedStream emits local posts immediately if available', () async {
      // Arrange
      final fakePost = {'id': '123', 'created_at': '2026-05-02T12:00:00Z', 'content': 'Test'};
      when(() => mockBox.values).thenReturn([jsonEncode(fakePost)]);
      
      // We purposefully let Supabase throw or we don't mock it to simulate offline/failure
      when(() => mockSupabase.from(any())).thenThrow(Exception('Offline'));

      // Act
      final stream = repository.getFeedStream();
      final emissions = await stream.take(1).toList();

      // Assert
      expect(emissions.length, 1);
      expect(emissions.first.length, 1);
      expect(emissions.first.first['id'], '123');
    });

    test('getFeedStream yields empty list if box is empty and server fails', () async {
      // Arrange
      when(() => mockBox.values).thenReturn([]);
      when(() => mockSupabase.from(any())).thenThrow(Exception('Offline'));

      // Act
      final stream = repository.getFeedStream();
      final emissions = await stream.take(1).toList();

      // Assert
      expect(emissions.length, 1);
      expect(emissions.first, isEmpty);
    });
  });
}
