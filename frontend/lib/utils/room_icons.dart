import 'package:flutter/material.dart';
import '../models/room.dart';

class RoomIconOption {
  const RoomIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const roomIconOptions = [
  RoomIconOption(key: 'room', label: 'Room', icon: Icons.meeting_room_outlined),
  RoomIconOption(key: 'kitchen', label: 'Kitchen', icon: Icons.kitchen),
  RoomIconOption(key: 'bathroom', label: 'Bathroom', icon: Icons.bathtub),
  RoomIconOption(key: 'toilet', label: 'Toilet', icon: Icons.wc),
  RoomIconOption(key: 'bedroom', label: 'Bedroom', icon: Icons.bed),
  RoomIconOption(
    key: 'dressing',
    label: 'Dressing room',
    icon: Icons.checkroom,
  ),
  RoomIconOption(key: 'living', label: 'Living', icon: Icons.weekend),
  RoomIconOption(key: 'dining', label: 'Dining', icon: Icons.table_restaurant),
  RoomIconOption(key: 'hallway', label: 'Hallway', icon: Icons.door_front_door),
  RoomIconOption(key: 'garden', label: 'Garden', icon: Icons.yard),
  RoomIconOption(
    key: 'laundry',
    label: 'Laundry',
    icon: Icons.local_laundry_service,
  ),
  RoomIconOption(
    key: 'utility',
    label: 'Utility room',
    icon: Icons.inventory_2_outlined,
  ),
  RoomIconOption(key: 'pantry', label: 'Pantry', icon: Icons.shelves),
  RoomIconOption(key: 'garage', label: 'Garage', icon: Icons.garage_outlined),
  RoomIconOption(key: 'office', label: 'Office', icon: Icons.desk_outlined),
  RoomIconOption(key: 'attic', label: 'Attic', icon: Icons.roofing),
  RoomIconOption(key: 'basement', label: 'Basement', icon: Icons.foundation),
  RoomIconOption(key: 'storage', label: 'Storage', icon: Icons.inventory),
];

RoomIconOption roomIconOptionForKey(String key) {
  final normalized = key.trim().toLowerCase();
  for (final option in roomIconOptions) {
    if (option.key == normalized) return option;
  }
  return roomIconOptions.first;
}

IconData iconForRoom(Room room) {
  final configured = room.icon.trim();
  if (configured.isNotEmpty) return roomIconOptionForKey(configured).icon;

  final name = room.name.toLowerCase();
  if (_containsAny(name, ['utility', 'bijkeuken', 'scullery'])) {
    return Icons.inventory_2_outlined;
  }
  if (_containsAny(name, ['kitchen', 'keuken'])) return Icons.kitchen;
  if (_containsAny(name, ['toilet', 'wc'])) return Icons.wc;
  if (_containsAny(name, ['bath', 'badkamer'])) return Icons.bathtub;
  if (_containsAny(name, ['bed', 'slaapkamer'])) return Icons.bed;
  if (_containsAny(name, ['dressing', 'kleedkamer'])) return Icons.checkroom;
  if (_containsAny(name, ['living', 'woonkamer', 'lounge'])) {
    return Icons.weekend;
  }
  if (_containsAny(name, ['dining', 'eetkamer'])) {
    return Icons.table_restaurant;
  }
  if (_containsAny(name, ['hall', 'hallway', 'entry', 'gang', 'hal'])) {
    return Icons.door_front_door;
  }
  if (_containsAny(name, ['garden', 'tuin'])) return Icons.yard;
  if (_containsAny(name, ['laundry', 'washok', 'wasruimte'])) {
    return Icons.local_laundry_service;
  }
  if (_containsAny(name, ['pantry', 'voorraadkast'])) return Icons.shelves;
  if (name.contains('garage')) return Icons.garage_outlined;
  if (_containsAny(name, ['office', 'study', 'kantoor', 'werkkamer'])) {
    return Icons.desk_outlined;
  }
  if (_containsAny(name, ['attic', 'zolder'])) return Icons.roofing;
  if (_containsAny(name, ['basement', 'kelder'])) return Icons.foundation;
  if (_containsAny(name, ['storage', 'berging', 'kast'])) {
    return Icons.inventory;
  }
  return Icons.meeting_room_outlined;
}

bool _containsAny(String value, List<String> needles) {
  return needles.any(value.contains);
}
