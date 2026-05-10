import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/models/room_chore_suggestion.dart';

void main() {
  group('RoomChoreSuggestions', () {
    test('always includes basic room maintenance prompts', () {
      final suggestions = RoomChoreSuggestions.forRoomName('Hallway');

      expect(suggestions.map((s) => s.id), contains('floor'));
      expect(suggestions.map((s) => s.id), contains('windows'));
      expect(suggestions.map((s) => s.id), contains('dust'));
    });

    test('adds bathroom-specific prompts for toilets', () {
      final suggestions = RoomChoreSuggestions.forRoomName('Downstairs toilet');

      expect(suggestions.map((s) => s.id), contains('toilet'));
      expect(suggestions.map((s) => s.id), contains('sink_mirror'));
    });

    test('suggestion converts to a room-scoped chore body', () {
      final suggestion = RoomChoreSuggestions.forRoomName('Kitchen').first;

      final body = suggestion.toChoreBody('room1');

      expect(body['room'], 'room1');
      expect(body['season'], 'All');
      expect(body['interval_unit'], isIn(IntervalUnits.all));
      expect(body['onetimeonly_assignee'], '');
    });
  });
}
