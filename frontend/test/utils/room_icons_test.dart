import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/room.dart';
import 'package:frontend/utils/room_icons.dart';

void main() {
  group('iconForRoom', () {
    IconData iconFor(String name) {
      return iconForRoom(
        Room(id: name, name: name, icon: '', created: DateTime(2026)),
      );
    }

    test('matches common Dutch room names', () {
      expect(iconFor('Bijkeuken'), Icons.inventory_2_outlined);
      expect(iconFor('Slaapkamer'), Icons.bed);
      expect(iconFor('Kleedkamer'), Icons.checkroom);
      expect(iconFor('Gang'), Icons.door_front_door);
      expect(iconFor('Zolder'), Icons.roofing);
      expect(iconFor('Kelder'), Icons.foundation);
    });

    test('uses configured icon when set', () {
      final room = Room(
        id: '1',
        name: 'Anything',
        icon: 'dressing',
        created: DateTime(2026),
      );

      expect(iconForRoom(room), Icons.checkroom);
    });
  });
}
